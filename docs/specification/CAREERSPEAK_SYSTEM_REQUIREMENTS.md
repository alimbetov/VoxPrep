# CareerSpeak / VoxPrep — System Requirements & Architecture Specification

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.5  
**Status:** Architecture Baseline / Draft for implementation  
**Target platforms:** Android, iOS  
**Business model:** one-time paid application; initial target price — USD 2.99  
**Primary learning model:** Read → Listen → Repeat → Test → Review

Related documents:

- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`../architecture/CAREERSPEAK_TTS_PIPELINE.md`](../architecture/CAREERSPEAK_TTS_PIPELINE.md)

---

## 1. Purpose

CareerSpeak is a mobile application for practical English learning with two primary goals:

1. IELTS preparation;
2. preparation for international job interviews by profession and seniority.

CareerSpeak is an **English-only learning product**. Other supported languages are presentation/localization languages used for UI, translations, hints and explanations.

The product is content-driven. English text, vocabulary, model answers, mock-test questions and audio are prepared, validated and reviewed before publication.

The learner runtime does not require AI, Speech-to-Text, pronunciation scoring or runtime TTS.

---

## 2. Product principles

1. **Pay once, no mandatory subscription.**
2. **No ads in the initial product model.**
3. **English is the single learning language.**
4. **Localized UI, hints and explanations enable global expansion.**
5. **No mandatory AI cost per learner.**
6. **Read → Listen → Repeat** is the core practice loop.
7. **Learn → Test → Review** is the retention loop.
8. **Data-driven mobile application:** professions, tracks, questions, topics and tests are not hardcoded in Flutter.
9. **Offline-first consumption:** downloaded content remains usable without network access.
10. **Published content is immutable by revision.**
11. **Audio is generated before publication and served as immutable media.**
12. **Learner progress remains local by default.**
13. **Privacy first:** no personal learner account is required for MVP.
14. **Simple infrastructure first:** infrastructure components are added only after measured need.
15. **Visual ambience must never reduce readability:** themed backgrounds are decorative and optional.

---

## 3. MVP product scope

### 3.1 IELTS

CareerSpeak shall provide:

- IELTS vocabulary;
- phonetic transcription;
- part of speech;
- CEFR level;
- localized translation;
- localized hints and explanations;
- contextual examples;
- IELTS Speaking examples;
- IELTS Writing examples;
- collocations;
- word families;
- pre-generated pronunciation audio;
- pre-generated example audio;
- IELTS Speaking cue cards;
- model answers;
- IELTS-style mock tests.

### 3.2 Job Interview Trainer

CareerSpeak shall provide:

- General Interview;
- HR Interview;
- Behavioral / STAR Interview;
- Salary & Compensation;
- Relocation;
- Management Interview;
- profession-specific interview packs;
- seniority-specific questions;
- model answers;
- useful vocabulary and phrases;
- pre-generated question/answer audio;
- profession-specific knowledge tests;
- interview-English tests.

### 3.3 General learning

CareerSpeak shall provide:

- English Topics;
- Phrase Bank;
- Shadowing;
- Favorites;
- Search;
- Recently opened;
- Local Progress;
- Offline downloads;
- Daily / Quick Test mode;
- optional Study Ambience / visual themes.

---

## 4. Explicit non-goals for MVP

Do not implement for MVP:

- runtime LLM chat;
- Speech-to-Text;
- pronunciation scoring;
- learner voice upload;
- runtime TTS for learners;
- live teachers;
- social network;
- messaging;
- leaderboards;
- complex gamification;
- Kafka;
- RabbitMQ;
- Redis;
- Elasticsearch/OpenSearch;
- Kubernetes;
- Eureka;
- API Gateway as a separate deployable service;
- R2DBC/WebFlux;
- JavaFX moderator application;
- PySide6 moderator application;
- server-side learner progress synchronization;
- DRM-style audio protection.

Caffeine is not required for MVP. It may be introduced later for small immutable/reference datasets only after profiling demonstrates benefit.

---

## 5. Actors

### 5.1 Learner

Uses Flutter to:

- browse English content;
- choose UI/translation locale;
- listen to audio;
- repeat/shadow content;
- complete mock tests;
- save favorites;
- keep progress locally;
- download content for offline usage;
- choose a visual ambience theme or Focus Mode.

