# CareerSpeak / VoxPrep — System Requirements

**Document version:** 0.17  
**Status:** Normative MVP baseline  
**Target:** Android + iOS learner app, Spring Boot backend, TTS Worker

Normative documents:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`](CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [`CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`](CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md`](../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)
- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`../backend/CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md`](../backend/CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md)

---

## 1. Product/system boundary

CareerSpeak is an offline-first English practice application for international job interviews, professional/technical English and supported learning directions such as IELTS.

Primary loop:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

MVP deliberately excludes mandatory learner accounts, runtime AI, recommendation services, server learner profiles and curriculum/workflow engines.

---

## 2. Actors

Exactly:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

### ADMIN

One secured Content Studio account is sufficient for v1.

### FLUTTER INSTALLATION

```text
random installationId
→ Backend registration/re-registration
→ installationToken
→ Secure Storage
```

Learner preferences/progress remain device-local.

### TTS WORKER

Server-managed process/container with a dedicated worker token. It does not receive direct PostgreSQL or RustFS credentials.

---

## 3. Product/domain ownership

Backend owns mutable product truth:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
Category
Level
Skill
SupportedLocale
TtsVoice learner catalogue
published Content revisions
published PracticeTest revisions
asset/audio descriptors
```

Only learner hierarchy:

```text
Vertical
 ↓
LearningGoal
 ↓
LearningTrack
 ↓
LearningCollection
 ↓
exact ContentRevision / PracticeTestRevision members
```

`CareerTrack != LearningTrack != Vertical`.

Flutter owns local learner state:

```text
selected Goal/Track
self-assessed Level
locale/accent/voice preference
FAVORITE/LISTENED/COMPLETED
review schedule
PracticeTest active attempt/completion/history
playback progress
```

Current Vertical derives from selected Goal and CURRENT catalogue. Invalid learner selection fails closed; Flutter never auto-selects a sibling Goal/Track or another Vertical.

---

## 4. Backend architecture

CareerSpeak v1 uses one Spring Boot modular monolith.

Minimum target modules:

```text
installation
catalogue
publication
content
assessment
localization
asset
tts
```

Additional internal packages may exist where they support concrete use cases, but they do not create separate deployable domain services.

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

Use native SQL where it materially helps, notably TTS claim/lease concurrency.

Backend JPA entities are derived from backend invariants, not mirrored from Flutter DTOs.

Spring Boot is the sole remote learner/worker network boundary. RustFS is private Backend infrastructure accessed through Backend storage adapters.

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

Core application/infrastructure boundaries include:

```text
ContentSyncCoordinator
DownloadManager
AssetResolver
AudioPlaybackController
ReviewScheduler
StorageRetentionManager
learner-state repositories
```

Production Flutter has no runtime demo/mock catalogue switch and no direct object-storage credential path.

---

## 6. Learner experience

### Onboarding

Exactly three decisions:

```text
1. Vertical + LearningGoal
2. B1 / B2 / C1 / Not sure
3. support language
```

Skippable, restart-safe, account-free and CURRENT-validated. Skip does not invent a learning direction.

### Invalid selection

```text
inactive/missing Track → clear Track; preserve active Goal
inactive/missing Goal  → clear Goal + Track; Choose learning direction
inactive/missing Vertical → its Goal invalid; same Goal rule
```

No sibling auto-fallback.

### Home

```text
Continue
Current Vertical / Goal / Track
Review due
Browse current track/collections or Choose learning direction
Secondary statistics
```

### Continue Learning

```text
active PracticeTest
→ unfinished last-opened Content
→ next incomplete Collection member
→ next eligible Collection
→ current Track/Vertical browse
→ Choose learning direction
```

Every target is revalidated against CURRENT.

### Learn

```text
Current Vertical / Goal / Track
Verticals
Collections
Categories
Browse / Search
```

---

## 7. Content lifecycle and exact revisions

Backend revision lifecycle:

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

Learner-deliverable = `PUBLISHED + ACTIVE`.

Published revisions are immutable. Collection members, PracticeTest attempts and completion/history use exact revision identity.

---

## 8. Flutter lifecycle vocabulary

```text
Backend ACTIVE
= backend permits learner delivery

Flutter CURRENT
= one selected coherent local publication

