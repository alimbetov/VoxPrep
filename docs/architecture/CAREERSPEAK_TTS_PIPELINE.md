# CareerSpeak — Spring MVC + Local Headless Piper Worker

**Document version:** 1.0  
**Status:** Architecture baseline  
**Applies to:** VoxPrep / CareerSpeak v0.4+

---

## 1. Decision

CareerSpeak SHALL use the following content-production architecture for MVP and the first production release:

- one Spring Boot modular monolith;
- Spring MVC + Thymeleaf/HTMX for the internal Content Studio;
- PostgreSQL as the durable source of truth and TTS job queue;
- a local headless Python worker for Piper-based TTS generation;
- FFmpeg for post-processing and production audio encoding;
- DigitalOcean Spaces as production object storage;
- CDN delivery for published immutable audio;
- Flutter as the only learner-facing client.

JavaFX and PySide6 SHALL NOT be required for the primary moderator workflow.

Piper SHALL NOT run in a learner request path and SHALL NOT be embedded into the Spring Boot JVM.

---

## 2. Why this architecture

The TTS subsystem is a content-production tool, not a runtime user feature. Audio is generated before publication and reused by all learners.

Therefore CareerSpeak optimizes for:

1. deterministic generation;
2. recoverability after worker failure;
3. reproducible output;
4. minimal cloud runtime cost;
5. moderator review before publication;
6. no dependency of learners on the TTS worker;
7. easy migration from a local worker to one or more cloud workers later.

---

## 3. Target topology

```text
                    LEARNER RUNTIME

Flutter Mobile
     │
     ├──────────────► CareerSpeak REST API
     │                       │
     │                       ▼
     │                   PostgreSQL
     │
     └──────────────► CDN
                             │
                             ▼
                    DigitalOcean Spaces


                   CONTENT PRODUCTION

Moderator Browser
     │
     ▼
Spring MVC Content Studio
     │
     ├──────────────► PostgreSQL
     │                    │
     │                    ▼
     │                 TTS Jobs
     │
     └──────────────────────────────┐
                                    │ HTTPS polling
                                    ▼
                           Local TTS Worker
                           Python + Piper
                                  │
                                  ▼
                                WAV
                                  │
                                  ▼
                               FFmpeg
                                  │
                                  ▼
                           production MP3
                                  │
                           presigned PUT
                                  ▼
                         DigitalOcean Spaces
```

The local worker requires outbound HTTPS only. It does not require inbound connectivity from DigitalOcean.

---

## 4. Deployable components

CareerSpeak MVP SHALL consist of three application artifacts:

```text
1. careerspeak-backend
   Java / Spring Boot / Spring MVC

2. careerspeak-tts-worker
   Python / Piper / FFmpeg

3. careerspeak-mobile
   Flutter
```

Production infrastructure SHALL initially consist of:

```text
DigitalOcean App Platform or Droplet
Managed PostgreSQL
DigitalOcean Spaces
CDN
```

No Eureka, RabbitMQ, Kafka, Redis or Kubernetes is required for this pipeline in MVP.

---

## 5. Backend module structure

Recommended modular-monolith structure:

```text
careerspeak-backend
└── src/main/java/.../careerspeak
    ├── admin
    ├── assessment
    ├── audio
    ├── catalog
    ├── interview
    ├── localization
    ├── media
    ├── profession
    ├── publication
    ├── security
    ├── topic
    ├── tts
    └── vocabulary
```

The modules are logical boundaries inside one deployable Spring Boot application.

---

## 6. Content Studio

The internal moderator interface SHALL use:

```text
Spring MVC
Thymeleaf
HTMX
Bootstrap or equivalent minimal UI toolkit
Spring Security
server-side session authentication
CSRF protection
```

Initial administration routes:

```text
/admin/dashboard
/admin/professions
/admin/interviews
/admin/vocabulary
/admin/topics
/admin/questions
/admin/tests
/admin/localization
/admin/audio
/admin/publication
```

The Content Studio SHALL be treated as an internal CMS/content-production platform, not as a public SPA.

---

## 7. TTS lifecycle

Audio generation SHALL NOT run on every ordinary draft save.

Recommended lifecycle:

```text
DRAFT
  │
  ▼
READY_FOR_AUDIO
  │
  ▼
AUDIO_PENDING
  │
  ▼
AUDIO_GENERATING
  │
  ├──────────────► AUDIO_FAILED
  │
  ▼
AUDIO_READY
  │
  ▼
REVIEW
  │
  ▼
PUBLISHED
  │
  ▼
ARCHIVED
```

Generation is triggered by one of the following explicit actions:

- Prepare for Review;
- Generate Missing Audio;
- Regenerate Audio;
- bulk import finalization.

Publication SHALL be blocked when required audio is missing, stale, failed or unreviewed.

---

## 8. TTS job model

Recommended table:

```text
tts_job
────────────────────────────────
id
content_type
content_revision_id
audio_role
fingerprint
status
attempt_count
worker_id
lease_until
created_at
started_at
completed_at
error_code
error_message
```