### 5.2 Moderator / Content Editor

Uses the web-based CareerSpeak Content Studio to:

- create professions and career tracks;
- create interview questions and model answers;
- create vocabulary, examples and collocations;
- create topics and phrases;
- create Question Bank items;
- assemble Mock Tests;
- edit translations/hints;
- select/override TTS voice policies;
- trigger audio generation;
- preview generated audio;
- approve/reject/regenerate audio;
- publish revisions;
- archive outdated content.

### 5.3 Administrator

Manages:

- moderator accounts and roles;
- TTS voice registry;
- Piper model registry;
- model versions and lifecycle;
- TTS voice pools/policies;
- RustFS object-storage configuration;
- operational configuration;
- publication policy.

### 5.4 TTS Worker

A headless machine client that:

- claims pending TTS jobs;
- resolves the exact immutable voice model required by the job;
- downloads missing Piper models from RustFS through temporary authorization;
- verifies model checksums;
- caches approved models locally;
- generates speech with Piper;
- post-processes audio with FFmpeg;
- validates output;
- uploads generated media to RustFS;
- reports job completion/failure.

---

## 6. Product information architecture

```text
CareerSpeak
│
├── IELTS
│   ├── Vocabulary
│   ├── Collocations
│   ├── Speaking
│   ├── Topics
│   └── Mock Tests
│
├── Job Interview
│   ├── General
│   ├── Behavioral / STAR
│   ├── Salary / Relocation
│   ├── Profession Specific
│   └── Interview Tests
│
├── Learn
│   ├── Topics
│   ├── Phrase Bank
│   └── Shadowing
│
└── My
    ├── Favorites
    ├── Test Results
    ├── Review
    ├── Progress
    ├── Downloads
    └── Appearance / Ambience
```

---

## 7. Initial profession catalog

### Software & IT

- Software Engineer
- Java Backend Developer
- Python Developer
- Frontend Developer
- Mobile Developer
- QA / Test Engineer
- DevOps Engineer
- Cloud Engineer
- Cybersecurity Engineer

### Data & AI

- Data Analyst
- Data Engineer
- Data Scientist
- AI / ML Engineer

### Business & Product

- Business Analyst
- Project Manager
- Product Manager

### Commercial / Customer

- Sales / Account Manager
- Customer Success
- Customer Support

New professions must be publishable without a mobile release.

---

## 8. Seniority model

Supported initial values:

```text
JUNIOR
MIDDLE
SENIOR
LEAD
MANAGER
```

A question may map to multiple seniority levels.

---

## 9. Architecture decision — modular monolith

CareerSpeak MVP SHALL use one Spring Boot deployable backend.

```text
careerspeak-backend
│
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
├── vocabulary
└── installation
```

Logical boundaries are preserved as modules. No distributed-service boundary is introduced until justified by measured scale or operational requirements.

Reasons:

- one developer/team can evolve the system faster;
- transactions remain local;
- no service-discovery dependency;
- fewer network failure modes;
- simpler CI/CD;
- lower infrastructure cost;
- easier publication consistency;
- easier end-to-end testing.

Module boundaries SHOULD be enforceable with ArchUnit or Spring Modulith-style architecture tests.

---

## 10. Target runtime architecture

```text
                         GLOBAL LEARNERS

                            Flutter App
                                │
                   ┌────────────┴────────────┐
                   ▼                         ▼
          CareerSpeak REST API              CDN
                   │                         │
                   ▼                         ▼
           Spring Boot Backend        Published RustFS Assets
                   │
                   ▼
               PostgreSQL


                         CONTENT TEAM

                            Browser
                               │
                               ▼
                   Spring MVC Content Studio
                               │
                   ┌───────────┴───────────┐
                   ▼                       ▼
               PostgreSQL                RustFS
                 TTS jobs           models/draft/assets
                   │
                   │ outbound HTTPS polling
                   ▼
                Local TTS Worker
             Python + Piper + FFmpeg
                   │
                   ├── model cache
                   └── generated audio
                               │
                               ▼
                             RustFS
```

The learner path does not depend on Piper or worker availability.

---

## 11. Technology baseline

### Backend

