# CareerSpeak / VoxPrep — Backend TTS Implementation Requirements

**Document version:** 1.0  
**Status:** Normative Backend implementation specification  
**Applies to:** Spring Boot Backend ↔ production TTS Worker  
**Target:** CareerSpeak v0.10+  
**Transport:** HTTPS in production

## 1. Purpose

This document is the Backend implementation specification for the already production-hardened VoxPrep TTS Worker.

The Backend team MUST be able to implement the complete TTS domain without inventing additional Worker-facing protocol semantics.

Authoritative related contracts:

- `docs/backend/TTS_WORKER_BACKEND_INTEGRATION.md`
- `docs/backend/TTS_WORKER_BACKEND_AUTH_CONTRACT.md`
- `docs/architecture/CAREERSPEAK_TTS_PIPELINE.md`
- `docs/implementation/TTS_WORKER_REAL_BACKEND_ACCEPTANCE.md`

The target topology is:

```text
PostgreSQL ─────┐
                │
RustFS ─────────┼── Spring Boot Backend
                │          ▲
                │          │ HTTPS /internal/v1/tts/**
                │          │
                └──── TTS Worker
                         │
                         └── private persistent model cache
```

The Worker MUST NOT connect directly to PostgreSQL or RustFS.

---

## 2. Contract readiness decision

The Worker-facing design contract is implementation-ready when this specification is used together with the integration/auth contracts.

The following are already frozen:

```text
Worker authentication boundary
claim request/response
exact claimed model identity
model/config download
lease ownership
heartbeat
failure callback
multipart output upload
RustFS ownership by Backend
immutable FileAsset identity
replay-safe finalization
real A01-A11 acceptance matrix
```

The Backend implementation is NOT production-accepted until the real Backend ↔ Worker A01-A11 acceptance suite passes.

Machine-readable OpenAPI is a required Backend deliverable before final contract freeze; it must represent the wire contract defined here and must not redefine it.

---

## 3. Backend technology boundary

TTS is a module of the existing Spring Boot modular monolith.

Baseline:

```text
Java 21
Spring Boot
Spring MVC
Spring Security
Spring Data JPA
JDBC/native SQL where concurrency requires it
PostgreSQL
Liquibase
RustFS through Backend-owned object-storage adapter
OpenAPI
Micrometer / Actuator
Testcontainers
Docker
```

RabbitMQ, Kafka, Redis and a separate queue service are NOT required for the initial TTS implementation.

PostgreSQL is the durable queue.

---

## 4. Ownership boundary

Backend owns:

```text
TTS voice catalog
immutable voice-model revisions
model approval/lifecycle
model/config storage metadata
tts_job durable state
jobId/fileId allocation
normalized TTS input
fingerprint calculation
atomic claim
lease issuance and renewal
retry/terminal policy
RustFS credentials and persistence
FileAsset metadata
READY finalization
regeneration/replacement policy
ADMIN preview/review/publication
```

Worker owns only disposable compute:

```text
claim polling
private model cache
model/config checksum verification
Piper execution
FFmpeg post-processing
technical audio QC
heartbeat
output upload to Backend
classified failure reporting
```

Worker does not publish learner content and does not change content availability.

---

## 5. Security contract

Protected namespace:

```text
/internal/v1/tts/**
```

Every Worker request sends:

```http
Authorization: Bearer <WORKER_TOKEN>
```

Backend configuration:

```text
TTS_WORKER_TOKEN=<strong environment-specific secret>
```

Required behavior:

```text
missing token -> 401
wrong token   -> 401
valid token   -> continue to endpoint/domain validation
```

The comparison SHOULD be constant-time.

The following MUST NOT be logged:

```text
WORKER_TOKEN
Authorization header
leaseToken in normal application logs
RustFS credentials
```

`WORKER_TOKEN` authenticates the Worker process only. It does not grant ownership of a specific job.

---

## 6. Required Worker API