Suggested `audio_role` values:

```text
QUESTION
MODEL_ANSWER
VOCABULARY_WORD
VOCABULARY_EXAMPLE
TOPIC_SECTION
PHRASE
TEST_EXPLANATION
```

Status values:

```text
PENDING
RUNNING
READY
FAILED
CANCELLED
```

---

## 9. Worker claim protocol

The local worker SHALL NOT connect directly to PostgreSQL.

It SHALL communicate with the backend over authenticated HTTPS.

Example endpoints:

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{id}/heartbeat
POST /internal/v1/tts/jobs/{id}/complete
POST /internal/v1/tts/jobs/{id}/fail
```

A successful claim returns all information required to generate one asset:

```json
{
  "jobId": 913,
  "contentRevisionId": 10021,
  "audioRole": "QUESTION",
  "text": "Tell me about yourself.",
  "ttsText": "Tell me about yourself.",
  "voiceCode": "EN_US_LESSAC_HIGH",
  "fingerprint": "...",
  "uploadUrl": "..."
}
```

The worker SHALL NOT need database credentials or permanent object-storage credentials.

---

## 10. Lease and recovery

A claimed job SHALL have:

```text
worker_id
lease_until
```

If the worker crashes or loses network connectivity and `lease_until < now()`, the backend MAY return the job to `PENDING` after a bounded retry policy.

This prevents jobs from remaining permanently stuck in `RUNNING`.

The worker SHOULD send heartbeat requests for long synthesis/post-processing operations.

---

## 11. Fingerprint and idempotency

Audio SHALL have a deterministic fingerprint.

Recommended fingerprint input:

```text
normalized_tts_text
voice_code
voice_model_checksum
engine_version
speed
postprocess_profile
```

Recommended algorithm:

```text
SHA-256
```

If the required fingerprint already maps to an approved reusable audio asset, generation MAY be skipped.

If a revision changes and the fingerprint changes, existing attached audio SHALL be marked `STALE` for that revision.

The same exact content/voice configuration MUST NOT generate multiple production assets accidentally due to retries.

---

## 12. Display text and TTS text

CareerSpeak SHALL support two representations where necessary:

```text
display_text
    learner-visible canonical English

tts_text
    optional pronunciation-oriented representation
```

This is required for professional terminology, acronyms and product names.

Examples requiring explicit qualification may include:

```text
JPA
JVM
JWT
CI/CD
SQL
REST
OAuth
R2DBC
PostgreSQL
WebFlux
Kubernetes
```

The displayed English text MUST NOT be modified merely to accommodate a TTS engine.

---

## 13. Pronunciation dictionary

The Content Studio SHOULD support a controlled pronunciation dictionary:

```text
tts_pronunciation
────────────────────────────────
id
term
replacement
scope
priority
enabled
created_at
updated_at
```

The normalization pipeline is:

```text
display/canonical text
        ↓
content-specific tts_text override
        ↓
pronunciation dictionary
        ↓
normalized TTS input
        ↓
Piper
```

All pronunciation substitutions MUST be reviewable by a moderator.

---

## 14. Voice registry

Recommended model:

```text
tts_voice
────────────────────────────────
id
code
engine
language
accent
model_name
model_version
model_checksum
speed_default
license_name
license_reference
commercial_use_reviewed
enabled
created_at
updated_at
```

A voice SHALL NOT be enabled for production until its technical quality and licensing have been reviewed.

The voice model checksum SHALL participate in the audio fingerprint.

---

## 15. Audio processing pipeline

Piper output SHALL be treated as an intermediate master, not the learner-delivery format.

Recommended pipeline:

```text
Piper
  ↓
WAV temporary master
  ↓
technical validation
  ↓
FFmpeg
  ├── trim excessive silence
  ├── normalize if required by approved profile
  ├── convert to mono
  └── encode production format
  ↓
MP3 production asset
  ↓
technical QC
  ↓
upload
```

Initial production profile to qualify:

```text
MP3
mono
64–80 kbps
speech-oriented sample rate
```

The exact bitrate/sample-rate profile SHALL be selected after listening qualification and documented as an ADR.

Temporary WAV files SHOULD be deleted after successful production encoding and upload unless explicitly retained for mastering/debugging.

---

## 16. Technical quality checks

Before a job becomes `READY`, the worker SHALL verify at least:

```text
file exists
file size > 0
duration > 0
expected codec
expected channel count
expected sample rate/profile
checksum calculated
no synthesis exception
no FFmpeg failure
reasonable duration bounds
```

Suspicious duration SHALL fail or flag the asset for review.

Example: a long sentence resulting in a fraction-of-a-second file must not be automatically accepted.

---

## 17. Human review

MVP SHALL NOT automatically publish newly generated TTS audio.

Required flow:

```text
GENERATED
   ↓
TECHNICAL QC
   ↓
READY_FOR_REVIEW
   ↓
Moderator preview
   ↓
APPROVED
   ↓
