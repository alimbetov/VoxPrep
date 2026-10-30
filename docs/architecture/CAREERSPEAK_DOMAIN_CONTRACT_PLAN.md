# CareerSpeak — P0 Domain & Contract Design Plan

**Document version:** 1.2  
**Status:** Working architecture plan  
**Applies to:** VoxPrep / CareerSpeak v0.8+  
**Branch:** `feat/p0-domain-contracts`

---

## 1. Goal

P0 freezes domain ownership and contracts before production implementation.

Every bounded context must explicitly define:

```text
scope/ownership
aggregates/entities/value objects
invariants
state machine
persistence/local persistence model
constraints/indexes
application/API contracts
security zone
errors
idempotency
concurrency/recovery behavior
acceptance/failure tests
```

A context is implementation-ready only after these are agreed.

---

## 2. Architecture baseline

```text
ADMIN
→ Spring MVC Content Studio
→ one fixed secured account/session

Flutter
→ feature-first architecture
→ Riverpod + go_router
→ Drift/SQLite + Secure Storage
→ random installationId
→ backend-issued installation token
→ learner REST API
→ manifest/packs/locale deltas
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

Exactly three technical actors exist:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

---

## 3. Standard design package

Each domain specification follows the same template.

### Domain

```text
responsibility
aggregate roots
entities/value objects
business codes
invariants
state transitions
cross-domain dependencies
non-goals
```

### Persistence

```text
tables/local tables
PK/FK
unique/check constraints
indexes
optimistic concurrency where needed
immutability/version rules
migration rules
```

### Contract

```text
commands/use cases
REST/internal endpoints where applicable
request/response DTOs
pagination/filtering/sorting
errors
idempotency
security actor
concurrency semantics
```

### Qualification

```text
happy path
invalid transitions
concurrent operations
retries
crash/recovery
integration tests
```

---

## 4. P0.0 — Common Contract & Domain Conventions

Freeze once:

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

Suggested error envelope:

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

## 5. P0.1 — Revision / Publication / Availability

Separate:

```text
revision lifecycle
publication state
learner availability
```

Baseline revision lifecycle:

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

Freeze:

```text
published immutability
new-revision creation
publication qualification
deactivate/reactivate
manifest/tombstone effect
stale assets/jobs
```

---

## 6. P0.2 — Profession / Catalog

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

Consumer contracts use stable business codes and cursor pagination.

---

## 7. P0.3 — Localization

Canonical learning language remains English.

Freeze:

```text
uiLocale vs translationLocale
BCP-47 identifiers
Flutter ARB/gen-l10n UI resources
backend content translations/hints/explanations
typed localization tables
locale readiness
regional/base/English fallback
RTL readiness
locale delta packs
```

Missing non-required localization does not block canonical English publication.

---

## 8. P0.4 — Media / RustFS

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
private/public delivery
presigned GET/PUT
garbage collection
```

Baseline:

```text
PostgreSQL metadata
RustFS binary bytes
CDN/edge for published learner assets
```

---

## 9. P0.5 — TTS

Define:

```text
TtsVoice
TtsVoiceModel
TtsVoicePool/TtsVoicePolicy where needed
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

Queue contract:

```text
atomic claim
FOR UPDATE SKIP LOCKED
lease_token
lease_until
heartbeat
bounded retry
stale-result rejection
```

---

## 10. P0.6 — Interview

Define:

```text
InterviewQuestion
InterviewQuestionRevision
ModelAnswer
InterviewCategory
Profession/CareerTrack mapping
Seniority/Skill mapping
Audio roles
Localization
```

Freeze list/detail, publication and audio dependencies.

---

## 11. P0.7 — Vocabulary

Define revisioned vocabulary:

```text
VocabularyWord identity
VocabularyRevision
Definition
Example
Collocation
WordFamily if in MVP
Category
Localization
Audio roles
```

Published learner-visible text does not mutate in place.

---

## 12. P0.8 — Topic / Phrase / Shadowing Content

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
stable segment/order semantics
```

Shadowing depends on deterministic backend-published segmentation rather than client punctuation guessing.

---

## 13. P0.9 — Assessment

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

Mandatory:

```text
Published PracticeTestRevision
→ exact QuestionRevision references
```

---

## 14. P0.10 — Manifest / Content Delivery

Define:

```text
ContentManifest
ContentPack
PackRevision
LocaleDelta
AssetReference
Tombstone
contentVersion
schemaVersion
checksum/version semantics
```

Contracts:

```text
GET /api/v1/content/manifest
GET /api/v1/content/packs/{code}/manifest
```

A staged update must be verified before replacing the current local snapshot.

---

## 15. P0.11 — Pagination Contract

Learner API uses cursor/keyset pagination:

```json
{
  "items": [],
  "page": {
    "nextCursor": "...",
    "hasMore": true
  }
}
```

Sorting is deterministic with a unique tie-breaker.

ADMIN lists may use ordinary page/size pagination.

---

## 16. P0.12 — Flutter Application Contract

This is a full mobile architecture freeze, not only a retention design.

Authoritative specification:

```text
docs/specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md
```

### P0.12.1 Feature/module map

Freeze feature-first structure:

```text
onboarding
home
vocabulary
interview
topics
phrases
shadowing
assessment
review
favorites
downloads
settings
storage_management
```

### P0.12.2 State-management contract

Baseline:

```text
Riverpod
explicit provider/controller ownership
no duplicate global mutable singleton state
```

### P0.12.3 Navigation contract

Baseline:

```text
go_router
stable business-code routes
navigation restoration/deep-link readiness
```

### P0.12.4 Drift local ERD

Freeze local ownership for:

```text
settings
installation state
manifest/pack state
local content snapshots
local assets/references
favorites
progress
review schedule
test attempts/answers
download tasks
sync journal
```

### P0.12.5 Installation/API client

```text
installationId
backend-issued token
Secure Storage
one typed API client/error mapper
```

### P0.12.6 Mobile localization

Freeze:

```text
uiLocale
translationLocale
preferredAccent
ARB/gen-l10n UI strings
backend content locale deltas
fallback
RTL mixed English/support text
```

### P0.12.7 Manifest Sync Engine

Define `ContentSyncCoordinator`:

```text
last known-good local snapshot
remote manifest
staging
checksum/schema validation
atomic activation
tombstones
crash recovery
```

### P0.12.8 Download Manager

State machine:

```text
QUEUED
DOWNLOADING
VERIFYING
READY
PAUSED
FAILED
CANCELLED
```

Freeze retry/resume/concurrency/storage-precheck behavior.

### P0.12.9 Asset Resolver

One contract resolves:

```text
verified local file
or
remote CDN/edge asset
```

UI/audio features do not branch on storage source.

### P0.12.10 Audio / Shadowing Engine

Freeze:

```text
play/pause/seek
speed 0.75/1/1.25
repeat 1/3/5/infinite
skip
segment repeat
playback lifecycle
stable segmentation/highlighting rules
```

### P0.12.11 Assessment local engine

Freeze:

```text
Learn mode
Exam mode
Quick mode
attempt persistence
question/test revision identity
process-death restore
skill breakdown
```

### P0.12.12 Review scheduler

Deterministic local scheduling; no AI/ML requirement.

### P0.12.13 Storage / retention

```text
TTL
LRU
local quota
pin/manual-download protection
shared-asset reference-safe deletion
```

Progress survives media eviction.

### P0.12.14 Startup / errors / recovery

Freeze:

```text
local-first startup
network-independent rendering when cached
schema incompatibility
sync interruption
checksum failure
storage full
offline mode
user-facing error mapping
Drift migrations
```

Flutter implementation SHALL NOT begin before P0.12 acceptance.

---

## 17. P0.13 — Security / Installation

Keep security small.

### ADMIN

```text
/admin/**
→ fixed username/password
→ server session
→ HttpOnly/Secure/SameSite
→ CSRF
```

### Flutter

```text
first launch
→ random installationId
→ backend registration
→ backend-issued token
→ Secure Storage
→ /api/v1/**
```

Token is not client-computable from installationId.

### Worker

```text
/internal/v1/tts/**
→ dedicated machine token
```

---

## 18. P0.14 — Content Studio

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

## 19. P0.15 — Integrated ERD + Mobile ERD + OpenAPI

After contexts are agreed:

```text
compose PostgreSQL ERD
compose Flutter Drift ERD
verify aggregate ownership
verify no duplicate sources of truth
verify FK/unique/index strategy
freeze learner REST
freeze internal TTS contracts
freeze manifest/locale-delta contracts
freeze mobile schemaVersion compatibility rules
```

Cross-module backend calls use application/domain ports rather than HTTP.

---

## 20. P0.16 — Architecture Freeze

P0 closes when:

```text
all bounded contexts Domain Ready
PostgreSQL ERD accepted
Flutter Drift ERD accepted
OpenAPI accepted
TTS claim/lease/recovery accepted
manifest/sync/retention accepted
mobile localization/RTL accepted
security actors fixed
ADRs capture irreversible decisions
implementation backlog generated
```

---

## 21. Definition of Ready

A bounded context is ready when:

```text
[ ] ownership
[ ] aggregate roots/entities/value objects
[ ] invariants
[ ] lifecycle/state machine
[ ] DB/local schema
[ ] constraints/indexes
[ ] application/API contract
[ ] pagination/filtering where applicable
[ ] security actor
[ ] error codes
[ ] idempotency
[ ] concurrency/recovery behavior
[ ] acceptance tests
[ ] failure tests
```

Flutter additionally requires mobile screen/state/recovery contracts from P0.12.

---

## 22. Definition of Done for later implementation

```text
accepted spec
→ migrations/schema
→ domain/application code
→ repositories/adapters
→ UI/REST/admin adapter
→ unit tests
→ integration tests
→ architecture tests
→ contract qualification
→ CI green
```

---

## 23. Execution order

```text
P0.0  Common Contracts
P0.1  Revision / Publication / Availability
P0.2  Profession / Catalog
P0.3  Localization
P0.4  Media / RustFS
P0.5  TTS
P0.6  Interview
P0.7  Vocabulary
P0.8  Topic / Phrase / Shadowing Content
P0.9  Assessment
P0.10 Manifest / Content Delivery
P0.11 Pagination Contract
P0.12 Flutter Application Contract
P0.13 Security / Installation
P0.14 Content Studio
P0.15 Integrated ERD + Mobile ERD + OpenAPI
P0.16 Architecture Freeze
```

The next design slice remains **P0.0 Common Contract & Domain Conventions**, followed by **P0.1 Revision / Publication / Availability**. P0.12 now has a complete mobile architecture scope rather than only retention.