Backend MUST implement exactly this initial Worker-facing surface:

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{jobId}/heartbeat
POST /internal/v1/tts/jobs/{jobId}/fail
POST /internal/v1/tts/jobs/{jobId}/output
GET  /internal/v1/tts/models/{voiceModelId}/model
GET  /internal/v1/tts/models/{voiceModelId}/config
```

No Worker registration/session/token-issuance endpoint is required in MVP.

---

## 7. Logical persistence model

### 7.1 `tts_voice`

Minimum logical fields:

```text
id UUID PK
code varchar UNIQUE NOT NULL
display_name varchar NOT NULL
language varchar NOT NULL
accent varchar NULL
gender varchar NULL
style varchar NULL
enabled boolean NOT NULL
default_model_id UUID NULL
created_at timestamptz NOT NULL
updated_at timestamptz NOT NULL
```

### 7.2 `tts_voice_model`

Minimum logical fields:

```text
id UUID PK
code varchar UNIQUE NOT NULL
voice_id UUID FK NOT NULL
engine varchar NOT NULL              -- PIPER initially
engine_version varchar NOT NULL
model_version varchar NOT NULL
model_asset_id UUID NOT NULL
config_asset_id UUID NOT NULL
model_sha256 char(64) NOT NULL
config_sha256 char(64) NOT NULL
status varchar NOT NULL
license_name varchar NULL
license_reference varchar NULL
commercial_use_reviewed boolean NOT NULL
created_at timestamptz NOT NULL
approved_at timestamptz NULL
```

Model lifecycle:

```text
UPLOADING
UPLOADED
VALIDATING
READY_FOR_REVIEW
APPROVED
ACTIVE
DEPRECATED
INVALID
QUARANTINED
```

Only `ACTIVE` revisions may be selected for NEW jobs.

Changing `tts_voice.default_model_id` MUST NOT mutate an existing job.

An exact model revision is immutable. Model/config bytes and checksums are never overwritten in place.

### 7.3 `tts_job`

Minimum logical fields:

```text
id UUID PK
file_id UUID FK NOT NULL
content_type varchar NOT NULL
content_revision_id UUID NOT NULL
audio_role varchar NOT NULL
voice_id UUID NOT NULL
voice_model_id UUID FK NOT NULL
speaker_id varchar NULL
normalized_tts_text text NOT NULL
language varchar NOT NULL
audio_profile varchar NOT NULL
fingerprint char(64) NOT NULL
fingerprint_version varchar NOT NULL
status varchar NOT NULL
attempt_count integer NOT NULL DEFAULT 0
worker_id varchar NULL
lease_token varchar NULL
lease_until timestamptz NULL
created_at timestamptz NOT NULL
started_at timestamptz NULL
completed_at timestamptz NULL
error_code varchar NULL
error_message varchar NULL
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

### 7.4 `file_asset`

Minimum logical fields:

```text
id UUID PK
status varchar NOT NULL              -- PENDING | READY | FAILED
content_type varchar NOT NULL
extension varchar NOT NULL
size_bytes bigint NULL
sha256 char(64) NULL
duration_ms bigint NULL
storage_object_key varchar NULL
created_at timestamptz NOT NULL
ready_at timestamptz NULL
```

`fileId` is immutable. Regeneration allocates a new `jobId` and a new `fileId`.

A READY FileAsset is never overwritten in place.

---

## 8. Job creation invariant

Before a job can become `PENDING`, Backend MUST resolve and persist all immutable execution inputs:

```text
jobId
fileId
contentRevisionId
contentType
audioRole
normalizedTtsText
language
voiceId
voiceModelId
modelSha256
configSha256
audioProfile
fingerprint
```

Initial state:

```text
tts_job.status    = PENDING
attempt_count     = 0
file_asset.status = PENDING
```

The Worker never allocates these identities.

---

## 9. Fingerprint contract

Backend is the only authority that calculates the fingerprint. Worker receives it and echoes it unchanged during output upload.

Fingerprint algorithm:

```text
SHA-256
fingerprintVersion = TTS-FP-V1
```

`TTS-FP-V1` MUST include at least:

```text
normalizedTtsText
language
voiceModelId
modelSha256
configSha256
speakerId or null
engine
engineVersion
speakingRate or default value
audioProfile
```

Canonicalization requirements:

```text
UTF-8
stable field names
stable field ordering
no locale-dependent formatting
lowercase SHA-256 values
explicit null representation
version prefix included in the hashed payload
```

