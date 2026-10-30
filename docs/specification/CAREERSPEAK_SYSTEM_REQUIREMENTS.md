# CareerSpeak / VoxPrep — System Requirements & Architecture Specification

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.2  
**Status:** Architecture Baseline / Draft for implementation  
**Target platforms:** Android, iOS  
**Business model:** one-time paid application; initial target price — USD 2.99  
**Primary learning model:** Read → Listen → Repeat → Test → Review

---

## 1. Purpose

CareerSpeak is a mobile application for self-study of practical English with two primary goals:

1. IELTS preparation;
2. preparation for international job interviews by profession and seniority.

The product is deliberately content-driven. High-quality text, vocabulary, model answers, contextual examples, interview questions, mock tests and audio are prepared in advance and published by a moderator.

The MVP does **not** require runtime AI, speech recognition or automatic pronunciation scoring.

---

## 2. Product principles

1. **Pay once, use without subscription.**
2. **No mandatory AI cost per user.**
3. **Human-curated content first.**
4. **Read → Listen → Repeat** as the core learning interaction.
5. **Learn → Test → Review** as the knowledge-retention loop.
6. **Data-driven mobile application:** professions, tracks, questions, topics and tests are not hardcoded in Flutter.
7. **Offline-first consumption:** downloaded content must remain usable without network access.
8. **Immutable publication:** published revisions are not edited in place.
9. **Moderator works only through Admin API; never directly with PostgreSQL or RustFS credentials.**
10. **Simple infrastructure first:** no Kafka, Redis, Elasticsearch or Kubernetes unless there is a measured need.

---

## 3. Scope

### 3.1 IELTS

CareerSpeak shall provide:

- IELTS vocabulary;
- English definition and localized translation;
- phonetic transcription;
- part of speech;
- CEFR level;
- IELTS topic/category;
- contextual example sentences;
- IELTS Speaking examples;
- IELTS Writing examples;
- collocations;
- word families;
- pre-recorded pronunciation audio;
- pre-recorded sentence audio;
- IELTS Speaking cue cards;
- model answers;
- IELTS-style mock tests;
- progress and review.

### 3.2 Job Interview Trainer

CareerSpeak shall provide:

- General Interview;
- HR Interview;
- Behavioral / STAR Interview;
- Salary & Compensation;
- Relocation;
- Management Interview;
- Profession-specific interviews;
- seniority-specific questions;
- model answers;
- useful vocabulary and phrases;
- pre-recorded question and answer audio;
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
- Progress;
- Offline downloads;
- Daily / Quick Test mode.

---

## 4. Out of scope for MVP

The following are explicitly excluded from MVP:

- Speech-to-Text;
- pronunciation scoring;
- automatic speech evaluation;
- LLM chat;
- AI-generated model answers at runtime;
- runtime TTS;
- live teachers;
- social network;
- messaging;
- leaderboards;
- complex gamification;
- Kafka;
- RabbitMQ;
- Redis;
- Elasticsearch/OpenSearch;
- Kubernetes.

These capabilities may be added later only through a separate architecture decision.

---

## 5. Actors

### 5.1 Learner

Uses the Flutter application to:

- browse content;
- listen to audio;
- repeat/shadow phrases and answers;
- complete mock tests;
- save favorites;
- track progress;
- download content for offline usage.

### 5.2 Moderator / Content Editor

Uses a Python desktop application to:

- create professions and career tracks;
- create interview questions and model answers;
- create vocabulary, examples and collocations;
- create topics and phrase-bank entries;
- create Question Bank items;
- assemble Mock Tests;
- upload audio;
- preview content;
- publish revisions;
- archive outdated content.

### 5.3 Administrator

Manages moderator accounts, roles and operational configuration.

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

### 7.1 Software & IT

- Software Engineer
- Java Backend Developer
- Python Developer
- Frontend Developer
- Mobile Developer
- QA / Test Engineer
- DevOps Engineer
- Cloud Engineer
- Cybersecurity Engineer

### 7.2 Data & AI

- Data Analyst
- Data Engineer
- Data Scientist
- AI / ML Engineer

