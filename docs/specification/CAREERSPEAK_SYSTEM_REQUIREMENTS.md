# CareerSpeak / VoxPrep — System Requirements & Architecture Specification

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.12  
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
- [`../backend/CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md`](../backend/CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md)
- [`../backend/TTS_WORKER_BACKEND_INTEGRATION.md`](../backend/TTS_WORKER_BACKEND_INTEGRATION.md)
- [`../backend/TTS_WORKER_BACKEND_AUTH_CONTRACT.md`](../backend/TTS_WORKER_BACKEND_AUTH_CONTRACT.md)
- [`../backend/openapi/tts-worker-v1.yaml`](../backend/openapi/tts-worker-v1.yaml)

Mobile detailed contracts:

- [`../mobile/CAREERSPEAK_DRIFT_ERD.md`](../mobile/CAREERSPEAK_DRIFT_ERD.md)
- [`../mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md`](../mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md)
- [`../mobile/CAREERSPEAK_ADAPTIVE_UI.md`](../mobile/CAREERSPEAK_ADAPTIVE_UI.md)
- [`../mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md`](../mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md)
- [`../mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md`](../mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md)

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
Material Design 3 as the single UI design system
privacy-first installation identity
durable local learner markers
multi-locale product architecture
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
parallel custom iOS design system
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
Material Design 3
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
LearnerContentStateRepository
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

## 7. UI design system

CareerSpeak uses exactly one learner UI design system:

```text
Material Design 3
        ↓
CareerSpeak Theme + Design Tokens
        ↓
CareerSpeak reusable Material components
        ↓
Adaptive feature presentation
```

Requirements:

```text
ThemeData / ColorScheme is the theme source
System / Light / Dark modes
Material NavigationBar / NavigationRail adaptive mapping
central spacing/radius/type/motion tokens
Material components before bespoke replacements
Study Ambience is decorative, not a second design system
large-text and accessibility qualification
RTL/mixed-direction support
```

No separate visual framework is created for iOS, Shadowing, Assessment or tablets.

---

## 8. Production topology

```text
ADMIN Browser
    │ session
    ▼
Spring Boot Backend
    │
    ├── PostgreSQL
    │
    └── RustFS

TTS Worker
    │ WORKER_TOKEN / HTTPS
    └──────────────→ Spring Boot Backend
                       │
                       └──────────────→ RustFS

Flutter
├── installation token → Backend REST API
└── media → CDN/edge → RustFS published origin
```

The TTS Worker never receives PostgreSQL or RustFS credentials and never uploads directly to RustFS. Model download and generated-audio upload both pass through Backend APIs.

Initial deployment may run Backend, TTS Worker, RustFS and reverse proxy on one Docker host, with managed PostgreSQL separately.

---

## 9. Backend content lifecycle

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

## 10. Flutter lifecycle terminology

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

## 11. Learner content markers

Flutter owns three independent durable learner markers:

```text
FAVORITE
= explicit learner curation

LISTENED
= qualified audio consumption completed

COMPLETED
= pedagogical unit completed according to feature policy
```

The states are independent:

```text
FAVORITE + LISTENED + COMPLETED
```

is valid.

Rules:

```text
markers use stable content_code + content_type
markers survive app restart and cache/media eviction
Favorite does not imply offline pinning
Listened does not imply Completed
Completed does not replace detailed test/review history
markers remain local in MVP
```

Catalogs may filter by Favorites, Listened/Not listened and Completed/Not completed.

---

## 12. Content versioning and manifest

Backend publishes one root learner snapshot:

```text
contentVersion
```

Root snapshot references exact pack variants/revisions/checksums.

Examples:

```text
JAVA_SENIOR / canonical / rev 8
JAVA_SENIOR / locale:ru / rev 5
JAVA_SENIOR / locale:kk / rev 4
JAVA_SENIOR / locale:uz / rev 2
JAVA_SENIOR / locale:tr / rev 3
```

Locale pack variants do not create separate root epochs.

The root manifest identity is locale-independent: the same `contentVersion` must not resolve to different root checksums for different translation locales.

Flutter distinguishes remote version seen from locally CURRENT version.

Metadata update is atomic; optional media bytes do not block normal metadata activation.

---

## 13. Offline bundle replacement

Explicit offline bundle has independent readiness.

Valid state:

```text
metadata rev 8 = CURRENT
offline rev 7 = READY
offline rev 8 = UPDATING
```

Old READY bundle remains usable until replacement verifies.

---

## 14. Publication/assessment reproducibility

Published content revisions are immutable.

Published tests reference exact immutable `QuestionRevision` records.