Implementation SHOULD use one dedicated `TtsFingerprintService` with golden-vector tests.

Any relevant execution-input change MUST create a different fingerprint.

If a requested fingerprint equals the current READY fingerprint, Backend SHOULD reuse the existing READY asset rather than create a duplicate job.

If it differs, Backend allocates a new `jobId` and `fileId`; the old READY asset remains authoritative until replacement is READY.

---

## 10. Claim contract

Request:

```http
POST /internal/v1/tts/jobs/claim
Content-Type: application/json
Authorization: Bearer <WORKER_TOKEN>
```

```json
{
  "workerId": "tts-worker-01"
}
```

Empty queue:

```http
204 No Content
```

Claimed job:

```http
200 OK
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

All fields above are mandatory for the current Worker.

`leaseUntil` MUST contain timezone information. Backend SHOULD emit UTC `Z` timestamps.

SHA values MUST be lowercase 64-character hexadecimal SHA-256 digests.

---

## 11. Atomic claim and lease

Claim MUST be atomic and concurrency-safe.

Required PostgreSQL pattern:

```sql
WITH next_job AS (
    SELECT id
    FROM tts_job
    WHERE (
            status = 'PENDING'
          )
       OR (
            status = 'RUNNING'
            AND lease_until < NOW()
            AND attempt_count < :maxAttempts
          )
    ORDER BY created_at, id
    FOR UPDATE SKIP LOCKED
    LIMIT 1
)
UPDATE tts_job j
SET status        = 'RUNNING',
    worker_id     = :workerId,
    lease_token   = :newLeaseToken,
    lease_until   = NOW() + :leaseDuration,
    started_at    = COALESCE(started_at, NOW()),
    attempt_count = attempt_count + 1
FROM next_job
WHERE j.id = next_job.id
RETURNING j.*;
```

Claim and lease assignment MUST occur in one database transaction.

Every new claim/reclaim MUST generate a new opaque `leaseToken`.

Recommended initial configuration:

```text
TTS_LEASE_DURATION_SECONDS=60
TTS_MAX_ATTEMPTS=3
```

The Worker default heartbeat interval is 10 seconds. Lease duration must remain comfortably larger than the heartbeat interval and ordinary request jitter.

---

## 12. Expired lease recovery

An expired `RUNNING` lease is not owned by the old Worker anymore, even if `worker_id` and `lease_token` still match persisted values.

This is mandatory:

```text
lease_until > current database time
```

must be part of current-owner validation for heartbeat, fail and first-time output finalization.

A stale Worker MUST NOT be able to resurrect an already expired lease by sending heartbeat before another Worker claims it.

Expired jobs with attempts remaining may be reclaimed.

Expired jobs with:

```text
attempt_count >= TTS_MAX_ATTEMPTS
```

MUST eventually become terminal `FAILED`, for example:

```text
error_code = LEASE_RETRY_EXHAUSTED
```

A scheduled recovery task or equivalent transactional maintenance is acceptable.

---

## 13. Heartbeat contract

Request:

```http
POST /internal/v1/tts/jobs/{jobId}/heartbeat
```

```json
{
  "workerId": "tts-worker-01",
  "leaseToken": "<current lease token>"
}
```

Heartbeat succeeds only when all are true:

```text
job.id = jobId
job.status = RUNNING
job.worker_id = workerId
job.lease_token = leaseToken
job.lease_until > NOW()
```

On success:

```text
lease_until = NOW() + leaseDuration
```

Response:

```text
200 OK or 204 No Content
```

Ownership lost/expired:

```text
409 Conflict or 410 Gone
```

Recommended exact convention:

```text
409 = RUNNING job exists but worker/lease token conflicts
410 = job is no longer actively owned by that lease, including expired/terminal/superseded state
```

---

## 14. Model delivery contract

Model:

```http
GET /internal/v1/tts/models/{voiceModelId}/model
```

Response:

```text
200 OK
Content-Type: application/octet-stream
body SHA-256 == claim.modelSha256
```

Config:

```http
GET /internal/v1/tts/models/{voiceModelId}/config
```

Response:

```text
200 OK
Content-Type: application/json
body SHA-256 == claim.configSha256
```

Missing/unavailable revision:

```text
404 Not Found
```

Backend MUST NOT silently substitute another model revision.

A model revision selected into an existing job remains the exact job model even if the voice default later changes.

`DEPRECATED` prevents selection for new jobs but SHOULD NOT break already-created jobs while the immutable revision remains safe and available.

`INVALID` or `QUARANTINED` revisions MUST NOT be selected for new jobs and may be withdrawn from delivery according to administrative safety policy.

RustFS endpoint/credentials are never returned to Worker.

---

## 15. Failure callback contract

Request:

```http
POST /internal/v1/tts/jobs/{jobId}/fail
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

