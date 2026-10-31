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

### Contract-closed findings

C1 closes these findings at the **wire-contract + Flutter production lifecycle** boundary:

```text
BGA-001 root manifest locale identity       CONTRACT CLOSED / C1 ACCEPTED
BGA-002 localized payload delivery          CONTRACT CLOSED / C1 ACCEPTED
BGA-017 tombstone retirement semantics      CONTRACT CLOSED / C1 ACCEPTED
```

This does **not** mean the backend service is implemented. Backend persistence/controllers/publication code still belongs to the later backend implementation stream.

### Open P0 blockers before backend learner-domain/schema freeze

```text
BGA-003 typed learning-content payloads
BGA-004 production assessment contract
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

C2 typed content + small catalogues          NEXT
C3 assessment                                PENDING
C4 atomic publication                        PENDING
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
chore(c1): finalize production gate and remove staging tooling
```

`Flutter Production Adapters` run `41183382458` completed successfully on the exact `fa85f424...` SHA with:

```text
format                         PASS
Drift v6 reproducibility       PASS
flutter analyze                PASS
full flutter test              PASS
```

The learner wire contract uses one locale-independent root and an exact immutable localized payload identity:

```text
(contentCode, contentType, contentRevision,
 locale, localizationRevision, checksum)
```

Localized payloads contain locale-owned support copy only. Canonical English content and shared audio/media remain owned by the canonical content revision.

Fallback policy is Backend-owned publication metadata. Flutter canonicalizes BCP-47 identities and applies the supplied ordered chain; it does not infer a base-language fallback from the requested locale. Missing locale content therefore degrades according to the published policy and ultimately to canonical English without inventing client policy.

The local production model keeps fallback policy and content retirement separate from per-run sync journal state:

```text
immutable root
    ├── packs / exact localization refs
    └── locale fallback rules
             ↓
        Drift CURRENT policy

root tombstone
    ↓
ContentRetirements
    ↓
permanent stable-business-identity guard
```

`SyncTombstones` remains execution evidence only. Permanent no-resurrection semantics are owned by `ContentRetirements`, so later journal cleanup cannot make a retired identity publishable again.

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
C2 typed content + small catalogues
 ↓
C3 assessment
 ↓
C4 atomic publication
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

Localization wire identity and lifecycle semantics are now contract-closed by C1, but their backend persistence design should still be derived together with C2/C4 publication/domain decisions rather than prematurely mirroring Flutter tables.

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
