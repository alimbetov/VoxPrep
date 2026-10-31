# CareerSpeak Backend Contract Gap Audit — System Architecture Review

**Status:** ACTIVE ARCHITECTURE AUDIT / BACKEND DESIGN INPUT  
**Audit branch:** `feat/backend-contract-gap-audit`  
**Current baseline:** `main` @ `52bcda6ac580d13467c8cbfa87befb404820a1e9`  
**Scope:** Flutter ↔ Backend, Admin ↔ Backend, Backend ↔ TTS Worker, Backend ↔ RustFS/CDN, contract governance and operational invariants.

## 1. Executive verdict

The project has a strong architectural foundation:

- system actors are explicitly separated (`ADMIN`, `FLUTTER INSTALLATION`, `TTS WORKER`);
- Flutter is offline-first and already uses immutable revision/checksum semantics;
- local `CURRENT`, offline `READY`, and backend `ACTIVE` have separate ownership and vocabulary;
- learner state is kept out of backend product-content truth in MVP;
- the TTS Worker is correctly isolated from PostgreSQL and RustFS credentials;
- the TTS queue uses lease ownership and `FOR UPDATE SKIP LOCKED` rather than introducing an unnecessary broker;
- P2 production adapters, Drift projection, restart recovery and real renderer qualification are already materially ahead of the backend implementation.

The main architectural warning is that **backend persistence/domain design should not be frozen yet for learner content/publication**.

There are six P0 contract blockers that should be closed first:

```text
BGA-001 root manifest locale identity
BGA-002 localized payload delivery
BGA-003 typed learning-content payloads
BGA-004 production assessment contract
BGA-005 atomic backend publication snapshot
BGA-006 installation-token lifecycle / 401 recovery
```

The TTS boundary is much closer to implementation-ready. Its remaining findings are hardening items, not a reason to redesign the Worker architecture.

## 2. Severity model

```text
P0 BLOCKER
= close before backend aggregate/schema freeze or production API implementation

P1 HIGH
= close during first backend implementation stream; leaving it open creates avoidable rework or production risk

P2 MEDIUM
= contract/operational hardening; may follow the first vertical slice but must be explicit before production acceptance

RISK ACCEPTANCE
= not necessarily a defect; the product must explicitly accept or reject the trade-off
```

## 3. Consolidated gap ledger

| ID | Severity | Area | Finding |
|---|---|---|---|
| BGA-001 | P0 | Manifest / localization | Locale-scoped root request conflicts with global immutable `contentVersion + checksum` identity |
| BGA-002 | P0 | Localization | Locale pack has no learner payload transport for translations/hints/explanations |
| BGA-003 | P0 | Content domain | Current canonical `ContentPayload` is too shallow for real Vocabulary/Interview/Topic/Phrase/Shadowing pedagogy |
| BGA-004 | P0 | Assessment | Practice tests/questions are not production-backed |
| BGA-005 | P0 | Publication | RESOLVED by frozen C4: atomic immutable `PublicationSnapshot`, monotonic `contentVersion`, security-independent identity, stable asset delivery identity, and fail-closed local projection |
| BGA-006 | P0 | Installation security | RESOLVED by frozen C5: stable `installationId`, fresh token on every cold bootstrap, centralized Bearer use, bounded single-flight 401 re-issuance, second 401 fail-closed |
| BGA-007 | P1 | Taxonomy | Category/Level/Skill are not first-class revisioned backend catalogs |
| BGA-008 | P1 | Capability catalogs | Supported locales and learner-facing TTS voice/accent availability are not backend-owned revisioned catalogs |
| BGA-009 | P1 | Learner delivery | Specification describes cursor collection APIs while implemented mobile architecture uses manifest sync + local Drift queries; source-of-truth path is ambiguous |
| BGA-010 | P1 | Delivery scalability | Initial/changed pack sync performs one canonical payload GET per content item; no pack-size or batching contract exists |
| BGA-011 | P1 / risk | Media security/cost | CDN delivery authorization model is not explicit |
| BGA-012 | P1 | Admin security | Fixed ADMIN account lacks a complete operational security contract |
| BGA-013 | P1 | TTS concurrency | Generation dedupe/current-audio-slot uniqueness is recommended but not frozen transactionally |
| BGA-014 | P1 | TTS OpenAPI | Piper config is checksum-sensitive raw bytes, but OpenAPI models it as an `application/json` string rather than an exact binary representation |
| BGA-015 | P2 / accepted MVP risk | Worker auth | Shared static Worker token means `workerId` is an audit label, not an independently authenticated identity; zero-downtime rotation is intentionally absent |
| BGA-016 | P1 | Integrity/versioning | Canonicalization scope for root/pack/content JSON checksums is not frozen |
| BGA-017 | P2 | Tombstones | Tombstone `revision` semantics are not explicit enough relative to business-identity retirement |
| BGA-018 | P1 | Reliability | Learner API does not freeze `429 / Retry-After` semantics even though Flutter already classifies 429 as retryable |
| BGA-019 | P1 | Observability | TTS observability is detailed; installation/content/publication observability is not |
| BGA-020 | P1 | Durability | PostgreSQL + RustFS backup/restore/reconciliation contract is missing |
| BGA-021 | P1 | Contract governance | No backend-side consumer-contract gate is yet defined for `learner-api-v1.yaml` + Flutter fixtures |
| BGA-022 | RISK ACCEPTANCE | Commercial boundary | Anonymous installation registration does not prove App Store / Play Store purchase entitlement |