- Java 21 LTS;
- Spring Boot 4.x baseline; exact minor version pinned during implementation qualification;
- Spring MVC;
- Spring Security;
- Spring Data JPA;
- Hibernate;
- HikariCP;
- PostgreSQL;
- Liquibase;
- OpenAPI;
- Micrometer / Actuator;
- Thymeleaf;
- HTMX;
- Docker;
- Testcontainers.

### Explicit persistence decision

```text
Spring MVC + JPA/JDBC + HikariCP + PostgreSQL
```

R2DBC/WebFlux is not required for MVP. TTS job claiming and publication workflows rely on ordinary transactional SQL and may use `FOR UPDATE SKIP LOCKED` where appropriate.

### Mobile

- Flutter;
- local SQLite/Drift storage;
- audio playback;
- offline pack management;
- local appearance/ambience preferences.

### Content production

- Python 3.x headless worker;
- Piper TTS;
- FFmpeg;
- local immutable model cache.

### Production infrastructure

- DigitalOcean application runtime;
- DigitalOcean Managed PostgreSQL;
- RustFS S3-compatible object storage;
- CDN/reverse-proxy layer in front of published learner assets.

RustFS is the baseline object store. Backend domain code SHALL access it through an `ObjectStorage` abstraction rather than hardcoded RustFS URLs.

---

## 12. Persistence strategy

MVP uses one PostgreSQL database owned by the modular monolith.

Core logical domains:

```text
content
assessment
localization
media
admin
tts
publication
```

Liquibase owns all schema migrations.

JPA entities SHALL NOT be exposed as public API DTOs.

---

## 13. Core aggregates

```text
Profession
CareerTrack
InterviewCategory
InterviewQuestion
InterviewQuestionRevision
Skill
VocabularyWord
VocabularyExample
VocabularyCollocation
VocabularyCategory
Topic
TopicRevision
TopicSection
Phrase
PhraseCategory
QuestionBankItem
QuestionRevision
PracticeTest
PracticeTestRevision
FileAsset
TtsJob
TtsVoice
TtsVoiceModel
TtsVoicePool
TtsVoicePolicy
TtsWorker
TtsWorkerCapability
PronunciationRule
ContentManifest
ContentPack
```

Learner progress/test history is not part of the server-side MVP aggregate model.

---

## 14. Revision and publication model

Published English content is immutable by revision.

```text
InterviewQuestion Q100
├── revision 1 PUBLISHED
├── revision 2 ARCHIVED
└── revision 3 DRAFT
```

Rules:

1. Published revisions are not edited in place.
2. A revision references exact media assets required for that revision.
3. A revision that changes TTS-relevant text produces a new audio fingerprint.
4. Stale worker results MUST NOT replace media for a newer revision.
5. Test publication uses revision snapshots.

Assessment example:

```text
PracticeTestRevision #7
├── QuestionRevision #14
├── QuestionRevision #31
└── QuestionRevision #88
```

An already-published test therefore remains reproducible after later question edits.

---

## 15. Core content model

### Profession / career track

```text
profession
id
code
status
sort_order
created_at
updated_at
```

```text
career_track
id
profession_id
code
status
sort_order
created_at
updated_at
```

Localized names/descriptions belong in typed localization tables.

### Interview

```text
interview_question
id
code
status
created_at
updated_at
```

```text
interview_question_revision
id
question_id
revision
question_text
question_tts_text nullable
model_answer
model_answer_tts_text nullable
difficulty
cefr_level
status
created_at
published_at
```

### Vocabulary

```text
vocabulary_word
id
code
word
phonetic
part_of_speech
cefr_level
status
```

```text
vocabulary_localization
word_id
locale
translation
hint
explanation
```

### Topics

Topic content SHALL be revisioned. Topic sections may contain optional `tts_text` overrides separate from learner-visible English text.

---

## 16. Assessment domain

Assessment is a first-class module inside the monolith.

Initial test types:

```text
IELTS
VOCABULARY
JOB_INTERVIEW
PROFESSIONAL
GENERAL_ENGLISH
```

MVP question types:

```text
SINGLE_CHOICE
TRUE_FALSE
```

Future types:

```text
MULTIPLE_CHOICE
MATCHING
FILL_GAP
ORDERING
```

Questions are reusable through a shared Question Bank.

Skills enable deterministic result analysis without AI.

Examples:

```text
JAVA_CORE
JAVA_COLLECTIONS
JAVA_CONCURRENCY
SPRING_CORE
SPRING_SECURITY
SQL
DOCKER
KUBERNETES
IELTS_VOCABULARY
IELTS_SPEAKING
```

