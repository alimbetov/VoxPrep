# CareerSpeak — P0 Domain & Contract Design Plan

**Document version:** 2.2  
**Status:** Final P0 design roadmap  
**Applies to:** CareerSpeak v1+

Normative parent product contract:

- [`../specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](../specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md)

---

## 1. Goal

P0 freezes product/domain ownership and cross-system contracts before production implementation.

Every bounded context must define:

```text
scope/ownership
aggregates/entities/value objects
invariants/state transitions
persistence/schema
constraints/indexes
application/API contracts
security actor
errors/idempotency
concurrency/recovery
acceptance/failure tests
```

Backend persistence entities are derived from domain ownership and invariants; they SHALL NOT be mirrors of Flutter DTO classes.

---

## 2. System integration standard

All contexts follow:

```text
docs/architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md
```

Mandatory shared terminology:

```text
Backend ACTIVE
= learner-deliverable/downloadable

Flutter CURRENT
= selected local metadata revision

Flutter offline READY
= complete locally verified offline bundle
```

Do not reuse the same lifecycle term for different subsystem ownership.

---

## 3. Security actors

Exactly:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

No other human/admin role hierarchy is in MVP.

---

## 4. P0.0 — Common Contracts

Freeze:

```text
stable business codes
UTC/ISO-8601 time
API versioning
DTO naming/nullability
error envelope
traceId
cursor contract
idempotency conventions
optimistic-lock conventions
HTTP semantics
checksum canonicalization rules
```

Standard error:

```json
{
  "code": "CONTENT_NOT_FOUND",
  "message": "Content was not found",
  "traceId": "...",
  "details": {}
}
```

---

## 5. P0.1 — Revision / Publication / Availability

Backend lifecycle:

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

Learner delivery:

```text
PUBLISHED + ACTIVE
```

Freeze publication qualification, immutability, deactivation/reactivation and tombstone effects.

Publication must expose a single atomic learner snapshot; failed publication cannot expose a partial new root.

---

## 6. P0.2 — Career Taxonomy + Product Learning Structure

Career taxonomy and learning-path taxonomy are distinct.

### P0.2.1 Career taxonomy

Define:

```text
Profession
CareerTrack
Specialization where needed
Seniority
Category
Tag
Skill
Level
```

`CareerTrack` describes a professional/career specialization and SHALL NOT be reused as the learner curriculum path entity.

### P0.2.2 Product learning structure

Define backend-owned mutable product catalogues:

```text
LearningGoal
LearningTrack
LearningCollection
LearningActivity
ContentGoalRef / equivalent relation
TrackCollectionRef
CollectionActivityRef
```

Normative hierarchy:

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

Semantics:

```text
LearningGoal
= learner outcome, e.g. TECH_INTERVIEW / WORKPLACE_ENGLISH / IELTS

LearningTrack
= curated curriculum path toward a LearningGoal

LearningCollection
= coherent outcome-oriented group of activities

LearningActivity
= pedagogical action such as READ / LISTEN / REPEAT / TEST / REVIEW
```

Rules:

```text
stable business code is identity
mutable labels/presentation are not protocol enums
catalog additions/deactivation do not require a Flutter release
relations are deterministic and ordered where ordering matters
activity may reference exact content/test identity
publication/version semantics are explicit
```

Use stable business codes and deterministic publication/version contracts.

---

## 7. P0.3 — Localization

Freeze:

```text
English canonical learning language
uiLocale / translationLocale / preferredAccent
BCP-47 identifiers
typed localization tables
locale readiness
fallback
RTL/mixed-direction rules
locale pack variants
SupportedLocale capability catalog
```

UI strings are Flutter-owned ARB resources; learner content translations come from Backend.

Root manifest identity is locale-independent. Locale selection controls which published locale delta Flutter materializes, not the identity of the root snapshot.

---

## 8. P0.4 — Media / RustFS

Define:

```text
FileAsset
assetId/checksum/deliveryKey
ObjectStorage port
RustFS adapter
private/public rules
presigned GET/PUT where applicable
immutable object keys
media QC metadata
garbage collection
published delivery authorization policy
```

---

## 9. P0.5 — TTS

Define:

```text
TtsVoice
TtsVoiceModel
PronunciationRule
TtsJob
TtsWorker
```

Worker:

```text
server-managed Python process/container
Piper + FFmpeg
machine token
local model cache
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

Learner-facing `TtsVoice` capability is a backend-owned product projection. Worker-only model/storage details are not exposed to Flutter.

---

## 10. P0.6 — Interview

Define revisioned:

```text
InterviewQuestion
ModelAnswer
Category
Profession/CareerTrack/Seniority/Skill mappings
LearningGoal/LearningTrack/Collection relations where applicable
Localization
Audio roles
```

---

## 11. P0.7 — Vocabulary

Define:

```text
VocabularyWord identity
VocabularyRevision
Definition
Example
Collocation
WordFamily if in MVP
Category
Skill/Level mappings
LearningGoal/LearningTrack/Collection relations where applicable
Localization
Audio roles
```

Published learner-visible vocabulary never mutates in place.

---

## 12. P0.8 — Topic / Phrase / Shadowing

Define:

```text
Topic / TopicRevision
TopicSection
Phrase / PhraseCategory
display_text / tts_text
stable segment/order metadata
audio association
LearningGoal/LearningTrack/Collection relations where applicable
```

Shadowing must not depend on client punctuation guessing.

---

## 13. P0.9 — Assessment

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

Published test revision references exact question revisions.

Assessment result projection must be able to provide deterministic learning feedback using stable skill codes and explanations, not only a numeric score.

---

## 14. P0.10 — Manifest / Content Delivery

Freeze one locale-independent root:

```text
contentVersion
```

Root references exact:

```text
packCode
variantKey
revision
checksum
```

Variants include:

```text
canonical
locale:<locale>
```

Define tombstones, schema compatibility, asset descriptors, localized payload transport and capability/catalog publication semantics.

The manifest/exact-immutable-payload pipeline is the MVP backend synchronization source of truth. Learner browsing/filtering/pagination is local Drift behavior after synchronization unless a separate server-side use case is explicitly approved.

---

## 15. P0.11 — Pagination

Learner local catalogue browsing:

```text
Drift/keyset or deterministic local pagination
```

Backend learner APIs use cursor/keyset only where a concrete remote collection API is approved.

Admin:

```text
page/size
```

Cursor sort must be deterministic and filter/sort-bound.

---

## 16. P0.12 — Flutter Application Contract

Normative parents:

```text
docs/specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md
docs/specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md
```

Sub-slices:

```text
P0.12.1  Feature/module map
P0.12.2  Riverpod/state ownership
P0.12.3  Navigation
P0.12.4  Drift ERD
P0.12.5  Installation/API client
P0.12.6  Localization/RTL
P0.12.7  ContentSyncCoordinator
P0.12.8  DownloadManager
P0.12.9  AssetResolver
P0.12.10 Audio/Shadowing
P0.12.11 Assessment
P0.12.12 Review Scheduler
P0.12.13 Storage/Retention
P0.12.14 Startup/Error/Recovery
P0.12.15 Adaptive/Responsive UI
P0.12.16 Material Design 3 system
P0.12.17 Learner Content State / Markers
P0.12.18 Goal-based onboarding + local learner intent
P0.12.19 Home next-action / goal progress IA
P0.12.20 Guided Learn / track / collection IA
P0.12.21 Learner-facing copy / empty-state policy
P0.12.22 Branded Material component qualification
```

Accepted/working detailed specs:

```text
docs/mobile/CAREERSPEAK_DRIFT_ERD.md
docs/mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md
docs/mobile/CAREERSPEAK_ADAPTIVE_UI.md
docs/mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md
docs/mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md
```

Material 3 rule:

```text
ONE PRODUCT
ONE MATERIAL 3 DESIGN SYSTEM
ONE TOKEN LAYER
ONE REUSABLE COMPONENT LAYER
MANY ADAPTIVE PRESENTATIONS
```

Learner marker rule:

```text
FAVORITE  = explicit user curation
LISTENED  = qualified audio consumption
COMPLETED = pedagogical completion
```

The three markers are independent durable local state and do not imply offline pinning.

Review rule:

```text
Due = ReviewSchedule.nextReviewAt <= now
Due != !Completed
```

---

## 17. P0.13 — Security / Installation

```text
/admin/** → ADMIN session
/api/v1/** → installation token
/internal/v1/tts/** → worker token
private RustFS → Backend-controlled delivery policy
```

Installation token is backend-issued and stored in Secure Storage, not Drift.

Freeze token longevity, revocation/re-registration semantics and bounded credential-specific 401 recovery.

---

## 18. P0.14 — Content Studio

One ADMIN performs:

```text
create/edit
bulk import
validate/localize
manage goals/tracks/collections/taxonomies
manage models/voices
prepare/review audio
publish
activate/deactivate
```

No workflow/RBAC platform required.

---

## 19. P0.15 — Integrated contracts

Before freeze:

```text
Product Requirements accepted
LearningGoal/LearningTrack/LearningCollection ownership accepted
complete PostgreSQL ERD
Flutter Drift ERD
root/pack manifest DTOs
localized payload DTOs
typed content DTOs
assessment DTOs
catalog/capability DTOs
learner OpenAPI
worker OpenAPI/internal contracts
error-code catalog
cross-system acceptance scenarios
Material component/token contract
learner marker/review repository contracts
```

Cross-module calls inside monolith use application/domain ports rather than internal HTTP.

---

## 20. P0.16 — Architecture Freeze

P0 closes when:

```text
product positioning and product hierarchy accepted
LearningGoal != Profession/CareerTrack accepted
LearningTrack curriculum semantics accepted
LearningCollection/LearningActivity semantics accepted
all context ownership accepted
system integration vocabulary accepted
PostgreSQL ERD accepted
Flutter ERD accepted
OpenAPI contracts accepted
TTS lease/recovery accepted
manifest/current/offline semantics accepted
review Due semantics accepted
adaptive UI contract accepted
Material Design 3 single-system contract accepted
learner-facing copy policy accepted
LISTENED/COMPLETED/FAVORITE semantics accepted
failure/recovery matrices accepted
implementation backlog generated
```

---

## 21. Definition of Ready

For every backend/domain slice:

```text
[ ] product purpose / learner outcome
[ ] ownership
[ ] entities/value objects
[ ] invariants/state machine
[ ] persistence/schema
[ ] PK/FK/unique/check/indexes
[ ] API/application contract
[ ] publication/version semantics
[ ] security actor
[ ] errors
[ ] idempotency
[ ] concurrency
[ ] failure/recovery
[ ] acceptance tests
```

For Flutter additionally:

```text
[ ] local learner intent ownership
[ ] onboarding/default/fallback behavior
[ ] CURRENT/offline READY semantics
[ ] Drift migration rules
[ ] sync/download state machines
[ ] real review scheduling semantics
[ ] adaptive layout qualification
[ ] Material 3 theme/token/component qualification
[ ] light/dark/system qualification
[ ] LISTENED/COMPLETED/FAVORITE persistence/filter qualification
[ ] learner-facing copy qualification
[ ] text scale/RTL qualification
```

---

## 22. Definition of Done for later implementation

```text
accepted product requirement
→ accepted domain contract
→ migration/schema
→ domain/application code
→ adapters
→ Material UI components
→ unit tests
→ integration tests
→ architecture tests
→ OpenAPI/contract qualification
→ adaptive/accessibility/product-copy qualification
→ CI green
```

This is the final P0 domain/contract roadmap for CareerSpeak v1 product/domain freeze.
