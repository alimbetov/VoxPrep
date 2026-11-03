# CareerSpeak / VoxPrep — System Requirements

**Document version:** 0.19  
**Status:** Normative MVP baseline  
**Target:** Android + iOS learner app, Spring Boot backend, TTS Worker

Normative documents:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`](CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [`CAREERSPEAK_CONTENT_STUDIO_REQUIREMENTS.md`](CAREERSPEAK_CONTENT_STUDIO_REQUIREMENTS.md)
- [`CAREERSPEAK_CONTENT_STUDIO_HARDENING_ADDENDUM.md`](CAREERSPEAK_CONTENT_STUDIO_HARDENING_ADDENDUM.md)
- [`CAREERSPEAK_INFRASTRUCTURE_REQUIREMENTS.md`](CAREERSPEAK_INFRASTRUCTURE_REQUIREMENTS.md)
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

The Content Studio is an internal B1 authoring surface, not a separate learner feature stream or independent MVP release gate. It provides the minimum visual/XML/asset authoring capability required to populate Backend-owned catalogue/content truth safely and efficiently.

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
Docker / Docker Compose
```

The v1 Content Studio stays inside this monolith under the secured `/admin/**` boundary. Its authoring baseline is server-rendered Spring MVC + Thymeleaf + HTMX, with MapStruct for compile-time structural mapping, restricted Lombok use, Spring Cache + Caffeine for bounded read-mostly caches, and Jackson XML/XSD/StAX for secure bulk authoring. It SHALL NOT introduce a separate React/Vue/Angular admin SPA or separate authoring service.

Use native SQL where it materially helps, notably TTS claim/lease concurrency.

Backend JPA entities are derived from backend invariants, not mirrored from Flutter DTOs or authoring DTOs.

Spring Boot is the sole remote learner/worker network boundary. RustFS and PostgreSQL are private Backend infrastructure. Their DEV/TEST/PROD deployment, volumes, users, secrets, backup and restore requirements are defined by `CAREERSPEAK_INFRASTRUCTURE_REQUIREMENTS.md`.

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

Visual/XML/asset authoring MUST preserve these rules. A requested change to a published content revision creates a new mutable draft revision; it never mutates published learner-visible history in place.

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

Content Studio import/apply does not bypass this boundary and does not make DRAFT content learner-visible.

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

B1 Content Studio SHALL include minimal private asset authoring required by the accepted learner cover path. It may upload/bind PNG, JPEG and WebP `coverImage` assets to an exact mutable draft revision, with bounded upload size, media verification, server-generated storage keys, SHA-256/size metadata and normal publication validation. Binary media is never embedded in XML and a published revision is never mutated in place.

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
Backend storage     → scoped private RustFS credential
PostgreSQL runtime  → least-privileged Backend DB role
```

The production ADMIN credential is not a default/source-controlled password. Content Studio uses CSRF protection plus hardened session semantics: server-side logout/invalidation, session fixation protection and Secure/HttpOnly cookie policy in production. Production admin traffic uses TLS.

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

A Docker volume is not considered a backup. Production acceptance additionally requires a clean restore drill for PostgreSQL plus RustFS and representative publication/asset integrity verification.

---

## 18. Infrastructure / persistence deployment

B1 SHALL provide isolated `DEV`, `TEST` and `PROD` container infrastructure for PostgreSQL and RustFS.

Baseline:

```text
PostgreSQL official stable 18.x image
RustFS official stable 1.0.x image
explicit version pins
PROD digest pinning preferred
separate contour volumes/networks/secrets
private DB/object-store network boundary
health checks
backup + restore runbook
```

Credential split is mandatory:

```text
PostgreSQL superuser → bootstrap/maintenance only
PostgreSQL migrator  → Liquibase
PostgreSQL backend   → runtime DML

RustFS root          → bootstrap/break-glass only
RustFS backend IAM   → bucket/prefix-scoped runtime access
```

Spring Boot runtime SHALL NOT use the PostgreSQL superuser or RustFS root credentials.

PROD persistent paths survive container recreation and are separated from backup storage. DEV/TEST reset operations are namespaced so they cannot target PROD volumes by default.

The complete topology, directory and acceptance contract is normative in `CAREERSPEAK_INFRASTRUCTURE_REQUIREMENTS.md`.

---

## 19. Explicit non-goals

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
separate authoring SPA/service
custom PostgreSQL/RustFS images without a demonstrated packaging need
```

---

## 20. Remaining delivery gates

The system contract is sufficient for this Flutter/BA branch. Full MVP production acceptance still requires:

```text
C4 Atomic Publication
 ↓
C5 Installation / Security
 ↓
B1 Backend schema + modular-monolith implementation
   + Content Studio / asset authoring
   + PostgreSQL/RustFS infrastructure baseline
 ↓
A1 real Backend ↔ Flutter acceptance
```

The Content Studio/XML/asset authoring and container infrastructure capabilities are subordinate to B1 and do not add new delivery gates.

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
