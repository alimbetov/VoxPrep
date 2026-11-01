# Flutter ↔ Backend Contract Gap Resolution — 2026-11-01

**Status:** normative reconciliation of the earlier gap audit for backend design handoff.  
**Parent:** `BACKEND_DESIGN_BASELINE_V1.md`

The earlier `FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md` was intentionally conservative and predates several frozen Flutter contracts. This ledger states what is now resolved, what becomes a backend implementation/design requirement, and what is explicitly deferred.

## Verdict

There are **no remaining Flutter consumer-contract P0 blockers that prevent backend domain/schema design**.

Backend design may start now, provided it preserves the frozen contracts in `BACKEND_DESIGN_BASELINE_V1.md`.

## Reconciled ledger

| ID | Current state | Backend consequence |
|---|---|---|
| BGA-001 root manifest locale identity | **RESOLVED** | Root is locale-independent; locale changes do not create a different root identity. |
| BGA-002 localized payload delivery | **RESOLVED** | Exact localization endpoint is frozen by Flutter: content identity + canonical revision + locale + localization revision + checksum. |
| BGA-003 typed learning content | **RESOLVED FOR DESIGN** | C2 freezes typed-content direction; backend must implement typed immutable revision bodies, not EAV. |
| BGA-004 assessment production contract | **RESOLVED** | Exact PracticeTestRevision and QuestionRevision APIs are implemented in Flutter gateways and C3 contract. |
| BGA-005 atomic publication | **RESOLVED** | C4 is normative; design PublicationSnapshot as transactional release barrier. |
| BGA-006 installation credential lifecycle | **RESOLVED** | C5 is normative; random installationId + fresh token cold bootstrap + bounded single-flight 401 recovery. |
| BGA-007 taxonomy catalogs | **BACKEND DESIGN REQUIREMENT** | Model revisionable backend taxonomy/catalogue truth. Universal catalogue contract is the learner projection boundary. |
| BGA-008 locale/voice capabilities | **BACKEND DESIGN REQUIREMENT** | Locale capability is backend-owned; voice/model capability belongs to TTS/backend catalogs. |
| BGA-009 competing learner delivery protocols | **RESOLVED** | MVP learner truth path is manifest → exact immutable refs/payloads → local Drift queries. Do not add parallel browse APIs as source of truth. |
| BGA-010 one-payload-per-content scalability | **NON-BLOCKING MVP OPTIMIZATION** | Preserve exact endpoint semantics first. Batch transport may be versioned later without changing immutable identity. |
| BGA-011 media security/cost | **RESOLVED FOR V1** | Flutter uses authenticated backend media streaming only; RustFS/storage URLs are private. |
| BGA-012 Admin security | **BACKEND DESIGN REQUIREMENT** | Keep `/admin/**` separate from installation auth. Operational hardening belongs to backend implementation acceptance. |
| BGA-013 TTS dedupe/current-audio uniqueness | **BACKEND DESIGN REQUIREMENT** | Freeze transactional uniqueness/idempotency when designing `tts_job` and final FileAsset association. |
| BGA-014 TTS OpenAPI exact model/config bytes | **BACKEND CONTRACT OUTPUT** | Correct exact binary/config representation during backend/worker contract finalization. |
| BGA-015 shared Worker token | **ACCEPTED MVP RISK** | Worker identity is audit label under shared secret in v1 unless separately upgraded. |
| BGA-016 checksum canonicalization | **RESOLVED FOR LEARNER CONTRACT** | Flutter canonicalization/checksum validation is authoritative consumer behavior; backend must implement matching deterministic canonicalization. |
| BGA-017 tombstone semantics | **BACKEND DESIGN REQUIREMENT** | Tombstone is explicit publication evidence for business identity retirement/deactivation; absence is never deletion evidence. |
| BGA-018 429 / Retry-After | **BACKEND API REQUIREMENT** | Implement stable 429 behavior and Retry-After where applicable. |
| BGA-019 observability | **BACKEND IMPLEMENTATION REQUIREMENT** | Add traceId and metrics/audit for publication, installation, media and TTS without secret leakage. |
| BGA-020 backup/restore/reconciliation | **OPERATIONS REQUIREMENT** | Design PostgreSQL + RustFS backup/reconciliation before production acceptance; not a blocker for domain schema design. |
| BGA-021 consumer-contract gate | **NEXT BACKEND DESIGN OUTPUT** | Produce `learner-api-v1.yaml`/producer fixtures from the frozen baseline and run contract qualification against Flutter fixtures. |
| BGA-022 purchase entitlement | **ACCEPTED MVP PRODUCT RISK** | Anonymous installation identity does not prove store purchase. Do not silently turn it into learner identity. |

## What is frozen before backend table design

```text
Vertical → Goal → Track → Collection
exact immutable revision identity
PublicationSnapshot atomicity
locale-independent root
localized exact revision identity
assessment exact revision graph
installation random identity + rotating credential
backend-authorized media stream
RustFS private boundary
local learner progress ownership
fail-closed corruption/mismatch behavior
```

## What backend is free to design internally

Backend may choose internal normalized table shapes, JPA mappings, indexes, partitioning and package names as long as external invariants remain unchanged.

In particular, Flutter Drift table names and shapes are **not** a backend database specification.

## Mandatory design outputs before coding controllers deeply

1. module dependency diagram;
2. PostgreSQL logical schema/ER model;
3. immutable revision and publication transaction model;
4. installation token verifier/storage policy;
5. FileAsset/RustFS storage model;
6. learner OpenAPI v1 generated from frozen endpoints;
7. TTS job uniqueness/lease transaction rules;
8. producer contract fixtures matching Flutter decoders;
9. migration strategy and initial seed/reference catalog strategy.

## Final handoff statement

```text
Flutter contracts: sufficient for backend design
Backend domain/schema design: GO
Backend implementation: separate next stream
Cross-system acceptance: required before release
```
