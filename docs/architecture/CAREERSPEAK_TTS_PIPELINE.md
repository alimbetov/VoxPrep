# CareerSpeak — TTS Worker & Audio Production Architecture

**Document version:** 1.2  
**Status:** Architecture baseline  
**Applies to:** VoxPrep / CareerSpeak v0.7+

---

## 1. Decision

CareerSpeak SHALL use a separate long-running TTS worker for content production.

Production components:

```text
Spring Boot Backend
PostgreSQL TTS queue
RustFS model/media storage
TTS Worker: Python + Piper + FFmpeg
```

The worker is server-managed and SHALL start/restart automatically with the deployment environment.

Piper SHALL NOT run inside learner request paths or Spring MVC request threads.

---

## 2. Responsibilities

### Backend

Owns:

- TTS job lifecycle;
- exact voice/model resolution;
- PostgreSQL queue state;
- lease ownership;
- presigned RustFS authorization;
- stale-result protection;
- final FileAsset association;
- ADMIN review/publish workflow.

### Worker

Owns only:

- claim job;
- obtain exact model;
- synthesize;
- post-process;
- technical QC;
- upload;
- report success/failure.

Worker SHALL NOT publish content and SHALL NOT connect directly to PostgreSQL.

---

## 3. Production topology

```text
                    Spring Boot Backend
                           │
                           ▼
                     PostgreSQL
                    durable TTS queue
                           ▲
                           │ authenticated HTTPS
                           │
                     TTS Worker
              Python + Piper + FFmpeg
                           │
                 ┌─────────┴─────────┐
                 ▼                   ▼
           local model cache        RustFS
                                  models/audio
```

The worker uses outbound connectivity only.

---

## 4. Worker runtime model

The worker is a long-running process/container.

```text
START
 ↓
load configuration
 ↓
authenticate with machine token
 ↓
claim job
 ↓
no job? → bounded sleep/backoff → claim again
 ↓
job found
 ↓
obtain exact model
 ↓
Piper
 ↓
FFmpeg
 ↓
QC
 ↓
RustFS upload
 ↓
complete/fail
 ↓
next claim
```

Production SHALL use auto-start/auto-restart, for example Docker restart policy or equivalent process supervision.

A developer may run the worker locally, but local Windows execution is not the production architecture baseline.

---

## 5. Worker authentication

Worker uses a dedicated machine credential.

```text
Authorization: Bearer <worker-token>
```

Worker access is limited to `/internal/v1/tts/**` and required presigned RustFS operations.

Worker SHALL NOT receive:

```text
ADMIN password
PostgreSQL password
permanent RustFS secret key
learner installation token
```

---

## 6. Voice and model model

### `tts_voice`

Logical ADMIN-facing voice profile:

```text
id
code
display_name
language
accent
gender
style
enabled
default_model_id
```

### `tts_voice_model`

Exact immutable Piper model revision:

```text
id
code
voice_id
engine
model_name
model_version
model_asset_id
config_asset_id
model_sha256
config_sha256
status
license_name
license_reference
commercial_use_reviewed
created_at
approved_at
```

A job SHALL reference an exact immutable `voice_model_id`.

Silent model substitution is forbidden.

---

## 7. Model lifecycle

```text
UPLOADING
 ↓
UPLOADED
 ↓
VALIDATING
 ↓
READY_FOR_REVIEW
 ↓
APPROVED
 ↓
ACTIVE
 ↓
DEPRECATED
```

Failure states MAY include:

```text
INVALID
QUARANTINED
```

A model binary/version SHALL never be overwritten in place.

---

## 8. RustFS model storage

Models/config files are private RustFS objects.

Example:

```text
careerspeak-models/
└── piper/
    └── en/
        └── en_US-lessac-high/
            └── v1/
                ├── model.onnx
                └── model.onnx.json
```

PostgreSQL stores object metadata/checksum, not model binary bytes.

ADMIN model upload SHOULD use presigned PUT.

Worker model download SHOULD use presigned GET.

---

## 9. Local model cache

Worker maintains a persistent local disk cache.

Example:

```text
/var/lib/careerspeak/tts/models/
└── PIPER_EN_US_LESSAC_HIGH_V1/
    ├── model.onnx
    ├── model.onnx.json
    └── manifest.json
```

On cache miss:

