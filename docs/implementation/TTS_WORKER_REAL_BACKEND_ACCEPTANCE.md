# VoxPrep — Real Backend ↔ TTS Worker Production Acceptance

**Status:** Acceptance plan  
**Goal:** qualify the already production-hardened Worker against a real Backend, PostgreSQL, RustFS and one real Piper model  
**Exit state:** `TTS Worker Production Accepted`

## 1. Scope

This stage is not a new Worker feature stage.

It validates that the complete deployed system works as one pipeline:

```text
Backend catalog
     ↓
real Piper model
     ↓
tts_job PENDING
     ↓
Worker claim
     ↓
model download
     ↓
Piper
     ↓
MP3
     ↓
Backend
     ↓
RustFS
     ↓
tts_job READY
```

No Worker business responsibility should be added during this stage unless acceptance reveals a real contract defect.

---

## 2. Required environment

Acceptance environment MUST contain:

```text
PostgreSQL
Backend application
RustFS
TTS Worker container
one persistent Worker model-cache volume
one real approved Piper model.onnx
matching model.onnx.json
one valid WORKER_TOKEN
```

Recommended topology:

```text
PostgreSQL ─────┐
                │
RustFS ─────────┼── Backend : HTTPS/API
                │
                └──── TTS Worker
                         │
                         └── private persistent model cache
```

Worker receives only:

```text
BASE_URL
WORKER_TOKEN
WORKER_ID
MODEL_CACHE_DIR
MODEL_CACHE_MAX_BYTES
MAX_LOADED_MODELS
```

Worker MUST NOT receive PostgreSQL or RustFS credentials.

---

## 3. Test fixture

Seed exactly one model revision suitable for deterministic acceptance.

Example logical data:

```text
tts_voice
  code = acceptance-en-us
  language = en-US
  enabled = true


tts_voice_model
  code = acceptance-en-us-v1
  engine = PIPER
  status = ACTIVE
  model_sha256 = actual SHA-256(model.onnx)
  config_sha256 = actual SHA-256(model.onnx.json)
```

The real model and config artifacts are stored through Backend-owned storage flow and are downloadable only through:

```text
GET /internal/v1/tts/models/{voiceModelId}/model
GET /internal/v1/tts/models/{voiceModelId}/config
```

Use a short deterministic acceptance phrase, for example:

```text
Tell me about yourself.
```

The acceptance job is created with:

```text
jobId allocated
fileId allocated
contentRevisionId allocated
voiceModelId = seeded model
fingerprint calculated by Backend
status = PENDING
attemptCount = 0
FileAsset status = PENDING
```

---

## 4. Baseline acceptance A01 — cold-cache happy path

Precondition:

```text
Worker model cache does not contain the selected model revision
```

Execution:

```text
1. Backend contains ACTIVE model catalog entry.
2. Backend creates TTS job PENDING and FileAsset PENDING.
3. Worker starts with correct BASE_URL and WORKER_TOKEN.
4. Worker claims the job.
5. Backend atomically changes job PENDING -> RUNNING and assigns lease.
6. Worker sees cache miss.
7. Worker downloads exact model.onnx through Backend API.
8. Worker downloads exact model.onnx.json through Backend API.
9. Worker verifies modelSha256 and configSha256.
10. Worker atomically installs model revision into local cache.
11. Worker loads Piper model.
12. Worker synthesizes temporary WAV.
13. Worker converts WAV to mp3-mono-24k-64k-v1.
14. Worker validates codec/channels/sample-rate/bitrate/duration.
15. Worker revalidates lease.
16. Worker uploads multipart MP3 to Backend.
17. Backend validates job/file/model/fingerprint/lease metadata.
18. Backend writes immutable MP3 to RustFS.
19. Backend persists FileAsset metadata.
20. Backend changes FileAsset PENDING -> READY.
21. Backend changes TtsJob RUNNING -> READY.
22. Backend sets completed_at.
```

Expected final state:

```text
tts_job.status = READY
file_asset.status = READY
RustFS object exists
file_asset.sha256 = SHA-256(actual RustFS bytes)
file_asset.size_bytes = actual object size
file_asset.duration_ms > 0
job.file_id = file_asset.id
job.voice_model_id = seeded voiceModelId
```

Acceptance MUST fail if database state says READY but RustFS object does not exist.

---

## 5. A02 — generated audio qualification

The final RustFS object MUST be independently verified.

Required checks:

```text
content type = audio/mpeg
codec        = mp3
channels     = 1
sample rate  = 24000 Hz
bitrate      = accepted 64 kbps profile
size         > 0
duration     > 0
sha256       = FileAsset.sha256
```

Recommended external command:

```bash
ffprobe -v error \
  -select_streams a:0 \
  -show_entries stream=codec_name,sample_rate,channels,bit_rate:format=duration \
  -of json acceptance.mp3
```

Technical qualification is necessary but not sufficient for future model upgrades. The chosen production model should also pass a human listening check before catalog approval.

---

## 6. A03 — warm-cache second job

Create a second PENDING job using the same exact `voiceModelId`, `modelSha256` and `configSha256`.

Expected behavior:

```text
Worker claims second job
→ local exact revision found
→ no model/config download required
→ existing cached Piper model/revision reused
→ synthesis/upload succeeds
→ second job READY
```

Evidence SHOULD show that the second job did not require a fresh model artifact download.

This validates the operational benefit of the private persistent cache.

---

## 7. A04 — Worker restart and persistent cache

After A01/A03:

```text
stop Worker container
start a new Worker container/image instance
mount the same private model-cache volume
create another job for the same model revision
```

Expected:

```text
cached model revision survives container restart
new Worker resolves exact cached model
job reaches READY
```

This proves cache lifecycle is independent of container lifecycle.

---

## 8. A05 — lease ownership qualification

Create a job and make the current lease invalid before final upload, or simulate ownership transfer after lease expiry.

Expected:

```text
stale Worker heartbeat/output -> 409 or 410
stale Worker does not finalize output
TtsJob/FileAsset are not changed to READY by stale lease
new/current owner remains authoritative
```

This test proves `WORKER_TOKEN` authentication is not sufficient to mutate arbitrary jobs.

---

## 9. A06 — Worker crash/reclaim

Procedure:

```text
create PENDING job
Worker claims -> RUNNING
kill Worker before completion
wait until lease expires
start/reuse Worker
claim expired RUNNING job again
complete generation
```

Expected:

```text
no manual DB repair
attempt_count increments
new leaseToken is different
stale previous lease cannot finalize
reclaimed job can reach READY
```

---

## 10. A07 — RustFS temporary failure

Force RustFS unavailable during Backend output finalization.

Expected:

```text
upload/finalization does not produce READY database lie
FileAsset != READY
TtsJob != READY unless durable object exists
old READY asset remains untouched during replacement flow
```

Restore RustFS and verify that Backend retry/recovery policy can eventually complete or explicitly fail/requeue the job without Worker directly accessing storage.

---

## 11. A08 — output response loss / replay safety

Simulate:

```text
Worker sends valid output
Backend stores RustFS object and commits READY
response to Worker is lost
```

Then replay the exact same logical output request or exercise Backend replay handling.

Expected:

```text
same fileId + same identity + same sha256 -> safe/idempotent result
same READY fileId + different bytes/checksum -> rejected
no duplicate logical FileAsset
no second conflicting RustFS asset becomes authoritative
```

Worker MUST NOT convert this ambiguous transport failure into a false deterministic `/fail`.

---

## 12. A09 — model not found

Create or manipulate a job so claim references a model revision that Backend cannot expose.

Expected:

```text
model GET -> 404
Worker does not select another model
Worker reports VOICE_MODEL_NOT_FOUND
Backend applies configured retry/terminal policy
job never reaches READY with a substituted voice
```

---

## 13. A10 — checksum mismatch

Serve model/config bytes whose checksum does not match claim.

Expected:

```text
Worker rejects artifact
invalid revision is not installed into final model-cache path
Piper does not run with mismatched model
Worker reports VOICE_MODEL_CHECKSUM_MISMATCH
job never reaches READY
```

---

## 14. A11 — two Worker replicas

Run two Worker containers with separate private cache volumes and the same Backend queue.

Create at least two PENDING jobs.

Expected:

```text
atomic claim via FOR UPDATE SKIP LOCKED
each job has one current owner
no simultaneous lease ownership for one job
both Workers can complete independent jobs
no shared model-cache requirement
```

For a single PENDING job, exactly one Worker must receive it; the other should receive another job or `204 No Content`.

---

## 15. Evidence to capture

For each acceptance run capture:

```text
Backend commit/image version
Worker image tag/digest
Worker Git SHA
real voiceModelId
modelSha256
configSha256
jobId
fileId
initial/final tts_job row
initial/final FileAsset row
RustFS object metadata
final audio sha256
ffprobe output
relevant Backend logs
relevant Worker logs
```

Secrets and Authorization headers MUST be redacted.

Recommended final acceptance record:

```text
acceptance date
qualified Backend SHA
qualified Worker SHA/image digest
model revision
A01-A11 result table
known deviations = none or explicitly documented
approver
```

---

## 16. Production Accepted gates

`TTS Worker Production Accepted` MAY be declared only when all mandatory gates below are green:

```text
A01 cold-cache real E2E                PASS
A02 final MP3 technical verification   PASS
A03 warm-cache reuse                   PASS
A04 container restart/cache reuse      PASS
A05 stale lease rejection              PASS
A06 crash + lease reclaim              PASS
A07 RustFS failure safety              PASS
A08 replay-safe output                 PASS
A09 missing model fail-closed          PASS
A10 checksum mismatch fail-closed      PASS
A11 multi-worker atomic claim          PASS
```

And additionally:

```text
no Worker direct PostgreSQL access
no Worker direct RustFS access
WORKER_TOKEN not present in logs
no READY state without durable RustFS object
no silent model fallback
no overwrite of immutable READY fileId
```

---

## 17. Exit decision

When the gates above pass against the real Backend implementation:

```text
TTS Worker Production Accepted
```

At that point Worker development is closed as a separate feature stream.

Future Worker changes should be limited to:

```text
bug fixes discovered by production evidence
explicit dependency/security upgrades
qualified Piper/model engine upgrades
measured performance improvements
contract changes initiated by Backend/product requirements
```

New Backend/content/mobile development should not reopen Worker architecture without a demonstrated requirement.

---

## 18. Final system invariant

```text
Backend catalog
     ↓
exact immutable Piper model
     ↓
PENDING durable job
     ↓
atomic Worker lease
     ↓
verified local model revision
     ↓
Piper + FFmpeg + QC
     ↓
lease-safe multipart output
     ↓
Backend-owned RustFS persistence
     ↓
FileAsset READY + TtsJob READY
```

This is the required proof that the VoxPrep TTS production path is operational end-to-end.