Flutter may calculate skill breakdown and recommendations locally from completed test snapshots.

---

## 17. Globalization model

Canonical learning content is English.

Supported presentation/localization concepts:

```text
UI locale
translation locale
hint locale
explanation locale
```

Initial locales:

```text
en
ru
kk
```

Locale identifiers SHOULD follow BCP-47 compatible values so regional forms can be introduced later, for example `pt-BR` and `pt-PT`.

Do not create a multi-learning-language engine in MVP.

Do not store duplicated language columns such as `title_ru`, `title_kk`, `title_es`.

Use typed localization tables.

Locale-specific content MAY have independent readiness state so missing translation for one locale does not block canonical English publication where policy allows it.

RTL readiness must be considered for planned Arabic/Urdu support.

---

## 18. Locale selection and privacy

CareerSpeak SHALL NOT request GPS/precise location solely to select language.

Selection precedence:

```text
1. explicit user selection
2. OS per-app locale
3. OS preferred language
4. OS region
5. English fallback
```

Learner-facing server storage SHALL NOT require:

```text
name
email
phone
precise location
learning history
favorites
test history
```

---

## 19. Installation identity and local learner state

CareerSpeak MAY generate a cryptographically random `installationId` for technical purposes such as abuse protection or entitlement support.

It SHALL NOT be derived from:

```text
IMEI
IMSI
MAC
Advertising ID
hardware serial
```

The installation identity SHALL NOT become a learner profile and SHALL NOT be joined to learning history in MVP.

Flutter stores locally:

```text
settings
favorites
vocabulary progress
test attempts
test answers
review schedule
completed topics
downloads
content manifest
selected locale
selected ambience theme
focus mode
```

Recommended persistence:

```text
SQLite + Drift
```

---

## 20. Content Studio

The moderator UI is a server-rendered internal application:

```text
Spring MVC
Thymeleaf
HTMX
Spring Security
```

Initial routes:

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

The Content Studio SHOULD support:

- bulk CSV/XLSX/JSON import;
- content validation;
- duplicate detection;
- missing-localization detection;
- missing/stale-audio detection;
- audio preview;
- bulk generation status;
- TTS voice/model administration;
- model upload/validation/activation;
- publication qualification.

---

## 21. TTS architecture

CareerSpeak SHALL use asynchronous content-production TTS.

The authoritative design is defined in:

[`../architecture/CAREERSPEAK_TTS_PIPELINE.md`](../architecture/CAREERSPEAK_TTS_PIPELINE.md)

Key rules:

1. Piper does not execute in learner request paths.
2. Piper does not execute synchronously inside Spring MVC requests.
3. A headless worker claims jobs over authenticated HTTPS.
4. The worker does not receive PostgreSQL credentials.
5. The worker does not require permanent RustFS credentials; presigned URLs are preferred.
6. Piper produces temporary WAV; FFmpeg creates delivery audio.
7. Audio is fingerprinted for idempotency/staleness detection.
8. Newly generated audio is technically validated and reviewed before publication.
9. Every job resolves to an exact immutable `voice_model_id` before generation.
10. A worker MUST NOT silently substitute another voice/model.

---

## 22. Voice and model governance

Logical voice and physical model are separate concepts.

### `tts_voice`

Represents moderator-facing characteristics:

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

Examples:

```text
EN_US_FEMALE_LESSAC
EN_US_MALE_RYAN
EN_GB_FEMALE_ALBA
```

### `tts_voice_model`

Represents an exact immutable Piper model revision:

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
model_size_bytes
status
license_name
license_reference
commercial_use_reviewed
created_at
approved_at
```

Model lifecycle:

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

A model version SHALL never be overwritten in place.

---

## 23. Voice pools and policies

The moderator MAY choose a voice manually or use an automatic policy.

Recommended concepts:

```text
tts_voice_pool
tts_voice_pool_member
tts_voice_policy
```

Possible metadata:

```text
accent = US / UK
gender = FEMALE / MALE
style = NEUTRAL / PROFESSIONAL / WARM / ACADEMIC / CALM
```

Gender/accent/style are selection metadata; they do not replace the need to resolve an exact model.

Automatic resolution SHOULD be deterministic for the same content revision and policy.

The final `tts_job` SHALL store the resolved `voice_id` and immutable `voice_model_id`.

---

## 24. RustFS object-storage architecture

RustFS is the baseline S3-compatible object store.

Recommended buckets:

```text
careerspeak-models   private
careerspeak-draft    private
careerspeak-audio    published media origin
careerspeak-images   covers/backgrounds/assets
```

TTS models SHALL be private.

Example object layout:

```text
careerspeak-models/
└── piper/
    └── en/
        └── en_US-lessac-high/
            └── v1/
                ├── model.onnx
                └── model.onnx.json
