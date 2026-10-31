# Backend Contract Gap Audit Index

**Branch:** `feat/backend-contract-gap-audit`

## Normative product decision

The product audit has been reduced to a simple MVP contract:

- `docs/specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`

Minimal product hierarchy:

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
LearningTrack = learner curriculum/path
```

No backend `LearningActivity`, recommendation engine, workflow engine or remote-UI model is required.

## Primary backend audit

See:

- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md`
- `docs/backend/C1_ROOT_LOCALIZATION_ACCEPTANCE.md`
- `docs/backend/C2_TYPED_CONTENT_CATALOG_CONTRACT.md`
- `docs/backend/C2_QUALIFICATION_LEDGER.md`
- `docs/backend/C3_ASSESSMENT_CONTRACT.md`

### Contract-closed findings

C1 closes these findings at the **wire-contract + Flutter production lifecycle** boundary:

```text
BGA-001 root manifest locale identity       CONTRACT CLOSED / C1 ACCEPTED
BGA-002 localized payload delivery          CONTRACT CLOSED / C1 ACCEPTED
BGA-017 tombstone retirement semantics      CONTRACT CLOSED / C1 ACCEPTED
```

C2 closes these findings at the **domain/wire-contract + Flutter production lifecycle** boundary:

```text
BGA-003 typed learning-content payloads      CONTRACT CLOSED / C2 ACCEPTED
BGA-007 taxonomy catalogue shapes            CONTRACT CLOSED / C2 ACCEPTED
BGA-008 locale / learner voice capability    CONTRACT CLOSED / C2 ACCEPTED
BGA-016 checksum canonicalization             CONTRACT CLOSED / C2 ACCEPTED
```

C3 closes this finding at the **assessment domain/wire-contract + Flutter production lifecycle** boundary:

```text
BGA-004 production assessment contract       CONTRACT CLOSED / C3 ACCEPTED
```

This does **not** mean the backend service is implemented. Backend persistence/controllers/publication code still belongs to the later backend implementation stream.

### Open P0 blockers before backend learner-domain/schema freeze

```text
BGA-005 atomic backend publication snapshot
BGA-006 installation-token lifecycle / 401 recovery
```

P1/P2 findings remain useful hardening input, but they SHALL NOT be promoted into architecture unless needed for MVP acceptance.

## Current remediation status

```text
C0P product contract freeze                  ACCEPTED
C1 root + localization                       ACCEPTED
├─ C1.1 locale-independent root identity     ACCEPTED
├─ C1.2 exact localization refs              ACCEPTED
├─ C1.3 localized wire transport             ACCEPTED
├─ C1.4 Drift localization persistence       ACCEPTED
├─ C1.5 Backend-owned fallback               ACCEPTED
├─ C1.6 retirement + recovery hardening      ACCEPTED
└─ C1.7 exact-SHA production qualification   ACCEPTED

C2 typed content + small catalogues          ACCEPTED
├─ C2.1 typed body contract                  ACCEPTED
├─ C2.2 product/capability catalogue shapes  ACCEPTED
├─ C2.3 production typed wire cutover        ACCEPTED
├─ C2.4 Drift typed persistence / schema v7  ACCEPTED
├─ C2.5 adversarial + catalogue fallback     ACCEPTED
└─ C2.6 exact-SHA production qualification   ACCEPTED

C3 assessment                                ACCEPTED
├─ C3.1 assessment revision contract         ACCEPTED
├─ C3.2 question revision contract           ACCEPTED
├─ C3.3 ordered exact question refs          ACCEPTED
├─ C3.4 deterministic scoring                ACCEPTED
├─ C3.5 production exact payload transport   ACCEPTED
├─ C3.6 Drift persistence / schema v8        ACCEPTED
├─ C3.7 offline/restart reproducibility      ACCEPTED
├─ C3.8 adversarial qualification            ACCEPTED
└─ C3.9 exact-SHA production qualification   ACCEPTED

C4 atomic publication                        NEXT
C5 installation/security                     PENDING
```

C1 production implementation commit:

```text
f7e24a3a2beda04ef39188a36788c613b7a15903
feat(c1): complete localization and retirement lifecycle
```

