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
