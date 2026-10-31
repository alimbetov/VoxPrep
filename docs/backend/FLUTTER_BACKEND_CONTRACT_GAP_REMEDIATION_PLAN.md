# CareerSpeak Backend Contract Gap Remediation Plan

**Status:** PLANNED / AUDIT FOLLOW-UP  
**Baseline:** `main` @ `52bcda6ac580d13467c8cbfa87befb404820a1e9`  
**Primary audit:** `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md`

## 1. Goal

Close backend/system contract ambiguities before final backend aggregate/schema freeze, while preserving the already accepted Flutter production/offline foundation and the mature TTS Worker boundary.

This roadmap deliberately avoids architecture inflation.

No new microservice, broker, Redis layer, API Gateway or identity platform is required to close the current gaps.

## 2. Priority rule

```text
P0 contract contradiction / missing domain shape
        ↓
contract freeze
        ↓
backend aggregate + persistence design
        ↓
backend implementation
        ↓
real cross-system acceptance
```

Do not implement database tables merely to "make progress" while a P0 wire/domain decision remains unresolved.

---

# C0 — Baseline synchronization and audit freeze

**Status:** this audit branch

Deliverables:

- current-main baseline recorded;
- backend audit separated from UI motion roadmap;
- one severity ledger (`BGA-001..BGA-022`);
- explicit P0 blockers;
- exact remediation order.

Acceptance:

- audit branch contains current `main` plus audit documents;
- no production code changed by the audit itself.

---

# C1 — Root manifest + localization identity freeze

**Priority:** P0

Closes:

```text
BGA-001 root locale identity
BGA-002 localized payload transport
BGA-017 tombstone semantics (related contract cleanup)
```

## C1.1 Root identity decision

Recommended decision:

```text
one locale-independent RootContentManifest
one global contentVersion
one deterministic root checksum
one ETag identity
root references canonical + published locale pack revisions
```

The selected Flutter translation locale controls which locale delta is materialized/used, not the semantic identity of the root snapshot.

Deliverables:

- updated learner OpenAPI;
- updated manifest normative doc;
- explicit ETag scope;
- locale-switch acceptance matrix;
- backend golden checksum fixture.

## C1.2 Localization payload

Define exact immutable localized support projection.

Minimum logical contract:

```text
content identity
canonical content revision
locale
localization revision
checksum
localized support fields
```

Acceptance:

- `ru` / `kk` payloads can be synchronized and reopened offline;
- English/audio is not duplicated;
- regional fallback is deterministic;
- locale replacement does not rewrite canonical content.

---

# C2 — Typed learner-content contract

**Priority:** P0

Closes:

```text
BGA-003 typed content body
BGA-007 taxonomy
BGA-008 locale/voice capability projection
BGA-016 checksum canonicalization
```

## C2.1 Shared content envelope

Freeze fields common to all content:

```text
contentCode
contentType
revision
checksum
title/subtitle/description metadata
categoryCode
levelCode
sort/presentation metadata
asset relations
```

## C2.2 Typed body union

Freeze the minimum real product body for:

```text
VocabularyBody
InterviewBody
TopicBody
PhraseBody
ShadowingBody
```

Rules:

- use typed domain shapes;
- no generic EAV content store;
- no arbitrary unversioned JSON blob as the backend domain model;
- DTO polymorphism may differ from JPA entity shape;
- checksum covers the immutable product body deterministically.

## C2.3 Taxonomy/capability catalogs

Freeze:

```text
Category
Level
Skill
SupportedLocale
TtsVoice (learner-facing projection)
```

Every mutable catalog requires stable code + deterministic version/ETag/snapshot semantics.

Acceptance:

- Flutter does not invent mutable product catalogs;
- adding a category/skill/voice/translation capability does not require a mobile release unless protocol shape itself changes.

---

# C3 — Assessment production contract

**Priority:** P0

Closes `BGA-004`.

Deliverables:

```text
PracticeTest
PracticeTestRevision
Question
QuestionRevision
TestQuestionRef
PracticeTestSummaryDto
PracticeTestPayloadDto
PracticeQuestionDto
```

Rules:

- exact immutable question revisions;
- deterministic order;
- deterministic scoring inputs;
- publication state separate from attempt state;
- completed Flutter attempts store enough snapshot/revision data for historical review.

Acceptance:

- production repository no longer uses unavailable/mock assessment data;
- test definitions reopen offline;
- historical attempt remains reproducible after future edits.

---

# C4 — Publication snapshot contract

**Priority:** P0

Closes:

```text
BGA-005 atomic publication
BGA-009 delivery-path ambiguity
BGA-010 sync scalability limits
```

## C4.1 Publication aggregate

Freeze a backend-owned immutable learner snapshot concept:

```text
PublicationSnapshot
├── contentVersion
├── schemaVersion
├── publishedAt
├── checksum
├── pack revision refs
├── tombstones
└── capability/catalog refs where applicable
```

Required transaction:

```text
validate immutable revisions/assets
→ materialize pack snapshots
→ calculate checksums
→ allocate never-reused contentVersion
→ persist root snapshot
→ atomically switch current learner root
```

A failed attempt must expose none of the new root.

## C4.2 One learner delivery path

Recommended MVP rule:

```text
Backend sync truth = manifest + exact immutable payloads
Learner browsing    = local Drift query/pagination
```

Remove or clearly defer remote learner collection APIs from the normative MVP spec unless a concrete server-side browsing use case exists.

## C4.3 Operational limits

Freeze limits for:

```text
max pack contents
max pack manifest bytes
max canonical payload bytes
max localization payload bytes
first-install request budget
```

If measured content volume exceeds the simple one-payload-per-GET model, add an immutable pack bundle endpoint without deleting exact single-payload endpoints.

---

# C5 — Installation and external security contract

**Priority:** P0/P1

Closes:

```text
BGA-006 installation token lifecycle
BGA-011 CDN authorization decision
BGA-012 ADMIN security operations
BGA-018 learner API rate limiting
BGA-022 purchase-entitlement risk decision
```

## C5.1 Installation token lifecycle

Freeze:

```text
token longevity
re-registration behavior
revocation behavior
401 recovery behavior
retry loop bound
backend token storage/verifier policy
```

Required Flutter recovery:

```text
credential-specific 401
→ clear installation token only
→ preserve installationId
→ re-register once
→ retry startup/safe read
→ fail closed if rejected again
```

## C5.2 Registration abuse controls

Add:

- 429 contract;
- `Retry-After` guidance;
- per-IP / deployment-appropriate throttling;
- metrics for registration/auth rejection.

## C5.3 Media policy

Choose and document:

```text
public immutable CDN
or
signed edge delivery
```

Recommended MVP: public immutable CDN + rate/cost controls, explicitly accepting that installation token does not protect media bytes.

## C5.4 ADMIN hardening

Keep one ADMIN, but freeze:

- hash algorithm/config;
- CSRF/cookie policy;
- idle + absolute session TTL;
- login rate limit;
- credential rotation procedure;
- privileged action audit.

## C5.5 Commercial entitlement decision

Explicitly record whether MVP accepts storefront distribution as the commercial gate.

Do not add user accounts merely to solve this risk.

---

# C6 — TTS contract hardening

**Priority:** P1; may proceed in parallel with C1-C5

Closes:

```text
BGA-013 generation/current-slot concurrency
BGA-014 exact config-byte OpenAPI
BGA-015 Worker-token risk documentation
```

## C6.1 Logical audio slot

Define the backend uniqueness/ownership scope for current audio.

Prove concurrent regeneration cannot create two authoritative current outputs for one logical slot.

## C6.2 OpenAPI exact bytes

Correct model-config response so generated clients cannot parse/re-serialize checksum-sensitive Piper config data.

## C6.3 Worker trust-zone statement

Keep current MVP token design and record:

```text
WORKER_TOKEN = worker trust-zone authentication
workerId     = operational/audit label
leaseToken   = job ownership proof
```

No Worker identity database is needed for MVP.

Acceptance remains the existing A01-A11 real Backend ↔ Worker matrix.

---

# C7 — Production operability and contract governance

**Priority:** P1

Closes:

```text
BGA-019 observability
BGA-020 DB/RustFS recovery
BGA-021 contract governance
```

