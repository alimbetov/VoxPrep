# CareerSpeak — TTS Worker Implementation Plan

**Branch:** `feat/tts-worker-foundation`  
**Base:** `main` at `8b40477b493ad16608381ca0f8e1daf2860e431f`  
**Status:** Initial implementation design

Normative parent:

- `docs/architecture/CAREERSPEAK_TTS_PIPELINE.md`
- `docs/architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`

## Goal

Implement a separate server-managed TTS Worker that converts one backend-owned TTS job into one immutable audio asset.

```text
Backend PostgreSQL queue
        │
        │ POST /internal/v1/tts/jobs/claim
        ▼
TTS Worker
        │
        ├─ resolve exact voice_model_id
        ├─ local immutable model cache
        ├─ Piper synthesis
        ├─ FFmpeg post-processing
        ├─ technical QC
        ├─ presigned PUT → RustFS
        └─ complete/fail callback
```

The worker never owns publication state and never accesses PostgreSQL directly.

## Architecture decision

The SQL queue remains backend-owned:

```sql
SELECT id
FROM tts_job
WHERE status = 'PENDING'
   OR (status = 'RUNNING' AND lease_until < NOW())
ORDER BY created_at, id
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

The worker calls `POST /internal/v1/tts/jobs/claim`; the Backend executes the atomic `FOR UPDATE SKIP LOCKED` claim and returns a lease.

This preserves one authority for:

```text
job lifecycle
retry policy
lease ownership
fingerprint validation
content revision validation
model authorization
RustFS presigning
```

RabbitMQ is intentionally not required for the first production slice.

## Runtime boundary

Recommended runtime:

```text
Python worker process/container
Piper
FFmpeg
HTTP client
local model cache volume
```

Required runtime configuration:

```text
BACKEND_URL
WORKER_ID
WORKER_TOKEN
LOCAL_MODEL_CACHE_PATH
POLL_INTERVAL
MAX_LOADED_MODELS
LEASE_HEARTBEAT_INTERVAL
```

Forbidden configuration:

```text
PostgreSQL credentials
ADMIN password
learner installation token
permanent RustFS access/secret keys
```

## Proposed source layout

```text
worker/
├── pyproject.toml
├── README.md
├── Dockerfile
├── src/
│   └── careerspeak_tts_worker/
│       ├── main.py
│       ├── config.py
│       ├── application/
│       │   ├── worker_loop.py
│       │   ├── job_processor.py
│       │   └── heartbeat.py
│       ├── domain/
│       │   ├── job.py
│       │   ├── model.py
│       │   ├── audio.py
│       │   └── errors.py
│       ├── ports/
│       │   ├── backend.py
│       │   ├── synthesizer.py
│       │   ├── postprocessor.py
│       │   ├── model_cache.py
│       │   └── storage.py
│       └── adapters/
│           ├── backend_http.py
│           ├── piper.py
│           ├── ffmpeg.py
│           ├── filesystem_model_cache.py
│           └── rustfs_presigned.py
└── tests/
    ├── unit/
    ├── integration/
    └── acceptance/
```

Dependency direction:

```text
adapters → ports ← application → domain
```

Piper, FFmpeg and HTTP details must not leak into the worker orchestration state machine.

## Job processing state machine

Worker-local execution states are not persisted as backend business statuses.

```text
IDLE
  ↓ claim
LEASED
  ↓
MODEL_READY
  ↓
SYNTHESIZED
  ↓
POSTPROCESSED
  ↓
QC_PASSED
  ↓
UPLOADED
  ↓ complete
DONE
```

Any stage may produce a typed failure.

Backend remains authoritative for persisted status:

```text
PENDING → RUNNING → READY
                   ↘ FAILED
```

A lost lease terminates finalization even if local synthesis succeeded.

## Worker loop

Baseline algorithm:

```text
while running:
    claim one job

    if no job:
        sleep(POLL_INTERVAL)
        continue

    start lease heartbeat

    try:
        ensure exact model in local cache
        synthesize WAV with Piper
        validate synthesis output
        transcode/post-process with FFmpeg
        run technical QC
        request presigned upload
        upload immutable object
        complete job with lease token + fingerprint + asset metadata
    except LeaseLost:
        stop finalization
    except ClassifiedWorkerError as error:
        report fail when lease is still owned
    finally:
        stop heartbeat
        clean temporary files