```

Model object keys are immutable. New binary content requires a new model version or content-addressed object key.

PostgreSQL stores only metadata/object keys/checksums, not ONNX binary data.

The backend SHALL expose storage through an abstraction similar to:

```text
ObjectStorage
├── createUploadUrl
├── createDownloadUrl
├── getMetadata
└── delete
```

The implementation baseline is `RustFsObjectStorage`.

---

## 25. TTS model upload and worker distribution

### Admin upload flow

```text
Moderator/Admin
    ↓
Create model metadata
    ↓
Backend creates presigned PUT
    ↓
Browser uploads ONNX/config directly to RustFS
    ↓
Backend completes upload
    ↓
checksum/metadata validation
    ↓
worker runtime qualification
    ↓
moderator approval
    ↓
ACTIVE
```

Large ONNX binaries SHOULD NOT be proxied through the Spring JVM when direct presigned upload is available.

### Worker model flow

```text
TTS job requires voice_model_id
        ↓
worker checks local cache
        ↓
missing?
        ├── no  → load exact cached model
        └── yes → request presigned GET
                  ↓
                RustFS
                  ↓
             download model
                  ↓
             verify SHA-256
                  ↓
             install local cache
                  ↓
                 Piper
```

The worker MUST fail with an explicit model error if the exact required model cannot be obtained or validated. Silent fallback is forbidden.

---

## 26. TTS job reliability

Recommended model:

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
worker_id
lease_token
lease_until
created_at
started_at
completed_at
error_code
error_message
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

A successful claim SHALL issue a unique `lease_token`.

Heartbeat may extend `lease_until` for long operations.

Completion MUST validate:

```text
job id
lease token
current revision/fingerprint
expected voice_model_id
```

A stale completion MUST NOT overwrite a newer revision or association.

---

## 27. TTS text, pronunciation and fingerprint

The system SHALL support:

```text
display_text
optional tts_text
```

for professional acronyms and terminology.

A controlled pronunciation dictionary SHOULD support terms such as:

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

Changing voice/model/settings produces a new fingerprint and therefore a new immutable audio asset.

---

## 28. Audio production profile

```text
Piper
 ↓
Temporary WAV
 ↓
Technical validation
 ↓
FFmpeg
 ↓
Production MP3
 ↓
Technical QC
 ↓
Upload to RustFS
 ↓
Human review
 ↓
Publish
```

Initial candidate delivery profile:

```text
MP3
mono
64–80 kbps
speech-oriented sample rate
```

Final values must be selected through listening qualification and recorded in an ADR.

Temporary WAV SHOULD be deleted after successful production encoding/upload unless retained for diagnostics.

---

## 29. Media and CDN delivery

Recommended `file_asset` metadata:

```text
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

Do not store environment-specific permanent origin URLs in domain tables.

Published object keys are immutable/versioned, for example:

```text
audio/interview/Q100/rev-3/<fingerprint>.mp3
```

Normal learner playback path:

```text
Flutter → CDN → RustFS origin
```

Media bytes SHALL NOT be proxied through Spring Boot in the normal learner playback path.

The concrete CDN provider remains a deployment decision and is not part of the content domain.

---

## 30. Content manifest and offline packs

Flutter SHALL use a content manifest rather than repeatedly rebuilding all catalogs from many API calls.

Example endpoint:

```text
GET /api/v1/content/manifest
```

Manifest concepts:

```text
schemaVersion
contentVersion
publishedAt
packs
assets
checksums
```

Example packs:

```text
IELTS_VOCABULARY_B2
IELTS_SPEAKING
GENERAL_INTERVIEW
JAVA_JUNIOR
JAVA_SENIOR
DEVOPS
BUSINESS_ANALYST
```

