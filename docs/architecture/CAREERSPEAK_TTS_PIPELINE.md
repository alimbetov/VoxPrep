# CareerSpeak — Spring MVC + Local Headless Piper Worker

**Document version:** 1.1  
**Status:** Architecture baseline  
**Applies to:** VoxPrep / CareerSpeak v0.5+

---

## 1. Decision

CareerSpeak SHALL use the following content-production architecture for MVP and the first production release:

- one Spring Boot modular monolith;
- Spring MVC + Thymeleaf/HTMX for the internal Content Studio;
- PostgreSQL as the durable source of truth and TTS job queue;
- RustFS as S3-compatible object storage for Piper models, draft assets and published media origin;
- a local headless Python worker for Piper-based TTS generation;
- FFmpeg for post-processing and production audio encoding;
- CDN/edge delivery for published immutable learner audio;
- Flutter as the only learner-facing client.

JavaFX and PySide6 SHALL NOT be required for the primary moderator workflow.

Piper SHALL NOT run in a learner request path and SHALL NOT be embedded into the Spring Boot JVM.

---

## 2. Architecture principles

The TTS subsystem is a **content-production system**, not a learner runtime dependency.

It optimizes for:

1. deterministic generation;
2. exact voice/model reproducibility;
3. recoverability after worker failure;
4. immutable model revisions;
5. checksum-verified model distribution;
6. moderator review before publication;
7. minimal cloud runtime cost;
8. no dependency of learners on worker availability;
9. easy migration from one local worker to multiple workers later.

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
     └──────────────► CDN / Edge
                             │
                             ▼
                           RustFS
                    published media origin


                   CONTENT PRODUCTION

Moderator Browser
     │
     ▼
Spring MVC Content Studio
     │
     ├──────────────► PostgreSQL
     │                    │
     │                    ├── TTS jobs
     │                    ├── voice registry
     │                    └── model metadata
     │
     └──────────────► RustFS
                      │
                      ├── private Piper models
                      ├── private draft assets
                      └── generated media

Local TTS Worker
Python + Piper + FFmpeg
     │
     │ authenticated HTTPS
     ▼
CareerSpeak Backend
     │
     ├── claim/lease jobs
     └── presigned RustFS GET/PUT
```

The worker requires outbound HTTPS only. It does not require inbound connectivity.

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

Production infrastructure initially consists of:

```text
DigitalOcean application runtime
Managed PostgreSQL
RustFS
CDN / edge layer for published assets
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
    ├── catalog
    ├── interview
    ├── localization
    ├── manifest
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

Initial administration routes include:

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
/admin/tts/voices
/admin/tts/models
/admin/publication
```

The Content Studio is an internal CMS/content-production platform, not a public SPA.

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

Generation is triggered by explicit workflow transition or bulk action:

- Prepare for Review;
- Generate Missing Audio;
- Regenerate Audio;
- bulk import finalization.

Publication SHALL be blocked when required audio is missing, stale, failed or unreviewed.

---

## 8. Logical voice model

A **voice** is the moderator-facing logical choice.

Recommended entity:

```text
tts_voice
────────────────────────────────
id
code
display_name
language
accent
gender
style
default_model_id
enabled
created_at
updated_at
```

Examples:

```text
EN_US_FEMALE_LESSAC
EN_US_MALE_RYAN
EN_GB_FEMALE_ALBA
```

Suggested selection metadata:

```text
accent = US / UK / other qualified accent
gender = FEMALE / MALE
style  = NEUTRAL / PROFESSIONAL / WARM / ACADEMIC / CALM
```

These values are classification/selection metadata. Piper generation is always performed by an exact resolved model revision.

---

## 9. Physical voice model registry

A **voice model** is an exact immutable Piper binary/config revision.

Recommended entity:

```text
tts_voice_model
────────────────────────────────
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
model_size_bytes
status
license_name
license_reference
commercial_use_reviewed
created_at
approved_at
```

Example code:

```text
PIPER_EN_US_LESSAC_HIGH_V1
```

The same logical voice MAY have multiple model revisions:

```text
EN_US_FEMALE_LESSAC
├── model v1 DEPRECATED
└── model v2 ACTIVE
```

Old jobs/assets remain associated with the exact model revision used at generation time.

---

## 10. Model lifecycle

Recommended lifecycle:

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

Failure/administrative states MAY include:

```text
INVALID
QUARANTINED
```

Production activation requires:

- valid model/config assets;
- matching checksums;
- successful runtime qualification;
- technical-quality review;
- license/commercial-use review.

A model binary SHALL NOT be overwritten in place.

---

## 11. RustFS model storage

RustFS SHALL be the baseline object store for Piper binaries/configs.

Recommended private bucket:

```text
careerspeak-models
```

Example layout:

```text
piper/
└── en/
    ├── en_US-lessac-high/
    │   └── v1/
    │       ├── model.onnx
    │       └── model.onnx.json
    └── en_US-ryan-high/
        └── v1/
            ├── model.onnx
            └── model.onnx.json