---

# 4. Detailed findings

## BGA-001 — Root manifest locale identity is internally inconsistent

**Severity:** P0 BLOCKER

Current learner contract requires:

```text
GET /api/v1/content/manifest?locale=<translationLocale>
```

At the same time the architecture defines one global immutable root snapshot:

```text
contentVersion
+ checksum
+ exact pack set
```

Flutter correctly rejects this condition:

```text
same contentVersion
+ different manifest checksum
= CONTENT_VERSION_CHECKSUM_CONFLICT
```

This means the backend cannot safely return different root bodies/checksums for `ru`, `kk`, etc. under the same `contentVersion` without violating the current Flutter planner.

### Required decision

Choose exactly one model.

### Recommended model — locale-independent root

```text
RootContentManifest
= one global immutable snapshot
= contains canonical + all published locale pack refs
= checksum independent of the requester's selected translation locale
```

Flutter then selects/downloads only the locale variant it needs.

Under this model the current `locale` query parameter should either:

- be removed in the next contract revision; or
- be explicitly declared non-semantic for root identity until removed.

### Alternative model — locale-scoped root

If the backend intentionally returns different root pack sets per locale, then snapshot identity must become locale-scoped:

```text
(locale, contentVersion, checksum, etag)
```

That requires changing Flutter durable manifest state, ETag storage, planner invariants and locale-switch recovery.

**Recommendation:** do not choose the alternative for MVP. It adds state-space for little benefit.

### Acceptance

- changing `translationLocale` cannot create checksum conflict for the same immutable root;
- ETag scope is unambiguous;
- root checksum has one deterministic meaning;
- locale-switch offline recovery is tested.

---

## BGA-002 — Localized learner payload transport is missing

**Severity:** P0 BLOCKER

The product specification says backend-owned locale variants carry:

```text
translation
hint
explanation
localized title/description/support text
```

But learner API v1 exposes only the canonical content payload endpoint:

```text
GET /api/v1/content/{contentType}/{contentCode}/revisions/{revision}
```

and Flutter intentionally fetches no `ContentPayload` for non-canonical pack variants.

Therefore a `locale:ru` or `locale:kk` pack can currently exist as metadata, but there is no frozen wire contract that actually delivers the translated support data.

### Required contract

Add an exact immutable localization projection, for example:

```text
GET /api/v1/content/{type}/{code}/revisions/{revision}/localizations/{locale}
```

or an equivalent exact pack-localization payload contract.

Minimum identity:

```text
contentCode
contentType
canonicalRevision
locale
localizationRevision/checksum
```

Do not duplicate canonical English/audio in locale payloads.

### Acceptance

- `ru`/`kk` support text is delivered without duplicating canonical English/audio;
- regional fallback is deterministic (`ru-KZ -> ru -> en` where policy allows);
- locale payload survives offline/restart;
- locale replacement cannot mutate canonical content identity.

---

## BGA-003 — Canonical `ContentPayload` is not yet a real learning-domain contract

**Severity:** P0 BLOCKER

The current canonical payload/read model is intentionally generic:

```text
title
subtitle
description
category
level
minutes
hasAudio
```

That is sufficient for a production-backed catalog card and generic detail shell, but not for the actual CareerSpeak pedagogy.

The backend still needs typed immutable bodies for at least:

```text
VOCABULARY
INTERVIEW
TOPIC
PHRASE
SHADOWING
```

### Recommended design

Keep shared envelope fields, but add a discriminated typed body rather than a generic EAV/blob.

Conceptually:

```text
ContentPayload
├── identity / revision / checksum
├── shared presentation metadata
└── body
    ├── VocabularyBody
    ├── InterviewBody
    ├── TopicBody
    ├── PhraseBody
    └── ShadowingBody
```

Examples of domain fields that should be frozen before table design:

```text
VocabularyBody
- lemma / display form
- part-of-speech where required
- definition / canonical explanation
- examples

InterviewBody
- question/prompt
- model answer
- key points / guidance

TopicBody
- structured sections/body
- learning objectives where required

PhraseBody
- canonical English phrase
- usage/examples

ShadowingBody
- canonical transcript
- segment boundaries/order
- optional timing/alignment metadata if product requires it
```

Do not create one JPA entity that mirrors a future polymorphic REST DTO.

### Acceptance

- every product feature can render real learning material without hardcoded Flutter text;
- immutable revision/checksum covers the typed body;
- unsupported body schema fails closed;
- body design is domain-specific, not EAV.

---

## BGA-004 — PracticeTest / Assessment is not production-backed

**Severity:** P0 BLOCKER

Flutter already has test domain/session behavior, but production composition still has no backend-driven assessment payload path.

Required backend model should separate:

```text
PracticeTest
PracticeTestRevision
Question
QuestionRevision
TestQuestionRef (exact revision + order)
```

Wire projections should be separate from persistence entities.

Completed attempts must remain reproducible against exact immutable test/question revisions.

### Acceptance

- no production unavailable/mock assessment repository;
- exact test/question revision survives restart/offline;
- scoring is deterministic;
- later edits do not rewrite historical attempts.

---

## BGA-005 — Backend atomic publication snapshot contract is frozen

**Severity:** P0 BLOCKER — RESOLVED BY C4

**Normative contract:** `docs/backend/C4_ATOMIC_PUBLICATION_CONTRACT.md`.

Flutter assumes the learner root is an immutable, internally consistent publication barrier. C4 now freezes this as a first-class backend transaction boundary rather than a dynamically assembled view over mutable rows.

### Frozen publication invariant

A new learner root becomes visible only after all referenced objects are valid:

```text
content revisions immutable
pack revisions materialized
locale revisions materialized
referenced FileAssets READY/published where required
checksums calculated
cross-references validated
```

Backend then performs one atomic publication decision:

```text
allocate monotonic contentVersion
persist immutable PublicationSnapshot
persist exact pack refs/checksum
switch current learner-root pointer
COMMIT
```

`contentVersion` is never reused for different root content and a failed publication attempt never exposes a partial root.

### Security-independent publication identity

C4 explicitly separates publication truth from C5 installation security:

```text
PublicationSnapshot identity
!= installationId
!= installation token/session
```

The following MUST NOT affect `contentVersion`, root/pack/payload checksum, revision identity or ETag semantics:

```text
installationId
Authorization token
token issuance/expiry/rotation
request session
signed URL expiration
```

Credential rotation therefore cannot manufacture a different publication identity.

### Stable media identity

Immutable manifests carry stable media identity such as:

```text
assetId
checksumSha256
deliveryKey
```

They do not embed expiring signed URLs into publication identity. Authorization or short-lived delivery grants belong to C5/edge delivery and may change without changing the publication snapshot.

### Mid-sync credential recovery

If a client synchronizing publication `v42` receives a legitimate `401`, C5 may re-issue the installation credential and retry the **same exact immutable resource once**. A successful retry must still resolve the same exact revision/checksum selected by C4.

A token change does not start a new publication transaction and does not permit mixing `v42` and `v43` inside one local projection. Checksum/revision mismatch or repeated authentication failure fails closed; the previous committed local publication remains authoritative.

### Backend aggregate

```text
PublicationSnapshot
├── contentVersion
├── schemaVersion
├── publishedAt
├── checksum
├── packRevisionRefs[]
└── tombstones[]
```

The implementation may use different persistence tables, but these invariants are normative.

---

## BGA-006 — Installation token lifecycle and 401 recovery contract is frozen

**Severity:** P0 BLOCKER — RESOLVED BY C5

**Normative contract:** `docs/backend/C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`.

The learner security model no longer treats the installation token as a permanent or long-lived application secret.

### Frozen identity model

