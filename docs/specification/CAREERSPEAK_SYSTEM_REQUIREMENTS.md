# CareerSpeak / VoxPrep — System Requirements & Architecture Specification

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.4  
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

The product is content-driven. English text, vocabulary, model answers, mock-test questions and audio are prepared and reviewed before publication.

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
13. **Simple infrastructure first.** New infrastructure components are added only after measured need.

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
- Daily / Quick Test mode.

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
- JavaFX moderator application;
- PySide6 moderator application.

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
- download content for offline usage.

### 5.2 Moderator / Content Editor

Uses the web-based CareerSpeak Content Studio to:

- create professions and career tracks;
- create interview questions and model answers;
- create vocabulary, examples and collocations;
- create topics and phrases;
- create Question Bank items;
- assemble Mock Tests;
- edit translations/hints;
- trigger audio generation;
- preview generated audio;
- approve/reject/regenerate audio;
- publish revisions;
- archive outdated content.

### 5.3 Administrator

Manages moderator accounts, roles, voice registry, operational configuration and publication policy.

### 5.4 TTS Worker

A headless machine client that:

- claims pending TTS jobs;
- generates speech with Piper;
- post-processes audio with FFmpeg;
- validates output;
- uploads assets using temporary authorization;
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
    └── Downloads
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

## 9. Core learning scenarios

### Topic

```text
Read
 ↓
Listen
 ↓
Repeat / Shadow
 ↓
Continue
```

### Vocabulary

```text
Word
 ↓
Meaning / localized hint
 ↓
Collocations
 ↓
Context sentence
 ↓
Listen
 ↓
Repeat
 ↓
Review locally
```

### Job Interview

```text
Question
 ↓
Listen
 ↓
Answer aloud independently
 ↓
Reveal model answer
 ↓
Listen
 ↓
Repeat / Shadow
```

### Mock Test — Learn Mode

```text
Question
 ↓
Answer
 ↓
Immediate result
 ↓
Explanation / hint
 ↓
Related content
```

### Mock Test — Exam Mode

```text
Question 1..N
 ↓
Finish
 ↓
Score
 ↓
Skill breakdown
 ↓
Review incorrect answers
```

---

## 10. Architecture decision — modular monolith

CareerSpeak MVP SHALL use a single Spring Boot deployable backend.

```text
careerspeak-backend
│
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

Logical boundaries are preserved as modules, but no distributed-service boundary is introduced until justified by measured scale or operational requirements.

Reasons:

- one developer/team can evolve the system faster;
- transactions remain local;
- no service-discovery dependency;
- fewer network failure modes;
- simpler CI/CD;
- lower DigitalOcean cost;
- easier content publication consistency.

---

## 11. Target runtime architecture

```text
                    GLOBAL LEARNERS

                       Flutter App
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
      CareerSpeak REST API             CDN
              │                         │
              ▼                         ▼
       Spring Boot Backend      DigitalOcean Spaces
              │
              ▼
          PostgreSQL


                    CONTENT TEAM

                       Browser
                          │
                          ▼
              Spring MVC Content Studio
                          │
                          ▼
                      PostgreSQL
                          │
                          ▼
                       TTS Jobs
                          │
                  outbound HTTPS polling
                          ▼
                  Local Piper Worker
                    Python + FFmpeg
                          │
                          ▼
                DigitalOcean Spaces
```

The learner path does not depend on Piper availability.

---

## 12. Technology baseline

### Backend

- Java 21 LTS;
- Spring Boot 4.x;
- Spring MVC;
- Spring Security;
- Spring Data JPA;
- PostgreSQL;
- Liquibase;
- OpenAPI;
- Micrometer / Actuator;
- Thymeleaf;
- HTMX;
- Docker.

### Mobile

- Flutter;
- local SQLite/Drift storage;
- audio playback;
- offline pack management.

### Content production

- Python 3.x headless worker;
- Piper TTS;
- FFmpeg.

### Production infrastructure

- DigitalOcean application runtime;
- DigitalOcean Managed PostgreSQL;
- DigitalOcean Spaces;
- CDN.

---

## 13. Persistence strategy

MVP uses one PostgreSQL database owned by the modular monolith.

Suggested logical schemas or clear package ownership MAY be used, but distributed database ownership is not required.

Core domains:

```text
content
assessment
localization
media
admin
tts
```

Liquibase owns all schema migrations.

---

## 14. Core aggregates

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
FileAsset
TtsJob
TtsVoice
PronunciationRule
```

Learner progress/test history is not part of the server-side MVP aggregate model.

---

## 15. Revision model

Published English content is immutable by revision.

Example:

```text
InterviewQuestion Q100
├── revision 1 PUBLISHED
├── revision 2 ARCHIVED
└── revision 3 DRAFT
```

A revision owns or references its exact required audio version.

Changing text does not modify an already published revision.

---

## 16. Profession and career track

Recommended entities:

```text
profession
────────────────────────
id
code
status
sort_order
created_at
updated_at
```

```text
career_track
────────────────────────
id
profession_id
code
status
sort_order
created_at
updated_at
```

Human-readable localized names/descriptions belong in localization tables, not duplicated columns such as `name_ru`, `name_kk`, etc.

Stable `code` values are immutable after external use.

---

## 17. Interview model

```text
interview_question
────────────────────────
id
code
status
created_at
updated_at
```

```text
interview_question_revision
────────────────────────
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

Mappings MAY include:

```text
question_profession
question_career_track
question_category
question_seniority
question_skill
question_tag
```

Common questions must be reusable and not copied for each profession.

---

## 18. Vocabulary model

```text
vocabulary_word
────────────────────────
id
code
word
phonetic
part_of_speech
cefr_level
status
created_at
updated_at
```

```text
vocabulary_localization
────────────────────────
word_id
locale
translation
hint
explanation
```

```text
vocabulary_example
────────────────────────
id
word_id
sentence
tts_text nullable
example_type
sort_order
status
```

```text
vocabulary_collocation
────────────────────────
id
word_id
text
tts_text nullable
sort_order
status
```

---

## 19. Topics and Phrase Bank

Topic content is revisioned.

```text
topic
────────────────────────
id
code
category_id
status
sort_order
```

```text
topic_revision
────────────────────────
id
topic_id
revision
status
created_at
published_at
```

```text
topic_section
────────────────────────
id
topic_revision_id
title
text
tts_text nullable
sort_order
```

Phrase Bank SHALL support categories such as:

```text
STARTING_ANSWER
THINKING
CLARIFICATION
AGREEMENT
DISAGREEMENT
SALARY
RELOCATION
PRESENTATION
MEETING
TECHNICAL_EXPLANATION
CUSTOMER_COMMUNICATION
```

---

## 20. Assessment domain

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

---

## 21. Question Bank

```text
question_bank_item
────────────────────────
id
code
question_type
status
created_at
updated_at
```

```text
question_revision
────────────────────────
id
question_id
revision
question_text
question_tts_text nullable
explanation
difficulty
cefr_level
status
created_at
published_at
```

```text
test_answer_option
────────────────────────
id
question_revision_id
text
is_correct
feedback
sort_order
```

Validation rules are enforced before publication.

---

## 22. Skill taxonomy

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

Questions may map to one or more skills.

Flutter may calculate local skill breakdown and local recommendations from test results.

---

## 23. Globalization model

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

Planned expansion is defined in `CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`.

Do not create a multi-learning-language engine in MVP.

Do not store columns such as:

```text
title_ru
title_kk
title_es
```

Use typed localization tables.

RTL readiness must be considered for planned Arabic/Urdu support.

---

## 24. Locale selection and privacy

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

## 25. Installation identity

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

---

## 26. Local learner state

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
```

Recommended persistence:

```text
SQLite + Drift
```

Deletion of the application may remove local progress unless a future explicit backup/sync feature is introduced by a separate ADR.

---

## 27. Content Studio

The moderator UI is a server-rendered web application:

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
- publication qualification.

---

## 28. TTS architecture

CareerSpeak SHALL use asynchronous content-production TTS.

The authoritative design is defined in:

[`../architecture/CAREERSPEAK_TTS_PIPELINE.md`](../architecture/CAREERSPEAK_TTS_PIPELINE.md)

Key rules:

1. Piper does not execute in learner request paths.
2. Piper does not execute synchronously inside Spring MVC requests.
3. A headless worker claims jobs over HTTPS.
4. The worker does not receive PostgreSQL credentials.
5. The worker uses Piper for synthesis and FFmpeg for production encoding.
6. Audio is fingerprinted for idempotency/staleness detection.
7. Newly generated audio is technically validated and reviewed before publication.
8. Learners consume published immutable audio from CDN/object storage.

---

## 29. TTS lifecycle

```text
DRAFT
  ↓
READY_FOR_AUDIO
  ↓
AUDIO_PENDING
  ↓
AUDIO_GENERATING
  ├────────► AUDIO_FAILED
  ↓
AUDIO_READY
  ↓
REVIEW
  ↓
PUBLISHED
  ↓
ARCHIVED
```

Generation should occur on explicit workflow transition/bulk action, not on every draft keystroke/save.

---

## 30. TTS job reliability

Jobs are durable in PostgreSQL.

Required concepts:

```text
status
attempt_count
worker_id
lease_until
fingerprint
error_code
error_message
```

A crashed worker SHALL NOT require manual database repair.

Expired leases allow retry.

Duplicate completion and stale-result scenarios must be idempotently handled.

---

## 31. TTS text and pronunciation

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

The learner-visible canonical English must not be distorted to accommodate TTS pronunciation.

---

## 32. TTS voice governance

The voice registry SHALL record at least:

```text
code
engine
accent
model_name
model_version
model_checksum
license_name
license_reference
commercial_use_reviewed
enabled
```

Production use requires both technical-quality approval and license review.

---

## 33. Audio production profile

Piper WAV is an intermediate artifact.

Production pipeline:

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
Upload
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

WAV delivery to learners is not required.

---

## 34. Media and storage

Recommended production storage:

```text
DigitalOcean Spaces + CDN
```

Recommended metadata:

```text
file_asset
────────────────────────
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

Do not store environment-specific permanent origin URLs in content tables.

Published object keys are immutable/versioned, for example:

```text
audio/interview/Q100/rev-3/<fingerprint>.mp3
```

Media bytes SHALL NOT be proxied through Spring Boot in the normal learner playback path.

---

## 35. Content manifest and offline packs

Flutter SHALL use a content manifest rather than repeatedly rebuilding all catalogs from many API calls.

Example endpoint:

```text
GET /api/v1/content/manifest
```

Manifest concepts:

```text
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

Delta updates should download only changed content/assets.

---

## 36. Search

PostgreSQL is sufficient for MVP search.

Use as needed:

```text
B-tree indexes
PostgreSQL full-text search
pg_trgm
```

Do not add Elasticsearch until Postgres search fails measured requirements.

---

## 37. API design

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

The API SHOULD be coarse-grained for mobile screens to reduce round trips.

JPA entities SHALL NOT be exposed directly.

Stable DTO/contracts isolate Flutter from persistence changes.

---

## 38. Admin and worker security

Moderator authentication:

```text
Spring Security
server-side session
HttpOnly cookie
CSRF
```

TTS worker uses separate machine authentication.

The worker SHALL NOT expose public inbound endpoints and SHALL use outbound HTTPS.

Permanent Spaces credentials SHOULD NOT be embedded in the worker when temporary upload authorization can be used.

---

## 39. Observability

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
```

Media/backend metrics SHOULD avoid unnecessary persistent learner identifiers.

---

## 40. CI/CD

### Backend

```text
compile
format/static analysis
unit tests
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
Piper smoke synthesis test
FFmpeg conversion test
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

## 41. Mandatory failure tests for TTS

Before production acceptance, verify:

1. worker killed during synthesis;
2. worker killed during FFmpeg conversion;
3. network loss before upload;
4. network loss after upload but before completion callback;
5. duplicate completion callback;
6. expired upload authorization;
7. invalid voice/model configuration;
8. corrupt generated media;
9. backend restart with pending/running jobs;
10. two workers attempting concurrent claims;
11. text changed while old generation is running;
12. stale worker result received after a newer revision exists.

A stale result MUST NOT overwrite the current revision's required asset.

---

## 42. Production deployment — initial target

```text
DigitalOcean
│
├── CareerSpeak Backend
├── Managed PostgreSQL
└── Spaces + CDN
```

The first release does not require Kubernetes or a service mesh.

The local TTS worker may run on a controlled Windows content-production machine. If content throughput increases, the same worker protocol may be deployed to cloud workers without changing the learner runtime.

---

## 43. MVP acceptance criteria

MVP architecture is considered functional when this full path works repeatedly:

```text
Moderator creates/edits English content
        ↓
adds localization/hints
        ↓
marks revision READY_FOR_AUDIO
        ↓
backend creates only required TTS jobs
        ↓
local worker generates + converts + validates audio
        ↓
asset is uploaded
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
published audio plays from CDN
```

The learner experience MUST remain available when the local TTS worker is offline.

---

## 44. Roadmap

### P0 — System Design

```text
Domain map
ERD
Localization model
Revision model
Assessment model
TTS/job model
Media model
Content manifest
ADR baseline
```

### P1 — Backend Foundation

```text
Spring Boot modular monolith
PostgreSQL
Liquibase
Security
Spring MVC Content Studio shell
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
Practice Tests
Mock Tests
Skills
Scoring rules
```

### P4 — Media + TTS

```text
FileAsset
Spaces abstraction
TtsJob
worker protocol
Piper worker
FFmpeg pipeline
voice registry
pronunciation rules
QC/review
```

### P5 — Content Production Qualification

```text
bulk import
bulk TTS
sample production content
voice qualification
failure/recovery tests
```

### P6 — Flutter Foundation

```text
catalog
local DB
manifest
settings/locales
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
delta updates
asset verification
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
Spaces/CDN
monitoring
backup
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

## 45. Architecture summary

The CareerSpeak MVP architecture is deliberately conservative:

> One Spring Boot modular monolith manages content and the web-based Content Studio. A separate headless local Piper worker performs asynchronous TTS production over an authenticated job protocol. PostgreSQL is the durable source of truth and job store. DigitalOcean Spaces/CDN serves immutable reviewed media. Flutter keeps learner state locally and consumes versioned content/offline packs.

This architecture is the current implementation baseline for VoxPrep v0.4.
