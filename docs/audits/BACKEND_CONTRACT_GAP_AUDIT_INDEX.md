# Backend Contract Gap Audit Index

**Branch:** `feat/backend-contract-gap-audit`  
**Current audited baseline:** `main` @ `52bcda6ac580d13467c8cbfa87befb404820a1e9`

## Primary system architecture audit

See:

- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md`

The current P0 backend-contract blockers are:

```text
BGA-001 root manifest locale identity
BGA-002 localized payload delivery
BGA-003 typed learning-content payloads
BGA-004 production assessment contract
BGA-005 atomic backend publication snapshot
BGA-006 installation-token lifecycle / 401 recovery
```

The audit also records P1/P2 hardening for taxonomy, locale/voice catalogs, delivery scalability, media policy, ADMIN security, TTS concurrency, checksum semantics, rate limiting, observability, backup/restore and consumer-driven contract governance.

## Normative multi-locale requirement

The localization contract is now defined by:

- `docs/specification/CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md` v1.1

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

Recommended contract-completion order:

```text
C1 Root + localization identity
        ↓
C2 Typed learning content + catalogs
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
Content / ContentRevision
Localization
PracticeTest / Question
PublicationSnapshot
Taxonomy
SupportedLocale
learner-facing locale/voice catalogs
```

until the P0 contract blockers are resolved.

## Supplemental motion audit — out of backend readiness scope

Historical presentation findings remain in:

- `docs/audits/BACKEND_CONTRACT_GAP_AUDIT_MOTION_PLAN.md`

They are explicitly **not** part of backend contract readiness and must not block backend aggregate design once the backend P0 gaps above are closed.

Motion remains a Flutter presentation concern only.

## Architecture position

The current gaps do not justify microservices, Kafka/RabbitMQ, Redis, Keycloak, an API Gateway or server learner profiles.

The correct remediation is:

```text
complete contracts
→ freeze transactional invariants
→ derive backend aggregates
→ implement inside the modular monolith
→ qualify cross-system behavior
```
