# VoxPrep — Backend Integration Contract for TTS Worker

**Status:** Normative integration contract  
**Applies to:** production-hardened TTS Worker  
**Authentication:** static `WORKER_TOKEN`  
**Transport:** HTTPS in production

## 1. Purpose

This document defines the exact Backend responsibilities required to integrate the existing VoxPrep TTS Worker without changing Worker runtime semantics.

The integration boundary is intentionally narrow:

```text
PostgreSQL + RustFS
        ↑
      Backend
        ↑ HTTPS
     TTS Worker
```

Backend is authoritative for model catalog, durable job state, lease ownership, file identity and RustFS persistence.

Worker is authoritative only for disposable compute: model cache, Piper synthesis, FFmpeg post-processing, technical QC and upload of the generated artifact back to Backend.

Worker MUST NOT receive PostgreSQL or RustFS credentials.

---

## 2. Required Backend capabilities

Backend MUST provide:

```text
TTS voice/model catalog
exact immutable voice-model revision
model/config artifact delivery
PostgreSQL durable TTS queue
atomic claim with lease ownership
heartbeat lease extension
classified failure handling
multipart generated-audio acceptance
RustFS persistence
FileAsset metadata persistence
READY finalization
idempotent/replay-safe output handling
```

The Worker does not require RabbitMQ for this integration.

---

## 3. Authentication

Worker runtime configuration:

```text
BASE_URL=https://api.voxprep.kz
WORKER_TOKEN=<deployment secret>
WORKER_ID=<hostname or configured id>
```

Every Worker request sends:

```http
Authorization: Bearer <WORKER_TOKEN>
```

Backend configuration:

```text
TTS_WORKER_TOKEN=<same deployment secret>
```

Backend MUST protect:

```text
/internal/v1/tts/**
```

Validation:

```text
missing/wrong token -> 401
valid token         -> continue to endpoint/domain validation
```

`WORKER_TOKEN` authenticates the process. It does not prove ownership of a job. Job mutation additionally requires a valid current `leaseToken` and matching `workerId`.

Related contract:

```text
docs/backend/TTS_WORKER_BACKEND_AUTH_CONTRACT.md
```

---

## 4. Backend-owned model catalog

Worker does not synchronize or keep a list of available models.

Backend owns the complete model catalog and selects one exact immutable revision for each TTS job.

Minimum logical entities:

```text
tts_voice
  id
  code
  language
  enabled
  default_model_id


tts_voice_model
  id
  code
  voice_id
  engine
  model_version
  model_asset_id
  config_asset_id
  model_sha256
  config_sha256
  status
```

A model referenced by a claim MUST be immutable by revision.

Recommended usable status:

```text
ACTIVE
```

Backend MUST NOT silently replace the claimed `voiceModelId` with another model after job creation.

---

## 5. Durable job model

Minimum logical `tts_job` state required by the Worker contract:

```text
id
file_id
content_revision_id
audio_role
voice_model_id
fingerprint
status
attempt_count
worker_id nullable
lease_token nullable
lease_until nullable
created_at
started_at nullable
completed_at nullable
error_code nullable
error_message nullable
```

Statuses:

```text
PENDING
RUNNING
READY
FAILED
CANCELLED
SUPERSEDED
```

Backend allocates `jobId` and `fileId` before claim.

`fileId` is immutable. Regeneration allocates a new `jobId` and a new `fileId`; a READY asset is never overwritten in place.

---

## 6. FileAsset lifecycle

Backend SHOULD persist a file/asset record independently of `tts_job`.

Minimum logical state:

```text
file_asset
  id = fileId
  status = PENDING | READY | FAILED
  content_type
  extension
  size_bytes
  sha256
  duration_ms
  storage_object_key
  created_at
  ready_at nullable
```

Initial state when a TTS job is created:

```text
tts_job.status   = PENDING
file_asset.status = PENDING
```

Only Backend can transition both to READY.

---

## 7. Atomic claim API

### Request

```http
POST /internal/v1/tts/jobs/claim
Authorization: Bearer <WORKER_TOKEN>
Content-Type: application/json
```

```json
{
  "workerId": "tts-worker-01"
}
```

### Empty queue

```http
204 No Content
```

### Claimed job

```http
200 OK
Content-Type: application/json
```

