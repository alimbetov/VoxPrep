# CareerSpeak / VoxPrep — System Requirements

**Document version:** 0.14  
**Status:** Normative MVP baseline  
**Target:** Android + iOS learner app, Spring Boot backend, TTS Worker

Normative documents:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md`](CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md)
- [`../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md`](../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)
- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`../backend/CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md`](../backend/CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md)

---

## 1. Product

CareerSpeak is an offline-first English practice application focused on:

```text
international job interviews
professional / technical English
IELTS as a separate goal
```

Primary learning loop:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

MVP is deliberately simple: no mandatory learner account, no runtime AI, no recommendation service, no server learner profile and no complex curriculum/workflow engine.

---

## 2. Actors

Exactly:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

### ADMIN

One fixed secured account for Content Studio operations.

### FLUTTER INSTALLATION

```text
random installationId
→ backend registration
→ backend-issued installation token
→ Secure Storage
```

Learner progress/preferences remain local in MVP.

### TTS WORKER

Server-managed process/container using a dedicated machine token.

---

## 3. Product/domain ownership

Backend owns mutable product truth:

```text
LearningGoal
LearningTrack
LearningCollection
Category
Level
Skill
SupportedLocale
TtsVoice learner-facing catalogue
published content/test revisions
```

Minimal learner hierarchy:

```text
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
Content / PracticeTest
```

Important distinction:

```text
CareerTrack = professional taxonomy
LearningTrack = learning path
```

No backend `LearningActivity` aggregate is required in MVP.

Flutter owns local learner state:

```text
selected goal/track
self-assessed level
locale/accent/voice preference
favorites
listened/completed markers
review schedule
test history
playback progress
```

---

## 4. Backend architecture

One Spring Boot modular monolith.

Suggested logical modules:

```text
admin
assessment
catalog
learning
installation
interview
localization
manifest
media
profession
publication
security
topic
tts
vocabulary
```

Baseline:

```text
Java 21
Spring Boot / MVC / Security
Spring Data JPA + Hibernate
PostgreSQL + Liquibase
HikariCP
OpenAPI
Micrometer / Actuator
Testcontainers
Docker
```

Use native SQL only where useful, notably TTS claim/lease concurrency.

Do not mirror Flutter DTOs directly into JPA entities.

---

## 5. Flutter architecture

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

Core services:

```text
ContentSyncCoordinator
DownloadManager
AssetResolver
AudioPlaybackController
ReviewScheduler
StorageRetentionManager
LearnerContentStateRepository
```

---

## 6. Learner experience

### Onboarding

Three-step, skippable, restart-safe:

```text
1. LearningGoal
2. approximate level / Not sure
3. support language
```

### Home

Priority:

```text
Continue
Current goal/track
Review due
Browse current track/collections
Secondary statistics
```

No recommendation engine is required. Editorial sort order + local progress is enough.

### Learn

```text
Current track
Collections
Categories
Browse / Search
```

### Copy

Learner UI must not expose implementation language such as repository, adapter, persistence, DTO, manifest, Drift or RustFS.

---

## 7. Material Design 3 and adaptive UI

One design system only:

```text
Material Design 3
→ CareerSpeak theme/tokens
→ small reusable component set
→ adaptive feature UI
```

Width classes:

```text
COMPACT   < 600
MEDIUM    600–839
EXPANDED  840–1199
LARGE     >= 1200
```

State survives resize; presentation changes do not fork business logic.

---

## 8. Backend content lifecycle

Revision lifecycle:

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

Learner-deliverable:

```text
PUBLISHED + ACTIVE
```

Published revisions are immutable.

---

## 9. Flutter lifecycle vocabulary

```text
Backend ACTIVE
= backend permits delivery

Flutter CURRENT
= current local metadata snapshot

Flutter READY
= verified offline binary bundle
```

These state machines remain separate.

---

## 10. Content contract

Use a shared envelope plus typed bodies for real learner content:

```text
VocabularyBody
InterviewBody
TopicBody
PhraseBody
ShadowingBody
```

Do not use one generic EAV content table or arbitrary unversioned JSON domain model.

Assessment uses exact immutable test/question revisions.

---

## 11. Manifest and publication

Backend publishes one locale-independent root:

```text
contentVersion
```

Root references exact pack variants/revisions/checksums.

Variants:

```text
canonical
locale:<BCP-47>
```

Publication is atomic:

```text
validate
→ materialize exact refs/checksums
→ allocate never-reused contentVersion
→ persist immutable root
→ switch current root atomically
```

A failed publication exposes only the previous valid root.

---

## 12. Localization

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where applicable
```

Backend owns `SupportedLocale` and content translations/hints/explanations.

Flutter owns UI ARB strings and selected locale codes.

Runtime locale contracts accept arbitrary supported BCP-47 identifiers.

Root identity is locale-independent; locale changes only the downloaded support delta.

---

## 13. Audio / media

RustFS stores binary objects; PostgreSQL stores metadata.

Published media identity:

```text
assetId
checksumSha256
deliveryKey
```

Flutter verifies downloaded bytes before local use.

Media authorization/public-CDN policy must be explicit; do not imply the installation token protects CDN bytes if it does not.

---

## 14. TTS

Logical concepts:

```text
TtsVoice
TtsVoiceModel
TtsJob
TtsWorker
```

Worker flow:

```text
claim
→ exact model/config
→ Piper
→ FFmpeg
→ technical QC
→ backend upload/finalization
```

Queue:

```sql
FOR UPDATE SKIP LOCKED
```

with lease token, expiry, heartbeat, bounded retry and stale-result rejection.

Worker never receives direct PostgreSQL or permanent RustFS credentials.

---

## 15. Review semantics

Local deterministic review state:

```text
nextReviewAt
reviewStage
lastReviewOutcome
```

Strict rule:

```text
Due = nextReviewAt <= now
Due != !Completed
```

No ML/AI scheduler is needed.

---

## 16. Offline and retention

Drift separates:

```text
sync/system state
versioned content/cache
local learner preferences/progress
```

Disposable storage uses:

```text
TTL + LRU + quota + pin/download protection + reference-safe deletion
```

Eviction never erases learner progress/preferences/review state.

---

## 17. Security zones

```text
/admin/**       → ADMIN session
/api/v1/**      → installation token
/internal/v1/tts/** → worker token
```

Installation-token lifecycle must define re-registration, rejection/revocation and one bounded credential recovery attempt.

---

## 18. Failure isolation

```text
Backend down     → existing local learning continues
TTS Worker down  → jobs wait; published content unaffected
CDN/RustFS issue → verified local assets continue
sync crash       → last CURRENT snapshot remains
worker crash     → lease expires/reclaim
```

---

## 19. Explicit non-goals

Do not introduce in MVP without measured need:

```text
microservices
Kafka/RabbitMQ
Redis
Keycloak
API Gateway
server learner profile
LearningActivity aggregate
curriculum workflow engine
recommendation service
AI personalization
remote UI schema
social/leaderboards
complex gamification
```

---

## 20. P0 acceptance

Before backend content/schema freeze, accept:

```text
Product Requirements
Goal → Track → Collection → Content/Test ownership
CareerTrack != LearningTrack
three-step onboarding ownership
real Due semantics
typed content bodies
assessment production contract
locale-independent root
localized payload delivery
Category/Level/Skill/SupportedLocale/TtsVoice ownership
atomic publication snapshot
installation-token recovery
Drift ERD
learner + worker OpenAPI
TTS lease/recovery
failure/recovery scenarios
```

This is the authoritative MVP system baseline. Prefer the smallest design that satisfies these requirements.
