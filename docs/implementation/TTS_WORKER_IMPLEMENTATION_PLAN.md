# CareerSpeak — TTS Worker Implementation Plan

**Branch:** `feat/tts-worker-foundation`  
**Base:** `main` at `8b40477b493ad16608381ca0f8e1daf2860e431f`  
**Status:** W0 design in progress

Normative parents:

- `docs/architecture/CAREERSPEAK_TTS_PIPELINE.md`
- `docs/architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`

Detailed W0 worker contract:

- `docs/implementation/TTS_WORKER_W0_CONTRACT.md`

## Goal

Implement a separate server-managed TTS Worker that converts one backend-owned TTS job into one backend-owned immutable audio asset.

```text
Backend PostgreSQL queue
        │
        │ POST /internal/v1/tts/jobs/claim
        ▼
TTS Worker
        │
        ├─ exact backend-supplied fileId/jobId
        ├─ resolve exact voice_model_id
        ├─ local immutable model cache
        ├─ Piper synthesis
        ├─ FFmpeg post-processing
        ├─ technical QC
        └─ multipart audio upload → Backend API
                                      │
                                      ▼
                                    RustFS
```

The Worker never owns publication state, never allocates persistent IDs, never accesses PostgreSQL directly and never holds permanent RustFS credentials.

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

The Worker calls `POST /internal/v1/tts/jobs/claim`; Backend executes the atomic `FOR UPDATE SKIP LOCKED` claim and returns a lease plus the preallocated `jobId` and `fileId`.

Backend remains the single authority for:

```text
job lifecycle
file asset identity
retry policy
lease ownership
fingerprint validation
regeneration decisions
content revision validation
model authorization
RustFS persistence
asset replacement/cleanup
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
│       │   └── model_cache.py
│       └── adapters/
│           ├── backend_http.py
│           ├── piper.py
│           ├── ffmpeg.py
│           └── filesystem_model_cache.py
└── tests/
    ├── unit/
    ├── integration/
    └── acceptance/
```

Dependency direction:

```text
adapters → ports ← application → domain
```

Piper, FFmpeg and HTTP details must not leak into the Worker orchestration state machine.

## Persistent identities

Backend creates persistent identities before claim:

```text
jobId  = UUID
fileId = UUID
```

`jobId` identifies generation lifecycle.

`fileId` identifies the immutable produced audio asset.

Worker MUST use them unchanged and MUST NOT create replacement IDs.

Regeneration creates a new `jobId` and new `fileId`; the old READY audio remains usable until Backend atomically switches to the new READY asset.

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
  ↓ upload
OUTPUT_ACCEPTED
  ↓
DONE
```

Any stage may produce a typed failure.

Backend remains authoritative for persisted status:

```text
TtsJob:    PENDING → RUNNING → READY
                              ↘ FAILED

FileAsset: PENDING ─────────→ READY
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
        upload MP3 to Backend using jobId + fileId + leaseToken + fingerprint
    except LeaseLost:
        stop finalization
    except ClassifiedWorkerError as error:
        report fail when lease is still owned
    finally:
        stop heartbeat
        clean temporary files