Backend validates:

```text
RUNNING status
matching current workerId
matching current leaseToken
lease not expired
matching fileId
```

Current Worker error catalog includes:

```text
VOICE_MODEL_NOT_FOUND
VOICE_MODEL_DOWNLOAD_FAILED
VOICE_MODEL_CHECKSUM_MISMATCH
VOICE_MODEL_CACHE_INSTALL_FAILED
VOICE_MODEL_LOAD_FAILED
PIPER_SYNTHESIS_FAILED
FFMPEG_FAILED
AUDIO_QC_FAILED
INVALID_BACKEND_RESPONSE
BACKEND_TEMPORARILY_UNAVAILABLE
LEASE_LOST
WORKER_AUTH_FAILED
```

Not every code is expected to reach `/fail`: transport unavailability and lease loss normally recover through lease semantics, and authentication failure normally prevents the callback itself.

Backend SHOULD validate `errorCode` syntactically rather than reject unknown future codes solely because they are not in a database enum:

```text
[A-Z0-9_]{1,64}
```

Recommended `errorMessage` persistence limit:

```text
2000 characters
```

Secrets/headers must never be persisted in the message.

---

## 16. Backend retry policy

The Backend, not the Worker, owns durable retry decisions.

Initial policy:

### Terminal immediately

```text
VOICE_MODEL_NOT_FOUND
VOICE_MODEL_CHECKSUM_MISMATCH
AUDIO_QC_FAILED
INVALID_BACKEND_RESPONSE
```

### Retryable while `attempt_count < TTS_MAX_ATTEMPTS`

```text
VOICE_MODEL_DOWNLOAD_FAILED
VOICE_MODEL_CACHE_INSTALL_FAILED
VOICE_MODEL_LOAD_FAILED
PIPER_SYNTHESIS_FAILED
FFMPEG_FAILED
```

For a retryable accepted `/fail`:

```text
persist last error
clear current lease ownership
PENDING if attempts remain
FAILED if attempts exhausted
```

Transport loss without a successful `/fail` is recovered by lease expiry/reclaim.

Unknown well-formed Worker failure codes SHOULD default to terminal `FAILED` until explicitly classified.

ADMIN may explicitly request regeneration/retry by creating a new generation decision according to Backend domain rules; direct arbitrary status editing is not the normal path.

---

## 17. Output upload contract

Request:

```http
POST /internal/v1/tts/jobs/{jobId}/output
Content-Type: multipart/form-data
```