### 7.3 Business & Product

- Business Analyst
- Project Manager
- Product Manager

### 7.4 Commercial / Customer

- Sales / Account Manager
- Customer Success
- Customer Support

The architecture must allow new professions to be published without a mobile release.

---

## 8. Seniority model

Supported values:

```text
JUNIOR
MIDDLE
SENIOR
LEAD
MANAGER
```

A question may apply to more than one seniority level.

---

## 9. Core learning scenarios

### 9.1 Topic

```text
Read text
   ↓
Listen to pre-recorded audio
   ↓
Repeat / Shadow
   ↓
Continue to next section
```

### 9.2 Vocabulary

```text
Word
  ↓
Meaning / Translation
  ↓
Collocations
  ↓
Context sentence
  ↓
Listen
  ↓
Repeat
  ↓
Review later
```

### 9.3 Job Interview

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
  ↓
Next question
```

No user audio processing is required.

### 9.4 Mock Test — Learn Mode

```text
Question
  ↓
Select answer
  ↓
Immediate result
  ↓
Correct answer
  ↓
Explanation
  ↓
Related content / audio
```

### 9.5 Mock Test — Exam Mode

```text
Question 1
Question 2
...
Question N
   ↓
Finish
   ↓
Score
   ↓
Skill breakdown
   ↓
Review wrong answers
```

---

## 10. Bounded contexts

### 10.1 Identity & Access

Owner: `auth-service`

Responsibilities:

- users;
- devices;
- public keys;
- device challenge-response authentication;
- access/refresh tokens;
- moderator accounts;
- roles;
- revocation;
- future store-entitlement verification.

### 10.2 Content Catalog

Owner: `content-service`

Responsibilities:

- professions;
- career tracks;
- interview content;
- vocabulary;
- topics;
- phrase bank;
- categories;
- tags;
- revisions;
- publication lifecycle.

### 10.3 Assessment

MVP physical owner: `content-service` as an internal module.

Logical responsibilities:

- Question Bank;
- Practice Tests;
- Mock Tests;
- Learn Mode;
- Exam Mode;
- skills;
- scoring rules;
- attempts;
- answers;
- skill breakdown.

A separate `assessment-service` is **not** required for MVP.

### 10.4 Media

Owner: `file-service`

Responsibilities:

- file metadata;
- object keys;
- presigned upload/download URLs;
- checksum validation;
- upload lifecycle;
- RustFS integration.

### 10.5 Learning State

MVP physical owner: `content-service`.

Responsibilities:

- favorites;
- recently opened;
- vocabulary progress;
- test history;
- review scheduling;
- content progress.

May be split later if scale requires it.

---

## 11. Target system architecture

```text
                         Internet
                            │
                            ▼
                     ┌─────────────┐
                     │ API Gateway │
                     └──────┬──────┘
                            │
           ┌────────────────┼────────────────┐
           │                │                │
           ▼                ▼                ▼
     Auth Service     Content Service    File Service
           │                │                │
           │                │                ▼
           │                │              RustFS
           │                │
           └──────────┬─────┘
                      ▼
                  PostgreSQL

                 Service Discovery
                      │
                      ▼
                    Eureka
```

Clients:

```text
Flutter Mobile
      └── Consumer API

Python Moderator Desktop
      └── Admin API
```

---

## 12. Backend baseline

Recommended baseline:

- Java 21 LTS;
- Spring Boot 4.x;
- Spring Cloud;
- Spring Cloud Gateway;
- Spring Cloud Netflix Eureka;
- Spring Security;
- Spring Data JPA;
- PostgreSQL;
- Liquibase;
- springdoc-openapi / OpenAPI;
- Micrometer;
- Docker.

Java 21 is the conservative production baseline. Java 25 may be evaluated separately after compatibility qualification.

---

## 13. Persistence ownership

MVP may use one PostgreSQL cluster with logical schemas:

```text
postgres
├── auth
├── content
└── files
```

Rules:

1. Each service writes only to tables it owns.
2. Cross-service repository access is forbidden.
3. Cross-service integration occurs through API contracts.
4. Liquibase changelogs are owned by their service.

---

## 14. Core content aggregates

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
TestAttempt
FileAsset
```