```json
{
  "jobId": "c65d0b6b-2d59-4acf-bef1-8a41ea1a9448",
  "fileId": "aacdf5c7-41d4-4da6-80d6-a1107877738e",
  "contentRevisionId": "a4f4e070-2c1f-438f-a78c-c648b230cb57",
  "audioRole": "PRIMARY",
  "normalizedTtsText": "Tell me about yourself.",
  "language": "en-US",
  "voiceModelId": "bfcf20d1-28d9-46a4-9a58-5f71acdaf963",
  "voiceModelCode": "en-us-lessac-medium-v1",
  "modelSha256": "<64 lowercase hex chars>",
  "configSha256": "<64 lowercase hex chars>",
  "fingerprint": "<64 lowercase hex chars>",
  "leaseToken": "<opaque non-empty token>",
  "leaseUntil": "2026-10-30T16:00:00Z"
}
```

All fields above are required by the current Worker. `leaseUntil` MUST contain a timezone. SHA fields MUST be valid 64-character SHA-256 hex digests.

### Recommended PostgreSQL claim

```sql
WITH next_job AS (
    SELECT id
    FROM tts_job
    WHERE status = 'PENDING'
       OR (status = 'RUNNING' AND lease_until < NOW())
    ORDER BY created_at, id
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
UPDATE tts_job j
SET status        = 'RUNNING',
    worker_id     = :workerId,
    lease_token   = :leaseToken,
    lease_until   = NOW() + :leaseDuration,
    started_at    = COALESCE(started_at, NOW()),
    attempt_count = attempt_count + 1
FROM next_job
WHERE j.id = next_job.id
RETURNING j.*;
```

Claim and lease assignment MUST happen in one database transaction.

---

## 8. Model download APIs

Claim defines the exact model revision:

```text
voiceModelId
modelSha256
configSha256
```

Worker first checks its private persistent cache. On miss it calls Backend.

### Model

```http
GET /internal/v1/tts/models/{voiceModelId}/model
Authorization: Bearer <WORKER_TOKEN>
```

Response:

```http
200 OK
Content-Type: application/octet-stream
```

Body is the exact `model.onnx` bytes whose SHA-256 equals `modelSha256` from claim.

### Config

```http
GET /internal/v1/tts/models/{voiceModelId}/config
Authorization: Bearer <WORKER_TOKEN>
```

Response:

```http
200 OK
Content-Type: application/json
```

Body is the exact Piper config bytes whose SHA-256 equals `configSha256` from claim.

### Missing/unavailable model

```http
404 Not Found
```

Worker maps this to `VOICE_MODEL_NOT_FOUND` and never chooses another model automatically.

Backend may read these artifacts from RustFS internally, but RustFS URLs and credentials MUST NOT be exposed to Worker.

---

## 9. Heartbeat API

Worker renews ownership while model download/Piper/FFmpeg may still be running.

```http
POST /internal/v1/tts/jobs/{jobId}/heartbeat
Authorization: Bearer <WORKER_TOKEN>
Content-Type: application/json
```

```json
{
  "workerId": "tts-worker-01",
  "leaseToken": "<current lease token>"
}
```

Accepted response:

```text
200 OK
or
204 No Content
```

Backend extends `lease_until` only if all are true:

```text
job.id = jobId
job.status = RUNNING
job.worker_id = workerId
job.lease_token = leaseToken
```

Ownership lost:

```text
409 Conflict
or
410 Gone
```

Worker treats either as `LEASE_LOST` and will not finalize stale output.

---

## 10. Failure API

Worker reports classified deterministic processing failures:

```http
POST /internal/v1/tts/jobs/{jobId}/fail
Authorization: Bearer <WORKER_TOKEN>
Content-Type: application/json
```

```json
{
  "workerId": "tts-worker-01",
  "fileId": "<fileId from claim>",
  "leaseToken": "<current lease token>",
  "errorCode": "PIPER_SYNTHESIS_FAILED",
  "errorMessage": "Piper synthesis failed"
}
```

Accepted response:

```text
200 OK
or
204 No Content
```

Stale lease:

```text
409 Conflict
or
410 Gone
```

Backend owns retry policy. Worker MUST NOT decide whether a durable job becomes PENDING again, FAILED terminally, CANCELLED or SUPERSEDED.

Recommended Worker error codes include:

```text
VOICE_MODEL_NOT_FOUND
VOICE_MODEL_DOWNLOAD_FAILED
VOICE_MODEL_CHECKSUM_MISMATCH
VOICE_MODEL_CACHE_INSTALL_FAILED
VOICE_MODEL_LOAD_FAILED
PIPER_SYNTHESIS_FAILED
FFMPEG_FAILED
AUDIO_QC_FAILED
BACKEND_TEMPORARILY_UNAVAILABLE
LEASE_LOST
INVALID_JOB_PAYLOAD
```

