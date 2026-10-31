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

P0 blockers remain:

```text
BGA-001 root manifest locale identity
BGA-002 localized payload delivery
BGA-003 typed learning-content payloads
BGA-004 production assessment contract
BGA-005 atomic backend publication snapshot
BGA-006 installation-token lifecycle / 401 recovery
```

P1/P2 findings remain useful hardening input, but they SHALL NOT be promoted into architecture unless needed for MVP acceptance.

## Current remediation status

```text
C0P product contract freeze                  ACCEPTED
C1.1 locale-independent root identity        IMPLEMENTED
C1.2 locale-pack exact localization refs     IMPLEMENTED
C1.3 exact localized payload wire transport  IMPLEMENTED
C1.4 Drift localization persistence          IMPLEMENTED
C1.5 Backend-owned deterministic fallback    IMPLEMENTED / QUALIFYING
C1.6 retirement + offline/restart hardening  IMPLEMENTED / QUALIFYING
C1.7 exact-SHA green CI                      REQUIRED

C2 typed content + small catalogues          PENDING
C3 assessment                                PENDING
C4 atomic publication                        PENDING
C5 installation/security                     PENDING
```

The learner wire contract uses one locale-independent root and an exact immutable localized payload identity:

```text
(contentCode, contentType, contentRevision,
 locale, localizationRevision, checksum)
```

Localized payloads contain locale-owned support copy only. Canonical English content and shared audio/media remain owned by the canonical content revision.

Fallback policy is Backend-owned publication metadata. Flutter canonicalizes BCP-47 identities and applies the supplied ordered chain; it does not infer a base-language fallback from the requested locale. Missing policy or missing locale content therefore degrades safely to canonical English instead of inventing client policy.

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

C1 is not accepted until the final Drift v6 baseline, Backend-owned fallback persistence, locale repair, file-backed offline/restart behavior, and retirement acceptance all pass on one exact branch SHA through the complete production-adapters workflow.

## Localization

`docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md` remains normative.

Required principles:

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
C0P simple product contract
 ↓
C1 root + localization
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
Localization
PracticeTest / Question
PublicationSnapshot
Taxonomy
SupportedLocale / learner-facing voice catalogue
```

until the relevant P0 contracts are closed.

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