---

## 15. Profession

Suggested schema:

```text
profession
────────────────────────
id
code
name
description
icon_file_id
sort_order
status
created_at
updated_at
```

Examples of immutable `code`:

```text
JAVA_BACKEND_DEVELOPER
DEVOPS_ENGINEER
DATA_ANALYST
BUSINESS_ANALYST
```

---

## 16. Career Track

```text
career_track
────────────────────────
id
profession_id
code
name
description
status
sort_order
created_at
updated_at
```

Examples:

```text
JAVA_CORE
JAVA_SPRING
JAVA_SYSTEM_DESIGN
DEVOPS_KUBERNETES
DATA_ANALYTICS_SQL
```

---

## 17. Interview content

### 17.1 Interview Question

```text
interview_question
────────────────────────
id
code
status
created_at
updated_at
```

### 17.2 Interview Question Revision

```text
interview_question_revision
────────────────────────
id
question_id
revision
question_text
model_answer
difficulty
cefr_level
status
created_at
published_at
```

Published revisions are immutable.

### 17.3 Mappings

Use many-to-many mapping tables where appropriate:

```text
question_profession
question_career_track
question_category
question_seniority
question_skill
question_tag
```

Common interview questions must not be duplicated per profession.

---

## 18. Vocabulary model

### 18.1 Vocabulary Word

```text
vocabulary_word
────────────────────────
id
word
phonetic
part_of_speech
cefr_level
status
created_at
updated_at
```

### 18.2 Localized translation

```text
vocabulary_translation
────────────────────────
id
word_id
locale
definition
translation
```

Initial locales may include:

```text
en
ru
kk
```

Future expansion must not require schema redesign.

### 18.3 Vocabulary Example

```text
vocabulary_example
────────────────────────
id
word_id
sentence
example_type
sort_order
status
```

Example types:

```text
GENERAL
IELTS_SPEAKING
IELTS_WRITING
JOB_INTERVIEW
ACADEMIC
```

### 18.4 Collocation

```text
vocabulary_collocation
────────────────────────
id
word_id
text
translation_key / localized relation
sort_order
status
```

---

## 19. Topics

```text
topic
────────────────────────
id
code
category_id
title
description
cefr_level
status
sort_order
created_at
updated_at
```

Topic content should be revisioned.

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
sort_order
```

---

## 20. Phrase Bank

```text
phrase
────────────────────────
id
category_id
text
context
cefr_level
status
sort_order
```

Suggested categories:

- STARTING_ANSWER;
- THINKING;
- CLARIFICATION;
- AGREEMENT;
- DISAGREEMENT;
- SALARY;
- RELOCATION;
- PRESENTATION;
- MEETING;
- TECHNICAL_EXPLANATION;
- CUSTOMER_COMMUNICATION.

---

## 21. Assessment domain

Assessment is a first-class logical bounded context.

### 21.1 Supported test types

```text
IELTS
VOCABULARY
JOB_INTERVIEW
PROFESSIONAL
GENERAL_ENGLISH
```

### 21.2 Supported question types

MVP:

```text
SINGLE_CHOICE
TRUE_FALSE
```

Future:

```text
MULTIPLE_CHOICE
MATCHING
FILL_GAP
ORDERING
```

The data model must be extensible without breaking existing tests.

---

## 22. Question Bank

Questions are independent reusable entities.

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
explanation
difficulty
cefr_level
status
created_at
published_at
```

A single Question Bank item may be reused by several tests.

---

## 23. Test answer options

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

Validation rules:

- `SINGLE_CHOICE` must have exactly one correct option;
- `TRUE_FALSE` must have exactly two options and one correct value;
- future `MULTIPLE_CHOICE` may have multiple correct options;
- invalid question revisions cannot be published.

---

## 24. Skills

Skill taxonomy enables deterministic result analysis without AI.

```text
skill
────────────────────────
id
code
name
category
status
```

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

---

## 25. Practice Test / Mock Test