---

## 11. Output upload API

Worker generates and technically validates the production profile before upload:

```text
MIME          audio/mpeg
extension     .mp3
codec         MP3
channels      1
sample rate   24000 Hz
bitrate       64 kbps profile
profile       mp3-mono-24k-64k-v1
```

Request:

```http
POST /internal/v1/tts/jobs/{jobId}/output
Authorization: Bearer <WORKER_TOKEN>
Content-Type: multipart/form-data
```

Multipart text fields:

```text
workerId
fileId
leaseToken
fingerprint
voiceModelId
audioProfile
sha256
sizeBytes
durationMs
```

Binary part:

```text
name: file
Content-Type: audio/mpeg
```

Accepted response:

```text
200 OK
201 Created
or
204 No Content
```

Stale/invalid ownership:

```text
409 Conflict
or
410 Gone
```

Backend MUST validate before READY finalization:

```text
jobId exists
status = RUNNING
workerId matches
leaseToken matches current lease
fileId matches job.file_id
fingerprint matches expected fingerprint
voiceModelId matches job.voice_model_id
audioProfile is supported
uploaded sha256 matches bytes
uploaded sizeBytes matches bytes
durationMs is positive
content revision is still valid for this job
```

---

## 12. RustFS persistence and transaction boundary

Worker never writes RustFS directly.

Backend output finalization flow:

```text
receive multipart upload
→ validate job/lease/identity
→ stream/write immutable MP3 object to RustFS
→ verify storage write succeeded
→ persist FileAsset metadata
→ FileAsset PENDING -> READY
→ TtsJob RUNNING -> READY
→ set completed_at
→ switch logical current-audio reference if this is a replacement
```

Backend MUST NOT mark database state READY before the RustFS object is durably available.

If RustFS write fails:

```text
TtsJob MUST NOT become READY
FileAsset MUST NOT become READY
old READY asset/reference MUST remain unchanged during regeneration
```

The physical RustFS object-key format is Backend-private and is not part of Worker contract.

---

## 13. Replay/idempotency requirement

Output handling MUST be replay-safe because the following is possible:

```text
Worker uploads MP3
→ Backend persists MP3 and commits READY
→ HTTP response is lost
```

A replay of the same logical result for an already READY immutable `fileId` SHOULD be accepted when identity and checksum are identical.

A conflicting payload for the same READY `fileId` MUST be rejected.

Worker intentionally does not blindly call `/fail` after an ambiguous output transport failure.

---

## 14. HTTP error semantics expected by Worker

```text
200/201/204   expected success depending on endpoint
204 claim     empty queue
401/403       WORKER_TOKEN rejected
404 model     claimed model unavailable
409/410       lease/ownership lost on lease-sensitive endpoint
429           temporary Backend unavailability
5xx           temporary Backend unavailability
other 4xx     protocol/domain contract error
```

Backend SHOULD preserve these status classes because Worker already maps them to specific recovery semantics.

---

## 15. Backend implementation modules

A practical Spring Boot decomposition is:

```text
TtsWorkerAuthenticationFilter

TtsWorkerJobController
  claim()
  heartbeat()
  fail()
  output()

TtsWorkerModelController
  model()
  config()

TtsJobService
TtsJobClaimRepository
TtsVoiceModelService
TtsOutputFinalizationService
FileAssetService
RustFsObjectStoragePort
```

Within one Backend monolith these are application/domain calls, not internal HTTP calls.

---

## 16. Required database indexes

Recommended baseline:

```sql
CREATE INDEX idx_tts_job_pending_claim
ON tts_job (created_at, id)
WHERE status = 'PENDING';

CREATE INDEX idx_tts_job_expired_lease
ON tts_job (lease_until)
WHERE status = 'RUNNING';
```

Also enforce foreign keys from `tts_job.file_id` and `tts_job.voice_model_id` to their authoritative records.

---

## 17. Integration invariant

```text
Backend chooses WHAT must be generated and owns durable truth.
Worker decides only HOW to execute the assigned immutable generation contract.
RustFS is reachable only through Backend.
PostgreSQL is reachable only through Backend.
```

The existing production-hardened Worker requires no additional business responsibility for Backend integration.