```text
request download authorization
→ RustFS download
→ SHA-256 verification
→ local install
→ Piper load
```

If checksum validation fails, the worker SHALL fail the job/model operation explicitly.

The worker MAY maintain a small in-memory LRU of loaded Piper models to reduce repeated model initialization.

---

## 10. TTS job model

Recommended fields:

```text
tts_job
──────────────────────────────
id
content_type
content_revision_id
audio_role
voice_id
voice_model_id
speaker_id nullable
fingerprint
status
attempt_count
worker_id nullable
lease_token nullable
lease_until nullable
created_at
started_at
completed_at
error_code nullable
error_message nullable
```

Status baseline:

```text
PENDING
RUNNING
READY
FAILED
CANCELLED
SUPERSEDED
```

---

## 11. PostgreSQL queue contract

TTS queue is implemented in PostgreSQL. RabbitMQ is not required.

Job claiming MUST be atomic and concurrency-safe.

Recommended PostgreSQL pattern:

```sql
WITH next_job AS (
    SELECT id
    FROM tts_job
    WHERE status = 'PENDING'
       OR (
            status = 'RUNNING'
            AND lease_until < NOW()
       )
    ORDER BY created_at, id
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
UPDATE tts_job j
SET status        = 'RUNNING',
    worker_id     = :workerId,
    lease_token   = :leaseToken,
    lease_until   = NOW() + INTERVAL '5 minutes',
    started_at    = COALESCE(started_at, NOW()),
    attempt_count = attempt_count + 1
FROM next_job
WHERE j.id = next_job.id
RETURNING j.*;
```

The exact lease duration is configuration, not a domain constant.

Spring implementation MAY use native SQL for queue claim/lease operations while ordinary metadata remains managed through JPA.

---

## 12. Queue indexes

At minimum qualify partial indexes equivalent to:

```sql
CREATE INDEX idx_tts_job_pending_claim
    ON tts_job (created_at, id)
    WHERE status = 'PENDING';
```

and:

```sql
CREATE INDEX idx_tts_job_expired_lease
    ON tts_job (lease_until)
    WHERE status = 'RUNNING';
```

Index shape SHALL be verified against actual claim/recovery queries.

---

## 13. Claim API

Example:

```text
POST /internal/v1/tts/jobs/claim
```

Successful response includes enough information to produce exactly one asset:

```json
{
  "jobId": 501,
  "contentRevisionId": 1203,
  "audioRole": "MODEL_ANSWER",
  "text": "Dependency injection is a design pattern...",
  "ttsText": "Dependency injection is a design pattern...",
  "voiceModelId": 17,
  "fingerprint": "...",
  "leaseToken": "..."
}
```

No pending job may return `204 No Content` or the agreed empty-job response.

---

## 14. Lease and heartbeat

A successful claim creates a unique `lease_token` and `lease_until`.

Long-running synthesis SHOULD heartbeat:

```text
POST /internal/v1/tts/jobs/{id}/heartbeat
```

Heartbeat is valid only when job id, worker id and lease token match the current lease.

Conceptual SQL:

```sql
UPDATE tts_job
SET lease_until = NOW() + INTERVAL '5 minutes'
WHERE id = :jobId
  AND status = 'RUNNING'
  AND worker_id = :workerId
  AND lease_token = :leaseToken;
```

If zero rows are updated, the worker has lost ownership and SHALL NOT finalize the job.

---

## 15. Crash recovery

If a worker dies while a job is `RUNNING`, no manual database repair is required.

After `lease_until < now()`, the job becomes eligible for a later atomic claim.

A returned old worker result is rejected because its lease token no longer matches.

---

## 16. TTS text pipeline

```text
canonical display text
 ↓
content-specific tts_text override
 ↓
controlled pronunciation rules
 ↓
normalized TTS input
 ↓
Piper
```

Learner-visible English SHALL NOT be distorted to satisfy the TTS engine.

Professional terms such as JVM, JPA, SQL, OAuth and Kubernetes may require controlled pronunciation rules.

---

## 17. Fingerprint

Recommended fingerprint input:

```text
normalized_tts_text
voice_model_id
voice_model_checksum
speaker_id
engine_version
speaking_rate
postprocess_profile_version
```

Algorithm:

```text
SHA-256
```

Changing text, voice model or qualified audio profile creates a new fingerprint.

---

## 18. Audio processing