```text
practice_test
────────────────────────
id
code
title
description
test_type
profession_id nullable
career_track_id nullable
cefr_level nullable
difficulty
time_limit_sec nullable
passing_score nullable
status
sort_order
created_at
updated_at
```

Test ↔ question mapping:

```text
practice_test_question
────────────────────────
test_id
question_id
sort_order
points
```

---

## 26. Test attempts

```text
user_test_attempt
────────────────────────
id
user_id
test_id
mode
started_at
completed_at
correct_count
question_count
score
status
```

Modes:

```text
LEARN
EXAM
QUICK
```

```text
user_test_answer
────────────────────────
attempt_id
question_id
selected_option_id nullable
is_correct
answered_at
```

Offline attempts may be stored locally first and synchronized later.

---

## 27. Test result breakdown

Result API should support deterministic aggregation by skill.

Example:

```text
Overall          80%
Java Core        90%
Collections      85%
Concurrency      60%
Spring           85%
SQL              75%
```

Recommended review can be generated from the lowest-scoring skills without AI.

---

## 28. Audio and media

Audio is pre-recorded and uploaded by the moderator.

PostgreSQL stores metadata only. Binary media is stored in RustFS.

```text
PostgreSQL
   │
   ▼
FileAsset
   │ object_key
   ▼
RustFS
```

---

## 29. FileAsset

```text
file_asset
────────────────────────
id
bucket
object_key
original_filename
mime_type
size_bytes
checksum_sha256
duration_ms
status
created_at
updated_at
```

Permanent public URLs must not be stored in content tables.

Store object identity:

```text
bucket + object_key
```

Generate access URLs when needed.

---

## 30. Media relations

Prefer explicit FK relations instead of a generic `content_type/content_id` table for core content:

```text
interview_question_audio
interview_answer_audio
vocabulary_word_audio
vocabulary_example_audio
topic_section_audio
phrase_audio
test_question_audio
```

This preserves referential integrity.

---

## 31. Accent model

Architecture must support at least:

```text
UK
US
```

MVP may launch with one accent, but database and API contracts must not assume only one audio variant.

---

## 32. RustFS integration

RustFS is used as S3-compatible object storage.

Required operations:

- PUT;
- GET;
- HEAD;
- DELETE;
- presigned PUT;
- presigned GET.

The project must include integration tests against the exact RustFS version used in production.

---

## 33. Moderator Desktop

Recommended technology:

- Python 3.x;
- PySide6;
- httpx;
- pydantic.

Suggested structure:

```text
moderator-desktop/
├── main.py
├── api/
├── models/
├── screens/
│   ├── professions/
│   ├── interviews/
│   ├── vocabulary/
│   ├── topics/
│   ├── phrases/
│   ├── tests/
│   ├── question_bank/
│   └── files/
└── services/
```

Moderator Desktop must **not** connect directly to PostgreSQL and must **not** store RustFS root credentials.

---

## 34. Moderator workflow

```text
Create / edit content
       ↓
Save DRAFT
       ↓
Upload audio
       ↓
Validate
       ↓
Preview
       ↓
READY
       ↓
Publish
       ↓
PUBLISHED revision
```

Statuses:

```text
DRAFT
READY
PUBLISHED
ARCHIVED
```

Mobile Consumer API exposes only `PUBLISHED` content.

---

## 35. Atomic publication

Text and corresponding audio must be published consistently.

A published aggregate must never expose a newer text revision with an older incompatible audio revision.

Publication validation may require:

- mandatory text present;
- mandatory model answer present;
- required audio uploaded;
- file status completed;
- valid references;
- valid question answer configuration;
- no broken asset references.

---

## 36. File upload sequence

```text
Moderator Desktop
      │
      │ POST /admin/v1/files/upload-request
      ▼
File Service
      │
      │ fileId + presignedPutUrl
      ▼
Moderator Desktop
      │
      │ PUT audio file
      ▼
RustFS
      │
      ▼
Moderator Desktop
      │
      │ POST /admin/v1/files/{fileId}/complete
      ▼
File Service
```

