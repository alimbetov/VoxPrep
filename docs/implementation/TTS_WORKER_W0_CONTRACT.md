# CareerSpeak — TTS Worker W0 Contract

**Branch:** `feat/tts-worker-foundation`  
**Status:** W0 design baseline  
**Scope:** Backend ↔ TTS Worker ↔ audio asset contract

Normative parents:

- `docs/architecture/CAREERSPEAK_TTS_PIPELINE.md`
- `docs/architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`

---

## 1. Decision

The Backend owns all persistent identity and lifecycle decisions.

When English learner content requires audio, Backend allocates both:

```text
jobId  = UUID
fileId = UUID
```

before the Worker receives the job.

The Worker never invents persistent IDs and never decides whether the operation is an initial generation or a regeneration.

Worker responsibility is deliberately narrow:

```text
claim
→ synthesize
→ post-process
→ technical QC
→ upload generated audio through Backend API
```

Backend responsibility:

```text
content revision
fileId allocation
jobId allocation
queue/lease
regeneration decision
immutable asset replacement
RustFS persistence
publication/availability
old-asset cleanup
```

---

## 2. Creation flow

For a content revision requiring English audio:

```text
ADMIN saves English text
        │
        ▼
Backend creates/updates ContentRevision
        │
        ├── calculates expected TTS fingerprint
        ├── allocates fileId = UUID
        ├── creates FileAsset(PENDING)
        └── creates TtsJob(PENDING)
                    │
                    ▼
                 Worker
```

Minimum relationship:

```text
ContentRevision
      │
      │ currentAudioFileId
      ▼
  FileAsset
      ▲
      │ fileId
    TtsJob
```

`fileId` identifies the immutable produced audio asset.

`jobId` identifies one generation attempt/lifecycle.

They MUST NOT be treated as the same identity.

---

## 3. Claim contract

Worker claims one job through:

```http
POST /internal/v1/tts/jobs/claim
```

Backend executes the PostgreSQL atomic claim using `FOR UPDATE SKIP LOCKED` and lease ownership.

Minimum successful claim payload:

```json
{
  "jobId": "550e8400-e29b-41d4-a716-446655440000",
  "fileId": "d9735e16-42fc-4da6-9436-754561bbaa93",
  "contentRevisionId": "...",
  "audioRole": "PRIMARY",
  "normalizedTtsText": "Tell me about yourself.",
  "language": "en-US",
  "voiceModelId": "...",
  "voiceModelCode": "en_US-lessac-high-v1",
  "modelSha256": "...",
  "configSha256": "...",
  "fingerprint": "...",
  "leaseToken": "...",
  "leaseUntil": "2026-10-30T12:00:00Z"
}
```

Worker MUST use the supplied `fileId` unchanged.

---

## 4. Worker output format

### Production delivery baseline

```text
container/codec: MP3
extension:       .mp3
MIME:            audio/mpeg
channels:        mono
sample rate:     24 kHz
bitrate:         64 kbps CBR
```

Reasoning:

- speech-only content does not require stereo;
- MP3 has broad decoder support across Flutter target platforms;
- 64 kbps mono keeps offline packs compact while preserving clean TTS speech;
- 24 kHz is appropriate for speech TTS and avoids unnecessary high-rate storage;
- deterministic CBR simplifies qualification and operational sizing.

The profile MUST remain versioned/configurable so listening qualification can later move bitrate/sample rate without changing Worker orchestration.

Recommended profile identifier:

```text
audioProfile = mp3-mono-24k-64k-v1
```

### Intermediate format

Piper may emit temporary WAV:

```text
Piper
→ temporary WAV
→ FFmpeg
→ production MP3
```

WAV is never a learner delivery format and is deleted after processing.

Example FFmpeg intent:

```text
-ac 1
-ar 24000
-c:a libmp3lame
-b:a 64k
```

Exact command-line construction belongs to the FFmpeg adapter and is qualified in W4.

---

## 5. Flutter playback contract

Flutter receives/stores the immutable MP3 asset using the Backend manifest/delivery contract.

Required descriptor fields include at least:

```text
fileId
contentType = audio/mpeg
fileName/extension = .mp3
sizeBytes
sha256
durationMs
audioProfile
```

For HTTP playback/download Backend delivery MUST expose correct:

```text
Content-Type: audio/mpeg
Content-Length
```

Byte-range support SHOULD be enabled for efficient streaming/seeking.

For local offline playback the local filename MUST retain the `.mp3` extension so platform decoders can resolve the format reliably.

---

## 6. Generation pipeline

```text
normalizedTtsText
        ↓
exact voiceModelId
        ↓
Piper
        ↓
temporary WAV
        ↓
FFmpeg
        ↓
MP3
        ↓
technical QC
        ↓
Backend upload API
        ↓
RustFS
```

Worker never needs permanent RustFS credentials.

---

## 7. Upload API

