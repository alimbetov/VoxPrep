# CareerSpeak / VoxPrep — System Requirements & Architecture Specification

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.13  
**Status:** Consolidated P0 product + architecture baseline  
**Target platforms:** Android, iOS  
**Primary learning model:** Read → Listen → Repeat → Test → Review

Normative documents:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
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

CareerSpeak is an offline-first English performance coach focused primarily on:

```text
international job interviews
professional / technical English
international career progression
```

IELTS remains a supported but separate learner goal path.

CareerSpeak teaches English only. Other languages support UI, translations, hints and explanations.

The product SHALL be goal-driven rather than only catalogue-driven.

Learner runtime does not require runtime AI, STT, pronunciation scoring or runtime TTS.

---

## 2. Product principles

```text
career/interview first positioning
goal-driven learner journeys
one-time paid app initial model
no ads initially
no mandatory learner account
local-first learner intent/progress
offline-first consumption
published content immutable by revision
server can deactivate content without destructive deletion
pre-generated reviewed audio
simple infrastructure until measured need
adaptive mobile UI
Material Design 3 as the single UI design system
privacy-first installation identity
durable local learner markers/review schedules
multi-locale product architecture
no learner-facing implementation jargon
```

---

## 2A. Normative product hierarchy

Backend-owned product structure:

```text
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
LearningActivity
    ↓
Content / PracticeTest
```

Mandatory distinction:

```text
Profession / CareerTrack
= career taxonomy

LearningGoal
= learner outcome

LearningTrack
= curated curriculum path toward a learner outcome
```

These concepts SHALL NOT be collapsed into one persistence or API entity merely for convenience.

Backend owns mutable product catalogues for:

```text
LearningGoal
LearningTrack
LearningCollection
Category
Level
Skill
SupportedLocale
TtsVoice learner-facing projection
```

Flutter stores local projections and device-owned learner selections/progress.

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

Backend does not build a learner profile from progress/favorites/test history in MVP.

Local learner intent may include selected goal/track/level/locale/voice preferences.

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
server learner profile
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
├── learning
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

`learning` owns goal/track/collection/activity product structure. `profession` owns career taxonomy. The exact Java package/module boundaries may be refined, but ownership semantics remain distinct.

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

Persistence entities SHALL be derived from domain invariants and SHALL NOT mirror Flutter DTO shape.

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
LearnerIntentRepository / equivalent local ownership
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

## 7. Learner experience contract

### 7.1 Onboarding

First-run onboarding is short, skippable, account-free and restart-safe.

It SHOULD gather:

```text
LearningGoal
approximate English level or Not sure
support/translation locale
preferred accent/voice where available
starter-pack download preference
```

Skipping onboarding creates deterministic defaults and never blocks browsing.

### 7.2 Home hierarchy

Home prioritizes:

```text
Next best action / Continue
Current goal/track
Goal/track progress
Due review
Recommended next collection/content
Browse shortcuts
Secondary statistics
```

Database counters such as Completed/Listened/Favorites are secondary.

### 7.3 Learn hierarchy

Learner discovery favors:

```text
Continue your track
Goals / tracks
Collections
Recommended
Categories
Browse all / Search
```

Technical content types are not the only learner-facing navigation model.

### 7.4 Learner-facing copy

Production UI does not expose implementation terms such as repository, adapter, persistence, manifest, DTO, qualification, Drift or RustFS.

Raw transport/database errors are not learner-facing strings.

---

