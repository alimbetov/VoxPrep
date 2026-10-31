# CareerSpeak — P0 Domain & Contract Design Plan

**Document version:** 2.3  
**Status:** Final MVP domain/contract roadmap  
**Applies to:** CareerSpeak v1

Normative parent:

- [`../specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](../specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md)

---

## 1. Goal

Freeze only the domain ownership and cross-system contracts needed for MVP before production backend implementation.

Every backend context must define:

```text
ownership
entities/value objects
invariants
persistence/schema
API/application contract
security/errors
failure/recovery
acceptance tests
```

Do not create domain layers, tables or DTOs without a concrete MVP use case.

Persistence entities are derived from backend invariants; they are not mirrors of Flutter DTOs.

---

## 2. Shared system terminology

```text
Backend ACTIVE
= learner-deliverable/downloadable

Flutter CURRENT
= selected local metadata revision

Flutter offline READY
= complete locally verified offline bundle
```

---

## 3. Security actors

Exactly:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

No additional human/admin role hierarchy in MVP.

---

## 4. P0.0 — Common contracts

Freeze:

```text
stable business codes
UTC/ISO-8601 time
API versioning
DTO naming/nullability
error envelope
traceId
idempotency conventions
HTTP semantics
checksum canonicalization
```

---

## 5. P0.1 — Revision / publication / availability

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

Learner delivery:

```text
PUBLISHED + ACTIVE
```

Publication exposes one atomic learner snapshot. Failed publication must not expose a partial root.

---

## 6. P0.2 — Career taxonomy + learning navigation

Keep the model small.

### Career taxonomy

```text
Profession
CareerTrack
Seniority
Category
Level
Skill
```

### Learning navigation

```text
LearningGoal
LearningTrack
LearningCollection
```

Hierarchy:

```text
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
Content / PracticeTest
```

Rules:

```text
CareerTrack != LearningTrack
stable code is identity
sort order is explicit
active/inactive is backend-owned
Flutter does not invent mutable catalogues
```

No backend `LearningActivity`, workflow engine or curriculum graph is required in MVP.

---

## 7. P0.3 — Localization

Freeze:

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where applicable
BCP-47 identifiers
SupportedLocale catalog
fallback
locale pack variants
immutable localized payloads
RTL/mixed-direction rules
```

Root manifest identity is locale-independent.

---

## 8. P0.4 — Media / RustFS

Define:

```text
FileAsset
assetId/checksum/deliveryKey
ObjectStorage port
RustFS adapter
immutable object keys
media QC metadata
garbage collection
published media delivery policy
```

---

## 9. P0.5 — TTS

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

Flutter sees only learner-facing voice capability, not Worker/model-storage internals.

---

## 10. P0.6 — Interview

Define revisioned:

```text
InterviewQuestion
ModelAnswer
Category/Level/Skill mappings
Profession/CareerTrack/Seniority mappings where useful
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
Collocation where needed
Category/Level/Skill mappings
Localization
Audio roles
```

Published learner-visible vocabulary never mutates in place.

---

## 12. P0.8 — Topic / Phrase / Shadowing

Define only fields needed by the learner experience:

```text
Topic / TopicRevision
TopicSection
Phrase / PhraseCategory
display_text / tts_text
stable order/segment metadata
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

Published tests reference exact question revisions.

Assessment payload exposes deterministic score inputs and explanations. Complex recommendation logic is not required.

---

## 14. P0.10 — Manifest / content delivery

One locale-independent root:

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

Variants:

```text
canonical
locale:<BCP-47>
```

Freeze:

```text
tombstones
schema compatibility
asset descriptors
localized payload transport
Goal/Track/Collection catalogue delivery
```

MVP synchronization truth is manifest + exact immutable payloads/catalogues. Flutter browses local Drift data after sync.

---

## 15. P0.11 — Pagination

For MVP learner browsing:

```text
local deterministic pagination/query over Drift
```

Add remote cursor APIs only if a real server-side learner-browsing use case appears.

Admin may use page/size.

---

## 16. P0.12 — Flutter application contract

Normative parents:

```text
docs/specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md
docs/specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md
```

Required slices include:

```text
state ownership
navigation
Drift ERD
installation/API client
localization/RTL
sync/download/asset resolution
real audio
assessment
review scheduler
storage retention
startup/recovery
adaptive UI
Material 3
learner markers
3-step onboarding
Home current-action/current-goal hierarchy
Goal/Track/Collection discovery
learner-facing copy policy
```

Review rule:

```text
Due = nextReviewAt <= now
Due != !Completed
```

---

## 17. P0.13 — Security / installation

```text
/admin/** → ADMIN session
/api/v1/** → installation token
/internal/v1/tts/** → worker token
```

Freeze installation-token longevity, re-registration/revocation and bounded credential-specific 401 recovery.

---

## 18. P0.14 — Content Studio

One ADMIN performs:

```text
create/edit/import content
manage Goal/Track/Collection
manage taxonomy/localization
manage voices/models
prepare/review audio
publish
activate/deactivate
```

No workflow/RBAC platform required.

---

## 19. P0.15 — Integrated contracts

Before backend schema freeze:

```text
Product Requirements accepted
Goal/Track/Collection ownership accepted
PostgreSQL ERD accepted
Flutter Drift ERD accepted
root/pack manifest DTOs accepted
localized payload DTO accepted
typed content DTOs accepted
assessment DTOs accepted
catalog/capability DTOs accepted
learner OpenAPI accepted
worker OpenAPI accepted
failure/recovery scenarios accepted
```

---

## 20. P0.16 — Architecture freeze

P0 closes when:

```text
product hierarchy accepted
CareerTrack != LearningTrack accepted
all context ownership accepted
PostgreSQL ERD accepted
Flutter ERD accepted
OpenAPI contracts accepted
publication snapshot semantics accepted
locale-independent root accepted
real review Due semantics accepted
Material 3/adaptive UI accepted
learner-facing copy policy accepted
TTS lease/recovery accepted
implementation backlog generated
```

---

## 21. Definition of Ready

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

## 22. Explicit anti-overengineering rule

Do not introduce for MVP:

```text
LearningActivity aggregate
curriculum workflow engine
recommendation service
AI personalization
server learner profile
remote UI schema
generic EAV content model
microservices for domain separation
Kafka/RabbitMQ/Redis/Keycloak without measured need
```

---

## 23. Definition of Done

```text
accepted product requirement
→ accepted minimal domain contract
→ migration/schema
→ domain/application code
→ adapters
→ UI
→ tests
→ OpenAPI/contract qualification
→ CI green
```

This roadmap intentionally prefers a smaller correct model over a theoretically complete platform.
