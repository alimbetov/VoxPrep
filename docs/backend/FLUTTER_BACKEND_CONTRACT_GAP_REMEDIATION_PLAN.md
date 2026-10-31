# CareerSpeak Backend Contract Gap Remediation Plan

**Status:** PLANNED / AUDIT FOLLOW-UP  
**Normative product parent:** `docs/specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`

## 1. Goal

Close only the contract gaps required before backend aggregate/schema freeze.

Rule:

```text
smallest correct product contract
→ smallest correct backend domain
→ schema
→ implementation
→ cross-system acceptance
```

Do not add infrastructure or domain abstractions without a concrete MVP use case.

---

# C0P — Product contract freeze

Freeze:

```text
career/interview-first positioning
Goal → Track → Collection → Content/Test
CareerTrack != LearningTrack
3-step onboarding ownership
local learner state ownership
real Due semantics
learner-facing copy policy
```

No backend `LearningActivity`, workflow engine or recommendation service is needed.

---

# C1 — Root + localization

Close:

```text
BGA-001 root locale identity
BGA-002 localized payload transport
BGA-017 tombstone semantics
```

Decision:

```text
one locale-independent root
one contentVersion
one deterministic checksum/ETag identity
root references canonical + locale pack revisions
```

Define immutable localized payload delivery and deterministic fallback.

---

# C2 — Typed content + small product catalogues

Close:

```text
BGA-003 typed content body
BGA-007 taxonomy
BGA-008 locale/voice capability projection
BGA-016 checksum canonicalization
```

Freeze typed bodies:

```text
VocabularyBody
InterviewBody
TopicBody
PhraseBody
ShadowingBody
```

Freeze only these product catalogues:

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

`LearningCollection` references ordered `contentRefs[]` / `practiceTestRefs[]`; no separate activity aggregate.

---

# C3 — Assessment

Close `BGA-004`.

Minimum domain:

```text
PracticeTest
PracticeTestRevision
Question
QuestionRevision
TestQuestionRef
```

Wire contract includes deterministic answers/scoring inputs/explanations and stable skill codes where needed.

No recommendation engine is required.

---

# C4 — Atomic publication

Close:

```text
BGA-005 atomic publication
BGA-009 delivery-path ambiguity
BGA-010 sync scalability limits
```

Freeze one immutable `PublicationSnapshot` / equivalent transaction boundary.

MVP truth path:

```text
Backend: manifest + exact immutable payloads/catalogues
Flutter: Drift browsing/search/pagination
```

Add batch/bundle delivery only if measured pack size makes single-payload requests a real problem.

---

# C5 — Installation + external security

Close:

```text
BGA-006 installation token lifecycle
BGA-011 media policy
BGA-012 ADMIN security
BGA-018 rate limiting
BGA-022 entitlement risk decision
```

Freeze:

```text
token longevity
re-registration/revocation
one bounded 401 recovery
429/Retry-After
ADMIN cookie/CSRF/rate-limit/rotation basics
public-vs-signed media decision
```

Do not add user accounts or an identity platform for these MVP concerns.

---

# C6 — TTS hardening

May proceed in parallel.

Close:

```text
BGA-013 logical current-audio uniqueness
BGA-014 exact model-config byte contract
BGA-015 Worker-token risk documentation
```

Keep existing Worker architecture.

---

# C7 — Production operability

Before production acceptance define:

```text
basic observability
PostgreSQL/RustFS backup + restore
orphan/missing-object reconciliation
consumer contract CI
```

No distributed transaction or new platform component is required.

---

# Backend implementation order

```text
B1  project/security/Liquibase/RustFS foundation
B2  installation token domain
B3  taxonomy + locale + voice catalogues
B4  Goal + Track + Collection
B5  typed content revisions
B6  localization
B7  assessment
B8  publication snapshot + manifests
B9  learner exact-payload/catalog APIs
B10 TTS backend domain
B11 simple Admin Content Studio
B12 cross-system acceptance
```

---

# Acceptance gates

## G0 Product

```text
Goal → Track → Collection → Content/Test accepted
CareerTrack != LearningTrack
no unnecessary LearningActivity/workflow/recommendation layer
```

## G1 Contract

```text
G0 PASS
BGA-001..006 closed
BGA-007/008 shapes agreed
```

## G2 Backend domain

```text
ownership documented
schema derived from domain, not Flutter DTOs
immutable revision constraints documented
publication transaction documented
```

## G3 Learner API

Prove:

```text
installation
root/304
locale switch/localized payload
Goal/Track/Collection delivery
typed content
assessment
tombstone
offline/restart
401 recovery
429 bounded retry
```

## G4 Publication

Prove atomic root switch and never-reused `contentVersion`.

## G5 TTS

Use existing real Backend ↔ Worker acceptance plus current-audio uniqueness.

## G6 Recovery

Restore PostgreSQL + RustFS into a clean environment and prove learner root/assets remain valid or fail closed.

---

# Explicit anti-overengineering rule

Do not solve these gaps with:

```text
microservices
Kafka/RabbitMQ
Redis
Keycloak
API Gateway
server learner profiles
LearningActivity aggregate
workflow/rules engine
recommendation service
remote UI schema
generic EAV content table
one giant Content entity mirroring Flutter DTOs
```

The modular monolith remains the correct MVP architecture.