## C7.1 Learner/publication observability

Minimum structured evidence:

```text
traceId
installation auth result without token disclosure
contentVersion
pack identity/revision
publication attempt/result
payload endpoint/result class
admin privileged action
```

Minimum metrics are listed in the primary audit.

## C7.2 Backup/restore/reconciliation

Document:

```text
PostgreSQL backup schedule
RustFS backup/replication schedule
RPO
RTO
restore order
FileAsset/object reconciliation
orphan cleanup
missing-object fail-closed behavior
```

No distributed transaction is required.

## C7.3 Consumer-driven contract CI

Backend CI must test against the same representative fixtures Flutter decodes.

Gate:

```text
OpenAPI
+ Backend controller/serialization tests
+ shared fixtures
+ Flutter decoder/mapper tests
```

Breaking change = explicit contract version migration.

---

# 3. Backend implementation order after contract freeze

Recommended order:

```text
B1  project/security/Liquibase/RustFS foundation
B2  installation identity/token domain
B3  taxonomy + locale + learner-facing voice catalogs
B4  typed content authoring + immutable revisions
B5  localization domain
B6  assessment domain
B7  publication snapshot + manifest materialization
B8  learner exact-payload APIs
B9  media delivery metadata
B10 TTS backend domain / Worker API
B11 Admin Content Studio workflows
B12 real cross-system acceptance
```

TTS B10 can start earlier in parallel because its Worker-facing contract is already mature, provided its final publication linkage follows the publication rules frozen in C4.

---

# 4. Acceptance gates

## Gate G1 — Contract freeze

Required before content-domain schema freeze:

```text
BGA-001 CLOSED
BGA-002 CLOSED
BGA-003 CLOSED
BGA-004 CLOSED
BGA-005 CLOSED
BGA-006 CLOSED
BGA-007/008 shape agreed
```

## Gate G2 — Backend domain freeze

Required evidence:

- aggregate ownership documented;
- persistence model is not a REST DTO mirror;
- immutable revision constraints documented;
- publication transaction documented;
- exact IDs/codes/revision keys documented;
- Liquibase migration strategy agreed.

## Gate G3 — Learner API accepted

Must prove:

```text
fresh installation registration
valid authenticated root sync
same-root 304
locale switch
localized payload
schema incompatibility
content tombstone
restart/offline read
401 credential recovery
429 bounded retry
no mock product content
```

## Gate G4 — Publication accepted

Must prove:

```text
failed publication exposes old root only
successful publication changes root atomically
contentVersion never reused
referenced required assets exist/are READY
checksum golden vectors stable
concurrent admin/background transitions cannot create invalid root
```

## Gate G5 — TTS accepted

Use existing A01-A11 qualification unchanged, plus logical current-audio-slot concurrency qualification.

## Gate G6 — Disaster recovery accepted

Restore a qualified PostgreSQL + RustFS backup set into a clean environment and prove:

```text
learner root readable
READY assets resolve or fail closed
orphan reconciliation works
no immutable ID is rewritten
TTS queue recovery is bounded
```

---

# 5. What not to do

Do not close these gaps by introducing:

```text
microservices
Kafka/RabbitMQ
Redis
Keycloak
server learner profiles
runtime LLM/TTS
one generic EAV content table
one giant Content entity mirroring Flutter DTOs
```

The current modular monolith is the right deployment architecture for the MVP.

The remediation is primarily **contract completion + transactional invariants**, not infrastructure expansion.

# 6. Definition of Done

The backend contract-gap program is complete when:

- all P0 blockers are closed;
- backend aggregate schema is derived from domain ownership rather than Flutter DTO shape;
- localization is actually deliverable, not only represented by locale pack metadata;
- real learning bodies and assessment are backend-driven;
- one atomic publication snapshot controls learner truth;
- installation credentials have deterministic recovery semantics;
- mutable catalogs are backend-owned and revisionable;
- media/TTS trust boundaries are explicit;
- PostgreSQL/RustFS recovery is documented and tested;
- backend and Flutter share executable contract fixtures;
- real cross-system acceptance is green on exact qualified SHAs.