Flutter test attempts persist exact test/question revisions/snapshots so completed attempts remain reviewable after later content changes/cache eviction.

---

## 15. Localization

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

CareerSpeak is a multi-locale platform. Runtime locale contracts accept arbitrary supported BCP-47-compatible identifiers; they must not assume `locale ∈ {ru, kk}`.

Rollout baseline:

```text
Tier 0:
en / ru / kk

Tier 1:
uz / tr / ky / uk

Tier 2:
es / pt-BR / fr / de

Tier 3:
ar / ur / hi / bn / id / vi
```

Tier membership is product rollout policy, not protocol structure.

Backend owns the mutable `SupportedLocale` capability catalog and fallback metadata. Flutter stores the learner's selected stable locale codes.

The minimum recommended first expanded production set is:

```text
en
ru
kk
uz
tr
```

RTL/mixed-direction architecture must be qualified using at least `ar` even if Arabic content is not enabled in the first commercial release.

The authoritative detailed contract is `CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md` v1.1.

---

## 16. RustFS / media

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

## 17. TTS architecture

Logical `TtsVoice` and exact immutable `TtsVoiceModel` are separate.

Every job resolves exact `voice_model_id` before execution.

Worker:

```text
claim
obtain/cache exact model through Backend
Piper
FFmpeg
technical QC
Backend output upload
heartbeat / classified fail callback
```

Backend:

```text
model catalog
job/file identity
fingerprint
atomic claim + lease
model/config delivery
RustFS persistence
FileAsset metadata
READY finalization
retry/replay policy
```

Worker never publishes content and never connects directly to RustFS or PostgreSQL.

Exact Backend implementation requirements are defined in `docs/backend/CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md`.

---

## 18. TTS queue

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

Current-owner validation requires an unexpired lease. An expired lease cannot be revived by heartbeat.

Old/stale lease completion is rejected.

Initial recommended Backend policy:

```text
lease duration = 60 seconds
max attempts   = 3
```

RabbitMQ is not required initially.

---

## 19. Content delivery

Learner lists use cursor/keyset pagination.

Flutter syncs via:

```text
root manifest
pack manifests
locale variants
localized payloads
tombstones
checksums
```

Tombstones explicitly retire content; absence from a paginated list never implies deletion.

Changing translation locale reuses unchanged canonical English/audio/assets and downloads only the required locale delta.

---

## 20. Local persistence and retention

Drift separates:

```text
system/sync state
versioned content/cache
learner durable state
```

Durable learner state includes:

```text
favorites
LISTENED / COMPLETED markers
feature progress
review schedules
test history
```

Disposable storage management:

```text
TTL + LRU + quota + pin/download protection + reference-safe deletion
```

Cache/media eviction never erases learner progress or markers.

---

## 21. Adaptive UI

CareerSpeak adapts to available window width, including phone, tablet, split-screen and landscape windows.

Core requirements:

```text
one shared business state across layouts
NavigationBar on compact where appropriate
NavigationRail on wider layouts
master/detail only for natural master-detail domains
reading width constrained on tablets
large text support
RTL/mixed-direction support
resize without route/test/audio/marker state loss
```

RTL qualification must cover mixed RTL guidance with LTR English learning content.

---

## 22. Security zones

```text
/admin/**
→ ADMIN session

/api/v1/**
→ installation token

/internal/v1/tts/**
→ worker token

private RustFS
→ Backend-owned credentials; learner delivery only through configured published origin/CDN path
```

---

## 23. Failure isolation

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

Durable learner markers remain intact across recoverable sync/cache failures.

A missing translation locale must fall back deterministically without making canonical English content unavailable.

---

## 24. P0 acceptance

Before implementation freeze, accept:

```text
common identifiers/time/error contracts
Backend publication/availability lifecycle
cross-system ACTIVE/CURRENT/READY terminology
root manifest/pack variant version contract
locale-independent root identity
Backend-owned SupportedLocale catalog
localized payload delivery contract
arbitrary BCP-47 locale handling
configured locale fallback contract
RTL structural qualification
Drift ERD
ContentSyncCoordinator state machine
adaptive UI contract
Material Design 3 single-system contract
LISTENED/COMPLETED/FAVORITE learner-state contract
TTS claim/lease/recovery contract
PostgreSQL integrated ERD
Flutter local ERD
OpenAPI learner/worker contracts
failure/recovery qualification matrix
```

The TTS Worker machine-readable contract is now represented by `docs/backend/openapi/tts-worker-v1.yaml`; production acceptance still requires the real Backend A01-A11 qualification.

This is the authoritative system baseline for CareerSpeak v0.12.