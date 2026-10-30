# CareerSpeak — P0 Domain & Contract Design Plan

**Document version:** 1.1  
**Status:** Working architecture plan  
**Applies to:** VoxPrep / CareerSpeak v0.7+  
**Branch:** `feat/p0-domain-contracts`

---

## 1. Goal

P0 defines the domain model and contracts before production implementation begins.

Each bounded context must agree:

```text
scope/ownership
aggregates/entities/value objects
invariants
state machine
persistence model
constraints/indexes
application/API contracts
security zone
errors
idempotency
concurrency behavior
acceptance/failure tests
```

A context is implementation-ready only after these are explicit.

---

## 2. Architecture baseline

```text
ADMIN
→ Spring MVC Content Studio
→ one fixed secured account/session

Flutter
→ random installationId
→ backend-issued installation token
→ learner REST API
→ manifest/packs
→ CDN/edge → RustFS

TTS Worker
→ server-managed long-running process
→ worker machine token
→ Backend Job API
→ PostgreSQL SKIP LOCKED queue
→ exact Piper model/cache
→ Piper + FFmpeg
→ RustFS
```

Do not introduce additional human roles in MVP.

---

## 3. Security actors

Exactly three technical actors exist in MVP:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

### ADMIN

- one account;
- fixed username;
- strong deployment-managed password hash;
- Spring Security server-side session;
- complete Content Studio access.

Do not implement moderator/editor/reviewer roles, admin registration, user/role tables, password reset, OAuth, LDAP or Keycloak.

### FLUTTER INSTALLATION

- no personal account;
- app-generated cryptographically random `installationId`;
- backend-issued installation token;
- token stored in platform secure storage;
- no server learner-progress profile.

### TTS WORKER

- dedicated machine token;
- no ADMIN credentials;
- no direct PostgreSQL credentials;
- no permanent RustFS credentials;
- accesses only internal TTS contracts and presigned object URLs.

---

## 4. Standard design package per bounded context

Each domain specification follows the same template.

### 4.1 Domain

```text
responsibility
aggregate roots
entities
value objects
business codes
invariants
state transitions
cross-domain dependencies
non-goals
```

### 4.2 Persistence

```text
tables
PK/FK
unique constraints
check constraints
indexes
optimistic concurrency where needed
immutability/version rules
migration rules
```

### 4.3 Contract

```text
commands/use cases
REST/internal endpoints where applicable
request/response DTOs
pagination/filtering/sorting
error codes
idempotency
security actor
concurrency semantics
```

### 4.4 Qualification

```text
happy path
invalid state transitions
concurrent operations
retries
crash/recovery
integration tests
```

---

## 5. P0.0 — Common Contract & Domain Conventions

Define once for every module:

```text
identifier types
immutable business codes
timestamp/time-zone rules
revision numbering
API versioning
DTO naming/nullability
error envelope
cursor contract
idempotency conventions
optimistic-lock conventions
HTTP semantics
trace/correlation ID
```

Suggested error shape:

```json
{
  "code": "CONTENT_REVISION_NOT_FOUND",
  "message": "Content revision was not found",
  "traceId": "...",
  "details": {}
}
```

Deliverables:

```text
COMMON_CONTRACTS.md
ERROR_CONTRACT.md
API_CONVENTIONS.md
```

---

## 6. P0.1 — Revision / Publication / Availability

This is the foundational content lifecycle.

Separate:

```text
revision lifecycle
publication state
learner availability
```

Baseline:

```text
DRAFT
READY_FOR_AUDIO
READY_FOR_REVIEW
PUBLISHED
ARCHIVED
```

Availability:

```text
ACTIVE
INACTIVE
```

Rules to freeze:

```text
when published revision becomes immutable
how new revision is created
when publication is allowed
how deactivate/reactivate works
how manifests/tombstones change
how stale assets/jobs are handled
```

All content domains depend on this contract.

---

## 7. P0.2 — Profession / Catalog

Define:

```text
Profession
CareerTrack
Specialization where required
Seniority
Category
Tag
Skill taxonomy ownership
```

Consumer examples:

```text
GET /api/v1/professions
GET /api/v1/professions/{code}
GET /api/v1/career-tracks
```

Use stable business codes and cursor pagination for learner lists.

---

## 8. P0.3 — Localization

Canonical learning language remains English.

Localization owns:

```text
UI locale metadata
translation
hint
explanation
locale readiness/fallback
```

Freeze:

```text
BCP-47 identifiers
fallback rules
locale publication readiness
RTL readiness
typed localization tables
```

Missing non-English localization should not automatically block canonical English publication unless an explicit pack policy requires it.

---

## 9. P0.4 — Media / RustFS

Define:

```text
FileAsset
AssetStatus
AssetRole
ObjectStorage port
RustFsObjectStorage adapter
immutable object keys
checksum
mime/size/duration/codec
private/public delivery rules
presigned GET/PUT
garbage collection rules
```

Baseline storage:

```text
PostgreSQL metadata
RustFS binary bytes
CDN/edge for published learner assets
```

---

## 10. P0.5 — TTS

Define:

```text
TtsVoice
TtsVoiceModel
TtsVoicePool/TtsVoicePolicy only where needed
PronunciationRule
TtsJob
TtsWorker
```

Production worker:

```text
server-managed long-running Python process/container
Piper
FFmpeg
auto-start/auto-restart
local model cache
```

Queue contract is PostgreSQL-based:

```text
atomic claim
FOR UPDATE SKIP LOCKED
lease_token
lease_until
heartbeat
bounded retry
stale-result rejection
```

Do not add RabbitMQ for initial TTS workload.

---

## 11. P0.6 — Interview

Define:

```text
InterviewQuestion
InterviewQuestionRevision
ModelAnswer
InterviewCategory
Profession mapping
CareerTrack mapping
Seniority mapping
Skill mapping
Audio roles
Localization
```

Freeze consumer list/detail contracts and exact publication dependencies.

---

## 12. P0.7 — Vocabulary

Define revisioned vocabulary content:

```text
VocabularyWord identity
VocabularyRevision
Definition
Example
Collocation
WordFamily if included in MVP
Category
Localization
Audio roles
```

Do not allow published learner-visible vocabulary text to mutate in place.

---

## 13. P0.8 — Topic / Phrase / Shadowing

Define:

```text
Topic
TopicRevision
TopicSection
Phrase
PhraseCategory
display_text
tts_text
audio association
sort/order semantics
```

Shadowing contract must preserve deterministic text/audio segmentation where highlighting/repeat behavior depends on sections.

---

## 14. P0.9 — Assessment

Define:

```text
QuestionBankItem
QuestionRevision
AnswerOption
Skill
PracticeTest
PracticeTestRevision
PracticeTestQuestion
ScoringRule
```

Mandatory rule:

```text
Published PracticeTestRevision
→ exact QuestionRevision references
```

Never resolve a published test against mutable current question data.

---

## 15. P0.10 — Manifest / Content Delivery

Define:

```text
ContentManifest
ContentPack
PackRevision
AssetReference
Tombstone
contentVersion
checksum/version semantics
```

Contracts:

```text
GET /api/v1/content/manifest
GET /api/v1/content/packs/{code}/manifest
```

Only changed/missing assets should be downloaded.

---

## 16. P0.11 — Pagination Contract

Learner API uses cursor/keyset pagination.

Response convention:

```json
{
  "items": [],
  "page": {
    "nextCursor": "...",
    "hasMore": true
  }
}
```

Cursor sorting must be deterministic with a unique tie-breaker.

Internal ADMIN lists may use ordinary page/size pagination.

---

## 17. P0.12 — Flutter Local Domain / Retention

Define local SQLite/Drift ownership for:

```text
Favorite
Progress
TestAttempt
ReviewSchedule
Download
LocalContentSnapshot
LocalAsset
ContentAssetReference
CacheEntry
Settings
```

Retention:

```text
TTL
LRU
local quota
pin/manual-download protection
ref-count/reference-safe deletion
```

Progress must survive media/cache eviction.

---

## 18. P0.13 — Security / Installation

Keep security deliberately small.

### ADMIN contract

```text
/admin/**
→ fixed ADMIN username/password
→ server-side session
→ HttpOnly/Secure/SameSite cookie
→ CSRF
```

No role hierarchy in MVP.

### Flutter installation contract

```text
first launch
→ generate random installationId
→ POST registration
→ backend issues installation token
→ secure local storage
→ Bearer token for /api/v1/**
```

Token SHALL be backend-issued, not `SHA256(installationId)` or another client-computable credential.

### TTS worker contract

```text
/internal/v1/tts/**
→ dedicated machine token
```

---

## 19. P0.14 — Content Studio

Content Studio is an orchestration/admin interface, not a separate identity platform.

One ADMIN executes:

```text
create/edit
bulk import
validate
localize
prepare audio
manage voice/models
preview audio
publish
activate/deactivate
```

No multi-user workflow engine is required.

---

## 20. P0.15 — Integrated ERD + OpenAPI

After individual contexts are agreed:

```text
compose complete PostgreSQL ERD
verify aggregate ownership
verify no duplicate source-of-truth fields
verify FK/unique/index strategy
freeze learner REST contracts
freeze internal TTS contracts
freeze admin command contracts where externalized
```

Cross-module calls inside the modular monolith use application/domain ports rather than HTTP.

A module SHALL NOT mutate another module's repository directly.

---

## 21. P0.16 — Architecture Freeze

P0 closes when:

```text
all bounded contexts are Domain Ready
integrated ERD is accepted
OpenAPI contracts are accepted
TTS claim/lease/recovery protocol is accepted
manifest/retention semantics are accepted
security actors are fixed to ADMIN / INSTALLATION / WORKER
ADRs capture remaining irreversible decisions
implementation backlog is generated
```

After P0.16, P1 begins executable foundation work.

---

## 22. Definition of Ready

A bounded context is ready when all boxes are satisfied:

```text
[ ] ownership
[ ] aggregate roots/entities/value objects
[ ] invariants
[ ] lifecycle/state machine
[ ] DB schema
[ ] PK/FK/unique/check constraints
[ ] indexes
[ ] application/API contract
[ ] pagination/filtering where applicable
[ ] security actor
[ ] error codes
[ ] idempotency
[ ] concurrency behavior
[ ] acceptance tests
[ ] failure/recovery tests where applicable
```

---

## 23. Definition of Done for implementation

Later implementation for a domain follows:

```text
accepted spec
→ Liquibase
→ domain/application code
→ repositories/adapters
→ REST/admin adapter
→ unit tests
→ integration/Testcontainers tests
→ architecture tests
→ OpenAPI qualification
→ CI green
```

---

## 24. Execution order

```text
P0.0  Common Contracts
P0.1  Revision / Publication / Availability
P0.2  Profession / Catalog
P0.3  Localization
P0.4  Media / RustFS
P0.5  TTS
P0.6  Interview
P0.7  Vocabulary
P0.8  Topic / Phrase / Shadowing
P0.9  Assessment
P0.10 Manifest / Content Delivery
P0.11 Pagination Contract
P0.12 Flutter Local Domain / Retention
P0.13 Security / Installation
P0.14 Content Studio
P0.15 Integrated ERD + OpenAPI
P0.16 Architecture Freeze
```

The next implementation-design slice is **P0.0 Common Contract & Domain Conventions**, followed by **P0.1 Revision / Publication / Availability**.