MVP delta behavior may be asset-level: unchanged assets are not downloaded again.

---

## 31. Study Ambience / visual themes

Visual themes are a Flutter UX concern in MVP and SHALL NOT complicate backend publication.

Initial theme candidates:

```text
MINIMAL
NATURE
COSMOS
LIBRARY
COFFEE_STUDY
PROFESSIONAL
```

Rules:

1. text readability has priority over decoration;
2. text is rendered on a controlled readable surface/card;
3. Study Mode may use ambience backgrounds;
4. Focus Mode uses minimal/solid presentation;
5. Exam/Mock Test mode SHOULD default to minimal visuals;
6. background selection within a theme SHOULD be deterministic, e.g. hash of `contentCode + themeCode`;
7. initial backgrounds MAY ship as Flutter assets for full offline availability;
8. selected theme/focus mode remains local learner preference.

Remote downloadable theme packs MAY be introduced later through a separate ADR.

---

## 32. Search and caching

PostgreSQL is sufficient for MVP search.

Use as needed:

```text
B-tree indexes
PostgreSQL full-text search
pg_trgm
```

Do not add Elasticsearch until Postgres fails measured requirements.

Caching baseline:

```text
Flutter local storage
HTTP caching / ETag where appropriate
CDN for immutable media
PostgreSQL buffer/cache
```

Redis and Caffeine are not required initially.

---

## 33. API design

Learner REST API examples:

```text
/api/v1/content/manifest
/api/v1/professions
/api/v1/interviews
/api/v1/vocabulary
/api/v1/topics
/api/v1/tests
/api/v1/search
```

Worker endpoints include:

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{id}/heartbeat
POST /internal/v1/tts/jobs/{id}/complete
POST /internal/v1/tts/jobs/{id}/fail
POST /internal/v1/tts/models/{id}/download
```

Admin model endpoints include concepts such as:

```text
POST /admin/api/tts/voices
POST /admin/api/tts/models
POST /admin/api/tts/models/{id}/upload-url
POST /admin/api/tts/models/{id}/complete
POST /admin/api/tts/models/{id}/validate
POST /admin/api/tts/models/{id}/approve
POST /admin/api/tts/models/{id}/activate
POST /admin/api/tts/models/{id}/deprecate
```

The mobile API SHOULD be coarse-grained to reduce round trips.

---

## 34. Security

Moderator authentication:

```text
Spring Security
server-side session
HttpOnly cookie
CSRF
roles: ADMIN / EDITOR / REVIEWER
```

TTS worker uses separate machine authentication.

The worker SHALL NOT expose public inbound endpoints and SHALL use outbound HTTPS.

Permanent RustFS credentials SHOULD NOT be embedded in the worker when presigned GET/PUT authorization can be used.

TTS model buckets SHALL remain private.

---

## 35. Observability

Backend minimum:

```text
Spring Boot Actuator
Micrometer
structured logs
trace/correlation identifiers
health/readiness
```

TTS metrics:

```text
tts.jobs.pending
tts.jobs.running
tts.jobs.ready
tts.jobs.failed
tts.job.duration
tts.retry.count
tts.models.active
tts.model.download.failures
```

Worker logs SHOULD include:

```text
jobId
workerId
voiceCode
voiceModelId
fingerprint
stage
duration
errorCode
```

---

## 36. CI/CD

### Backend

```text
compile
format/static analysis
unit tests
architecture/module tests
integration tests
Testcontainers PostgreSQL
Liquibase validation
security/dependency scan
build container
```

### TTS worker

```text
lint
unit tests
model registry tests
Piper smoke synthesis test
FFmpeg conversion test
checksum verification test
job-protocol integration test
```

### Flutter

```text
flutter pub get
format
analyze
test
build
```

---

## 37. Mandatory TTS failure tests

Before production acceptance, verify at least:

1. worker killed during synthesis;
2. worker killed during FFmpeg conversion;
3. network loss before/after upload;
4. duplicate completion callback;
5. expired presigned URL;
6. invalid voice/model configuration;
7. missing model in local cache;
8. model download failure;
9. model checksum mismatch;
10. corrupt generated media;
11. backend restart with pending/running jobs;
12. two workers attempting concurrent claims;
13. expired lease followed by old worker completion;
14. text changed while old generation is running;
15. stale result after a newer revision/fingerprint exists;
16. active logical voice changed to model v2 while an old job still references model v1.

A stale or incorrectly leased result MUST NOT overwrite current publication data.

---

## 38. Production deployment — initial target

```text
DigitalOcean
│
├── CareerSpeak Backend
├── Managed PostgreSQL
├── RustFS
│   ├── private TTS models
│   ├── private draft assets
│   └── published audio/images origin
└── CDN / edge layer for published assets
```

The first release does not require Kubernetes or a service mesh.

The local TTS worker may run on a controlled Windows content-production machine. If throughput increases, the same authenticated worker protocol may be deployed to additional local/cloud workers without changing learner runtime.

---

## 39. MVP acceptance criteria

MVP architecture is considered functional when this full path works repeatedly:

```text
Admin uploads/activates an approved Piper model in RustFS
        ↓