```

The first implementation should process one job at a time per worker process. Horizontal scale is achieved by running multiple worker instances, not by adding internal concurrency first.

## Claim contract

Minimum claim response:

```text
jobId
contentRevisionId
audioRole
normalizedTtsText
voiceModelId
voiceModelCode
modelSha256
configSha256
fingerprint
leaseToken
leaseUntil
```

Model download authorization should be resolved by Backend and use short-lived URLs.

Worker must not silently replace `voiceModelId` with another voice/model.

## Model cache

Cache key:

```text
voice_model_id + immutable revision/checksum
```

Cache miss flow:

```text
request model download authorization
→ download model/config to temp directory
→ verify SHA-256 for both files
→ fsync/close
→ atomic rename into immutable cache directory
→ mark locally usable
```

Checksum mismatch is a hard failure.

Concurrent worker processes sharing one cache volume must not publish partially downloaded model directories. Initial deployment may avoid shared-volume concurrency; cache locking is qualified before enabling it.

## Heartbeat and lease loss

Heartbeat is independent from Piper/FFmpeg execution.

```text
POST /internal/v1/tts/jobs/{id}/heartbeat
```

Heartbeat includes:

```text
workerId
leaseToken
```

Backend extends the lease only for the current owner.

If heartbeat returns ownership loss / stale lease:

```text
worker marks local execution cancelled
→ no completion callback
→ no fail callback for the stale lease
→ temporary output is discarded
```

The worker cannot always interrupt Piper/FFmpeg instantly, but it must reject their result after lease loss.

## Synthesis and post-processing

Pipeline:

```text
normalized TTS text
→ Piper
→ temporary WAV
→ validation
→ FFmpeg
→ production MP3
→ QC
```

Initial production audio target remains configurable; do not hard-code a final bitrate/sample-rate policy until listening qualification is complete.

Piper invocation and FFmpeg invocation must capture:

```text
exit code
stderr
execution duration
output path
```

Worker logs must never contain machine tokens or presigned URL query credentials.

## Technical QC

Minimum checks:

```text
output exists
size > 0
duration > 0
expected codec
expected channel count
reasonable duration range
SHA-256 generated
FFmpeg probe succeeds
```

QC failure prevents upload/complete.

## Upload and completion

Upload flow:

```text
request presigned PUT
→ PUT immutable object to RustFS
→ verify HTTP success
→ POST complete callback
```

Completion request includes:

```text
jobId
workerId
leaseToken
fingerprint
voiceModelId
objectKey
sha256
sizeBytes
durationMs
codec
```

Backend accepts completion only when lease, model, fingerprint and content revision still match.

Callback handling must be idempotent. Upload success followed by callback loss must be recoverable without creating a second logical audio asset.

## Failure taxonomy

Worker errors are typed before reporting:

```text
VOICE_MODEL_NOT_FOUND
VOICE_MODEL_DOWNLOAD_FAILED
VOICE_MODEL_CHECKSUM_MISMATCH
VOICE_MODEL_LOAD_FAILED
PIPER_SYNTHESIS_FAILED
FFMPEG_FAILED
AUDIO_QC_FAILED
STORAGE_TEMPORARILY_UNAVAILABLE
BACKEND_TEMPORARILY_UNAVAILABLE
LEASE_LOST
INVALID_JOB_PAYLOAD
```

Retry policy is backend-owned. Worker reports facts; it does not independently convert every error into an unbounded retry loop.

## Observability

Every log/event should carry:

```text
workerId
jobId
voiceModelId
fingerprint prefix
stage
attempt context when supplied by Backend
```

Useful metrics:

```text
claim_empty_total
jobs_processed_total
jobs_failed_total
lease_lost_total
model_cache_hit_total
model_cache_miss_total
piper_duration_seconds
ffmpeg_duration_seconds
job_end_to_end_seconds
upload_bytes_total
```

## Implementation slices

### W0 — Contract qualification

Freeze worker-facing DTOs and error semantics.

Acceptance:

```text
claim/heartbeat/complete/fail contracts documented
lease loss semantics documented
no direct DB/RustFS-secret dependency
failure taxonomy accepted
```

### W1 — Runtime skeleton

Create Python package, configuration, structured logging, graceful shutdown and single-job polling loop using fake ports.

Acceptance:

```text
worker starts with validated config
idle polling is deterministic
SIGTERM stops new claims and cleans current resources
unit tests use fake backend/synthesizer/storage
```

### W2 — Backend HTTP adapter

Implement machine-token authenticated claim/heartbeat/complete/fail client.

Acceptance includes stale lease and duplicate callback cases.

### W3 — Model cache

Implement exact immutable model download, SHA-256 verification and atomic local installation.

### W4 — Piper + FFmpeg + QC

Implement real synthesis, post-processing and probe-based validation behind ports.

### W5 — RustFS upload

Implement short-lived presigned PUT flow and completion metadata.

### W6 — Recovery qualification

Prove:

```text
worker crash during Piper
worker crash during FFmpeg
lease expiry and reclaim
stale completion rejection
callback loss after successful upload
duplicate complete/fail
model checksum mismatch
corrupt output
backend restart
RustFS temporary outage
```

### W7 — Container and CI

Add production Docker image, health/readiness strategy, persistent model cache volume contract and CI gates.

## Explicit non-goals for the first slice

Do not add yet:

```text
RabbitMQ
GPU scheduling
multiple jobs concurrently inside one worker
voice-model auto-selection
publication logic
ADMIN review logic
learner APIs
worker direct PostgreSQL access
worker permanent RustFS credentials
```

## First implementation target

The first code commit after this design should be **W1 Runtime Skeleton** only.

It should prove this vertical seam:

```text
FakeBackend.claim()
→ JobProcessor
→ FakeSynthesizer
→ FakePostProcessor
→ FakeStorage
→ FakeBackend.complete()
```

No Piper, FFmpeg or RustFS dependency is required to qualify W1.

That gives the worker a testable orchestration core before infrastructure adapters are introduced.