Spring Boot should not proxy large media bodies through the JVM unless necessary.

---

## 37. Mobile application

Technology: Flutter.

Flutter responsibilities:

- navigation;
- rendering;
- audio playback;
- playback speed;
- seek;
- repeat;
- shadowing;
- test interaction;
- offline persistence;
- favorites UI;
- progress UI;
- search UI.

Backend does not manage playback state.

---

## 38. Shadowing requirements

Minimum controls:

```text
Play / Pause
Seek -5 sec / +5 sec
0.75x
1.00x
1.25x
Repeat 1x
Repeat 3x
Repeat 5x
Loop
```

Future enhancement: sentence-level timestamps for synchronized highlighting.

---

## 39. Offline model

Users may download content packs such as:

- IELTS Vocabulary;
- IELTS Speaking;
- Java Interview;
- DevOps Interview;
- Business Analyst Interview.

A pack contains:

```text
manifest
content metadata
text
asset references
audio files
checksums
```

Downloaded content must remain usable without backend connectivity.

---

## 40. Content manifest

Consumer API shall provide a versioned manifest, for example:

```http
GET /api/v1/content/manifest
```

Manifest should include:

- contentVersion;
- publishedAt;
- packs;
- assets;
- checksums;
- minimum supported app version if required.

Future delta synchronization must be possible without redesigning the content model.

---

## 41. Search

MVP uses PostgreSQL search capabilities.

Search targets:

- vocabulary word;
- phrase;
- profession;
- career track;
- interview question;
- topic;
- skill;
- tag.

Potential PostgreSQL extensions:

- full-text search;
- `pg_trgm`.

Do not introduce Elasticsearch/OpenSearch on MVP.

---

## 42. Favorites and progress

### 42.1 Favorites

A generic content reference is acceptable for user-state data:

```text
user_favorite
────────────────────────
user_id
content_type
content_id
created_at
```

### 42.2 Vocabulary progress

```text
user_vocabulary_progress
────────────────────────
user_id
word_id
state
times_seen
last_seen_at
next_review_at
```

States:

```text
NEW
LEARNING
REVIEW
KNOWN
```

### 42.3 Interview progress

```text
user_interview_progress
────────────────────────
user_id
track_id
question_id
completed
last_opened_at
```

---

## 43. Device authentication

Mobile users do not need mandatory email/password registration.

At first launch the application creates an asymmetric key pair.

```text
Private Key
  └── Android Keystore / iOS Keychain

Public Key
  └── Auth Service
```

Recommended algorithm: Ed25519.

Suggested protocol:

```text
POST /auth/device/register
POST /auth/challenge
client signs challenge
POST /auth/challenge/verify
      ↓
Access JWT + Refresh Token
```

Private key must never leave the device.

---

## 44. Device model

```text
device
────────────────────────
id
user_id
public_key
platform
device_name
status
created_at
last_seen_at
revoked_at
```

Future capabilities:

- My Devices;
- revoke device;
- account recovery / migration strategy.

---

## 45. Moderator authentication

Moderator accounts use a conventional administrative authentication flow.

MVP:

```text
username/password
+
JWT
+
ROLE_ADMIN
```

Future roles:

```text
ADMIN
CONTENT_EDITOR
CONTENT_REVIEWER
```

All privileged operations must be audited.

---

## 46. Store purchase model

The application is intended as a one-time paid application.

Store purchase and API identity are separate concerns:

```text
App Store / Google Play
        ↓
Purchase entitlement

Device Auth
        ↓
Backend identity
```

The architecture must allow future entitlement verification / app attestation without changing the content model.

---

## 47. API Gateway

Recommended: Spring Cloud Gateway.

Responsibilities:

- routing;
- auth boundary;
- correlation / trace IDs;
- rate limiting;
- CORS;
- common headers;
- API version routing.

Internal services must not be directly exposed to the public Internet.

---

## 48. Service discovery

Eureka is used for discovery of:

```text
api-gateway
auth-service
content-service
file-service
```

This is a deliberate ecosystem choice, not an MVP scaling requirement.

---

## 49. REST API surface

### 49.1 Consumer API