Text fields:

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
name = file
Content-Type = audio/mpeg
```

Initial production profile:

```text
MIME          audio/mpeg
extension     .mp3
codec         MP3
channels      1
sample rate   24000 Hz
bitrate       64 kbps profile
profile       mp3-mono-24k-64k-v1
```

Backend MUST stream the multipart body rather than buffer arbitrarily large files entirely in heap memory.

A configurable maximum upload size MUST be enforced.

---

## 18. First-time output finalization

For a `RUNNING` job Backend MUST validate before finalization:

```text
jobId exists
status = RUNNING
workerId matches
leaseToken matches
lease_until > NOW()
fileId matches job.file_id
fingerprint matches expected fingerprint
voiceModelId matches job.voice_model_id
audioProfile matches expected profile
sha256 syntax is valid
actual uploaded SHA-256 == submitted sha256
actual byte length == submitted sizeBytes
durationMs > 0
content revision is still valid for this job
job is not CANCELLED or SUPERSEDED
```

The Backend MUST calculate uploaded SHA-256 and actual byte size itself while streaming or immediately after persistence. Worker metadata is not trusted as integrity proof.

---

## 19. RustFS persistence and database transaction boundary

Required sequence:

```text
receive/validate request identity
→ stream immutable object to Backend-owned RustFS location
→ verify object write succeeded
→ persist FileAsset metadata
→ FileAsset PENDING -> READY
→ TtsJob RUNNING -> READY
→ completed_at = NOW()
→ switch current logical audio reference when replacement is eligible
```

Database state MUST NOT say READY before the object is durably available.

Recommended object-key identity is deterministic from immutable `fileId` plus controlled extension/profile. The physical key format remains Backend-private.

If RustFS succeeds but the following DB transaction fails, the object is an orphan/non-authoritative object, not a READY asset. A replay with the same `fileId` and checksum SHOULD reuse/verify it rather than create a conflicting object. A cleanup process may later delete unreferenced objects.

If RustFS fails:

```text
TtsJob != READY
FileAsset != READY
old current READY asset/reference remains unchanged
```

---

## 20. Mandatory replay/idempotency semantics

This failure is expected in distributed systems:

```text
Worker uploads valid MP3
→ Backend stores object
→ Backend commits READY
→ HTTP success response is lost
```

Therefore `/output` MUST implement two paths.

### Path A — first finalization

```text
job.status = RUNNING
+ valid unexpired current lease
→ perform normal finalization
```

### Path B — replay of already finalized result

If:

```text
job.status = READY
same jobId
same fileId
same finalized worker/lease identity
same fingerprint
same voiceModelId
same audioProfile
same sha256
same sizeBytes
compatible durationMs
```

Backend MUST return idempotent success without creating a second logical FileAsset and without rewriting a conflicting object.

Recommended response:

```text
200 OK
```

The finalized lease token/worker identity SHOULD remain available on the job for audit/replay validation even though the lease is no longer active.

If a READY `fileId` receives different bytes/checksum or different immutable identity metadata:

```text
409 Conflict
```

A READY immutable asset MUST never be overwritten.

---

## 21. Cancellation and supersession

Backend may move non-final jobs to:

```text
CANCELLED
SUPERSEDED
```

Typical supersession:

```text
content execution inputs change
→ new fingerprint
→ new jobId + fileId
→ old non-current job SUPERSEDED
```

Heartbeat/fail/output from an old lease after cancellation/supersession MUST NOT change authoritative state.

Return:

```text
410 Gone
```

The old READY asset remains usable until a replacement is READY and the Backend atomically switches the logical current-audio reference.

---

## 22. HTTP/error contract

Success classes expected by current Worker:

```text
claim:      200 or 204
heartbeat:  200 or 204
fail:       200 or 204
output:     200, 201 or 204
model:      200
config:     200
```

Failure classes:

```text
401/403       worker authentication rejected
404 model     claimed model unavailable
409/410       lease/ownership/finalization conflict
429           temporary Backend overload
5xx           temporary Backend/storage failure
other 4xx     protocol/domain contract error
```

Backend API error body SHOULD use the system error envelope:

```json
{
  "code": "TTS_LEASE_LOST",
  "message": "TTS job lease is no longer valid",
  "traceId": "...",
  "details": {}
}
```

Worker currently relies primarily on HTTP status classes, so Backend MUST preserve the status semantics even if error-body details evolve.

---

## 23. Required indexes and constraints

Baseline indexes:

```sql
CREATE INDEX idx_tts_job_pending_claim
ON tts_job (created_at, id)
WHERE status = 'PENDING';

