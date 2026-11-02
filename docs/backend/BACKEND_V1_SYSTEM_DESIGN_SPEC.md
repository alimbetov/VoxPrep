# VoxPrep / CareerSpeak Backend v1 — System Design Specification

**Status:** normative design specification for Backend B1+

**Branch:** `feat/backend-v1-design-spec`

**Applies to:** Spring Boot Backend, Spring MVC Content Studio, Flutter learner client, TTS Worker, PostgreSQL/H2 persistence profiles, RustFS, Store verification boundary.

## 1. Purpose

This specification defines the Backend design that must satisfy the already frozen Flutter and TTS Worker contracts without making external DTOs the internal domain model.

The Backend is one Spring Boot modular monolith and the sole network boundary for Flutter and TTS Worker.

Normative parents:

1. `contracts/learner-api-v2.yaml` — aggregate learner HTTP/wire contract.
2. `docs/backend/BACKEND_API_CONTRACT_BASELINE.md` — reconciled Flutter DTO/API baseline.
3. `docs/architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md` — system ownership/security/publication invariants.
4. `docs/backend/CAREERSPEAK_BACKEND_TTS_REQUIREMENTS.md` and related Worker integration/auth documents — Worker wire/lifecycle contract.
5. `docs/mobile/FLUTTER_ENVIRONMENTS.md` — Flutter environment policy.

This document defines internal composition, module boundaries, authoring/moderation workflow, persistence strategy, model provisioning and implementation qualification. It does not redefine wire DTO fields already frozen by the contracts above.

## 2. Architectural decision

Backend v1 uses **CQRS-lite Authoring + Immutable Publication**.

```text
ADMIN / Spring MVC
        |
        v
Mutable Authoring / Production Domain
        |
        | review / approve / materialize
        v
Immutable exact revisions
        |                    \
        |                     \
        v                      v
TTS production             Publication candidate
        |                      |
        v                      | validate / preview / publish
TTS Worker                   v
                         Immutable learner publication
                                  |
                                  v
                               Flutter
```

The architecture intentionally separates:

- mutable authoring state;
- immutable approved/published revisions;
- TTS execution state;
- immutable learner delivery projections;
- external HTTP DTOs;
- persistence/JPA representation.

Required rule:

```text
Contract DTO != Domain Entity != JPA Entity
```

## 3. Technology baseline

Backend v1 baseline:

- Java 21;
- Spring Boot 3.x approved project line;
- Spring MVC;
- Thymeleaf for ADMIN Content Studio;
- Spring Security;
- Spring Data JPA for ordinary persistence;
- JDBC/native SQL where PostgreSQL concurrency semantics are required;
- Bean Validation;
- Liquibase;
- H2 for the `dev` profile only;
- PostgreSQL for `test` and `prod`;
- PostgreSQL Testcontainers for automated integration/contract tests;
- RustFS behind a Backend-owned object-storage port;
- springdoc/OpenAPI for exposed HTTP surfaces;
- Actuator/Micrometer;
- Docker packaging.

Not required in v1:

- microservices;
- Kafka/RabbitMQ;
- Redis;
- Elasticsearch;
- GraphQL;
- event-sourcing framework;
- separate queue service;
- Keycloak/LDAP/OAuth for ADMIN;
- mandatory learner account.

PostgreSQL is the durable TTS queue in test/prod.

## 4. Actors and security zones

Exactly three external actors exist in MVP:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

Security namespaces:

```text
/admin/**                 -> one secured ADMIN session + CSRF
/api/v1/installations     -> anonymous idempotent installation registration
/api/v1/**                -> installation bearer authentication
/internal/v1/tts/**       -> Worker bearer authentication
PostgreSQL / RustFS       -> Backend-private only
```

### 4.1 ADMIN

MVP has one configured secured ADMIN account. No Editor/Moderator/Reviewer role hierarchy and no RBAC tables are required.