Moderator creates/edits English content
        ↓
adds localization/hints
        ↓
selects voice or automatic voice policy
        ↓
marks revision READY_FOR_AUDIO
        ↓
backend resolves exact voice_model_id
        ↓
backend creates only required TTS jobs
        ↓
worker claims job with lease token
        ↓
worker downloads/verifies model if not cached
        ↓
Piper generates + FFmpeg converts + QC validates audio
        ↓
asset uploads to RustFS
        ↓
moderator previews and approves audio
        ↓
revision publishes atomically
        ↓
manifest version changes
        ↓
Flutter discovers content
        ↓
learner reads/listens/tests
        ↓
progress remains local
        ↓
published audio plays through CDN from RustFS origin
```

The learner experience MUST remain available when the local TTS worker is offline.

---

## 40. Roadmap

### P0 — Architecture Freeze

```text
Domain map
Full PostgreSQL ERD
Revision/publication model
Localization model
Assessment snapshot model
TTS voice/model/job ERD
RustFS media/model model
Content manifest/offline-pack model
OpenAPI contracts
ADR baseline
```

### P1 — Executable Foundation

```text
monorepo skeleton
Spring Boot modular monolith
PostgreSQL
Liquibase
Spring Security
Spring MVC Content Studio shell
RustFS adapter
CI
Testcontainers
```

### P2 — Content Core

```text
Professions
Career tracks
Interview content
Vocabulary
Topics
Localization
Revision/publication lifecycle
```

### P3 — Assessment

```text
Question Bank
Question/Test revisions
Mock Tests
Skills
Scoring rules
```

### P4 — TTS Model Registry + Media

```text
FileAsset
RustFS presigned upload/download
TtsVoice
TtsVoiceModel
model lifecycle
voice pools/policies
model upload/qualification
worker model cache protocol
```

### P5 — TTS Jobs + Content Production

```text
TtsJob
lease token/heartbeat
Piper worker
FFmpeg pipeline
pronunciation rules
QC/review
bulk TTS
failure/recovery qualification
```

### P6 — Flutter Foundation

```text
catalog
local DB
manifest
settings/locales
ambience/focus mode
```

### P7 — Learning UX

```text
audio
shadowing
vocabulary
interviews
mock tests
favorites
local progress
```

### P8 — Offline Packs

```text
pack manifests
downloads
asset-level delta updates
checksum verification
```

### P9 — Globalization

```text
RU
KK
additional planned locales
RTL readiness
translation QA
```

### P10 — Production

```text
DigitalOcean deployment
Managed PostgreSQL
RustFS
CDN/edge
monitoring
backup/restore
CI/CD
```

### P11 — Store Release

```text
Android
iOS
store metadata
one-time purchase
privacy declarations
release qualification
```

---

## 41. Architecture summary

The CareerSpeak v0.5 baseline is deliberately conservative and reproducible:

> One Spring Boot modular monolith manages content, assessment, publication and the web-based Content Studio. PostgreSQL is the durable source of truth and TTS job store. RustFS is the S3-compatible object store for immutable Piper models, draft assets and published media origin. A separate headless Python/Piper/FFmpeg worker claims leased jobs over HTTPS, downloads the exact immutable model revision required by each job, verifies checksums, caches models locally, generates reviewed audio and uploads it to RustFS. Flutter stores learner state locally, consumes versioned content/offline packs and plays published media through a CDN in front of RustFS.

This architecture is the current implementation baseline for VoxPrep v0.5.