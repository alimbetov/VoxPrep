# CareerSpeak / VoxPrep — System Requirements & Architecture Specification

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.8  
**Status:** Architecture baseline / P0 domain-contract design  
**Target platforms:** Android, iOS  
**Primary learning model:** Read → Listen → Repeat → Test → Review

Related documents:

- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
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
4. vocabulary, topics, phrase banks and shadowing;
5. reusable practice/mock tests and local review.

CareerSpeak teaches **English only**. Other languages are presentation/localization languages used for UI, translations, hints and explanations.

The learner runtime does not require runtime AI, Speech-to-Text, pronunciation scoring or runtime TTS.

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
9. Large learner catalogs use cursor/keyset pagination.
10. Re-downloadable local media is automatically reclaimable.
11. Canonical English content/audio is reused across localization languages.
12. Infrastructure remains simple until measured requirements justify additional components.

---

## 3. Technical actors

CareerSpeak MVP has exactly three technical actors.

### 3.1 ADMIN

One human administrative account performs all Content Studio operations:

```text
authoring
localization
TTS voice/model management
audio review
publication
activate/deactivate
operational content configuration
```

ADMIN authentication:

```text
fixed username
strong deployment-managed password hash
Spring Security server-side session
HttpOnly/Secure/SameSite cookie
CSRF
```

MVP does not implement Moderator/Editor/Reviewer roles, account registration, password reset, OAuth, LDAP, Keycloak or user/role tables.

### 3.2 FLUTTER INSTALLATION

The learner has no personal backend account.

```text
first launch
→ random app-specific installationId
→ backend registration
→ backend-issued installation token
→ platform secure storage
```

Installation identity is not linked to learner progress/favorites/test history in MVP.

### 3.3 TTS WORKER

TTS Worker is a machine actor with a dedicated rotatable machine token.

Production worker is a server-managed long-running process/container with automatic start/restart.

---

## 4. MVP non-goals

Do not implement initially:

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

One deployable JVM application owns transactional business logic. Module boundaries SHOULD be protected by architecture tests.

Backend baseline:

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

---

## 6. Flutter architecture

Flutter is the only learner-facing client.

Authoritative mobile specification:

