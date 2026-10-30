# CareerSpeak / VoxPrep — System Requirements & Architecture Specification

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.7  
**Status:** Architecture baseline / P0 domain-contract design  
**Target platforms:** Android, iOS  
**Primary learning model:** Read → Listen → Repeat → Test → Review

Related documents:

- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md`](CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md)
- [`../architecture/CAREERSPEAK_TTS_PIPELINE.md`](../architecture/CAREERSPEAK_TTS_PIPELINE.md)
- [`../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md`](../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)

---

## 1. Product purpose

CareerSpeak is an English-learning mobile application focused on:

1. IELTS preparation;
2. international job-interview preparation by profession and seniority;
3. professional/technical English;
4. reusable vocabulary, topics, phrase banks, shadowing and mock tests.

CareerSpeak teaches **English only**. Other languages are presentation/localization languages for UI, translations, hints and explanations.

The learner runtime does not require runtime AI, STT, pronunciation scoring or runtime TTS.

---

## 2. Product principles

1. One-time paid application is the initial commercial model.
2. No ads in the initial product.
3. No mandatory learner account.
4. Learner progress remains local by default.
5. Published content is immutable by revision.
6. Content may be deactivated without destructive deletion.
7. Audio is generated before publication.
8. Mobile consumption is offline-first.
9. Large catalogs are paginated.
10. Re-downloadable local media is automatically reclaimable.
11. Infrastructure remains simple until measured requirements justify additional components.

---

## 3. Actors

CareerSpeak MVP has exactly three technical actors.

### 3.1 ADMIN

There is one administrative human account for MVP.

ADMIN performs all Content Studio operations:

- profession/catalog management;
- interview/vocabulary/topic/test authoring;
- localization;
- TTS voice/model administration;
- audio generation/review;
- publication;
- activate/deactivate;
- operational content configuration.

MVP SHALL NOT implement moderator/editor/reviewer account hierarchies, registration, password reset, OAuth, LDAP, Keycloak or role-management tables.

ADMIN authentication:

```text
fixed username
+
strong fixed password hash supplied through deployment secret/environment
+
Spring Security server-side session
+
HttpOnly/Secure/SameSite cookie
+
CSRF
```

No clear-text admin password may be committed to source control.

### 3.2 FLUTTER INSTALLATION

The learner has no personal backend account.

On first launch Flutter generates a cryptographically random app-specific `installationId` and registers it with the backend. The backend issues an installation token used for learner API calls.

The installation identifier SHALL NOT be derived from IMEI, IMSI, MAC, advertising ID, hardware serial or phone number.

The installation identity SHALL NOT be joined to learner progress, favorites or test history in MVP.

### 3.3 TTS WORKER

TTS Worker is a machine actor with its own rotatable machine token. It is not an ADMIN account and does not use learner tokens.

The production worker is a long-running server-managed process/container that starts and restarts automatically.

---

## 4. MVP non-goals

Do not implement for MVP:

```text
runtime LLM chat
Speech-to-Text
pronunciation scoring
learner voice upload
runtime learner TTS
social network
messaging
leaderboards
complex gamification
server-side learner profile/progress sync
multi-user admin RBAC
OAuth / social login / Keycloak / LDAP
RabbitMQ
Kafka
Redis
Eureka
separate API Gateway
Elasticsearch/OpenSearch
R2DBC/WebFlux
Kubernetes
JavaFX/PySide6 admin UI
DRM-style audio protection
```

Caffeine is not required initially and may be introduced only after profiling.

---

## 5. Backend architecture

CareerSpeak uses one Spring Boot modular monolith:

```text
careerspeak-backend
├── admin
├── assessment
├── catalog
├── installation
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

One deployable JVM application owns ordinary transactional business logic. Module boundaries SHOULD be protected by architecture tests such as ArchUnit or Spring Modulith-style rules.

---

## 6. Technology baseline

### Backend

```text
Java 21
Spring Boot
Spring MVC
Spring Security
Spring Data JPA
Hibernate
HikariCP
PostgreSQL
Liquibase
Thymeleaf
HTMX
OpenAPI
Micrometer / Actuator
Testcontainers
Docker
```

Explicit persistence decision:

```text
Spring MVC + JPA/JDBC + HikariCP + PostgreSQL
```

Reactive R2DBC/WebFlux is not required.

### Mobile

```text
Flutter
SQLite / Drift
Secure Storage for installation token
local filesystem for downloaded assets
```

### TTS

```text
Python
Piper
FFmpeg
server-managed long-running worker
local immutable model cache
```

### Storage

```text
PostgreSQL = structured durable state + TTS queue
RustFS     = S3-compatible binary/object storage
CDN/edge   = published learner-media delivery
```

---

## 7. Production topology

```text
                     INTERNET

          Flutter                 ADMIN Browser
             │                         │
 installation token             admin session
             │                         │
             └────────────┬────────────┘
                          ▼
                  Spring Boot Backend
                          │
             ┌────────────┴────────────┐
             ▼                         ▼
        PostgreSQL                   RustFS
     data + TTS queue       models/drafts/published assets
                                       ▲
                                       │
                                 TTS Worker
                           Python + Piper + FFmpeg
                              auto-start / auto-restart

Flutter ─────────► CDN/Edge ─────────► RustFS published assets
```

Initial deployment may use a single Docker host for backend, TTS worker, RustFS and reverse proxy, with managed PostgreSQL separately.

---

## 8. Core content domains

Initial domain ownership includes:

```text
Profession / CareerTrack / Catalog
Interview
Vocabulary
Topic / Phrase / Shadowing
Assessment
Localization
Publication / Availability
Media / FileAsset
TTS
Manifest / ContentPack
Installation
Admin orchestration
```