```text
installationId = stable installation identity
token          = temporary backend-issued credential
```

`installationId` survives normal application restarts and is the identity used to request a session credential. The token is replaceable runtime security state.

### Cold-bootstrap issuance

Every cold application bootstrap performs:

```text
preserve/get installationId
→ POST /api/v1/installations
→ backend issues a fresh token
→ TokenStore atomically replaces the previous token
→ centralized HTTP client uses the current Bearer token
```

A stored token MUST NOT be used as a reason to skip cold-start issuance. Business repositories/features do not own or manually propagate `Authorization`.

### 401 recovery

For an installation-credential rejection:

```text
request with current token
→ 401
→ single-flight token re-issuance for the same installationId
→ atomically replace TokenStore token
→ retry the original safe/idempotent request once
```

A second `401` fails closed. There is no infinite recovery loop.

Concurrent requests that observe the same rejected token must share one re-issuance operation rather than independently rotating credentials.

### Revocation and failure semantics

Backend may reject a disabled/revoked installation. In that case credential issuance/re-issuance fails closed; the client does not create a new installation identity to bypass revocation.

`POST /api/v1/installations` remains safe to retry at the transport boundary under its explicit idempotency contract and is rate-limited against abuse.

### Explicit non-goals

C5 intentionally does not introduce:

```text
learner login/password
refresh token
OAuth/OIDC identity platform
static token embedded in Flutter
business-layer Authorization handling
```

Token TTL/expiry is an implementation policy of the temporary credential and MUST NOT alter the frozen bootstrap/re-issuance lifecycle above.

---

## BGA-007 — Taxonomy must become a first-class backend catalog

**Severity:** P1 HIGH

`categoryCode/categoryLabel` and `levelCode/levelLabel` are currently embedded in content payloads. This is acceptable as a projection, not as the authoritative taxonomy model.

Backend needs revisionable catalogs for at least:

```text
Category
Level
Skill
```

Identity is the stable code; labels are localized presentation.

Catalog additions/deactivation must not require a Flutter release.

---

## BGA-008 — Locale and learner-facing voice availability need revisioned catalogs

**Severity:** P1 HIGH

Device preference remains local, but product capability is backend-owned.

Required projections:

```text
SupportedLocale
TtsVoice
```

Do not expose Worker-only storage/model internals to Flutter.

Flutter persists stable selected codes and applies deterministic fallback when a catalog choice disappears.

---

## BGA-009 — Avoid two competing learner-delivery protocols

**Severity:** P1 HIGH

The retention specification describes learner cursor APIs such as:

```text
GET /api/v1/vocabulary?...&cursor=...
```

but current production Flutter architecture obtains backend truth through:

```text
root manifest
→ pack manifest
→ exact immutable payloads
→ Drift
→ local cursor/query repository
```

The learner OpenAPI currently contains the sync/exact-revision path, not collection-list endpoints.

### Recommendation

For MVP, make the manifest/exact-payload pipeline the only mobile content synchronization source of truth.

Use local Drift for learner catalog browsing/filtering/pagination.

Add remote collection APIs later only for a concrete use case. They must never become deletion evidence or a second independently versioned truth source.

Update the specification to remove ambiguity.

---

## BGA-010 — Sync protocol is N+1 for canonical payloads

**Severity:** P1 HIGH for content growth

For every changed canonical pack Flutter currently fetches each referenced content payload individually.

This is correct and simple for a small MVP, but the contract has no stated limits for:

```text
contents per pack
pack manifest size
payload size
initial-install request count
```

### Recommendation

Keep exact single-content endpoints, but define operational limits now and reserve a batch/bundle path, e.g. compressed JSON/NDJSON or immutable pack payload bundle.

Do not wait until a 500-item pack makes first-install sync hundreds of HTTPS requests.

---

## BGA-011 — CDN authorization / entitlement boundary must be explicit

**Severity:** P1 HIGH / PRODUCT RISK

Flutter resolves:

```text
CAREERSPEAK_CDN_BASE_URL + deliveryKey
```

Normal learner media bypasses Spring Boot. That is a good scaling decision, but the authorization model is not frozen.

Choose explicitly:

```text
A. public immutable CDN objects
B. signed URLs/cookies
C. another edge authorization mechanism
```

Given the stated MVP goals (`no DRM`, no learner account, low-price paid app), **public immutable CDN objects are a reasonable MVP choice**, but it must be documented as a deliberate trade-off with rate/cost controls.