Flutter READY
= verified local binary asset/bundle ready for offline use
```

These state concepts remain separate.

---

## 9. Content and assessment contracts

Use typed content bodies rather than one generic EAV/unversioned domain JSON model.

Representative content bodies:

```text
VocabularyBody
InterviewBody
TopicBody
PhraseBody
ShadowingBody
```

Assessment references exact immutable PracticeTest/question revisions. An active attempt is restart-safe and submitted completion is exact-revision aware.

---

## 10. Atomic publication — C4

Backend exposes one immutable publication identity/root. It references the exact mutable catalogue snapshot and exact immutable payload/checksum set required by the learner app.

Consistency boundary:

```text
Vertical
Goal
Track
Collection
Content revisions
PracticeTest revisions
Localization
Assets/audio references
```

Publication flow:

```text
validate complete candidate
→ materialize exact refs/checksums
→ allocate never-reused publication/content version
→ persist immutable root
→ atomically activate CURRENT
```

Required semantics:

- readers never observe mixed publication versions;
- failed/incomplete/corrupt publication exposes only previous valid CURRENT;
- restart preserves/reconstructs the last valid activation deterministically;
- exact revision/checksum identity is reproducible.

---

## 11. Localization

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where applicable
```

Backend owns SupportedLocale and localized learner payloads. Flutter owns UI ARB strings and selected locale codes.

Publication/root identity is locale-independent; missing optional translation/hint/explanation does not invalidate canonical English content.

---

## 12. Learner media / RustFS

RustFS stores private binary objects behind Backend; PostgreSQL stores metadata.

Published asset identity includes stable asset identity plus integrity metadata such as SHA-256 and size.

CareerSpeak v1 has one Flutter-facing learner media contract:

```text
Flutter installation token
→ authenticated Backend learner media API
→ Backend-controlled byte delivery
→ Flutter size/checksum verification
→ verified local asset
```

Non-negotiable invariants:

```text
Flutter never receives RustFS/object-storage credentials
Flutter never treats deliveryKey as a remote locator
Backend controls learner media authorization
verified local files remain usable offline
```

A Backend-issued direct/signed object-storage grant is not a v1 contract. Introducing it later requires a separately versioned contract and security/acceptance update.

A user-managed Downloads dashboard is not an MVP release gate; offline verified asset availability is.

---

## 13. TTS

Logical concepts:

```text
TtsVoice
TtsVoiceModel
TtsJob
TtsWorker
```

Worker flow:

```text
claim through Backend
→ exact model/config through Backend
→ Piper
→ FFmpeg
→ technical QC
→ Backend upload/finalization
```

Queue uses PostgreSQL `FOR UPDATE SKIP LOCKED` with lease token, expiry, heartbeat, bounded retry and stale-result rejection.

---

## 14. Review semantics

Local deterministic state:

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

Outcome scheduling is local/deterministic/restart-safe. No AI/ML/FSRS requirement in v1.

---

## 15. Offline / retention

Drift separates:

```text
sync/system state
versioned product/content projections
local learner preferences/progress
```

Disposable cache/media may be evicted under bounded retention/quota policies, but learner preferences, markers, review and PracticeTest state are never removed by cache cleanup.

Standalone Favorites and Downloads application areas are post-MVP convenience surfaces, not system release gates.

---

## 16. Installation security — C5

Security zones:

```text
/admin/**           → ADMIN session
/api/v1/**          → installation token
/internal/v1/tts/** → worker token
Backend storage     → private RustFS credentials
```

Normative learner identity flow:

```text
installationId
→ idempotent registration/re-registration
→ installationToken
→ authorized learner API
```

Bounded credential recovery:

```text
401
→ invalidate rejected token only
→ preserve installationId + learner state
→ re-register once
→ retry safe request once where permitted
→ fail closed on repeated rejection
```

No mandatory learner account.

---

## 17. Failure isolation

```text
Backend down               → valid local learning continues
TTS Worker down            → jobs wait; published content unaffected
Backend media/storage down → verified local assets continue
sync/publication crash     → previous CURRENT remains valid
worker crash               → lease expires/reclaim
401 repeated after recovery → fail closed without deleting learner state
```

---

## 18. Explicit non-goals

Do not introduce in v1 without a new versioned requirement:

```text
microservices
Kafka/RabbitMQ for learner flows
Redis architectural dependency
Keycloak
API Gateway
server learner profile
mandatory learner account
LearningActivity aggregate
curriculum workflow engine
recommendation service
AI personalization
remote UI schema
generic EAV content model
social/leaderboards/complex gamification
advanced SRS/FSRS/SM-2
runtime STT/pronunciation scoring
standalone Favorites feature stream
user-managed Downloads feature stream
```

---

## 19. Remaining delivery gates

The system contract is sufficient for this Flutter/BA branch. Full MVP production acceptance still requires:

```text
C4 Atomic Publication
 ↓
C5 Installation / Security
 ↓
B1 Backend schema + modular-monolith implementation
 ↓
A1 real Backend ↔ Flutter acceptance
```

A1 must prove:

```text
Backend publication
→ HTTP API
→ Flutter sync
→ Drift CURRENT
→ content/audio/PracticeTest/Review
→ offline
→ restart
```

with stale/corrupt/replay/interruption/exact-revision adversarial cases.

This is the authoritative v1 system baseline. Prefer the smallest design that satisfies these requirements.