PUBLISHED
```

The Content Studio SHALL support play/approve/regenerate actions.

After a voice and content category have accumulated sufficient quality evidence, a future ADR MAY allow more automated publication for selected low-risk content classes.

---

## 18. File asset model

Recommended metadata:

```text
file_asset
────────────────────────────────
id
storage_provider
bucket
object_key
mime_type
size_bytes
checksum_sha256
duration_ms
status
created_at
updated_at
```

The database SHALL NOT store permanent environment-specific origin URLs.

`object_key` SHALL be immutable after publication.

---

## 19. Storage and CDN strategy

Production recommendation for the first release:

```text
DigitalOcean Spaces + CDN
```

Published audio SHALL use versioned/immutable object keys, for example:

```text
audio/interview/Q100/rev-3/<fingerprint>.mp3
```

Changing text, voice, model version or audio profile produces a new fingerprint and therefore a new object key.

This allows long-lived CDN caching without cache invalidation complexity.

Draft or unapproved assets MAY remain private.

Published learner assets SHOULD be optimized for CDN delivery rather than proxied through the Spring Boot application.

---

## 20. Security model

Moderator browser authentication:

```text
Spring Security
server-side session
HttpOnly cookie
CSRF protection
```

TTS worker authentication SHALL be separate machine authentication, for example a rotatable worker token or mutually authenticated mechanism documented in a later security ADR.

The worker SHALL receive time-limited upload authorization rather than permanent Spaces secrets whenever practical.

The worker SHALL NOT expose a public inbound service.

---

## 21. Local worker behavior

The worker SHALL be able to run on a developer/content-production Windows machine.

Expected behavior:

```text
start worker
   ↓
authenticate
   ↓
claim job
   ↓
generate
   ↓
post-process
   ↓
validate
   ↓
upload
   ↓
complete job
   ↓
claim next job
```

When no jobs exist, the worker SHOULD use bounded polling/backoff.

If the local machine is off, content-production jobs remain pending. Learner runtime remains unaffected.

---

## 22. Scaling path

The first release uses:

```text
Local Worker × 1
```

No backend contract change is required to evolve to:

```text
Local Worker × 1
Cloud Worker × N
```

Workers compete for leased jobs via the backend claim protocol.

RabbitMQ or another queue MAY be introduced only if measured throughput/reliability requirements exceed the PostgreSQL-backed job design.

---

## 23. Bulk generation

The Content Studio SHALL support bulk workflows.

Example:

```text
Import 500 vocabulary items
        ↓
validate content
        ↓
mark final rows READY_FOR_AUDIO
        ↓
create all missing TTS jobs
        ↓
worker processes jobs
        ↓
review failures / samples
        ↓
publish
```

The UI SHOULD expose aggregate generation status:

```text
Total
Pending
Running
Ready
Failed
```

Bulk operations MUST remain idempotent.

---

## 24. Observability

Backend SHALL expose metrics for:

```text
tts.jobs.pending
tts.jobs.running
tts.jobs.ready
tts.jobs.failed
tts.job.duration
tts.retry.count
```

The worker SHALL produce structured logs containing at least:

```text
jobId
workerId
voiceCode
fingerprint
stage
duration
errorCode
```

Logs MUST NOT contain unnecessary personal learner data because the TTS pipeline operates only on moderator-authored content.

---

## 25. Failure scenarios that must be tested

The implementation SHALL cover at least:

1. worker killed during Piper synthesis;
2. worker killed during FFmpeg conversion;
3. network loss before upload;
4. network loss after upload but before completion callback;
5. duplicate completion callback;
6. expired upload URL;
7. invalid voice configuration;
8. corrupted generated file;
9. backend restart with pending/running jobs;
10. two workers claiming concurrently;
11. text changed while an old job is running;
12. stale result returned after a newer revision/fingerprint exists.

A stale worker result MUST NOT overwrite the current audio association of a newer revision.

---

## 26. Acceptance criteria

The TTS architecture is accepted when the following end-to-end scenario is repeatable:

```text
Moderator edits English content
        ↓
marks revision READY_FOR_AUDIO
        ↓
backend creates exactly the required jobs
        ↓
local worker claims job
        ↓
Piper generates temporary WAV
        ↓
FFmpeg produces qualified MP3
        ↓
worker uploads through temporary authorization
        ↓
backend records FileAsset
        ↓
moderator previews and approves audio
        ↓
revision is published
        ↓
Flutter receives immutable CDN asset reference
        ↓
learner playback does not depend on Piper or worker availability
```

The system MUST recover from worker termination without manual database repair.

---

## 27. Explicit non-goals for MVP

Do not implement for MVP:

```text
JavaFX moderator
PySide6 moderator UI
Piper JNI integration
Piper inside Spring request threads
RabbitMQ for TTS jobs
Kafka
Kubernetes
runtime TTS for learners
automatic publication without review
WAV delivery to learners
Spring Boot proxying of audio bytes
```

---

## 28. Architecture principle

The production rule is:

> CareerSpeak generates audio asynchronously during content production, publishes immutable reviewed assets, and serves learners from CDN/object storage. The learner runtime is independent of Piper and of the TTS worker.