```

Alternative content-addressed keys MAY include a checksum component.

PostgreSQL stores metadata/object keys/checksums only. ONNX/config binary data SHALL NOT be stored in PostgreSQL.

Model objects remain private and are not served to learners.

---

## 12. Object-storage abstraction

Backend code SHALL access storage through an abstraction rather than direct environment-specific URLs.

Conceptual interface:

```text
ObjectStorage
├── createUploadUrl(...)
├── createDownloadUrl(...)
├── getMetadata(...)
└── delete(...)
```

Initial implementation:

```text
RustFsObjectStorage
```

Domain tables SHALL store bucket/object key and asset identifiers, not permanent RustFS endpoint URLs.

---

## 13. Model upload flow

Large model files SHOULD upload directly from the moderator browser to RustFS using temporary authorization.

```text
Admin
  ↓
create tts_voice_model metadata
  ↓
backend creates presigned PUT
  ↓
browser uploads ONNX/config → RustFS
  ↓
backend complete-upload call
  ↓
metadata/checksum validation
  ↓
runtime qualification job
  ↓
moderator review
  ↓
APPROVED / ACTIVE
```

The Spring JVM SHOULD NOT proxy large ONNX binaries when direct upload is available.

---

## 14. Runtime model qualification

Backend metadata validation alone is insufficient to prove that Piper can load and synthesize with a model.

A newly uploaded model SHOULD undergo runtime qualification:

```text
model UPLOADED
   ↓
qualification requested
   ↓
worker downloads model
   ↓
verify checksums
   ↓
load Piper model
   ↓
generate standard qualification text
   ↓
FFmpeg/QC
   ↓
report result
```

Only qualified models may proceed to `APPROVED`/`ACTIVE` according to policy.

---

## 15. Voice pools and policies

Content may select a voice manually or through an automatic policy.

Recommended concepts:

```text
tts_voice_pool
tts_voice_pool_member
tts_voice_policy
```

Examples:

```text
GENERAL_ENGLISH
JAVA_INTERVIEW
IELTS_SPEAKING
VOCABULARY
```

A policy may filter/prefer by:

```text
accent
gender
style
audio_role
content category
```

Automatic resolution SHOULD be deterministic for the same content revision/policy.

At job creation time, policy resolution SHALL produce a concrete:

```text
voice_id
voice_model_id
```

The job no longer depends on future changes to the voice default model.

---

## 16. TTS job model

Recommended table:

```text
tts_job
────────────────────────────────
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
worker_id
lease_token
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
SUPERSEDED
```

---

## 17. Worker claim protocol

The local worker SHALL NOT connect directly to PostgreSQL.

It communicates with the backend over authenticated HTTPS.

Example endpoints:

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{id}/heartbeat
POST /internal/v1/tts/jobs/{id}/complete
POST /internal/v1/tts/jobs/{id}/fail
POST /internal/v1/tts/models/{id}/download
```

A successful claim returns enough immutable information to reproduce generation:

```json
{
  "jobId": 913,
  "leaseToken": "...",
  "contentRevisionId": 10021,
  "audioRole": "QUESTION",
  "text": "Tell me about yourself.",
  "ttsText": "Tell me about yourself.",
  "voiceCode": "EN_US_FEMALE_LESSAC",
  "voiceModelId": 17,
  "voiceModelCode": "PIPER_EN_US_LESSAC_HIGH_V1",
  "modelSha256": "...",
  "fingerprint": "..."
}
```

The worker SHALL NOT need database credentials or permanent RustFS credentials.

---

## 18. Lease and recovery

A claimed job SHALL have:

```text
worker_id
lease_token
lease_until
```

The unique `lease_token` prevents an expired/stale worker from completing a job after another worker has legitimately reclaimed it.

If `lease_until < now()`, the backend MAY return the job to `PENDING` according to retry policy.

The worker SHOULD send heartbeat requests for long operations.

Completion SHALL validate the active lease token.