CREATE INDEX idx_tts_job_expired_lease
ON tts_job (lease_until)
WHERE status = 'RUNNING';
```

Required constraints include:

```text
FK tts_job.file_id -> file_asset.id
FK tts_job.voice_model_id -> tts_voice_model.id
UNIQUE voice/model business codes
attempt_count >= 0
SHA fields are 64-char lowercase hex at application boundary
READY FileAsset requires storage_object_key + sha256 + size_bytes + ready_at
READY TtsJob requires completed_at
```

Database CHECK constraints may supplement application validation where practical.

---

## 24. Concurrency invariants

Backend MUST prove:

```text
one PENDING job has at most one current RUNNING owner
two Worker replicas cannot claim the same active lease
reclaim always creates a new leaseToken
expired lease cannot heartbeat itself back to life
stale owner cannot fail/finalize after reclaim
READY immutable fileId cannot be overwritten
replacement does not remove old READY asset before new READY exists
```

`FOR UPDATE SKIP LOCKED` is the required initial queue-claim primitive.

---

## 25. Observability

Backend MUST expose enough evidence to diagnose the production pipeline without logging secrets.

Recommended structured fields:

```text
traceId
jobId
fileId
workerId
voiceModelId
contentRevisionId
status transition
attemptCount
errorCode
elapsedMs
uploadedBytes
```

Recommended metrics:

```text
tts_jobs_pending
tts_jobs_running
tts_jobs_ready_total
tts_jobs_failed_total
tts_claim_total
tts_reclaim_total
tts_lease_lost_total
tts_generation_attempts
tts_output_bytes
tts_output_finalize_seconds
tts_model_download_requests
```

Actuator health SHOULD distinguish Backend/PostgreSQL/RustFS readiness where appropriate.

---

## 26. OpenAPI deliverable

Backend MUST publish a machine-readable OpenAPI definition for all six Worker endpoints before final contract freeze.

The schema MUST encode at minimum:

```text
required claim fields
UUID/string formats
SHA-256 patterns
ISO-8601 leaseUntil
204 empty-queue behavior
heartbeat/fail request DTOs
multipart output fields
binary model/config responses
401/404/409/410/429/5xx semantics
```

Contract tests MUST compare Backend behavior against representative Worker fixtures.

The OpenAPI definition is generated from or tested against the normative contract; it does not override the rules in this document.

---

## 27. Backend implementation order

Recommended implementation stream:

```text
B1  tts_voice + tts_voice_model catalog
B2  FileAsset + tts_job persistence
B3  fingerprint service + job creation
B4  atomic claim + lease + reclaim
B5  model/config delivery API
B6  heartbeat + classified fail policy
B7  RustFS output finalization + replay safety
B8  OpenAPI + real A01-A11 acceptance
```

Each stage should have Testcontainers-backed PostgreSQL tests where persistence/concurrency is involved.

B4 MUST include a real concurrent claim test with at least two transactions/workers.

B7 MUST include response-loss/replay tests and RustFS failure simulation.

---

## 28. Real acceptance gates

The Backend is not TTS-production-accepted until all existing real acceptance scenarios pass:

```text
A01 cold-cache real E2E
A02 final MP3 technical verification
A03 warm-cache reuse
A04 container restart/cache reuse
A05 stale lease rejection
A06 crash + lease reclaim
A07 RustFS failure safety
A08 replay-safe output
A09 missing model fail-closed
A10 checksum mismatch fail-closed
A11 multi-worker atomic claim
```

Required global invariants:

```text
no Worker direct PostgreSQL access
no Worker direct RustFS access
WORKER_TOKEN absent from logs
no READY DB state without durable object
no silent model fallback
no overwrite of READY fileId
no stale-lease finalization
```

---

## 29. Definition of Done

Backend TTS domain is implementation-complete when:

```text
Liquibase schema exists
catalog/domain persistence exists
job creation resolves exact immutable model
fingerprint is deterministic and golden-tested
claim is atomic and multi-worker safe
lease expiry cannot be resurrected
heartbeat/fail/output ownership rules are enforced
model/config artifacts are delivered through Backend
RustFS is hidden from Worker
output integrity is independently verified by Backend
READY transition occurs only after durable object write
output replay is idempotent
retry policy is bounded
OpenAPI matches Worker contract
A01-A11 all PASS on qualified Backend/Worker SHAs
```

Only then may the system declare:

```text
TTS Worker Production Accepted
Backend TTS Domain Production Accepted
```

---

## 30. Final invariant

```text
Backend decides WHAT is generated and owns durable truth.
Worker decides HOW to execute one assigned immutable generation contract.
PostgreSQL owns queue/job truth.
RustFS owns bytes but is reachable only through Backend.
A lease proves temporary execution ownership.
A READY FileAsset is immutable.
```