```text
/api/v1/auth/**
/api/v1/professions
/api/v1/career-tracks
/api/v1/interviews
/api/v1/interview-questions
/api/v1/vocabulary
/api/v1/vocabulary/categories
/api/v1/topics
/api/v1/phrases
/api/v1/tests
/api/v1/tests/{id}
/api/v1/test-attempts
/api/v1/search
/api/v1/progress
/api/v1/favorites
/api/v1/content/manifest
/api/v1/files/{id}/access
```

### 49.2 Admin API

```text
/admin/v1/professions
/admin/v1/career-tracks
/admin/v1/interviews
/admin/v1/questions
/admin/v1/vocabulary
/admin/v1/topics
/admin/v1/phrases
/admin/v1/skills
/admin/v1/question-bank
/admin/v1/tests
/admin/v1/files
/admin/v1/publication
```

---

## 50. API conventions

Mandatory:

- JSON / UTF-8;
- HTTPS only outside local development;
- `/api/v1` versioning;
- one global ID policy;
- ISO-8601 timestamps;
- UTC on backend;
- pagination;
- sorting;
- filtering;
- structured validation errors;
- OpenAPI contracts;
- stable machine-readable error codes.

Example error:

```json
{
  "code": "CONTENT_NOT_FOUND",
  "message": "Content was not found",
  "traceId": "...",
  "timestamp": "..."
}
```

Clients must not implement business logic based on human-readable `message`.

---

## 51. Security requirements

Mandatory:

- TLS;
- short-lived access JWT;
- refresh token rotation;
- device revocation;
- moderator RBAC;
- rate limiting;
- no DB credentials in clients;
- no RustFS credentials in clients;
- presigned media access;
- file MIME/type validation;
- max file size validation;
- SHA-256 checksum validation;
- moderator audit log;
- secrets outside Git;
- private object-storage buckets.

Presigned URL TTL should be intentionally limited.

---

## 52. Content security and licensing

Commercial content must be original, licensed, or otherwise legally usable.

For IELTS, CareerSpeak should use **IELTS-style** original practice questions and must not copy proprietary official exam material without permission.

The moderator workflow should support source/provenance metadata in future versions.

---

## 53. Data-driven mobile requirement

Flutter must not contain logic such as:

```dart
if (profession == JAVA) { ... }
if (profession == DEVOPS) { ... }
```

The backend publishes catalog metadata.

Adding a new profession, skill, test or topic must normally require only content publication, not a new mobile build.

---

## 54. DigitalOcean deployment

Target infrastructure:

```text
DigitalOcean
│
├── Application containers
│   ├── API Gateway
│   ├── Eureka
│   ├── Auth Service
│   ├── Content Service
│   └── File Service
│
├── PostgreSQL
│
└── RustFS
    └── persistent storage
```

Kubernetes is not required for MVP.

RustFS must never rely on ephemeral local storage for production data.

---

## 55. Observability

All Spring services shall expose appropriate operational telemetry through:

- Spring Boot Actuator;
- Micrometer;
- structured logs;
- trace/correlation IDs;
- health/readiness endpoints.

Minimum monitored signals:

- HTTP latency;
- HTTP 5xx rate;
- DB pool usage;
- authentication failures;
- RustFS errors;
- upload failures;
- JVM memory;
- CPU;
- disk/storage usage.

---

## 56. Audit

Moderator audit records should capture:

```text
who
when
action
entity type
entity ID
old revision
new revision
```

Actions:

```text
CREATE
UPDATE
PUBLISH
ARCHIVE
DELETE
UPLOAD
```

---

## 57. Repository strategy

Initial recommendation: monorepo.

```text
VoxPrep/
│
├── apps/
│   ├── careerspeak-mobile/
│   └── moderator-desktop/
│
├── services/
│   ├── api-gateway/
│   ├── discovery-server/
│   ├── auth-service/
│   ├── content-service/
│   └── file-service/
│
├── libs/
│   └── backend-common/
│
├── infra/
│   ├── docker/
│   ├── local/
│   └── digitalocean/
│
├── docs/
│   ├── specification/
│   ├── architecture/
│   ├── adr/
│   ├── api/
│   └── database/
│
└── README.md
```