Do not imply that the installation token protects media bytes if the CDN does not validate it.

---

## BGA-012 — ADMIN fixed-account security needs operational rules

**Severity:** P1 HIGH

The fixed single ADMIN account is a good MVP simplification. It still needs:

- deployment-managed secret/password hash;
- strong password hashing policy;
- login rate limiting / brute-force protection;
- CSRF;
- `Secure`, `HttpOnly`, appropriate `SameSite` cookie;
- idle and absolute session timeout;
- password/secret rotation procedure;
- failed-login and privileged-publication audit events;
- no default credential baked into image/source.

No RBAC platform is needed.

---

## BGA-013 — TTS dedupe and logical audio-slot concurrency must be frozen

**Severity:** P1 HIGH

TTS requirements correctly say identical READY fingerprints SHOULD be reused and replacements must keep old READY audio until new output is READY.

What is still missing is one explicit transactional uniqueness model for concurrent regeneration requests.

Define a logical slot, for example:

```text
(contentRevisionId, audioRole, learnerVoice/accent selection policy)
```

and guarantee:

- at most one authoritative current FileAsset per logical slot;
- duplicate concurrent requests for the same generation fingerprint do not create competing current outputs;
- replacement pointer switch is atomic;
- old READY asset remains authoritative until replacement is READY.

---

## BGA-014 — TTS model-config OpenAPI does not model exact bytes correctly

**Severity:** P1 HIGH, small fix

Worker verifies `configSha256` against exact downloaded bytes.

The OpenAPI currently declares the config response as `application/json` with schema `type: string` and a description saying it is raw stored Piper JSON bytes.

That is ambiguous for generators/clients because a JSON `string` is not the same thing as an arbitrary exact JSON document byte sequence.

### Recommendation

Model the response explicitly as exact binary bytes (while retaining a suitable media type) so generated tooling cannot parse/re-serialize and accidentally invalidate the checksum.

---

## BGA-015 — Shared Worker token is an accepted MVP risk, not worker identity

**Severity:** P2 / RISK ACCEPTANCE

Current contract deliberately uses one deployment token. That is acceptable for MVP.

Document clearly:

```text
WORKER_TOKEN authenticates membership in the worker trust zone.
workerId is self-asserted operational identity/audit data.
leaseToken proves one job's temporary ownership.
```

A compromised shared Worker token compromises the entire Worker API trust zone. Zero-downtime dual-token rotation is explicitly deferred.

No redesign is required unless operational requirements change.

---

## BGA-016 — Freeze checksum canonicalization semantics

**Severity:** P1 HIGH

Assets have clear byte-level SHA-256 semantics. JSON domain objects are less explicit.

Backend must define what is hashed for:

```text
RootContentManifest.checksum
PackContentManifest.checksum
ContentPayload.checksum
localized payload checksum
assessment payload checksum
```

### Recommendation

Use one deterministic canonicalization/fingerprint service per schema family with golden vectors.

The checksum must not depend on:

```text
JSON property order produced by a serializer
whitespace
server locale/timezone formatting
non-semantic database row order
```

Whether Flutter recomputes every JSON checksum or treats it as a backend immutable identity is a separate implementation decision; backend publication must still guarantee deterministic checksum generation.

---

## BGA-017 — Tombstone revision meaning needs one sentence of normative semantics

**Severity:** P2 MEDIUM

Flutter retires content by stable business identity `(contentCode, contentType)`, while the tombstone also carries `revision`.

Freeze whether `revision` means:

```text
last learner-deliverable revision being retired
```

rather than "delete only this exact local revision".

This matters for republish/reactivation and audit history.

---

## BGA-018 — Learner API rate-limit contract should match Flutter retry behavior

**Severity:** P1 HIGH

Flutter already treats HTTP 429 as retryable, but learner OpenAPI does not define 429 on registration/manifest/payload endpoints and no `Retry-After` behavior is frozen.

Add:

- 429 response contract;
- optional/required `Retry-After` policy;
- bounded retry guidance;
- registration-specific abuse limits.

Flutter should eventually honor server retry hints instead of only fixed exponential delay.

---

## BGA-019 — Observability contract is asymmetric

**Severity:** P1 HIGH

TTS has a strong metric/logging plan. Learner delivery/publication does not yet have an equivalent baseline.

Recommended metrics/events:

```text
installation_register_total
installation_auth_rejected_total
manifest_requests_total
manifest_304_total
manifest_publish_total
manifest_publish_failed_total
content_payload_requests_total
publication_content_version
publication_duration_seconds
asset_delivery_metadata_errors_total
admin_login_failed_total
```

Every API error should correlate through `traceId` without logging credentials.

---

## BGA-020 — Database/object-store recovery contract is missing

**Severity:** P1 HIGH

PostgreSQL is business truth; RustFS stores bytes. Production recovery must define what happens when they are restored independently.

Required invariants:

- no READY FileAsset may remain authoritative if its object is missing after restore;
- orphan RustFS objects are non-authoritative and reclaimable;
- restore/reconciliation can rebuild consistency without rewriting immutable IDs;
- backup retention, RPO and RTO are documented;
- publication root never references a known-missing required asset.

A periodic reconciliation job/admin command is sufficient for MVP; no distributed storage transaction is required.

---

## BGA-021 — Add consumer-driven contract governance before backend implementation

**Severity:** P1 HIGH

`learner-api-v1.yaml` is already a useful frozen artifact, and Flutter has fixtures/decoder tests. Backend implementation must be prevented from drifting away from it.

Required CI gate:

```text
OpenAPI schema
+ backend controller contract tests
+ shared representative fixtures
+ Flutter decoder/mapper fixture tests
```

Breaking changes require explicit contract/schema versioning rather than silent field mutation.

Recommended rule:

```text
No backend learner API PR is merge-ready if it breaks current Flutter contract fixtures without an intentional versioned migration.
```

---

## BGA-022 — Anonymous installation does not prove purchase entitlement

**Severity:** RISK ACCEPTANCE

The current model intentionally has no learner account and anonymous registration creates backend-issued installation tokens.

Therefore anyone able to reproduce the registration call can potentially obtain a valid learner API token; the backend has no App Store / Play Store receipt proof in the current contract.

This is not automatically a defect because CareerSpeak explicitly rejects heavy DRM/account infrastructure for MVP.

The product decision must be recorded:

```text
MVP accepts distribution/storefront as the commercial gate
and does not enforce server-side purchase entitlement
```

If abuse becomes material later, add store receipt validation/app attestation as a separate security feature, not by contaminating learner progress identity.

---

# 5. Backend design freeze decision

## Can implementation start now?

### Yes — with limited scope

The following can proceed with low architectural risk:

```text
project/bootstrap infrastructure
Spring Security zone separation
PostgreSQL/Liquibase foundation
RustFS adapter foundation
TTS voice/model/job persistence and Worker API implementation
observability/security plumbing
```

### Do not freeze yet

Do not freeze final JPA/domain schema for:

```text
Content
ContentRevision
Localization
PublicationSnapshot
PracticeTest / Question
Taxonomy
learner-facing locale/voice catalogs
```

until BGA-001 through BGA-006 are resolved and BGA-007/BGA-008 shapes are agreed.

# 6. Recommended target architecture

```text
                         BACKEND
                            │
       ┌────────────────────┼────────────────────┐
       │                    │                    │
       ▼                    ▼                    ▼
 Content Authoring      Assessment          TTS Catalog/Jobs
       │                    │                    │
       └──────────────┬─────┴──────────────┬─────┘
                      ▼                    ▼
              Publication Snapshot     FileAsset
                      │                    │
                      ├──── exact pack refs
                      ├──── tombstones
                      ├──── catalog refs
                      └──── contentVersion/checksum
                      │
                      ▼
                 Learner API
                      │
          root / packs / exact payloads
                      │
                      ▼
                    Flutter
                      │
                    Drift
                      │
                local repositories
```

Side channels remain explicit:

```text
ADMIN Browser -> /admin/** session/CSRF
TTS Worker    -> /internal/v1/tts/** worker token + lease
Flutter       -> /api/v1/** installation token
Flutter media -> CDN/edge -> published RustFS origin
```

# 7. Architectural conclusion

The project should **not** be converted into microservices, Kafka/Rabbit infrastructure, Redis caching, Keycloak, or server-side learner profiles to close these gaps.

The correct next move is contract completion inside the existing modular-monolith architecture.

The largest current risk is not infrastructure scalability. It is freezing backend tables before the product contracts for localization, typed learning bodies, assessment and publication snapshots are complete.

That is cheaper to fix now than after JPA entities, Liquibase migrations, Admin forms and Flutter decoders all depend on the wrong shape.