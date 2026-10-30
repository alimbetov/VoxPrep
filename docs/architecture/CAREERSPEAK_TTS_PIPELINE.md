# CareerSpeak — TTS Worker & Audio Production Architecture

**Document version:** 2.1  
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

The Backend allocates persistent `jobId` and `fileId` identities before Worker claim.

---

## 2. Ownership

Backend owns:

```text
TTS voice/model registry
exact voice_model_id resolution
TTS job lifecycle
PostgreSQL queue
lease ownership
fileId/jobId allocation
fingerprint expectation
RustFS persistence
FileAsset metadata association
regeneration/replacement policy
ADMIN review/publication
```

Worker owns only:

```text
claim
model download/cache
synthesis
post-processing
technical QC
Backend audio upload
fail reporting
```

Worker does not publish learner content, does not allocate persistent IDs and does not connect directly to PostgreSQL.

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

Model download may use a Backend-authorized stream or short-lived download URL. Generated learner audio is uploaded through Backend API; Backend owns the RustFS write.

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
request Backend model authorization
→ download exact model/config
→ verify SHA-256
→ install atomically in cache
→ load Piper model
```

Checksum mismatch is a hard model-use failure; worker never chooses another voice automatically.

A small in-memory LRU of loaded models may be used.

---

## 7. TTS job and file identity

Recommended fields:

```text
tts_job
id
file_id
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

Backend allocates:

```text
jobId  = UUID
fileId = UUID
```

before Worker claim.

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

`fileId` identifies an immutable audio asset. Regeneration creates a new `fileId`; physical overwrite of an already published/READY asset identity is forbidden.

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
POST /internal/v1/tts/jobs/{id}/output
POST /internal/v1/tts/jobs/{id}/fail
POST /internal/v1/tts/models/{id}/download
```

Claim response contains enough information to generate exactly one asset, including:

```text
jobId
fileId
contentRevisionId
audioRole
normalizedTtsText
language
voiceModelId
fingerprint
leaseToken
```

Worker uses the supplied `jobId` and `fileId` unchanged.

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

Old worker output is rejected because lease token no longer matches.

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
postprocess_profile_version/audio_profile
```

Algorithm:

```text
SHA-256
```

Any relevant change creates a new fingerprint.

If the fingerprint changes, Backend allocates a new `jobId` and new `fileId`. The old READY asset remains usable until the replacement reaches READY.

---

## 14. Audio generation

```text
Piper
→ temporary WAV
→ technical validation
→ FFmpeg
→ production MP3
→ QC
→ Backend output upload
→ RustFS
```

Initial production delivery profile:

```text
MP3
MIME audio/mpeg
.mp3 extension
mono
24 kHz
64 kbps CBR
profile: mp3-mono-24k-64k-v1
```

The profile is versioned/configurable and may be changed after listening qualification without changing Worker orchestration.

---

## 15. Technical QC

Verify at least:

```text
file exists
size > 0
duration > 0
codec = MP3
channels = 1
expected sample rate/profile
Piper success
FFmpeg success
checksum generated
reasonable duration bounds
```

Invalid audio never reaches job READY.

---

## 16. Upload/finalization

Worker uploads the generated MP3 through Backend:

```http
POST /internal/v1/tts/jobs/{jobId}/output
Content-Type: multipart/form-data
```

Request includes at least:

```text
fileId
leaseToken
fingerprint
voiceModelId
audioProfile
file
```

Backend accepts only if:

```text
current lease matches
job RUNNING
job.fileId matches
voice model matches
fingerprint still expected
content revision still valid
```

Backend then owns:

```text
stream validation
RustFS object write
checksum/size/duration association
FileAsset PENDING → READY
TtsJob RUNNING → READY
current audio reference switch when applicable
```

Duplicate upload/finalization handling must be idempotent/replay-safe.

A conflicting payload for an already READY immutable `fileId` is rejected.

---

## 17. Regeneration and replacement

Worker has no overwrite operation.

Backend decides whether a new generation is required:

```text
new fingerprint == current fingerprint
→ no generation

new fingerprint != current fingerprint
→ allocate new jobId
→ allocate new fileId
→ generate new immutable audio
```

Reference switch occurs only after the new `FileAsset` is READY.

The old audio remains valid until then and later becomes a Backend cleanup candidate.

This preserves Flutter cache, manifest, checksum and offline-pack identity.

---

## 18. Failure reporting

Worker fail codes include:

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

Retry is bounded and classified by Backend policy.

---

## 19. Human review/publication

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

## 20. Worker configuration

Only operational configuration such as:

```text
BACKEND_URL
WORKER_ID
WORKER_TOKEN
LOCAL_MODEL_CACHE_PATH
POLL_INTERVAL
MAX_LOADED_MODELS
LEASE_HEARTBEAT_INTERVAL
```

No direct DB or permanent RustFS secrets.

---

## 21. Scaling

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

## 22. Mandatory failure qualification

Must prove:

```text
two workers claim concurrently
worker crash during Piper
worker crash during FFmpeg
lease expiry/reclaim
stale worker output
upload success + response loss
duplicate output upload
missing model
model checksum mismatch
corrupt output
text/fingerprint changes during job
model deprecated after job creation
backend restart with queue state preserved
RustFS temporary outage behind Backend
regeneration while old READY asset remains playable
```

---

## 23. End-to-end acceptance

```text
ADMIN creates/changes content
→ Backend calculates fingerprint
→ Backend allocates jobId + fileId
→ PENDING job + PENDING FileAsset
→ Worker atomic claim
→ exact model/cache
→ Piper + FFmpeg + QC
→ Worker uploads MP3(jobId, fileId, leaseToken) to Backend
→ Backend validates lease/fingerprint/model/revision
→ Backend writes immutable object to RustFS
→ FileAsset READY + TTS job READY
→ Backend switches current audio reference when replacing
→ ADMIN review
→ PUBLISHED + ACTIVE
→ learner manifest
→ Flutter stream/download immutable MP3 asset
```

This is the authoritative TTS production baseline for CareerSpeak v0.9.