---

## 19. Worker model cache

The worker SHALL maintain a local immutable model cache.

Example Windows layout:

```text
C:\CareerSpeak\tts-worker\models\
├── PIPER_EN_US_LESSAC_HIGH_V1\
│   ├── model.onnx
│   ├── model.onnx.json
│   └── manifest.json
└── PIPER_EN_US_RYAN_HIGH_V1\
    ├── model.onnx
    ├── model.onnx.json
    └── manifest.json
```

The manifest SHOULD include:

```text
voiceModelCode
modelSha256
configSha256
file sizes
installedAt
```

On first download the worker MUST calculate/verify SHA-256 before accepting the model into cache.

A worker MUST NOT silently substitute another installed model when the required model is absent or invalid.

---

## 20. Worker model download flow

```text
job requires voice_model_id
        ↓
check local cache
        ↓
model present and valid?
      ┌─┴─┐
     yes  no
      │    │
      │    ▼
      │ request presigned GET
      │    │
      │    ▼
      │  RustFS
      │    │
      │ download model/config
      │    │
      │ verify checksum
      │    │
      │ install immutable cache
      └────┬────────────
           ▼
         Piper
```

Explicit failures include:

```text
VOICE_MODEL_NOT_FOUND
VOICE_MODEL_DOWNLOAD_FAILED
VOICE_MODEL_CHECKSUM_MISMATCH
VOICE_MODEL_CONFIG_INVALID
VOICE_MODEL_LOAD_FAILED
```

---

## 21. Fingerprint and idempotency

Audio SHALL have a deterministic fingerprint.

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

Recommended algorithm:

```text
SHA-256
```

If the exact fingerprint already maps to an approved reusable audio asset, generation MAY be skipped.

Changing text, model revision, speaker, rate or post-processing profile creates a new fingerprint.

Retries MUST NOT create conflicting production associations.

---

## 22. Display text and TTS text

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

## 23. Pronunciation dictionary

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

Normalization pipeline:

```text
canonical display text
        ↓
content-specific tts_text override
        ↓
pronunciation dictionary
        ↓
normalized TTS input
        ↓
Piper
```

All substitutions MUST be moderator-reviewable.

---

## 24. Audio processing pipeline

Piper output is an intermediate master, not the learner-delivery format.

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
RustFS upload
```

Initial production profile to qualify:

```text
MP3
mono
64–80 kbps
speech-oriented sample rate
```

Exact profile SHALL be selected after listening qualification and recorded in an ADR.

Temporary WAV files SHOULD be deleted after successful encoding/upload unless retained for diagnostics.

---

## 25. Technical quality checks

Before a job becomes `READY`, the worker SHALL verify at least:

```text
file exists
file size > 0
duration > 0
expected codec
expected channel count
expected sample-rate/profile
checksum calculated
no synthesis exception
no FFmpeg failure
reasonable duration bounds
```

Suspicious duration SHALL fail or flag the asset for review.

---

## 26. Human review

MVP SHALL NOT automatically publish newly generated TTS audio.

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

The Content Studio SHALL support play/approve/reject/regenerate actions.

A future ADR MAY allow greater automation only after sufficient quality evidence exists for a specific voice/content class.

---

## 27. File asset model

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
codec
bitrate
status
created_at
updated_at
```

The database SHALL NOT store permanent environment-specific RustFS URLs.

Published object keys SHALL be immutable/versioned.

---

## 28. RustFS bucket strategy

Recommended baseline:

```text
careerspeak-models   private
careerspeak-draft    private
careerspeak-audio    published media origin
careerspeak-images   visual assets
```

Example published audio key:

```text
audio/interview/Q100/rev-3/<fingerprint>.mp3
```

Example immutable model key:

```text
piper/en/en_US-lessac-high/v1/model.onnx
```

A new model binary requires a new version/object key.

---

## 29. CDN strategy

Published learner media SHOULD be delivered through a CDN/edge layer in front of RustFS.

```text
Flutter → CDN/Edge → RustFS origin
```

Spring Boot SHALL NOT proxy ordinary learner audio bytes.

TTS models remain private and bypass learner CDN distribution.

The concrete CDN provider is deployment-specific and SHOULD NOT leak into content-domain persistence.

---

## 30. Security model

Moderator browser authentication:

```text
Spring Security
server-side session
HttpOnly cookie
CSRF protection
```

TTS worker authentication SHALL use separate machine credentials/token mechanisms.