---

## 58. Architecture Decision Records

Initial ADR backlog:

```text
ADR-001 Monorepo
ADR-002 Spring Boot backend
ADR-003 Eureka service discovery
ADR-004 PostgreSQL ownership model
ADR-005 RustFS object storage
ADR-006 Device public-key authentication
ADR-007 Presigned media access
ADR-008 Immutable content revisions
ADR-009 Data-driven mobile catalog
ADR-010 No AI/STT in MVP
ADR-011 One-time purchase model
ADR-012 Offline-first content
ADR-013 Assessment as logical bounded context inside content-service for MVP
ADR-014 Reusable Question Bank
```

---

## 59. Environments

Minimum:

```text
local
test
prod
```

Potential later environment:

```text
stage
```

Configuration is provided through environment variables / secret storage.

Secrets are never committed to Git.

---

## 60. Database migrations

Liquibase changelogs are service-owned:

```text
auth-service/src/main/resources/db/changelog/
content-service/src/main/resources/db/changelog/
file-service/src/main/resources/db/changelog/
```

---

## 61. CI/CD baseline

### Backend

```text
compile
unit tests
integration tests
architecture tests
format/static analysis
security/dependency scan
container image build
```

### Flutter

```text
flutter pub get
format
analyze
test
build qualification
```

### Python Moderator

```text
ruff
mypy
pytest
package qualification
```

---

## 62. Testing strategy

### Backend

- unit tests;
- repository tests;
- API integration tests;
- security tests;
- architecture tests;
- Testcontainers PostgreSQL;
- RustFS compatibility tests;
- publication validation tests;
- assessment scoring tests.

### Required RustFS qualification

Test at least:

```text
upload request
presigned PUT
HEAD/verification
complete upload
presigned GET
expired URL
deleted file
checksum mismatch
invalid MIME/type
```

### Assessment qualification

Test at least:

```text
single-choice invariant
true/false invariant
score calculation
skill aggregation
learn-mode immediate feedback
exam-mode deferred feedback
offline attempt synchronization
question reuse across multiple tests
published-revision immutability
```

---

## 63. Initial NFR targets

Engineering targets for MVP:

```text
catalog API p95 < 300 ms
auth API p95 < 500 ms
search p95 < 500 ms
normal API availability target >= 99.5%
no binary audio in PostgreSQL
consumer content usable offline after download
```

These are engineering objectives, not contractual SLA commitments.

---

## 64. Caching strategy

Because most published content is immutable, use:

- ETag;
- Cache-Control;
- content version;
- manifest version;
- local Flutter cache.

CDN may be introduced later without changing persistence identifiers.

---

## 65. MVP content target

Initial commercial baseline target:

- 500–1000 IELTS vocabulary entries;
- 100+ collocations;
- 30+ IELTS Speaking topics;
- 20+ general English topics;
- 50+ general interview questions;
- 30+ behavioral / STAR questions;
- 8–15 profession tracks;
- 50–150 profession-specific questions for priority professions where feasible;
- reusable Question Bank;
- several IELTS-style Mock Tests;
- profession-specific Practice Tests.

Exact launch volume is a product/content decision, not a hard architecture constraint.

---

## 66. Implementation roadmap

### P0 — Foundation

- repository structure;
- architecture specification;
- ADR baseline;
- Docker local environment;
- CI baseline.

### P1 — Identity

- auth-service;
- device registration;
- challenge-response;
- JWT;
- moderator authentication.

### P2 — File Platform

- file-service;
- RustFS;
- FileAsset;
- presigned PUT/GET;
- checksum validation.

### P3 — Content Core

- professions;
- career tracks;
- categories;
- tags;
- skills;
- publication lifecycle;
- immutable revisions.

### P4 — Interview Domain

- interview questions;
- model answers;
- seniority;
- question mappings;
- audio relations.

### P5 — Vocabulary Domain

- words;
- translations;
- examples;
- collocations;
- audio.

### P6 — Assessment Core

