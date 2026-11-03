# VoxPrep / CareerSpeak Backend v1 — Implementation Roadmap

**Status:** normative implementation sequence after design approval

## 1. Delivery strategy

Implement the Backend as a sequence of small exact-SHA-qualified slices. Do not open one long-lived `feat/backend` branch containing all functionality.

Each slice must preserve the contract baseline and must not weaken immutable revision, publication, media-security or Worker lease invariants.

## 2. B0 — Design and contract freeze

Scope:

- approve `BACKEND_V1_SYSTEM_DESIGN_SPEC.md`;
- approve `BACKEND_V1_DOMAIN_COMPOSITION.md`;
- approve `BACKEND_V1_DATABASE_AND_ENVIRONMENT_PROFILES.md`;
- reconcile any open contract questions with `learner-api-v2` and Worker contract;
- no production Backend implementation yet.

Acceptance:

```text
learner API source of truth identified
Worker source of truth identified
domain ownership agreed
dev/test/prod DB policy agreed
MVC/moderation workflow agreed
TTS model provisioning boundary agreed
```

Suggested branch: current `feat/backend-v1-design-spec`.

## 3. B1 — Backend foundation

Suggested branch:

```text
feat/backend-b1-foundation
```

Scope:

- Spring Boot project under a dedicated Backend directory/module;
- Java 21;
- package-by-feature module skeleton;
- common error handling;
- Spring Security baseline;
- ADMIN session/form-login baseline;
- Worker-token security filter/boundary skeleton;
- learner bearer boundary skeleton;
- Liquibase master changelog;
- H2 `dev` profile;
- PostgreSQL `test`/`prod` profiles;
- PostgreSQL Testcontainers integration-test base;
- Actuator health/readiness;
- CI for build/unit/PostgreSQL integration tests.

Acceptance:

```text
application starts with dev/H2
application starts in test context with PostgreSQL Testcontainers
Liquibase empty-DB migration GREEN
H2 console dev-only
open-in-view disabled
no ddl-auto update/create
/admin security boundary proven
/internal/v1/tts security boundary proven
/api/v1 security boundary proven
```

No real learner domain yet except minimal test endpoints/fixtures needed to prove boundaries.

## 4. B2 — Installation identity and learner authentication

Suggested branch:

```text
feat/backend-b2-installation-auth
```

Scope:

- `Installation` aggregate;
- idempotent `POST /api/v1/installations`;
- token issuance/validation;
- blocked/revoked handling foundation;
- API error envelope;
- bounded re-registration support expected by Flutter.

Acceptance:

```text
same installationId is idempotent
new valid token returned
secured learner endpoint accepts valid token
missing/invalid token rejected
blocked installation rejected
contract DTO matches learner-api-v2
PostgreSQL integration tests GREEN
```

## 5. B3 — Authoring foundation: catalogue, content, assessment

Suggested branch:

```text
feat/backend-b3-authoring-domain
```

Scope:

- catalogue authoring aggregates;
- Content + ContentRevision;
- ContentLocalizationRevision;
- Question/QuestionRevision;
- PracticeTest/PracticeTestRevision;
- ADMIN MVC CRUD for drafts;
- typed validation;
- optimistic locking;
- revision creation/freeze foundation;
- review audit foundation.

Acceptance:

```text
ADMIN can author hierarchy/content/assessment
published/approved revision cannot be edited in place
new revision is created for material changes
ordered memberships validated
H2 dev CRUD usable
PostgreSQL integration tests authoritative GREEN
```

Do not expose learner publication APIs yet except test projections if necessary.

## 6. B4 — Media and RustFS

Suggested branch:

```text
feat/backend-b4-media-assets
```

Scope:

- FileAsset aggregate;
- Backend-owned object-storage port;
- RustFS S3-compatible adapter;
- staging/upload/finalization;
- SHA-256/size validation;
- content cover/audio bindings;
- learner media streaming endpoint contract;
- ADMIN media upload/preview.

Acceptance:

```text
READY asset immutable
replacement gets new assetId
Flutter media endpoint streams through Backend
no RustFS URL/credential exposed
checksum/size integrity proven
storage failure leaves metadata consistent
```

## 7. B5 — TTS catalogue, provisioning and Worker production path

Suggested branch:

```text
feat/backend-b5-tts-production
```

Scope:

### TTS catalogue

- TtsVoice;
- TtsVoiceModel;
- lifecycle/approval/activation;
- model/config FileAsset refs;
- provenance/license fields.

### Provisioning

- typed `TtsModelSelector`;
- seed configuration;
- `TtsModelCatalogGateway`;
- initial Hugging Face/Piper adapter;
- `TtsModelProvisioningService`;
- bootstrap coordinator;
- `DISABLED|ENSURE_PRESENT|STRICT` modes;
- process-local dev lock;
- PostgreSQL test/prod distributed uniqueness/lock;
- no live public registry dependency in CI.

Initial requested seed candidates:

```text
en_US / lessac    / high
de_DE / thorsten  / high
tr_TR / fahrettin / medium
es_MX / claude    / high
es_ES / davefx    / medium
```

