# CareerSpeak / VoxPrep — System Requirements & Architecture Specification

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.9  
**Status:** Consolidated P0 architecture baseline  
**Target platforms:** Android, iOS  
**Primary learning model:** Read → Listen → Repeat → Test → Review

Normative documents:

- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md`](CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md)
- [`../architecture/CAREERSPEAK_TTS_PIPELINE.md`](../architecture/CAREERSPEAK_TTS_PIPELINE.md)
- [`../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md`](../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)

Mobile detailed contracts:

- [`../mobile/CAREERSPEAK_DRIFT_ERD.md`](../mobile/CAREERSPEAK_DRIFT_ERD.md)
- [`../mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md`](../mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md)
- [`../mobile/CAREERSPEAK_ADAPTIVE_UI.md`](../mobile/CAREERSPEAK_ADAPTIVE_UI.md)

---

## 1. Product purpose

CareerSpeak is an offline-first English-learning application focused on:

```text
IELTS preparation
international job interviews
professional/technical English
vocabulary/topics/phrases/shadowing
practice/mock tests
local review and progress
```

CareerSpeak teaches English only. Other languages support UI, translations, hints and explanations.

Learner runtime does not require runtime AI, STT, pronunciation scoring or runtime TTS.

---

## 2. Product principles

```text
one-time paid app initial model
no ads initially
no mandatory learner account
local-first learner progress
offline-first consumption
published content immutable by revision
server can deactivate content without destructive deletion
pre-generated reviewed audio
simple infrastructure until measured need
adaptive mobile UI
privacy-first installation identity
```

---

## 3. Technical actors

Exactly:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

### ADMIN

One fixed secured account for all Content Studio operations.

No moderator/editor/reviewer hierarchy, RBAC tables, registration, password reset, OAuth, LDAP or Keycloak in MVP.

### FLUTTER INSTALLATION

No learner account.

```text
random installationId
→ backend registration
→ backend-issued installation token
→ platform Secure Storage
```

Backend does not build a learner profile from progress/favorites/test history.

### TTS WORKER

Machine actor with dedicated token; server-managed long-running process/container.

---

## 4. Explicit MVP non-goals

```text
runtime LLM chat
Speech-to-Text
pronunciation scoring
learner voice upload
runtime learner TTS
social/messaging/leaderboards
complex gamification
server learner-progress sync
multi-user admin identity platform
RabbitMQ
Kafka
Redis
Eureka
separate API Gateway
Elasticsearch/OpenSearch
R2DBC/WebFlux
Kubernetes
JavaFX/PySide admin UI
DRM-style media protection
```

---

## 5. Backend architecture

One Spring Boot modular monolith:

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

Baseline:

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

Persistence:

```text
Spring MVC + JPA/JDBC + HikariCP + PostgreSQL
```

Use native SQL where queue/concurrency semantics require it, notably TTS claim/lease operations.

---

## 6. Flutter architecture

Baseline:

```text
Flutter + Dart
Riverpod
go_router
Drift + SQLite
Secure Storage
local filesystem
HTTP abstraction
audio abstraction
```

Shared services:

```text
ContentSyncCoordinator
DownloadManager
AssetResolver
StorageRetentionManager
AudioPlaybackController
ReviewScheduler
```

Adaptive width classes:

```text
COMPACT   < 600
MEDIUM    600–839
EXPANDED  840–1199
LARGE     >= 1200
```

Adaptive presentation never forks business logic by device type.

---

## 7. Production topology

```text
ADMIN Browser
    │ session
    ▼
Spring Boot Backend
    │
    ├── PostgreSQL
    │
    └── RustFS
          ▲
          │ presigned/private operations
       TTS Worker