- Question Bank;
- question revisions;
- answer options;
- Mock Tests;
- Practice Tests;
- Learn Mode;
- Exam Mode;
- scoring;
- skill breakdown;
- test history.

### P7 — Topics / IELTS Speaking / Phrase Bank

- topics;
- topic revisions;
- sections;
- IELTS cue cards;
- phrases.

### P8 — Moderator Desktop

- Python / PySide6;
- CRUD;
- Question Bank editor;
- test builder;
- file upload;
- preview;
- publish.

### P9 — Flutter Core

- device auth;
- catalog;
- navigation;
- audio player;
- test renderer.

### P10 — Learning UX

- shadowing;
- favorites;
- progress;
- review;
- search;
- Quick Test.

### P11 — Offline

- content manifest;
- packs;
- downloads;
- checksums;
- delta synchronization;
- offline test attempts.

### P12 — Production

- DigitalOcean;
- PostgreSQL;
- RustFS;
- TLS;
- backups;
- monitoring;
- CI/CD;
- production hardening.

### P13 — Store Release

- Android release;
- iOS release;
- store metadata;
- one-time purchase;
- entitlement strategy;
- final acceptance.

---

## 67. MVP end-to-end acceptance scenario

The system is functionally complete for MVP when the following path works:

```text
Moderator creates Profession / Track
        ↓
creates interview/vocabulary/test content
        ↓
uploads required audio
        ↓
validates and previews revision
        ↓
publishes
        ↓
Flutter receives new catalog/content without hardcoded changes
        ↓
Learner reads/listens/repeats
        ↓
Learner completes a Mock Test
        ↓
Learner sees score and skill breakdown
        ↓
Learner reviews weak areas
        ↓
Learner downloads selected content
        ↓
Content remains usable offline
```

Mandatory architecture invariants:

```text
Moderator never accesses PostgreSQL directly.
Moderator never receives RustFS root credentials.
Mobile never receives RustFS root credentials.
Published content is revisioned and immutable.
Text/audio consistency is validated before publication.
Question Bank items are reusable.
Professions and tests are data-driven.
Audio binary is never stored in PostgreSQL.
Core offline content does not require backend connectivity after download.
```

---

## 68. Required System Design v1 deliverables

Before substantial feature implementation, create:

1. C4 System Context diagram;
2. C4 Container diagram;
3. bounded-context map;
4. PostgreSQL ERD;
5. device-auth sequence diagram;
6. content-publication sequence diagram;
7. file upload/download sequence diagram;
8. Mock Test execution sequence diagram;
9. offline synchronization sequence diagram;
10. initial OpenAPI contracts;
11. ADR-001…ADR-014;
12. P0 implementation backlog.

---

## 69. Open architecture questions

The following decisions should be resolved during System Design v1:

1. Global identifier policy: `BIGINT` vs UUID/UUIDv7.
2. Exact moderator authorization model for first production release.
3. Whether `user_*` learning-state tables stay in `content` schema or receive a dedicated schema from day one.
4. Exact offline pack format and manifest schema.
5. Content localization model for topic/question/model-answer translations.
6. Exact audio format baseline (MP3/AAC/Opus) and allowed upload constraints.
7. Store entitlement verification requirements for paid applications.
8. Recovery strategy when a user changes or loses a device.
9. Whether test questions may have localized stems/options or remain English-only in MVP.
10. Whether IELTS Speaking cue cards are modeled as Topics or as a dedicated aggregate.

---

## 70. Architecture baseline statement

CareerSpeak shall be implemented as a low-runtime-cost, content-driven learning platform with four primary domains:

```text
CONTENT
ASSESSMENT
IDENTITY
MEDIA
```

The essential product loop is:

```text
LEARN
  ↓
LISTEN
  ↓
REPEAT
  ↓
TEST
  ↓
REVIEW
```

The system must maximize the ability to add new professions, questions, vocabulary, tests, topics and audio through the Moderator Desktop **without requiring a new mobile release**.

This document is the initial architecture baseline for subsequent C4, ERD, OpenAPI, ADR and implementation work.