Production ACTIVE model requires pinned immutable source revision, SHA-256 and license/commercial-use review.

### Worker path

- TtsJob;
- Backend fingerprint service + golden vectors;
- atomic PostgreSQL claim;
- lease/heartbeat/reclaim;
- model/config delivery;
- failure callback;
- output upload/finalization;
- retry/terminal policy;
- reuse of identical READY fingerprint where allowed.

Acceptance:

```text
model can be provisioned if missing
restart is idempotent
Worker never sees registry/RustFS credentials
claim is atomic under concurrent PostgreSQL workers
expired lease cannot finalize
reclaim creates new lease token
exact model bytes/checksum match claim
output finalization replay-safe
real Worker A01-A11 acceptance GREEN before production closure
```

## 8. B6 — Publication and moderation

Suggested branch:

```text
feat/backend-b6-publication
```

Scope:

- review/approval transitions required for publication;
- Publication candidate;
- exact ref materialization;
- root/pack/catalogue checksums;
- deterministic candidate validation;
- candidate preview/diff;
- publication history;
- atomic CURRENT pointer switch;
- tombstone/removal semantics;
- ADMIN publication UI.

Acceptance:

```text
candidate cannot include invalid/unapproved exact refs
candidate validation deterministic
current publication remains unchanged on failure
publish allocates never-reused contentVersion
CURRENT switch atomic in PostgreSQL
published bytes reproducible
preview/diff matches materialized candidate
```

## 9. B7 — Learner delivery API

Suggested branch:

```text
feat/backend-b7-learner-api
```

Implement `learner-api-v2` over immutable publication/read models:

```text
GET /api/v1/content/manifest
GET /api/v1/content/packs/{packCode}/manifest
GET /api/v1/content/{type}/{code}/revisions/{revision}
GET /api/v1/content/.../localizations/...
GET /api/v1/catalogues/{kind}/revisions/{revision}
GET /api/v1/assessment/practice-tests/{code}/revisions/{revision}
GET /api/v1/assessment/questions/{code}/revisions/{revision}
GET /api/v1/media/assets/{assetId}/content
```

Acceptance:

```text
DTO wire guards match Flutter expectations
ETag/304 semantics correct
exact identity/revision/checksum enforced
locale does not alter root identity
publication eligibility enforced for media
Flutter sync N->N+1 succeeds against real Backend
corrupt/mismatched payload fails closed
```

## 10. B8 — Access and monetization

Suggested branch:

```text
feat/backend-b8-monetization
```

Scope:

- PurchaseVerificationRecord;
- Entitlement;
- `POST /api/v1/purchases/verify`;
- product/provider allowlist;
- replay/idempotency;
- real Google Play verification;
- Apple verification when iOS release requires it;
- restore/reverification policy.

Acceptance:

```text
verified=false returns HTTP 200 negative result
verified purchase grants FULL
same semantic purchase event replay-safe
conflicting event reuse rejected
proof never logged
provider outage retryable/fail-closed
Flutter real Store -> Backend -> FULL acceptance GREEN
```

## 11. B9 — Full product acceptance and hardening

Suggested branch:

```text
feat/backend-b9-production-qualification
```

Scope:

- cross-system adversarial tests;
- observability dashboards/metrics;
- security review;
- backup/restore rehearsal;
- load/concurrency qualification;
- release configuration;
- exact-SHA CI evidence.

Required end-to-end paths:

```text
ADMIN authoring
 -> review
 -> TTS provisioning/job
 -> audio review
 -> publication
 -> Flutter sync
 -> offline asset use

Flutter purchase
 -> Store
 -> Backend verification
 -> FULL entitlement

Worker crash/expired lease
 -> reclaim
 -> stale completion rejected
```

Production acceptance requires PostgreSQL; H2 is excluded from release qualification.

## 12. CI gate per implementation slice

Every Backend slice should run at least:

```text
mvn/gradle compile
unit tests
format/static analysis if configured
PostgreSQL Testcontainers integration tests
Liquibase empty-DB migration
contract tests for affected endpoints
architecture/module-boundary tests
```

TTS/publication slices add concurrency tests.

No slice is `CLOSED` until one exact branch SHA is green.

## 13. Branch/merge discipline

```text
design baseline
 -> B1 branch -> qualified -> merge
 -> B2 branch -> qualified -> merge
 -> ...
```

Do not let later slices silently repair unqualified earlier foundations. Defects found in an accepted foundation get explicit remediation commits/tests and exact-SHA requalification.

## 14. MVP stop condition

Backend v1 is feature-complete for the current product when:

```text
Installation/auth             GREEN
Authoring Content Studio      GREEN
Content/Catalogue/Assessment  GREEN
RustFS media                  GREEN
TTS provisioning + Worker     GREEN
Publication                   GREEN
learner-api-v2                GREEN
Purchase verification         GREEN
Flutter real Backend E2E      GREEN
PostgreSQL exact-SHA CI       GREEN
```

Only after this baseline should the project consider learner cloud accounts, RBAC, microservices, brokers or generalized CMS features.