## 8. UI design system

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
CareerSpeak branded components remain Material-based
Study Ambience is decorative, not a second design system
large-text and accessibility qualification
RTL/mixed-direction support
```

No separate visual framework is created for iOS, Shadowing, Assessment or tablets.

---

## 9. Production topology

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

## 10. Backend content lifecycle

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

## 11. Flutter lifecycle terminology

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

## 12. Learner content markers and intent

Flutter owns three independent durable learner markers:

```text
FAVORITE
LISTENED
COMPLETED
```

The states are independent. Any valid combination is allowed.

Rules:

```text
markers use stable content_code + content_type
markers survive app restart and cache/media eviction
Favorite does not imply offline pinning
Listened does not imply Completed
Completed does not replace detailed test/review history
markers remain local in MVP
```

Flutter also owns local learner intent:

```text
onboardingCompleted
selectedGoalCode
selectedTrackCode?
selfAssessedLevelCode?
uiLocale
translationLocale
preferredAccent / preferredVoiceCode?
```

Selected mutable product codes are sourced from backend-owned catalogues.

---

## 13. Review scheduling semantics

MVP review scheduling is deterministic and local.

Required state:

```text
nextReviewAt
reviewStage
lastReviewedAt
lastReviewOutcome
```

Mandatory rule:

```text
Due = nextReviewAt <= now
Due != !Completed
```

Possible outcomes include:

```text
incorrect
hard
correct
known
```

Review schedules survive restart/cache eviction and do not require runtime AI.

---

## 14. Content versioning and manifest

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

## 15. Offline bundle replacement

Explicit offline bundle has independent readiness.

Valid state:

```text
metadata rev 8 = CURRENT
offline rev 7 = READY
offline rev 8 = UPDATING
```

Old READY bundle remains usable until replacement verifies.

---

## 16. Publication / content / assessment reproducibility

Published content revisions are immutable.

The backend learner-content contract uses a shared envelope plus typed immutable bodies for at least:

```text
VocabularyBody
InterviewBody
TopicBody
PhraseBody
ShadowingBody
```

Published tests reference exact immutable `QuestionRevision` records.

Flutter test attempts persist exact test/question revisions/snapshots so completed attempts remain reviewable after later content changes/cache eviction.

Assessment feedback can use stable `skillCode` identity and explanations to identify weak/strong skills and recommend a next learning action.

---

## 17. Localization

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where applicable
```

UI strings:

```text
Flutter ARB / gen-l10n
```

Content translation/hints/explanations:

```text
Backend typed localization tables
→ locale pack variants
→ immutable localized payload delivery
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

The authoritative detailed contract is `CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`.

---

## 18. RustFS / media

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

Published media authorization policy must be explicit; the installation token must not be described as protecting CDN bytes unless the delivery path actually enforces it.

---

## 19. TTS architecture

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

## 20. TTS queue

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

## 21. Content delivery

MVP backend synchronization truth is:

```text
root manifest
pack manifests
canonical immutable payloads
localized immutable payloads
product/catalog capability snapshots
tombstones
checksums
```

Learner browsing/filtering/pagination is performed against local Drift projections after synchronization unless a separate remote collection use case is explicitly approved.

Tombstones explicitly retire content; absence from a list never implies deletion.

Changing translation locale reuses unchanged canonical English/audio/assets and downloads only the required locale delta.

---

## 22. Local persistence and retention

Drift separates:

```text
system/sync state
versioned product/content cache
durable learner state
local learner intent
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

Cache/media eviction never erases learner intent, progress, review schedules or markers.

---

## 23. Adaptive UI

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
resize without route/test/audio/marker/review/onboarding state loss
```

RTL qualification must cover mixed RTL guidance with LTR English learning content.

---

## 24. Security zones

```text
/admin/**
→ ADMIN session

/api/v1/**
→ installation token

/internal/v1/tts/**
→ worker token

private RustFS
→ Backend-owned credentials; learner delivery only through configured published origin/CDN policy
```

Installation token lifecycle must define longevity, revocation/re-registration and bounded credential-specific 401 recovery.

---

## 25. Failure isolation

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

Durable learner intent, review schedules and markers remain intact across recoverable sync/cache failures.

A missing translation locale must fall back deterministically without making canonical English content unavailable.

---

## 26. Product activation semantics

Product activation means:

```text
onboarding completed or explicitly skipped deterministically
AND
at least one meaningful learning activity completed
```

Meaningful activities include qualified audio listen, content completion, completed practice test or completed review.

Server learner analytics are not required for MVP. Future telemetry requires a separate privacy/data contract.

---

## 27. P0 acceptance

Before implementation/domain freeze, accept:

```text
Product Requirements normative baseline
career/interview-first positioning with IELTS as separate goal path
LearningGoal / LearningTrack / LearningCollection / LearningActivity ownership
LearningGoal distinct from Profession/CareerTrack
local learner-intent ownership
onboarding complete/skip/fallback semantics
Home next-action/current-goal hierarchy
real Due review semantics
learner-facing copy policy
common identifiers/time/error contracts
Backend publication/availability lifecycle
cross-system ACTIVE/CURRENT/READY terminology
root manifest/pack variant version contract
locale-independent root identity
Backend-owned SupportedLocale catalog
localized payload delivery contract
typed learning-content body contract
assessment production contract
Category/Level/Skill catalog ownership
learner-facing TtsVoice capability ownership
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

The TTS Worker machine-readable contract is represented by `docs/backend/openapi/tts-worker-v1.yaml`; production acceptance still requires real Backend ↔ Worker qualification.

Backend content/JPA schema SHALL NOT be considered frozen until the product hierarchy, typed content, assessment, publication, localization and installation lifecycle contracts above are closed.

This is the authoritative system baseline for CareerSpeak v0.13.