For the MVP the Worker uploads through Backend instead of writing directly to RustFS.

Recommended endpoint:

```http
POST /internal/v1/tts/jobs/{jobId}/output
Content-Type: multipart/form-data
Authorization: Bearer <WORKER_TOKEN>
```

Multipart fields:

```text
fileId
leaseToken
fingerprint
voiceModelId
audioProfile
file
```

`file` is the generated `.mp3` binary.

Backend validates before accepting finalization:

```text
job exists
job.status == RUNNING
job.id == jobId
job.fileId == fileId
job.voiceModelId == voiceModelId
job.fingerprint == fingerprint
job.leaseToken == leaseToken
leaseUntil > now
content revision is still valid
```

Backend then:

```text
stream/validate file
→ calculate/verify metadata
→ store immutable object in RustFS
→ mark FileAsset READY
→ mark TtsJob READY
→ atomically expose/switch current audio reference when applicable
```

A stale Worker MUST NOT be allowed to overwrite or finalize the asset.

---

## 8. FileAsset lifecycle

Initial MVP states:

```text
PENDING
READY
FAILED
```

Example:

```text
Backend allocates fileId
→ FileAsset.PENDING

Worker upload accepted
→ FileAsset.READY

terminal generation failure
→ FileAsset.FAILED
```

Backend may later add cleanup-oriented states such as `SUPERSEDED`/`ORPHANED`; they are not Worker concerns.

---

## 9. TtsJob lifecycle

```text
PENDING
RUNNING
READY
FAILED
CANCELLED
SUPERSEDED
```

Worker only observes/causes transitions through Backend APIs.

Worker does not update persistence directly.

---

## 10. Regeneration / text changes

Regeneration is entirely Backend-owned.

Worker has no `overwrite` operation.

When a relevant input changes, Backend calculates a new fingerprint.

```text
new fingerprint == current fingerprint
→ do not generate

new fingerprint != current fingerprint
→ allocate new fileId
→ create new TtsJob
→ generate new immutable audio asset
```

The existing READY asset remains valid until the replacement is successfully produced.

Example:

```text
current audio
fileId = A
status = READY
        │
        │ text/voice/profile changes
        ▼
new FileAsset
fileId = B
status = PENDING
        │
        ▼
Worker generates B
        │
        ▼
B = READY
        │
        ▼
Backend switches currentAudioFileId A → B
        │
        ▼
A becomes cleanup candidate
```

Physical overwrite of `audio/{fileId}.mp3` is forbidden.

This preserves immutable cache semantics for Flutter, manifests, checksums and offline packs.

---

## 11. Fingerprint

Fingerprint MUST include all inputs that can materially change the generated audio, at least:

```text
normalizedTtsText
voiceModelId
voiceModelChecksum
speakerId when applicable
engineVersion
speakingRate
postprocessProfileVersion/audioProfile
```

Algorithm:

```text
SHA-256
```

Fingerprint is Backend-owned and supplied to Worker.

---

## 12. Upload idempotency

The final output endpoint MUST be replay-safe.

A retry with the same:

```text
jobId
fileId
leaseToken
fingerprint
content checksum
```

must not create a second logical FileAsset.

Backend may return the already accepted result when the exact same output was committed previously.

A retry with conflicting bytes/checksum for an already READY immutable `fileId` MUST be rejected.

---

## 13. Failure rules

Worker reports generation failures through the job failure API when it still owns the lease.

Important failures include:

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

If lease ownership is lost during synthesis/post-processing:

```text
stop finalization
→ do not upload
→ do not overwrite anything
→ delete temporary output
```

---

## 14. Security boundary

Worker configuration contains only operational secrets/configuration such as:

```text
BACKEND_URL
WORKER_ID
WORKER_TOKEN
LOCAL_MODEL_CACHE_PATH
POLL_INTERVAL
LEASE_HEARTBEAT_INTERVAL
```

Worker MUST NOT receive:

```text
PostgreSQL credentials
ADMIN password
learner installation token
permanent RustFS credentials
```

---

## 15. W0 acceptance

W0 is accepted when the following are frozen:

```text
[ ] Backend allocates UUID jobId and UUID fileId
[ ] claim payload includes fileId
[ ] Worker never generates persistent IDs
[ ] production delivery format is MP3/audio/mpeg
[ ] baseline profile is mono / 24 kHz / 64 kbps CBR
[ ] Worker uploads via Backend API
[ ] upload requires jobId + fileId + leaseToken + fingerprint
[ ] Backend owns RustFS persistence
[ ] regeneration allocates a new fileId
[ ] immutable assets are never overwritten in place
[ ] old audio remains valid until replacement is READY
[ ] upload/finalization is replay-safe
[ ] Flutter manifest exposes MIME/size/checksum/duration/profile
[ ] no direct Worker PostgreSQL or permanent RustFS credentials
```

After W0 acceptance, implementation proceeds to **W1 Runtime Skeleton** with fake ports only.