```

The first implementation processes one job at a time per Worker process. Horizontal scale is achieved by multiple Worker instances, not internal concurrency first.

## Claim contract

Minimum claim response:

```text
jobId
fileId
contentRevisionId
audioRole
normalizedTtsText
language
voiceModelId
voiceModelCode
modelSha256
configSha256
fingerprint
leaseToken
leaseUntil
```

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

Model binaries may still be downloaded through short-lived Backend-authorized URLs; this does not grant the Worker permanent RustFS credentials.

Checksum mismatch is a hard failure.

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

If heartbeat reports ownership loss:

```text
worker marks local execution cancelled
→ no upload/finalization
→ no fail callback for the stale lease
→ temporary output is discarded
```

The Worker cannot always interrupt Piper/FFmpeg instantly, but it must reject their result after lease loss.

## Production audio profile

Initial delivery baseline:

```text
format:       MP3
extension:    .mp3
MIME:         audio/mpeg
channels:     mono
sample rate:  24 kHz
bitrate:      64 kbps CBR
profile id:   mp3-mono-24k-64k-v1
```

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

The profile remains versioned/configurable. Listening qualification may change bitrate/sample rate later without changing the Worker orchestration contract.

Piper and FFmpeg adapters must capture:

```text
exit code
stderr
execution duration
output path
```

Worker logs must never contain machine tokens or signed URL query credentials.

## Technical QC

Minimum checks:

```text
output exists
size > 0
duration > 0
codec == MP3
MIME == audio/mpeg
channels == 1
expected sample rate/profile
reasonable duration range
SHA-256 generated
FFmpeg probe succeeds
```

QC failure prevents upload.

## Backend output upload

MVP output is sent through Backend rather than directly to RustFS.

Recommended endpoint:

```http
POST /internal/v1/tts/jobs/{jobId}/output
Content-Type: multipart/form-data
Authorization: Bearer <WORKER_TOKEN>
```

Required multipart metadata:

```text
fileId
leaseToken
fingerprint
voiceModelId
audioProfile
file
```

Backend validates current ownership and expected generation inputs before accepting bytes.

Backend then owns:

```text
stream validation
checksum/metadata verification
RustFS object write
FileAsset PENDING → READY
TtsJob RUNNING → READY
current audio reference switch
old asset cleanup eligibility
```

The endpoint MUST be replay-safe. Same accepted output may be acknowledged idempotently; conflicting bytes for an already READY immutable `fileId` are rejected.

## Regeneration

Worker has no overwrite command.

Backend compares the expected audio fingerprint:

```text
fingerprint unchanged
→ no new generation

fingerprint changed
→ new jobId
→ new fileId
→ new immutable audio
→ switch reference only after READY
```

Physical overwrite of an existing `fileId` object is forbidden because Flutter manifest/checksum/offline-cache identity depends on asset immutability.

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
fileId
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

Freeze:

```text
jobId/fileId ownership
claim DTO
lease semantics
MP3 production profile
Backend output upload
regeneration/immutability
failure semantics
```

Detailed acceptance lives in `TTS_WORKER_W0_CONTRACT.md`.

### W1 — Runtime skeleton

Create Python package, configuration, structured logging, graceful shutdown and single-job polling loop using fake ports.

Acceptance:

```text
worker starts with validated config
idle polling is deterministic
SIGTERM stops new claims and cleans current resources
fake claim carries jobId/fileId
fake output upload validates IDs and lease
unit tests use fake backend/synthesizer/postprocessor
```

### W2 — Backend HTTP control adapter

Implement machine-token authenticated:

```text
claim
heartbeat
fail
model authorization
```

Acceptance includes stale lease behavior and backend transient failures.

### W3 — Model cache

Implement exact immutable model download, SHA-256 verification and atomic local installation.

### W4 — Piper + FFmpeg + QC

Implement real synthesis, MP3 post-processing and probe-based validation behind ports.

### W5 — Backend output upload

Implement multipart MP3 upload with `jobId + fileId + leaseToken + fingerprint`, including replay-safe success handling.

### W6 — Recovery qualification

Prove:

```text
worker crash during Piper
worker crash during FFmpeg
lease expiry and reclaim
stale output rejection
upload response loss and replay
duplicate upload
model checksum mismatch
corrupt output
backend restart
RustFS temporary outage behind Backend
text/fingerprint changes during job
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

The first code commit after W0 acceptance is **W1 Runtime Skeleton** only.

It proves this vertical seam:

```text
FakeBackend.claim()
→ JobProcessor
→ FakeSynthesizer
→ FakePostProcessor
→ FakeBackend.uploadOutput(jobId, fileId, leaseToken, mp3)
```

No Piper, FFmpeg or RustFS dependency is required to qualify W1.

This gives the Worker a deterministic orchestration core before infrastructure adapters are introduced.