The same ADMIN may edit, request/inspect TTS, review, approve and publish. Workflow state and audit records remain explicit even though the actor is one account.

### 4.2 Flutter installation

No learner account is mandatory. Flutter owns local learner progress/history and obtains an installation token by idempotent registration of its stable `installationId`.

### 4.3 TTS Worker

Worker is disposable compute. It has no PostgreSQL or RustFS credentials. It receives exact job/model identities and lease ownership only through Backend APIs.

## 5. Backend modules

Use package-by-feature. Do not create repository-wide `controller/service/repository/entity` packages.

Recommended root:

```text
kz.voxprep.backend
  identity
  access
  catalogue
  content
  assessment
  media
  tts
  publication
  admin
  shared
```

Each business module may contain:

```text
api
application
domain
infrastructure
```

`admin` is an MVC/application composition surface over module use-cases; it does not own duplicate product truth.

`shared` is intentionally small: time, IDs, checksum primitives, error envelope and carefully selected infrastructure abstractions only.

## 6. Bounded-domain responsibilities

### 6.1 Identity

Owns:

- `Installation`;
- installation registration/re-registration;
- credential issuance/revocation/versioning;
- bounded 401 recovery support.

Does not own learner progress.

### 6.2 Access

Owns:

- Store purchase verification processing;
- replay/idempotency by `purchaseEventId`;
- `Entitlement` (`FREE|FULL`);
- provider/product allowlist configuration.

Purchase evidence is not entitlement truth. Verified purchase grants/maintains entitlement.

### 6.3 Catalogue

Owns the editable product hierarchy and exact collection membership:

```text
Vertical
  -> LearningGoal
     -> LearningTrack
        -> LearningCollection
           -> exact ContentRevision / PracticeTestRevision members
```

Collection access is explicit `FREE|FULL`.

### 6.4 Content

Owns:

- `Content` stable business identity;
- immutable `ContentRevision` after approval/publication;
- typed content body semantics: vocabulary/interview/topic/phrase/shadowing;
- `ContentLocalizationRevision`;
- references to media bindings, not RustFS coordinates.

Published revision bytes are never edited in place. A material change creates a new revision.

### 6.5 Assessment

Owns:

- `Question` + immutable `QuestionRevision`;
- `PracticeTest` + immutable `PracticeTestRevision`;
- exact ordered question membership;
- deterministic scoring inputs.

Flutter learner attempts/history remain local in MVP.

### 6.6 Media

Owns `FileAsset` and storage lifecycle.

Public/delivery identity is `assetId`; bucket/object coordinates and credentials are infrastructure-private.

Typical asset roles/kinds include:

- content cover;
- learner audio;
- TTS model;
- TTS config;
- TTS output;
- optional model-card/provenance document.

READY immutable assets are not overwritten in place.

### 6.7 TTS

Owns:

- `TtsVoice` learner/product voice identity;
- immutable `TtsVoiceModel` revisions;
- external model provisioning/import provenance;
- `TtsJob` durable queue state;
- lease ownership fields;
- Backend-owned fingerprints;
- retry/terminal policy;
- model/config delivery to Worker;
- replay-safe output finalization.

Worker never publishes learner content.

### 6.8 Publication

Owns immutable learner snapshot composition and CURRENT pointer semantics.

Publication contains exact immutable refs/checksums, not mutable authoring rows.

Conceptual flow:

```text
collect approved exact revisions
-> build candidate
-> validate ownership/membership/assets/schema
-> materialize canonical bytes/checksums
-> preview/diff in ADMIN
-> allocate never-reused publication/contentVersion
-> persist immutable publication
-> atomically switch Backend CURRENT pointer
```

Flutter never observes a half-built publication.

## 7. Authoring and moderation model

### 7.1 Principle

ADMIN edits draft/working revisions. The learner never reads mutable authoring tables directly.

Recommended revision lifecycle, adapted per aggregate:

```text
DRAFT
IN_REVIEW
APPROVED
PUBLISHED
ARCHIVED
```