The worker SHALL receive time-limited presigned GET/PUT authorization rather than permanent RustFS secrets whenever practical.

The worker SHALL NOT expose a public inbound service.

The model bucket SHALL remain private.

---

## 31. Local worker behavior

Expected flow:

```text
start worker
   ↓
authenticate
   ↓
claim job
   ↓
resolve/check model cache
   ↓
download+verify exact model if needed
   ↓
generate
   ↓
post-process
   ↓
validate
   ↓
upload to RustFS
   ↓
complete job
   ↓
claim next job
```

When no jobs exist, the worker SHOULD use bounded polling/backoff.

If the local machine is off, jobs remain pending. Learner runtime remains unaffected.

---

## 32. Scaling path

Initial release:

```text
Local Worker × 1
```

The same protocol supports:

```text
Local Worker × 1
Cloud Worker × N
```

Workers compete for leased jobs through the backend claim protocol.

RabbitMQ MAY be introduced only if measured throughput/reliability requirements exceed the PostgreSQL-backed design.

---

## 33. Bulk generation

The Content Studio SHALL support bulk workflows.

```text
Import 500 vocabulary items
        ↓
validate content
        ↓
mark rows READY_FOR_AUDIO
        ↓
resolve voice/model policies
        ↓
create missing TTS jobs
        ↓
worker processing
        ↓
review failures/samples
        ↓
publish
```

The UI SHOULD expose:

```text
Total
Pending
Running
Ready
Failed
Superseded
```

Bulk operations MUST remain idempotent.

---

## 34. Observability

Backend metrics SHOULD include:

```text
tts.jobs.pending
tts.jobs.running
tts.jobs.ready
tts.jobs.failed
tts.job.duration
tts.retry.count
tts.models.active
tts.model.download.failures
tts.model.validation.failures
```

Worker logs SHOULD contain:

```text
jobId
workerId
leaseToken correlation
voiceCode
voiceModelId
voiceModelCode
fingerprint
stage
duration
errorCode
```

Sensitive secrets/presigned URLs MUST NOT be logged.

---

## 35. Failure scenarios that must be tested

The implementation SHALL cover at least:

1. worker killed during Piper synthesis;
2. worker killed during FFmpeg conversion;
3. network loss before upload;
4. network loss after upload but before completion callback;
5. duplicate completion callback;
6. expired presigned upload/download URL;
7. invalid voice/model configuration;
8. missing model in local cache;
9. RustFS model download unavailable;
10. checksum mismatch after model download;
11. corrupt model config;
12. Piper cannot load model;
13. corrupt generated media;
14. backend restart with pending/running jobs;
15. two workers claim concurrently;
16. lease expires and job is reclaimed;
17. old worker completes with stale lease token;
18. text changes while old job is running;
19. stale result returned after newer revision/fingerprint;
20. logical voice default changes from model v1 to v2 while an old job explicitly references v1.

A stale worker result MUST NOT overwrite current audio association.

---

## 36. Acceptance criteria

The TTS architecture is accepted when this scenario is repeatable:

```text
Admin creates logical voice
        ↓
uploads immutable Piper model/config to RustFS
        ↓
backend validates metadata/checksums
        ↓
worker runtime-qualifies model
        ↓
moderator approves/activates model
        ↓
moderator edits English content
        ↓
voice policy resolves exact voice_model_id
        ↓
revision becomes READY_FOR_AUDIO
        ↓
backend creates exactly required jobs
        ↓
worker claims job with lease token
        ↓
worker downloads/verifies model if missing locally
        ↓
Piper generates temporary WAV
        ↓
FFmpeg produces qualified MP3
        ↓
worker uploads MP3 to RustFS
        ↓
backend records FileAsset
        ↓
moderator previews/approves audio
        ↓
revision publishes
        ↓
Flutter receives immutable CDN asset reference
        ↓
learner playback does not depend on Piper/worker availability
```

The system MUST recover from worker termination without manual database repair.

---

## 37. Explicit non-goals for MVP

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
Spring Boot proxying of learner audio bytes
storing ONNX binaries in PostgreSQL
silent voice/model substitution
```

---

## 38. Architecture principle

> CareerSpeak centrally governs logical voices and immutable Piper model revisions. Model binaries/configs live privately in RustFS. Each TTS job resolves to an exact voice model before execution. Workers download and checksum-verify missing models, cache them locally, generate reviewed immutable audio asynchronously, and upload media back to RustFS. Learner playback is independent of Piper and worker availability.