C1 cleaned exact-SHA production baseline:

```text
fa85f4240cdf96176098c64284fbd3a4629eb5ec
```

`Flutter Production Adapters` run `41183382458` completed successfully on that exact C1 SHA.

C2 typed persistence production commit:

```text
eba871d51edb8dc6d4fb5425e7a13374246e6a30
feat(c2): persist typed content revisions in Drift v7
```

C2 final clean qualification baseline:

```text
3c7b171c1123a33ec05e2ca6f4c92e6882727b4c
```

`Flutter Production Adapters` run `41197400808` completed successfully with:

```text
format                         PASS
Drift v7 reproducibility       PASS
flutter analyze                PASS
full flutter test              PASS
```

C3 final clean qualification baseline:

```text
49937959a1ce71322abec159dd36a41e72137bd0
ci(c3): qualify Drift v8 production baseline
```

`Flutter Production Adapters` run `41207314641` completed successfully with:

```text
format                         PASS
Drift v8 reproducibility       PASS
flutter analyze                PASS
full flutter test              PASS
```

`C3 Drift v8 Qualification` run `41207305741` completed successfully on the same exact SHA with targeted C3 lifecycle and full regression green.

The C2 contract freezes:

```text
VOCABULARY / INTERVIEW / TOPIC / PHRASE / SHADOWING typed bodies
LearningGoal → LearningTrack → LearningCollection shapes
Category / Level / Skill stable-code catalogues
SupportedLocale / learner-facing TtsVoice capability shapes
RFC 8785 + SHA-256 checksum canonicalization
safe deterministic fallback for inactive catalogue selections
```

The C3 contract additionally freezes:

```text
PracticeTest / PracticeTestRevision
Question / QuestionRevision
ordered exact TestQuestionRef
singleChoice MVP question body
deterministic integer scoring in basis points
exact immutable assessment payload transport
Drift v8 offline/restart revision reproducibility
```

Drift projections keep responsibilities separate:

```text
ContentCatalogReads            = C1 presentation projection
TypedContentReads              = C2 exact-revision typed projection
AssessmentQuestionReads        = C3 exact question revision projection
PracticeTestRevisionReads      = C3 exact test revision projection
PracticeTestQuestionRefs       = C3 ordered exact question references
```

The backend shall not mirror these Flutter tables directly. Backend aggregate/schema design remains deferred until C4 publication and C5 installation/security contracts are closed.

## Localization

`docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md` remains normative.

Accepted principles:

```text
Backend-owned SupportedLocale
locale-independent root
immutable localized payloads
BCP-47 support
Backend-configured fallback
canonical English/audio reuse
RTL readiness
```

## Remediation order

See:

- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_REMEDIATION_PLAN.md`

Current order:

```text
C0P simple product contract       ACCEPTED
 ↓
C1 root + localization            ACCEPTED
 ↓
C2 typed content + catalogues     ACCEPTED
 ↓
C3 assessment                     ACCEPTED
 ↓
C4 atomic publication             NEXT
 ↓
C5 installation/security
 ↓
backend schema freeze
```

TTS hardening may proceed in parallel.

## Backend readiness

Can proceed now:

```text
project/bootstrap
security-zone plumbing
PostgreSQL/Liquibase foundation
RustFS adapter foundation
TTS voice/model/job foundation
basic observability plumbing
```

Do not freeze final JPA schema yet for:

```text
LearningGoal / LearningTrack / LearningCollection
Content / ContentRevision
PracticeTest / Question
PublicationSnapshot
Taxonomy
SupportedLocale / learner-facing voice catalogue
```

C1, C2 and C3 contract semantics are accepted. Final persistence design should now be derived together with C4 atomic publication and C5 installation/security decisions rather than prematurely mirroring Flutter projections.

## Anti-overengineering position

The audit does not justify:

```text
microservices
Kafka/RabbitMQ
Redis
Keycloak
API Gateway
server learner profile
LearningActivity aggregate
workflow/rules engine
recommendation service
remote UI schema
```

Correct approach:

```text
freeze the small MVP contract
→ derive minimal aggregates
→ implement in the modular monolith
→ qualify real cross-system behavior
```