Detailed ownership and contracts are defined in `CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md`.

---

## 9. Revision, publication and availability

Publication lifecycle and learner availability are separate concepts.

A content revision may be:

```text
DRAFT
READY_FOR_AUDIO
READY_FOR_REVIEW
PUBLISHED
ARCHIVED
```

Learner availability is independently:

```text
ACTIVE
INACTIVE
```

Learner APIs expose content only when:

```text
revision_status = PUBLISHED
AND
availability_status = ACTIVE
```

Published revisions are immutable. Changes create a new revision.

Deactivation does not delete historical content.

---

## 10. Assessment reproducibility

Published tests SHALL reference exact immutable `QuestionRevision` records, not a mutable current question.

```text
PracticeTestRevision
├── QuestionRevision A
├── QuestionRevision B
└── QuestionRevision C
```

This guarantees reproducible published tests after later question edits.

---

## 11. Localization

Canonical learning content is English.

Localization covers:

```text
UI
translation
hint
explanation
```

Initial locales:

```text
en
ru
kk
```

Locale identifiers SHOULD be BCP-47 compatible. Typed localization tables are preferred over generic EAV localization.

---

## 12. RustFS media/model storage

RustFS is the baseline S3-compatible object store.

Recommended logical buckets:

```text
careerspeak-models   private Piper models/config
careerspeak-draft    private draft/generated assets
careerspeak-audio    published audio origin
careerspeak-images   covers/background assets
```

PostgreSQL stores metadata, object keys and checksums; binary ONNX/audio/image data is not stored in PostgreSQL.

Backend accesses RustFS through an `ObjectStorage` abstraction.

Large upload/download operations SHOULD use presigned URLs so Spring does not proxy binary payloads unnecessarily.

---

## 13. TTS voice/model rule

Logical voice and exact Piper model revision are separate.

```text
TtsVoice
US / Female / Lessac
        │
        ├── TtsVoiceModel v1 DEPRECATED
        └── TtsVoiceModel v2 ACTIVE
```

Before a TTS job is created, backend resolves an exact immutable `voice_model_id`.

A worker SHALL NOT silently substitute a different voice/model.

Detailed worker, queue and model-distribution contracts are defined in `CAREERSPEAK_TTS_PIPELINE.md`.

---

## 14. TTS queue principle

TTS jobs are a durable PostgreSQL queue. Worker claiming uses an atomic SQL transaction based on:

```sql
FOR UPDATE SKIP LOCKED
```

plus:

```text
worker_id
lease_token
lease_until
heartbeat
attempt_count
fingerprint
```

RabbitMQ is not required for the initial TTS workload.

---

## 15. Content delivery

Learner catalog APIs use cursor/keyset pagination.

Example:

```text
GET /api/v1/vocabulary?limit=50&cursor=...
```

Admin lists may use ordinary page/size pagination because they are low-volume internal workflows.

Flutter synchronizes versioned content through root/pack manifests rather than rebuilding every catalog from many requests.

Server deactivation/removal is propagated through manifest tombstones.

---

## 16. Flutter local retention

Durable learner state is separate from disposable/re-downloadable assets.

Durable local state:

```text
favorites
progress
test attempts
review schedule
settings
```

Re-downloadable state:

```text
pack snapshots
audio
remote images
future downloadable theme assets
```

Automatic cleanup uses:

```text
TTL + LRU + local quota + pinning + asset reference tracking
```

Evicting content/media SHALL NOT erase learner progress.

Detailed rules are defined in `CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md`.

---

## 17. Study ambience

Initial visual themes may include:

```text
MINIMAL
NATURE
COSMOS
LIBRARY
COFFEE_STUDY
PROFESSIONAL
```

Themes are primarily a Flutter concern. Exam/Mock Test mode defaults to minimal presentation. Readability has priority over decoration.

---

## 18. API security zones

```text
/admin/**
    → ADMIN password + server session

/api/v1/**
    → backend-issued installation token

/internal/v1/tts/**
    → TTS worker machine token

RustFS private model access
    → presigned GET/PUT
```

These authentication mechanisms SHALL remain separate.

---

## 19. Content Studio

Content Studio is server-rendered:

```text
Spring MVC
Thymeleaf
HTMX
Spring Security
```

One ADMIN performs all workflows.

The application should prioritize content-production throughput over complex UI administration:

```text
bulk import
validation
duplicate detection
localization completeness
missing/stale audio
TTS model/voice management
audio preview
publish/deactivate
```

---

## 20. Initial production deployment

Baseline:

```text
Docker Host
├── careerspeak-backend
├── careerspeak-tts-worker
├── rustfs
└── reverse-proxy / edge entry

Managed PostgreSQL
```

The worker runs continuously, polls/claims jobs, and consumes almost no application traffic when idle.

Additional workers may be added later without changing the job API or learner runtime.

---

## 21. P0 acceptance

Architecture is ready for implementation only after each bounded context has agreed:

```text
ownership
aggregates/value objects
invariants
state transitions
DB schema
constraints/indexes
API/application contracts
errors
security
idempotency
concurrency rules
acceptance/failure tests
```

The integrated ERD and OpenAPI contracts are frozen at the end of P0.

---

## 22. Current baseline summary

```text
ADMIN
→ Spring MVC Content Studio
→ one fixed secured account

Flutter
→ installationId
→ backend-issued installation token
→ REST API / manifests
→ CDN → RustFS

TTS Worker
→ server-managed long-running process
→ Backend Job API
→ PostgreSQL SKIP LOCKED queue
→ exact Piper model from RustFS/cache
→ Piper + FFmpeg
→ RustFS
→ ADMIN review/publish
```

This is the authoritative CareerSpeak architecture baseline for v0.7.