TTS-dependent content may additionally derive readiness such as `READY_FOR_AUDIO`/`AUDIO_PENDING`; do not force one universal enum across all modules.

### 7.2 Review audit

MVP does not require multiple user roles, but review actions must be auditable.

Use module-owned approval state plus an audit record such as:

```text
ReviewRecord
  id
  subjectType
  subjectId
  subjectRevision
  decision
  comment
  actedAt
  actor = ADMIN
```

`ReviewRecord` is audit/history; the subject module remains authority for whether a revision is publishable.

### 7.3 Publication preview/diff

ADMIN must be able to compare current publication with a candidate before publish:

```text
+ added exact revisions
~ changed exact revisions
- removed/tombstoned identities
+/- catalogue membership/order/access changes
+/- asset bindings
```

Publish is a separate action from Save/Edit.

## 8. External DTO mapping rule

Learner DTOs are immutable delivery projections generated from domain/publication state.

Examples:

```text
RootContentManifest
  <- Publication + exact publication refs

PackContentManifest
  <- Publication materialization + ContentRevision + FileAsset descriptors

ContentPayload
  <- exact ContentRevision

LocalizedContentPayload
  <- exact ContentLocalizationRevision

CataloguePayload
  <- exact CatalogueRevision/materialized catalogue bytes

PracticeTestRevision / QuestionRevision
  <- exact Assessment revisions

media bytes
  <- FileAsset

PurchaseVerificationResponse
  <- PurchaseVerification processing + Entitlement
```

Worker DTOs are execution projections:

```text
ClaimResponse
  <- TtsJob + TtsVoiceModel + FileAsset IDs + current lease

Heartbeat
  -> current TtsJob lease validation

Output upload
  -> TtsJob + pending output FileAsset
```

Do not persist external DTOs as serialized entities merely to avoid mapping.

## 9. Persistence strategy

### 9.1 Common rules

- Liquibase is the only schema evolution owner.
- Hibernate `ddl-auto` must be `validate` (or disabled where validation is covered explicitly), never `update/create` in shared environments.
- `spring.jpa.open-in-view=false`.
- timestamps use UTC semantics.
- public UUID/business-code identity is separate from internal database key where useful.
- immutable revisions have database uniqueness on stable identity + revision.
- checksums are lowercase SHA-256.
- optimistic locking is recommended for mutable authoring rows.

### 9.2 H2 vs PostgreSQL

`dev` may use H2 to optimize local MVC/CRUD development. H2 is **not** accepted as proof of PostgreSQL behavior.

`test` and `prod` use PostgreSQL.

PostgreSQL-only behaviors that must be qualified on PostgreSQL include at least:

- TTS atomic claim with `FOR UPDATE SKIP LOCKED`;
- lease/reclaim concurrency;
- advisory/distributed provisioning locks if used;
- PostgreSQL-specific indexes/constraints;
- transaction/isolation behavior relied on by publication CURRENT switching;
- any JSONB/native SQL feature introduced later.

Automated integration tests must therefore use PostgreSQL Testcontainers rather than H2.

Detailed profile rules are normative in `BACKEND_V1_DATABASE_AND_ENVIRONMENT_PROFILES.md`.

## 10. TTS model provisioning

Backend must be able to ensure configured Piper models exist without exposing external model registries to Worker.

Architecture:

```text
External registry (initially Hugging Face/rhasspy-piper-voices)
       |
       v
TtsModelCatalogGateway
       |
       v
TtsModelProvisioningService
       |
       +-> download model/config/(optional model card)
       +-> validate metadata/pair
       +-> compute SHA-256
       +-> persist immutable FileAssets into RustFS
       +-> persist provenance
       +-> create/update TtsVoice/TtsVoiceModel lifecycle
       v
Backend Model API
       |
       v
Worker local exact-model cache
```

Worker never downloads from Hugging Face directly.

### 10.1 Selection parameters

Use a typed selector/value object, at minimum:

```text
engine = PIPER
locale
voiceName
quality
sourceProvider
sourceRepository
sourceRevision
```

Optional discovered/validated metadata:

```text
sampleRateHz
speakerCount
engineVersion
licenseName
licenseReference
```

A URL is acquisition metadata, not model identity.

### 10.2 Seed candidates

Initial requested seed candidates include:

```text
en_US / lessac    / high
de_DE / thorsten  / high
tr_TR / fahrettin / medium
es_MX / claude    / high
es_ES / davefx    / medium
```

Production activation requires an immutable source revision/tag/commit, exact SHA-256 after import and completed license/commercial-use review. Floating `main` may be used for development discovery only and must not be the identity of an ACTIVE production model.

### 10.3 Bootstrap modes

Support configuration:

```text
DISABLED
ENSURE_PRESENT
STRICT
```

- `DISABLED`: no automatic acquisition.
- `ENSURE_PRESENT`: import missing configured models; failures degrade TTS capability but do not destroy learner-serving Backend availability.
- `STRICT`: required models are mandatory for TTS readiness; missing/invalid models keep the TTS subsystem not-ready until resolved.

Model initialization should run through an initialization/bootstrap coordinator and the same provisioning use-case used by ADMIN manual import. It must not create a second download implementation.

The general Backend liveness must not depend on public internet/Hugging Face availability. TTS-specific readiness can be degraded independently.

### 10.4 Multi-instance safety

In PostgreSQL environments only one Backend instance may provision the same source model at a time. Use a durable uniqueness constraint plus a PostgreSQL advisory/application lock or equivalent transaction-safe mechanism.

H2 dev may use a process-local lock; this is explicitly not concurrency qualification.

## 11. TTS Worker invariants

