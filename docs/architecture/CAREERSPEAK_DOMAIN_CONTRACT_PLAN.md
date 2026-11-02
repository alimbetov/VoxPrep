# CareerSpeak — Domain & Contract Plan

**Document version:** 2.4  
**Status:** Reconciled MVP domain/contract baseline  
**Applies to:** CareerSpeak v1

Normative parents:

- [`../specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](../specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`../specification/CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](../specification/CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`../specification/CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`](../specification/CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md)

---

## 1. Goal

Freeze only the domain ownership and cross-system contracts needed for CareerSpeak v1 before production backend implementation.

Every backend context must justify:

```text
concrete MVP use case
ownership
entities/value objects
invariants
persistence/schema
API/application contract
security/errors
failure/recovery
acceptance tests
```

Do not create domain layers, tables or DTOs without a concrete MVP use case. Persistence entities are derived from backend invariants, not Flutter DTO mirrors.

---

## 2. Shared terminology

```text
Backend ACTIVE
= backend permits learner delivery

Flutter CURRENT
= one atomically active local publication

Flutter READY
= verified local binary asset/bundle usable offline
```

These concepts are separate state machines.

---

## 3. Security actors

Exactly:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

No learner account or additional admin role hierarchy is required in v1.

---

## 4. Common contracts

Freeze:

```text
stable business codes
UTC / ISO-8601 time
API versioning
DTO naming/nullability
error envelope
traceId
idempotency conventions
HTTP semantics
checksum canonicalization
exact revision identity
```

---

## 5. Revision / publication / availability

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

Learner-deliverable:

```text
PUBLISHED + ACTIVE
```

Published revisions are immutable. Publication exposes one atomic learner snapshot; failed/incomplete publication never exposes a partial CURRENT graph.

---

## 6. Career taxonomy + learner navigation

### Career taxonomy

```text
Profession
CareerTrack
Seniority
Category
Level
Skill
```

### Learner hierarchy

```text
Vertical
 ↓
LearningGoal
 ↓
LearningTrack
 ↓
LearningCollection
 ↓
ordered CollectionMember
 ├─ exact ContentRevision
 └─ exact PracticeTestRevision
```

Rules:

```text
CareerTrack != LearningTrack != Vertical
Goal belongs to exactly one Vertical
Track belongs to exactly one Goal
Collection belongs to exactly one Track
stable code is identity
sort order is explicit
active/inactive is backend-owned
Flutter does not invent mutable catalogues
```

Invalid saved selection fails closed:

```text
inactive/missing Track → clear Track; preserve active Goal
inactive/missing Goal  → clear Goal + Track
inactive/missing Vertical → invalidate selected Goal
```

Do not auto-select the first sibling Track/Goal and do not silently switch Vertical.

No backend `LearningActivity`, workflow engine or curriculum graph is required.

---

## 7. Localization