[`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)

Baseline:

```text
Flutter + Dart
Riverpod
go_router
Drift + SQLite
platform secure storage
local filesystem
HTTP client abstraction
audio playback abstraction
```

Mobile architecture is feature-first and offline-first.

Shared mobile services include:

```text
ContentSyncCoordinator
DownloadManager
AssetResolver
StorageRetentionManager
AudioPlaybackController
ReviewScheduler
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

Initial deployment may use one Docker host for backend, TTS worker, RustFS and reverse proxy, with managed PostgreSQL separately.

---

## 8. Core content domains

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
Flutter local domain
```

Detailed ownership/contracts are defined in the P0 domain-contract plan.

---

## 9. Revision, publication and availability

Revision lifecycle:

```text
DRAFT
READY_FOR_AUDIO
READY_FOR_REVIEW
PUBLISHED
ARCHIVED
```

Availability is separate:

```text
ACTIVE
INACTIVE
```

Learner APIs expose only:

```text
revision_status = PUBLISHED
AND
availability_status = ACTIVE
```

Published revisions are immutable. Changes create a new revision.

---

## 10. Assessment reproducibility

Published tests reference exact immutable `QuestionRevision` records.

```text
PracticeTestRevision
├── QuestionRevision A
├── QuestionRevision B
└── QuestionRevision C
```

A completed local attempt preserves the exact test/question revision identifiers used for that attempt.

---

## 11. Localization model

Canonical learning content/audio is English and stored once.

Flutter distinguishes:

```text
uiLocale
translationLocale
preferredAccent
```

Learning language is fixed:

```text
learningLanguage = en
```

### UI localization

System/application UI strings are Flutter-owned compile-time resources:

```text
ARB
Flutter gen-l10n
```

Initial UI locales:

```text
en
ru
kk
```

### Content localization

Backend-driven locale content includes:

```text
translation
hint
explanation
data-driven localized labels
```

It is distributed through manifests/packs/locale deltas and may be updated without an application release when compatible.

Locale identifiers are BCP-47 compatible and mobile architecture is RTL-ready.

---

## 12. RustFS media/model storage

RustFS is the S3-compatible object store.

Logical buckets:

```text
careerspeak-models   private Piper models/config
careerspeak-draft    private draft/generated assets
careerspeak-audio    published audio origin
careerspeak-images   covers/background assets
```

PostgreSQL stores metadata/object keys/checksums, not large binary content.

Backend accesses RustFS through an `ObjectStorage` abstraction and uses presigned GET/PUT where practical.

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

Every TTS job resolves an exact immutable `voice_model_id` before execution.

Worker SHALL NOT silently substitute another model.

---

## 14. TTS queue

PostgreSQL is the durable TTS queue.

Worker claiming uses an atomic SQL transaction with:

```sql
FOR UPDATE SKIP LOCKED
```

and:

```text
worker_id
lease_token
lease_until
heartbeat
attempt_count
fingerprint
```

RabbitMQ is not required for the initial workload.

---

## 15. Content delivery

Learner collection APIs use cursor/keyset pagination.

Flutter synchronizes through:

```text
root manifest
pack manifests
locale deltas
tombstones
checksums
```

A new pack snapshot is staged and verified before atomic local activation.

A failed/partial update SHALL NOT replace the last known-good local snapshot.

---

## 16. Flutter local persistence

Structured local state uses Drift/SQLite.

Core local concepts include:

```text
settings
installation state
manifest/pack state
local content snapshot
local asset/content-asset references
favorites
progress
review schedule
test attempts/answers
download tasks
sync journal
```

Installation token is stored separately in platform secure storage.

---

## 17. Flutter local retention

Durable learner state is separate from disposable/re-downloadable data.

Automatic cleanup uses:

```text
TTL
+
LRU
+
local quota
+
pinning/manual-download protection
+
reference-safe shared-asset deletion
```

Media eviction SHALL NOT erase learner progress.

---

## 18. Audio and shadowing

Audio playback is a shared mobile service and resolves either a verified local file or remote CDN asset through `AssetResolver`.

MVP supports:

```text
play/pause/seek
0.75x / 1.0x / 1.25x
repeat 1 / 3 / 5 / infinite
skip back/forward
segment repeat where deterministic segmentation exists
```

Shadowing SHALL use backend-published stable segment/order metadata rather than client punctuation guessing.

---

## 19. Offline behavior

With downloaded content and local DB available, Flutter remains usable when backend/CDN/TTS Worker are offline.

Offline-capable operations include:

```text
read/listen downloaded content
complete downloaded tests
write progress/favorites/review state
use local search/index where available
```

Sync/new downloads are deferred until connectivity returns.

---

## 20. Study ambience

Initial themes may include:

```text
MINIMAL
NATURE
COSMOS
LIBRARY
COFFEE_STUDY
PROFESSIONAL
```

Study Mode may use ambience backgrounds. Focus and Exam/Mock Test modes default to minimal presentation. Readability has priority.

---

## 21. API security zones

```text
/admin/**
    → ADMIN password + server session

/api/v1/**
    → backend-issued installation token

/internal/v1/tts/**
    → TTS worker machine token

RustFS private access
    → presigned GET/PUT
```

These mechanisms remain separate.

---

## 22. Content Studio

Content Studio is server-rendered:

```text
Spring MVC
Thymeleaf
HTMX
Spring Security
```

One ADMIN executes all authoring/localization/TTS/publication workflows.

---

## 23. Mobile failure/recovery requirements

Mobile acceptance SHALL include:

```text
first launch online/offline
registration/token recovery
backend offline with local learning
manifest failure
interrupted pack staging
checksum mismatch
unsupported schemaVersion
tombstones
storage pressure/LRU cleanup
shared asset references
in-progress test restoration
locale change/fallback/RTL
CDN failure with local asset
Drift migration with progress retention
```

Raw transport/database exceptions are not learner-facing UI messages.

---

## 24. P0 acceptance

Architecture is implementation-ready only after each bounded context agrees:

```text
ownership
aggregates/value objects
invariants
state transitions
DB/local schema
constraints/indexes
API/application contracts
errors
security
idempotency
concurrency rules
acceptance/failure tests
```

Flutter additionally requires accepted:

```text
feature map
Riverpod ownership conventions
navigation
Drift ERD
sync/download/audio state machines
locale/RTL contract
assessment/review local state
retention/recovery contract
```

Integrated ERD/local ERD/OpenAPI contracts are frozen at the end of P0.

---

## 25. Current baseline summary

```text
ADMIN
→ Spring MVC Content Studio
→ one fixed secured account

Flutter
→ feature-first + Riverpod + go_router
→ Drift/SQLite + Secure Storage
→ installationId → backend-issued token
→ manifest/pack/locale-delta sync
→ local-first learning
→ AssetResolver → local file or CDN → RustFS
→ TTL/LRU/quota retention

TTS Worker
→ server-managed long-running process
→ Backend Job API
→ PostgreSQL SKIP LOCKED queue
→ exact Piper model from RustFS/cache
→ Piper + FFmpeg
→ RustFS
→ ADMIN review/publish
```

This is the authoritative CareerSpeak architecture baseline for v0.8.