Initial Worker-facing namespace remains:

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{jobId}/heartbeat
POST /internal/v1/tts/jobs/{jobId}/fail
POST /internal/v1/tts/jobs/{jobId}/output
GET  /internal/v1/tts/models/{voiceModelId}/model
GET  /internal/v1/tts/models/{voiceModelId}/config
```

No Worker registration endpoint is required in MVP.

`TtsJob` freezes all execution inputs before `PENDING`, including exact voice model identity and fingerprint inputs. Changing a voice default must not mutate an existing job.

Test/prod claim is PostgreSQL-backed and concurrency-safe using the contractually required `FOR UPDATE SKIP LOCKED` pattern.

## 12. Media/RustFS boundary

RustFS remains Backend-internal.

Flutter and Worker must never receive:

- RustFS/S3 credentials;
- internal bucket/object path as authorization input;
- direct storage endpoint;
- presigned RustFS URL in learner v1;
- storage secret through DTOs.

All uploaded/imported bytes become `FileAsset` records with Backend-computed integrity metadata.

## 13. Learner publication and media availability

Publication may reference only learner-deliverable exact revisions and valid assets according to contract rules.

TTS generation does not automatically publish content. Typical flow:

```text
ContentRevision draft/approved
-> request audio
-> TtsJob
-> output FileAsset READY
-> ADMIN review/bind/approve
-> Publication candidate
-> validate
-> publish
```

Existing published asset remains authoritative until replacement is READY, approved and included in a later publication.

## 14. ADMIN Content Studio minimum surface

Initial MVC routes should cover:

```text
/admin/catalogue/**
/admin/content/**
/admin/assessment/**
/admin/media/**
/admin/tts/voices/**
/admin/tts/models/**
/admin/tts/jobs/**
/admin/moderation/**
/admin/publications/**
```

Minimum functions:

- create/edit draft content and catalogue structure;
- create/edit assessment drafts;
- manage localizations;
- upload/inspect covers/media;
- discover/import/validate Piper voice models;
- request/retry TTS jobs;
- play/inspect generated audio;
- approve/reject/record review notes;
- build publication candidate;
- preview/diff candidate;
- validate and publish;
- inspect publication history.

## 15. Configuration and secrets

Backend profiles:

```text
dev
 test
 prod
```

Secrets must come from environment/secret management and never from committed YAML:

- DB credentials outside H2 dev;
- RustFS access/secret keys;
- Worker bearer token;
- Backend signing keys/secrets;
- Google/Apple server verification credentials when implemented.

Non-secret configuration includes service ports, bootstrap modes, model selectors, allowed product IDs and feature toggles.

## 16. Observability

At minimum expose Actuator health/readiness and metrics for:

- database connectivity;
- RustFS connectivity/readiness where relevant;
- TTS queue depth by status;
- TTS claim/ready/fail counts;
- lease expiry/reclaim count;
- model provisioning success/failure;
- current publication version;
- publication failure count;
- installation registration/auth failures;
- purchase verification outcomes without proof data.

Never log Worker token, lease token, Store verification proof, RustFS credentials or Authorization headers.

## 17. Transaction boundaries

Explicit transactions are required around:

- idempotent installation registration/credential update;
- purchase-event replay handling + entitlement grant;
- exact revision approval where invariants are frozen;
- publication creation/materialization metadata;
- atomic CURRENT publication pointer switch;
- TTS claim/reclaim;
- TTS output finalization (`TtsJob` + `FileAsset` state);
- model provisioning final registration.

Remote HTTP/storage work must not hold long database row locks unnecessarily. Download/upload bytes first into controlled staging, then finalize metadata transactionally.

## 18. Error policy

Public learner errors use the contracted `ApiError` envelope. Worker errors follow the Worker contract. ADMIN MVC surfaces safe validation/business errors and logs traceable internal failures without exposing secrets.

Domain errors must not be represented by raw persistence exceptions at API boundaries.

## 19. Testing strategy

### Unit/domain

- pure domain/value object tests;
- no database required where possible.

### Dev smoke

- H2 may exercise common JPA/MVC flows quickly;
- H2 results are convenience evidence only.

### Integration/contract

- PostgreSQL Testcontainers is mandatory;
- Liquibase migrations from empty DB;
- Spring MVC/API security;
- publication transaction semantics;
- TTS claim/lease concurrency;
- model provisioning persistence with fake/local registry server;
- media metadata/finalization.

No CI test may depend on live Hugging Face, Google Play, Apple or public network availability.

### End-to-end

Required before production acceptance:

```text
Flutter <-> real Backend <-> PostgreSQL/RustFS
Backend <-> real TTS Worker <-> Piper/FFmpeg
Store sandbox <-> Backend verification (when monetization B8 is implemented)
```

## 20. Primary invariants

1. Published exact revisions are immutable.
2. Flutter receives only coherent immutable publication state.
3. Backend is the sole RustFS/network security boundary.
4. Worker is disposable compute and cannot publish learner content.
5. TTS jobs freeze exact model identity and fingerprint inputs.
6. READY assets are never silently overwritten.
7. Publication and entitlement are separate concepts.
8. H2 never substitutes for PostgreSQL acceptance.
9. External model registry availability never becomes a prerequisite for serving an already-valid learner publication.
10. Contract DTOs do not dictate JPA/domain structure.

## 21. Non-goals for the first Backend implementation stream

Do not add unless a contracted requirement proves need:

- microservice decomposition;
- learner accounts/cloud progress synchronization;
- RBAC/editor role hierarchy;
- async message broker;
- direct Flutter/Worker object-storage access;
- automatic production activation of newly downloaded models without qualification;
- dynamic arbitrary model execution supplied by a client;
- generic artifact/CMS framework replacing typed domain models.

## 22. Design acceptance

Backend implementation may start when this specification and the related domain/database documents are reviewed against the contract baseline and no unresolved blocker remains in the Backend contract questions ledger.

Implementation completion is a separate qualification and requires exact-SHA green CI plus real PostgreSQL/RustFS/Worker acceptance. Documentation approval alone is not production acceptance.
