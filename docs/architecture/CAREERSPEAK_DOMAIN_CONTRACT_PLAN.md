# CareerSpeak — P0 Domain & Contract Design Plan

**Document version:** 2.1  
**Status:** Final P0 design roadmap  
**Applies to:** CareerSpeak v0.9+

---

## 1. Goal

P0 freezes domain ownership and cross-system contracts before production implementation.

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

---

## 6. P0.2 — Profession / Catalog

Define:

```text
Profession
CareerTrack
Specialization where needed
Seniority
Category
Tag
Skill taxonomy
```

Use stable business codes and cursor pagination.

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
```

UI strings are Flutter-owned ARB resources; learner content translations come from Backend.

---

## 8. P0.4 — Media / RustFS

Define:

```text
FileAsset
assetId/checksum/deliveryKey
ObjectStorage port
RustFS adapter
private/public rules
presigned GET/PUT
immutable object keys
media QC metadata
garbage collection
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

---

## 10. P0.6 — Interview

Define revisioned:

```text
InterviewQuestion
ModelAnswer
Category
Profession/CareerTrack/Seniority/Skill mappings
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

---

## 14. P0.10 — Manifest / Content Delivery

Freeze one root:

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

Define tombstones, schema compatibility and asset descriptors.

---

## 15. P0.11 — Pagination

Learner API:

```text
cursor/keyset
```

Admin:

```text
page/size
```

Cursor sort must be deterministic and filter/sort-bound.

---

## 16. P0.12 — Flutter Application Contract

Normative parent:

```text
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

---

## 17. P0.13 — Security / Installation

```text
/admin/** → ADMIN session
/api/v1/** → installation token
/internal/v1/tts/** → worker token
private RustFS → presigned URL
```

Installation token is backend-issued and stored in Secure Storage, not Drift.

---

## 18. P0.14 — Content Studio

One ADMIN performs:

```text
create/edit
bulk import
validate/localize
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
complete PostgreSQL ERD
Flutter Drift ERD
root/pack manifest DTOs
learner OpenAPI
worker OpenAPI/internal contracts
error-code catalog
cross-system acceptance scenarios
Material component/token contract
learner marker repository/filter contract
```

Cross-module calls inside monolith use application/domain ports rather than internal HTTP.

---

## 20. P0.16 — Architecture Freeze

P0 closes when:

```text
all context ownership accepted
system integration vocabulary accepted
PostgreSQL ERD accepted
Flutter ERD accepted
OpenAPI contracts accepted
TTS lease/recovery accepted
manifest/current/offline semantics accepted
adaptive UI contract accepted
Material Design 3 single-system contract accepted
LISTENED/COMPLETED/FAVORITE semantics accepted
failure/recovery matrices accepted
implementation backlog generated
```

---

## 21. Definition of Ready

```text
[ ] ownership
[ ] entities/value objects
[ ] invariants/state machine
[ ] persistence/schema
[ ] PK/FK/unique/check/indexes
[ ] API/application contract
[ ] security actor
[ ] errors
[ ] idempotency
[ ] concurrency
[ ] failure/recovery
[ ] acceptance tests
```

For Flutter additionally:

```text
[ ] CURRENT/offline READY semantics
[ ] Drift migration rules
[ ] sync/download state machines
[ ] adaptive layout qualification
[ ] Material 3 theme/token/component qualification
[ ] light/dark/system qualification
[ ] LISTENED/COMPLETED/FAVORITE persistence/filter qualification
[ ] text scale/RTL qualification
```

---

## 22. Definition of Done for later implementation

```text
accepted spec
→ migration/schema
→ domain/application code
→ adapters
→ Material UI components
→ unit tests
→ integration tests
→ architecture tests
→ OpenAPI/contract qualification
→ adaptive/accessibility qualification
→ CI green
```

This is the final P0 domain/contract roadmap for CareerSpeak v0.9.