# CareerSpeak — TTS Worker & Audio Production Architecture

**Document version:** 2.0  
**Status:** Normative TTS production baseline  
**Applies to:** CareerSpeak v0.9+

Related standard:

- [`CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)

---

## 1. Decision

CareerSpeak uses a separate server-managed long-running TTS Worker:

```text
Python
Piper
FFmpeg
local immutable model cache
```

Production worker starts/restarts automatically under Docker/process supervision.

Piper never runs in learner request paths or Spring MVC request threads.

---

## 2. Ownership

Backend owns:

```text
TTS voice/model registry
exact voice_model_id resolution
TTS job lifecycle
PostgreSQL queue
lease ownership
fingerprint expectation
presigned RustFS authorization
FileAsset metadata association
ADMIN review/publication
```

Worker owns only:

```text
claim
model download/cache
synthesis
post-processing
technical QC
upload
complete/fail reporting
```

Worker does not publish learner content and does not connect directly to PostgreSQL.

---

## 3. Security

Worker calls:

```text
/internal/v1/tts/**
```

using dedicated machine token.

Worker SHALL NOT receive:

```text
ADMIN password
learner installation token
PostgreSQL password
permanent RustFS secret key
```

RustFS private operations use short-lived presigned GET/PUT.

---

## 4. Voice/model distinction

### `tts_voice`

Logical profile:

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

Exact immutable technical revision:

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

Every TTS job references exact immutable `voice_model_id`.

Silent substitution is forbidden.

---

## 5. Model lifecycle

```text
UPLOADING
UPLOADED
VALIDATING
READY_FOR_REVIEW
APPROVED
ACTIVE
DEPRECATED
```

Failure states:

```text
INVALID
QUARANTINED
```

Model objects are immutable by revision and never overwritten in place.

Only technically qualified and license-reviewed models may become ACTIVE.

---

## 6. Model storage/cache

Private RustFS model layout may be:

```text
careerspeak-models/
└── piper/en/en_US-lessac-high/v1/
    ├── model.onnx
    └── model.onnx.json
```

Worker local cache:

```text
/var/lib/careerspeak/tts/models/<VOICE_MODEL_CODE>/
```

On cache miss:

```text
request presigned GET
→ download exact model/config
→ verify SHA-256
→ install atomically in cache
→ load Piper model
```

Checksum mismatch is a hard model-use failure; worker never chooses another voice automatically.

A small in-memory LRU of loaded models may be used.

---

## 7. TTS job

Recommended fields:

```text
tts_job
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

Statuses:

```text
PENDING
RUNNING
READY
FAILED
CANCELLED
SUPERSEDED
```

Worker `READY` is a TTS-job result state and is unrelated to Flutter offline pack `READY`.

---

## 8. PostgreSQL durable queue

Job claim is atomic.

Recommended pattern:

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
SET status         = 'RUNNING',
    worker_id      = :workerId,
    lease_token    = :leaseToken,
    lease_until    = NOW() + :leaseDuration,
    started_at     = COALESCE(started_at, NOW()),
    attempt_count  = attempt_count + 1
FROM next_job
WHERE j.id = next_job.id
RETURNING j.*;
```

Exact lease duration is configuration.

Recommended indexes:

```sql
CREATE INDEX idx_tts_job_pending_claim
ON tts_job (created_at, id)
WHERE status = 'PENDING';

CREATE INDEX idx_tts_job_expired_lease
ON tts_job (lease_until)
WHERE status = 'RUNNING';
```

RabbitMQ is not required initially.

---

## 9. Worker APIs

Baseline:

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{id}/heartbeat
POST /internal/v1/tts/jobs/{id}/complete
POST /internal/v1/tts/jobs/{id}/fail
POST /internal/v1/tts/models/{id}/download
```

Claim response contains enough information to generate exactly one asset, including:

```text
jobId
contentRevisionId
audioRole
text/ttsText
voiceModelId
fingerprint
leaseToken
```

---

## 10. Lease/heartbeat

Claim generates unique:

```text
leaseToken
leaseUntil
```

Heartbeat extends lease only when:

```text
job id matches
status = RUNNING
worker id matches
lease token matches
```

Zero-row update means ownership is lost. Worker must stop finalization for that lease.

---

## 11. Crash recovery

If Worker dies:

```text
RUNNING job remains leased until leaseUntil
→ lease expires
→ later claim may reclaim
```

Old worker completion is rejected because lease token no longer matches.

No manual database repair is required.

---

## 12. TTS text pipeline

```text
canonical display text
→ optional content tts_text override
→ controlled pronunciation rules
→ normalized TTS input
→ Piper
```

Learner-visible text is not distorted for synthesis.

Technical terms may have explicit pronunciation rules.

---

## 13. Fingerprint

Fingerprint input includes at least:

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

Any relevant change creates a new fingerprint.

---

## 14. Audio generation

```text
Piper
→ temporary WAV
→ technical validation
→ FFmpeg
→ production MP3
→ QC
→ RustFS
```

Candidate profile:

```text
MP3
mono
64–80 kbps
speech-oriented sample rate
```

Final audio profile is qualified by listening tests.

---

## 15. Technical QC

Verify at least:

```text
file exists
size > 0
duration > 0
expected codec/channel/profile
Piper success
FFmpeg success
checksum generated
reasonable duration bounds
```

Invalid audio never reaches job READY.

---

## 16. Upload/completion

Worker obtains presigned PUT and uploads directly to RustFS.

Completion contains at least:

```text
jobId
leaseToken
fingerprint
voiceModelId
objectKey/checksum
size
duration
```

Backend accepts only if:

```text
current lease matches
job RUNNING
voice model matches
fingerprint still expected
content revision still valid
```

Otherwise reject or mark SUPERSEDED according to contract.

Duplicate callback handling must be idempotent/replay-safe.

---

## 17. Failure reporting

Worker fail codes include:

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

Retry is bounded and classified by Backend policy.

---

## 18. Human review/publication

```text
TTS job READY
→ generated asset available to ADMIN preview
→ ADMIN approve/regenerate
→ content revision qualifies for publication
→ PUBLISHED + ACTIVE
→ asset appears in learner manifest/delivery
```

Worker itself never changes Backend availability.

---

## 19. Worker configuration

Only operational configuration such as:

```text
BACKEND_URL
WORKER_ID
WORKER_TOKEN
LOCAL_MODEL_CACHE_PATH
POLL_INTERVAL
MAX_LOADED_MODELS
```

No direct DB or permanent RustFS secrets.

---

## 20. Scaling

Initial:

```text
TTS Worker × 1
```

Future:

```text
TTS Worker × N
```

All workers use the same claim/lease protocol. `FOR UPDATE SKIP LOCKED` + leases prevent simultaneous ownership.

---

## 21. Mandatory failure qualification

Must prove:

```text
two workers claim concurrently
worker crash during Piper
worker crash during FFmpeg
lease expiry/reclaim
stale worker completion
upload success + callback loss
duplicate callback
missing model
model checksum mismatch
corrupt output
text changes during job
model deprecated after job creation
backend restart with queue state preserved
RustFS temporary outage
```

---

## 22. End-to-end acceptance

```text
ADMIN creates content
→ Backend resolves exact model
→ PENDING job
→ Worker atomic claim
→ exact model/cache
→ Piper + FFmpeg + QC
→ RustFS upload
→ Backend validates lease/fingerprint/model/revision
→ TTS job READY
→ ADMIN review
→ PUBLISHED + ACTIVE
→ learner manifest
→ Flutter stream/download immutable asset
```

This is the authoritative TTS production baseline for CareerSpeak v0.9.