Freeze:

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where applicable
BCP-47 identifiers
SupportedLocale catalogue
fallback rules
locale payload variants
immutable localized payloads
RTL/mixed-direction rules
```

Publication/root identity remains locale-independent.

---

## 8. Media / RustFS

Define:

```text
FileAsset
stable asset identity
size/checksumSha256
Backend-internal storage key/deliveryKey
ObjectStorage port
RustFS adapter
immutable object keys
media QC metadata
garbage collection
```

Flutter-facing v1 delivery is fixed:

```text
installation-authenticated Backend media API
→ Backend-controlled byte delivery
→ Flutter integrity verification
→ verified local asset
```

Flutter never receives storage credentials and never treats `deliveryKey` as a remote locator. RustFS topology remains Backend-internal.

A direct/signed storage grant is post-v1 unless a new versioned contract explicitly introduces it.

---

## 9. TTS

Define:

```text
TtsVoice
TtsVoiceModel
PronunciationRule where needed
TtsJob
TtsWorker
```

Queue:

```text
PostgreSQL
FOR UPDATE SKIP LOCKED
lease_token
lease_until
heartbeat
bounded retry
stale-result rejection
```

Flutter sees learner-facing voice capability only. Worker/model/storage internals remain Backend-controlled.

---

## 10. Typed content domains

Define revisioned structures only where required by learner experience, including:

```text
Interview
Vocabulary
Topic
Phrase
Shadowing
```

Use typed bodies and explicit invariants. Do not replace the domain with a generic EAV table or arbitrary unversioned JSON model.

Published learner-visible content never mutates in place.

---

## 11. Assessment

Define:

```text
QuestionBankItem
QuestionRevision
AnswerOption
Skill
PracticeTest
PracticeTestRevision
PracticeTestQuestion
ScoringRule
```

Published tests reference exact immutable question revisions. Active attempts and completion/history preserve exact test revision identity.

Complex recommendation logic is not required.

---

## 12. C4 — Atomic publication contract

One locale-independent publication/root identity references exact catalogue/payload/integrity data.

Mandatory consistency boundary:

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

Activation contract:

```text
build complete candidate
→ validate ownership/refs/revisions/checksums
→ persist immutable candidate/root
→ one atomic CURRENT activation
```

Required invariants:

- no mixed CURRENT publication is visible to readers;
- current publication/version identity is never reused;
- failed/corrupt/incomplete candidate leaves previous CURRENT active;
- restart preserves or deterministically recovers last-known-good CURRENT;
- tombstones/removals are publication-scoped and reproducible;
- exact payload/checksum identity is stable.

Flutter browses local Drift projections after synchronization.

---

## 13. Flutter application contract

Required accepted slices:

```text
state ownership
3-step onboarding
Vertical/Goal/Track/Collection discovery
fail-closed selection validation
Continue Learning
Drift persistence
localization/RTL
sync/download/asset resolution
real audio
PracticeTest exact-revision lifecycle
ReviewScheduler
storage retention
startup/recovery
adaptive Material 3 UI
FAVORITE/LISTENED/COMPLETED markers
learner-facing copy policy
```

Review invariant:

```text
Due = nextReviewAt <= now
Due != !Completed
```

`FAVORITE` marker is required; standalone Favorites area is not. Offline verified asset use is required; user-managed Downloads dashboard is not.

After R1, do not introduce a new Flutter learner-domain subsystem unless required to fix a demonstrated correctness defect in an accepted contract.

---

## 14. C5 — Installation / security contract

Security zones:

```text
/admin/**                   → ADMIN session
POST /api/v1/installations  → anonymous installation registration/re-registration
other /api/v1/**            → installation token
/internal/v1/tts/**         → worker token
```

The anonymous endpoint is only the bootstrap/session-issuance boundary. Learner content, media, catalogue, assessment and purchase-verification operations remain installation-authenticated.

Learner identity:

```text
installationId
→ idempotent Backend registration/re-registration
→ installationToken
→ authorized learner API
```

Bounded 401 recovery:

```text
invalidate rejected token only
→ preserve installationId + learner state
→ re-register once
→ retry safe request once where policy permits
→ fail closed on repeated rejection
```

Freeze token lifetime/revocation/re-registration/error semantics in OpenAPI/security implementation. No mandatory learner account.

---

## 15. Content Studio

One ADMIN may:

```text
create/edit/import content
manage Vertical/Goal/Track/Collection
manage taxonomy/localization
manage voices/models
prepare/review audio
publish
activate/deactivate
```

`READY_FOR_REVIEW` is a content process state, not a security role. No workflow/RBAC platform is required.

---

## 16. Backend implementation boundary — B1

Implement accepted contracts in one Spring Boot modular monolith with minimum modules:

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

Use PostgreSQL + Liquibase and private RustFS through an ObjectStorage adapter. TTS Worker is a separate computational process, not a reason to decompose product domains into microservices.

Before schema freeze, require accepted:

```text
business ownership/invariants
PostgreSQL ERD
publication/root contract
learner OpenAPI
worker OpenAPI
failure/recovery contract
```

---

## 17. Cross-system acceptance — A1

Qualify the production path:

```text
Backend publication
→ authenticated learner HTTP API
→ Flutter sync/staging
→ atomic Drift CURRENT
→ content/audio/PracticeTest/Review
→ offline
→ restart
```

Acceptance includes:

```text
stale revisions
corrupt payload/checksum
interrupted sync/download
publication replay
401 recovery
missing/inactive catalogue parents
restart during active PracticeTest/review/offline use
exact-revision reproducibility
```

---

## 18. Explicit anti-overengineering rule

Do not introduce for v1:

```text
LearningActivity aggregate
curriculum workflow engine
recommendation service
AI personalization
server learner profile
mandatory learner login
remote UI schema
generic EAV content model
microservices for domain separation
Kafka/RabbitMQ/Redis/Keycloak without measured need
advanced SRS/FSRS/SM-2
standalone Favorites feature stream
user-managed Downloads feature stream
```

---

## 19. Definition of Ready

```text
[ ] concrete MVP use case
[ ] ownership
[ ] entities/value objects
[ ] invariants
[ ] persistence constraints
[ ] API/application contract
[ ] security/errors
[ ] failure/recovery
[ ] acceptance tests
```

If a proposed entity/service cannot satisfy the first item, defer it.

---

## 20. Remaining delivery sequence

The former P0.0–P0.16 roadmap is retained conceptually as completed design work. The active delivery sequence is now:

```text
R1 exact-revision qualification
 ↓
C4 Atomic Publication
 ↓
C5 Installation / Security
 ↓
B1 Backend schema + modular monolith
 ↓
A1 Cross-system acceptance
```

This plan intentionally prefers a smaller correct model over a theoretically complete platform.