Flutter
├── installation token → Backend REST API
└── media → CDN/edge → RustFS published origin
```

Initial deployment may run Backend, TTS Worker, RustFS and reverse proxy on one Docker host, with managed PostgreSQL separately.

---

## 8. Backend content lifecycle

Revision status:

```text
DRAFT
READY_FOR_AUDIO
READY_FOR_REVIEW
PUBLISHED
ARCHIVED
```

Availability:

```text
ACTIVE
INACTIVE
```

Learner-delivery condition:

```text
PUBLISHED + ACTIVE
```

Meaning: visible/deliverable/downloadable according to learner contracts.

---

## 9. Flutter lifecycle terminology

Local metadata states:

```text
STAGING
VERIFIED
CURRENT
SUPERSEDED
FAILED
```

Offline pack states:

```text
NOT_DOWNLOADED
QUEUED
DOWNLOADING
VERIFYING
READY
UPDATING
FAILED
```

Mandatory distinction:

```text
Backend ACTIVE = server allows delivery
Flutter CURRENT = local metadata currently used
Flutter READY = complete offline bundle locally verified
```

---

## 10. Content versioning and manifest

Backend publishes one root learner snapshot:

```text
contentVersion
```

Root snapshot references exact pack variants/revisions/checksums.

Examples:

```text
JAVA_SENIOR / canonical / rev 8
JAVA_SENIOR / locale:kk / rev 4
```

Locale pack variants do not create separate root epochs.

Flutter distinguishes remote version seen from locally CURRENT version.

Metadata update is atomic; optional media bytes do not block normal metadata activation.

---

## 11. Offline bundle replacement

Explicit offline bundle has independent readiness.

Valid state:

```text
metadata rev 8 = CURRENT
offline rev 7 = READY
offline rev 8 = UPDATING
```

Old READY bundle remains usable until replacement verifies.

---

## 12. Publication/assessment reproducibility

Published content revisions are immutable.

Published tests reference exact immutable `QuestionRevision` records.

Flutter test attempts persist exact test/question revisions/snapshots so completed attempts remain reviewable after later content changes/cache eviction.

---

## 13. Localization

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent
```

UI strings:

```text
Flutter ARB / gen-l10n
```

Content translation/hints/explanations:

```text
Backend typed localization tables
→ locale pack variants
```

Initial locales:

```text
en
ru
kk
```

BCP-47-compatible identifiers and RTL readiness are required.

---

## 14. RustFS / media

RustFS stores binary objects; PostgreSQL stores metadata/lifecycle.

Logical buckets:

```text
careerspeak-models
careerspeak-draft
careerspeak-audio
careerspeak-images
```

Published media identity:

```text
assetId
checksumSha256
deliveryKey
```

Do not persist CDN hostname as durable domain identity.

---

## 15. TTS architecture

Logical `TtsVoice` and exact immutable `TtsVoiceModel` are separate.

Every job resolves exact `voice_model_id` before execution.

Worker:

```text
claim
obtain/cache exact model
Piper
FFmpeg
technical QC
RustFS upload
complete/fail callback
```

Worker never publishes content.

---

## 16. TTS queue

PostgreSQL durable queue using atomic claim with:

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

Old/stale lease completion is rejected.

RabbitMQ is not required initially.

---

## 17. Content delivery

Learner lists use cursor/keyset pagination.

Flutter syncs via:

```text
root manifest
pack manifests
locale variants
tombstones
checksums
```

Tombstones explicitly retire content; absence from a paginated list never implies deletion.

---

## 18. Local persistence and retention

Drift separates:

```text
system/sync state
versioned content/cache
learner durable state
```

Disposable storage management:

```text
TTL + LRU + quota + pin/download protection + reference-safe deletion
```

Cache/media eviction never erases learner progress.

---

## 19. Adaptive UI

CareerSpeak adapts to available window width, including phone, tablet, split-screen and landscape windows.

Core requirements:

```text
one shared business state across layouts
bottom navigation on compact where appropriate
navigation rail on wider layouts
master/detail only for natural master-detail domains
reading width constrained on tablets
large text support
RTL/mixed-direction support
resize without route/test/audio state loss
```

---

## 20. Security zones

```text
/admin/**
→ ADMIN session

/api/v1/**
→ installation token

/internal/v1/tts/**
→ worker token

private RustFS
→ presigned authorization
```

---

## 21. Failure isolation

```text
Backend down
→ existing local Flutter learning continues

TTS Worker down
→ production jobs wait; published learner content unaffected

CDN/RustFS learner delivery issue
→ verified local assets continue

Flutter sync crash
→ last CURRENT snapshot remains

Worker crash
→ lease expires/reclaim
```

---

## 22. P0 acceptance

Before implementation freeze, accept:

```text
common identifiers/time/error contracts
Backend publication/availability lifecycle
cross-system ACTIVE/CURRENT/READY terminology
root manifest/pack variant version contract
Drift ERD
ContentSyncCoordinator state machine
adaptive UI contract
localization/RTL contract
TTS claim/lease/recovery contract
PostgreSQL integrated ERD
Flutter local ERD
OpenAPI learner/worker contracts
failure/recovery qualification matrix
```

This is the authoritative system baseline for CareerSpeak v0.9.