```text
Piper
 ↓
temporary WAV
 ↓
technical validation
 ↓
FFmpeg
 ↓
production MP3
 ↓
technical QC
 ↓
RustFS
```

Candidate production profile:

```text
MP3
mono
64–80 kbps
speech-oriented sample rate
```

Final parameters SHALL be qualified by listening tests and recorded separately.

Temporary WAV should normally be deleted after successful conversion/upload.

---

## 19. Technical QC

Worker SHALL verify at least:

```text
output exists
size > 0
duration > 0
expected codec
expected channel count
expected sample-rate/profile
checksum calculated
Piper success
FFmpeg success
reasonable duration bounds
```

A technically invalid asset SHALL NOT become `READY`.

---

## 20. Upload and completion

Worker obtains temporary upload authorization and uploads directly to RustFS.

Completion endpoint example:

```text
POST /internal/v1/tts/jobs/{id}/complete
```

Completion data includes at minimum:

```text
jobId
leaseToken
fingerprint
voiceModelId
objectKey
checksum
size
duration
```

Backend accepts completion only if:

```text
current lease token matches
job is RUNNING
voice_model_id matches
fingerprint is still expected
content revision is still valid
```

Otherwise result is rejected or marked `SUPERSEDED`.

---

## 21. Failure endpoint

Worker reports bounded failures through:

```text
POST /internal/v1/tts/jobs/{id}/fail
```

Useful error codes include:

```text
VOICE_MODEL_NOT_FOUND
VOICE_MODEL_DOWNLOAD_FAILED
VOICE_MODEL_CHECKSUM_MISMATCH
VOICE_MODEL_LOAD_FAILED
PIPER_SYNTHESIS_FAILED
FFMPEG_FAILED
AUDIO_QC_FAILED
STORAGE_TEMPORARILY_UNAVAILABLE
LEASE_LOST
```

Retry policy SHALL be bounded.

---

## 22. Human review

Generated audio does not automatically publish learner content.

```text
GENERATED
 ↓
TECHNICAL QC
 ↓
READY_FOR_REVIEW
 ↓
ADMIN preview
 ↓
APPROVE / REGENERATE
 ↓
PUBLISH
```

There is one ADMIN actor; no separate moderator/reviewer role is required in MVP.

---

## 23. Worker configuration

Worker should require only operational configuration such as:

```text
BACKEND_URL
WORKER_ID
WORKER_TOKEN
LOCAL_MODEL_CACHE_PATH
POLL_INTERVAL
MAX_LOADED_MODELS
```

It SHALL NOT require direct database or permanent RustFS credentials.

---

## 24. Deployment

Initial production topology may be:

```text
Docker Host
├── careerspeak-backend
├── careerspeak-tts-worker
├── rustfs
└── reverse-proxy

Managed PostgreSQL
```

Worker runs continuously with auto-restart.

When idle it polls with bounded/exponential backoff.

---

## 25. Scaling

Initial:

```text
TTS Worker × 1
```

Future:

```text
TTS Worker × N
```

All workers use the same atomic claim API. `FOR UPDATE SKIP LOCKED` plus leases prevent duplicate ownership.

No queue contract change is required to add workers.

---

## 26. Mandatory failure tests

Qualification SHALL cover:

1. two workers claiming concurrently;
2. worker killed during Piper synthesis;
3. worker killed during FFmpeg conversion;
4. lease expiry and re-claim;
5. old worker completes with stale lease token;
6. network loss before upload;
7. upload succeeds but completion callback is lost;
8. duplicate completion callback;
9. model missing locally;
10. RustFS model download failure;
11. model checksum mismatch;
12. invalid/corrupt generated audio;
13. text revision changes while job runs;
14. exact voice model becomes deprecated while an already-created job still references it;
15. backend restart with pending/running jobs.

---

## 27. Acceptance path

```text
ADMIN creates/edits content
 ↓
backend resolves exact voice_model_id
 ↓
backend inserts PENDING TTS job
 ↓
worker atomically claims job
 ↓
worker gets/caches exact model
 ↓
Piper + FFmpeg + QC
 ↓
RustFS upload
 ↓
backend validates lease/fingerprint/model/revision
 ↓
job READY
 ↓
ADMIN previews and approves
 ↓
content publishes
 ↓
Flutter plays immutable published asset
```

The learner runtime remains independent of worker availability.
