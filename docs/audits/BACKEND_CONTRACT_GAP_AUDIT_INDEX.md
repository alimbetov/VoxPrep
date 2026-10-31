# Backend Contract Gap Audit Index

**Branch:** `feat/backend-contract-gap-audit`  
**Audited baseline:** `main` @ `52bcda6ac580d13467c8cbfa87befb404820a1e9`

## Normative product decision

The marketing/design critique has now been converted into a normative product contract:

- `docs/specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`

This contract is a prerequisite for final learning/content aggregate and schema freeze.

Mandatory product hierarchy:

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

Mandatory distinction:

```text
Profession / CareerTrack
= career taxonomy

LearningGoal / LearningTrack
= learner outcome + curriculum path
```

The product contract also freezes goal-based onboarding, local learner intent, Home next-action hierarchy, real `Due` review semantics and learner-facing copy policy.

## Primary system architecture audit

See:

- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md`

The original P0 backend-contract blockers are:

```text
BGA-001 root manifest locale identity
BGA-002 localized payload delivery
BGA-003 typed learning-content payloads
BGA-004 production assessment contract
BGA-005 atomic backend publication snapshot
BGA-006 installation-token lifecycle / 401 recovery
```

The audit also records P1/P2 hardening for taxonomy, locale/voice catalogs, delivery scalability, media policy, ADMIN security, TTS concurrency, checksum semantics, rate limiting, observability, backup/restore and consumer-driven contract governance.

The product freeze adds a prerequisite gate before backend content/schema freeze; it does not replace the BGA ledger.

## Normative multi-locale requirement

The localization contract is defined by:

- `docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`

The system must be designed for arbitrary supported BCP-47 locale identifiers rather than a closed `ru|kk` runtime model.

Required product capability direction:

```text
Tier 0:
en / ru / kk

Tier 1:
uz / tr / ky / uk

Tier 2:
es / pt-BR / fr / de

Tier 3:
ar / ur / hi / bn / id / vi
```

Tier membership is rollout policy only and MUST NOT become protocol logic.

The locale contract requires:

```text
Backend-owned SupportedLocale catalog
locale-independent root manifest identity
same contentVersion => same root checksum
immutable localized payload delivery
configured fallback chains
canonical English/audio reuse
RTL readiness
no fixed per-language DB columns
no hardcoded locale ∈ {ru, kk} assumption
```

Therefore `BGA-001`, `BGA-002` and the locale-catalog portion of `BGA-008` are mandatory contract-freeze gates, not optional future enhancements.

## Remediation roadmap

See:

- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_REMEDIATION_PLAN.md`

Current contract-completion order:

```text
C0P Product contract freeze
        ↓
C1 Root + localization identity
        ↓
C2 Typed learning content + product/taxonomy/capability catalogs
        ↓
C3 Assessment
        ↓
C4 Publication snapshot
        ↓
C5 Installation / external security
        ↓
Backend aggregate/schema freeze
        ↓
Backend implementation
```

C1 is complete only when arbitrary BCP-47 locale variants, localized payload transport, deterministic fallback and root identity semantics are frozen.

C2 is complete only when typed content plus `LearningGoal`, `LearningTrack`, `LearningCollection`, taxonomy and capability ownership are frozen.

TTS contract hardening (`C6`) may proceed in parallel because the Worker-facing boundary is already comparatively mature.

Production operability / contract governance (`C7`) must be complete before production acceptance.

## Backend readiness decision

Implementation may already proceed for:

```text
project/bootstrap infrastructure
security-zone plumbing
PostgreSQL/Liquibase foundation
RustFS adapter foundation
TTS voice/model/job foundation
observability plumbing
```

Do **not** freeze final domain/JPA schema yet for:

```text
LearningGoal / LearningTrack / LearningCollection
Content / ContentRevision
Localization
PracticeTest / Question
PublicationSnapshot
Taxonomy
SupportedLocale
learner-facing locale/voice catalogs
```

until the relevant product/P0 contract gates are resolved.

## Supplemental presentation audit

The design/marketing source review remains in:

- `docs/product/MARKETING_DESIGN_EXPERT_PANEL_REVIEW.md`

Its accepted product decisions are now promoted into `CAREERSPEAK_PRODUCT_REQUIREMENTS.md`; unresolved visual experimentation remains non-normative until explicitly promoted.

Historical motion findings remain in:

- `docs/audits/BACKEND_CONTRACT_GAP_AUDIT_MOTION_PLAN.md`

Motion remains a Flutter presentation concern and does not block backend aggregate design once the normative product/backend P0 gates are closed.

## Architecture position

The current gaps do not justify microservices, Kafka/RabbitMQ, Redis, Keycloak, an API Gateway or server learner profiles.

The correct remediation is:

```text
freeze product intent
→ complete contracts
→ freeze transactional invariants
→ derive backend aggregates
→ implement inside the modular monolith
→ qualify cross-system behavior
```
