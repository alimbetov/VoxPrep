# CareerSpeak — P0 Domain & Contract Design Plan

**Status:** Working architecture plan  
**Applies to:** VoxPrep / CareerSpeak v0.6+  
**Branch:** `feat/p0-domain-contracts`

---

## 1. Purpose

This document defines the implementation-readiness process for every CareerSpeak bounded context before production coding begins.

The project SHALL NOT treat a module as implementation-ready until its domain model, invariants, persistence model, API/application contracts and acceptance criteria are explicitly agreed.

The goal is to finish P0 with an architecture freeze that reduces structural rewrites during implementation.

---

## 2. Standard design contract for every bounded context

Every bounded context SHALL be specified through the same layers:

```text
DOMAIN SPEC
│
├── scope / responsibility
├── aggregates
├── entities
├── value objects
├── invariants
├── state machines
├── commands / use cases
├── cross-domain dependencies
└── non-goals
        │
        ▼
DATA CONTRACT
│
├── tables
├── PK / FK
├── unique constraints
├── indexes
├── optimistic locking
└── migration rules
        │
        ▼
API / APPLICATION CONTRACT
│
├── endpoint / application port
├── request DTO
├── response DTO
├── pagination
├── filtering / sorting
├── errors
├── idempotency
├── authorization
└── versioning
        │
        ▼
ACCEPTANCE CONTRACT
├── happy path
├── invalid states
├── concurrency
├── failure recovery
└── integration tests
```

A global ERD SHALL be produced only after individual domain ownership has been agreed. The preferred sequence is:

```text
Global domain map
    ↓
Domain-by-domain ERD
    ↓
Integrated ERD
```

---

## 3. P0.0 — Common Contract & Domain Conventions

Before the first bounded context is implemented, the project SHALL define common conventions for:

```text
technical identifiers
stable business codes
timestamps
revision numbers
API versioning
DTO naming
nullability
error contract
cursor pagination
admin pagination
sorting/filtering
idempotency
optimistic concurrency
HTTP semantics
state-transition errors
```

Recommended error envelope:

```json
{
  "code": "CONTENT_REVISION_NOT_FOUND",
  "message": "Content revision was not found",
  "traceId": "...",
  "details": {}
}
```

Consumer collection APIs SHALL use cursor/keyset pagination unless a domain-specific reason is documented otherwise.

Internal Content Studio lists MAY use offset/page-based pagination through Spring `Pageable`.

---

## 4. P0.1 — Revision / Publication / Availability

This is a foundational bounded context because most content domains depend on its lifecycle semantics.

The following concepts SHALL remain separate:

```text
content identity
content revision
publication state
learner availability
```

Example revision lifecycle:

```text
DRAFT
  ↓
READY_FOR_AUDIO
  ↓
READY_FOR_REVIEW
  ↓
PUBLISHED
  ↓
ARCHIVED
```

Availability SHALL be modeled independently:

```text
ACTIVE
INACTIVE
```

Example:

```text
revision_status = PUBLISHED
availability_status = ACTIVE
```

is learner-visible, while:

```text
revision_status = PUBLISHED
availability_status = INACTIVE
```

remains historically published but is excluded from learner catalog APIs and propagated through manifest tombstones.

Required decisions:

- revision ownership;
- immutable transition point;
- publication validation;
- activation/deactivation permissions;
- rollback semantics;
- manifest impact;
- stale media behavior;
- archive behavior.

---

## 5. P0.2 — Profession / Catalog

Core concepts:

```text
Profession
CareerTrack
Specialization
Seniority
Category
Tag
Skill taxonomy
```

Example hierarchy:

```text
Software Engineering
    ↓
Java Backend Developer
    ↓
Spring
    ↓
Senior
```

Required learner contracts include paginated/filterable profession and career-track catalogs.

Stable external `code` values SHALL not depend on database IDs.

---

## 6. P0.3 — Localization

CareerSpeak teaches English only.

Localization is presentation/support data:

```text
UI
translation
hint
explanation
```

Required decisions:

- BCP-47-compatible locale identifiers;
- fallback chain;
- localization readiness states;
- whether missing locale content blocks publication;
- RTL readiness;
- typed localization table ownership.

Example fallback:

```text
kk-KZ
  ↓
kk
  ↓
en
```

A missing secondary localization SHOULD NOT normally block canonical English publication unless a specific pack policy requires it.

---

## 7. P0.4 — Media / FileAsset / RustFS

Core concepts:

```text
FileAsset
StorageObject
AssetRole
AssetLifecycle
```

Storage SHALL be accessed through an application abstraction such as:

```text
ObjectStorage
├── createUploadUrl()
├── createDownloadUrl()
├── stat()
└── delete()
```

RustFS is the initial S3-compatible adapter.

Required metadata includes:

```text
bucket
object_key
checksum
mime_type
size_bytes
duration
codec
bitrate
status
```

Published object keys SHALL be immutable.

Garbage-collection rules SHALL distinguish referenced, superseded, draft and orphan assets.

---

## 8. P0.5 — TTS

Core concepts:

```text
TtsVoice
TtsVoiceModel
TtsVoicePool
TtsVoicePoolMember
TtsVoicePolicy
PronunciationRule
TtsJob
TtsWorker
TtsWorkerCapability
```

Logical voice and immutable model revision SHALL remain separate.

Every generation job SHALL resolve an exact `voice_model_id` before execution.

Job states:

```text
PENDING
RUNNING
READY
FAILED
CANCELLED
SUPERSEDED
```

Reliability contract includes:

```text
worker_id
lease_token
lease_until
attempt_count
fingerprint
heartbeat
stale completion rejection
```

Worker API contract SHALL cover:

```text
claim
heartbeat
model download authorization
complete
fail
```

The worker SHALL NOT connect directly to PostgreSQL and SHALL NOT silently substitute another voice/model.

---

## 9. P0.6 — Interview

Core concepts:

```text
InterviewQuestion
InterviewQuestionRevision
ModelAnswer
InterviewCategory
Profession mapping
CareerTrack mapping
Seniority mapping
Skill mapping
```

Required design areas:

- question/model-answer ownership;
- revisioning;
- question audio;
- answer audio;
- TTS voice policy;
- localization;
- publication qualification;
- filters and cursor pagination.

Example learner endpoints:

```text
GET /api/v1/interviews
GET /api/v1/interviews/{code}
```

---

## 10. P0.7 — Vocabulary

Core concepts:

```text
VocabularyWord
VocabularyRevision
Definition
Example
Collocation
WordFamily
VocabularyCategory
```

Vocabulary content SHOULD use revision semantics rather than mutating learner-visible published content in place.

A revision may own/reference:

```text
definition
examples
collocations
localizations
word audio
example audio
```

Required contracts include CEFR/category filtering, search and cursor pagination.

---

## 11. P0.8 — Topic / Phrase / Shadowing

Core concepts:

```text
Topic
TopicRevision
TopicSection
Phrase
PhraseCategory
```

Important contract fields include:

```text
display_text
tts_text
audio asset
sort_order
```

Shadowing requirements SHALL define how text sections map to audio assets and playback order.

---

## 12. P0.9 — Assessment

Core concepts:

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

Published tests SHALL reference exact question revisions:

```text
PracticeTestRevision
    ├── QuestionRevision A
    ├── QuestionRevision B
    └── QuestionRevision C
```

They SHALL NOT resolve "current question" dynamically at execution time.

This preserves reproducible scoring and review after future question edits.

Required design areas include:

- question-type invariants;
- answer correctness rules;
- scoring;
- skill mapping;
- deterministic result breakdown;
- test revision snapshots;
- local attempt representation in Flutter.

---

## 13. P0.10 — Manifest / Content Delivery

Core concepts:

```text
ContentManifest
ContentPack
PackRevision
AssetReference
Tombstone
```

Required endpoints include:

```text
GET /api/v1/content/manifest
GET /api/v1/content/packs/{code}/manifest
```

Example root manifest:

```json
{
  "schemaVersion": 1,
  "contentVersion": 105,
  "packs": [],
  "tombstones": []
}
```

Manifest design SHALL support:

- pack revisions;
- asset checksums;
- server-side deactivation propagation;
- obsolete revision cleanup;
- re-downloadable content;
- offline-first startup.

---

## 14. P0.11 — Pagination Contract

Pagination SHALL be defined once and reused across learner APIs.

Learner contract baseline:

```json
{
  "items": [],
  "page": {
    "nextCursor": "...",
    "hasMore": true
  }
}
```

Cursor generation SHALL be based on stable deterministic sort keys.

Examples:

```text
sort_order + id
published_at + id
```

The API SHALL NOT require expensive total-count calculations when the client UX does not need them.

Content Studio MAY use:

```text
page
size
sort
```

through `Pageable`.

---

## 15. P0.12 — Flutter Local Domain & Retention

Flutter local state is a first-class domain even though it is not stored on the backend.

Core concepts:

```text
LocalContent
LocalAsset
ContentAssetReference
Download
Favorite
Progress
TestAttempt
ReviewSchedule
CacheEntry
```

Retention states/policies include:

```text
AUTO_CACHE
PINNED
EXPLICIT_DOWNLOAD
EXPIRED
EVICTED
```

Automatic cleanup SHALL combine:

```text
TTL
+
LRU
+
local quota
+
pinning protection
+
asset reference tracking
```

Evicting downloadable content/media SHALL NOT erase learner progress, test history, favorites or review history.

Shared assets SHALL be physically deleted only when no retained content references them.

Cleanup SHOULD be triggered at controlled lifecycle points such as startup, manifest sync, large downloads, quota pressure and explicit "Free space" action rather than relying exclusively on background schedulers.

---

## 16. P0.13 — Security / Installation

Three security contexts SHALL remain separate.

### Human admin

```text
Spring Security session
HttpOnly cookie
Secure
SameSite
CSRF
ADMIN / EDITOR / REVIEWER
```

### TTS worker

```text
machine credential
scope
rotation
revocation
outbound HTTPS only
```

### Consumer

```text
no mandatory account
optional random installationId
```

`installationId` SHALL NOT be joined with learning progress, favorites, profession interests or test history in MVP.

---

## 17. P0.14 — Content Studio

Content Studio is an orchestration and content-production surface, not merely CRUD.

Primary workflow:

```text
Create
  ↓
Validate
  ↓
Localize
  ↓
Generate audio
  ↓
Review
  ↓
Publish
```

Required platform capabilities include:

```text
bulk import
bulk validation
duplicate detection
missing localization report
missing/stale audio report
TTS dashboard
model/voice registry
publication qualification
pagination/filtering/search
```

---

## 18. Modular-monolith interaction rules

Modules SHALL NOT mutate another module's persistence through foreign repositories merely because they share one PostgreSQL database.

Preferred interaction:

```text
caller module
    ↓
owner application port/service
    ↓
owner domain/persistence
```

Example conceptual boundary:

```text
Interview
    ↓
Publication application contract
```

rather than direct writes to publication tables.

A preliminary dependency map is:

```text
                     CATALOG
                       │
             ┌─────────┼─────────┐
             ▼         ▼         ▼
         INTERVIEW VOCABULARY   TOPIC
             │         │         │
             └────┬────┴────┬────┘
                  ▼         ▼
             LOCALIZATION  ASSESSMENT
                  │         │
                  └────┬────┘
                       ▼
                  PUBLICATION
                       │
               ┌───────┴───────┐
               ▼               ▼
             MEDIA            TTS
               │               │
               └───────┬───────┘
                       ▼
                    MANIFEST
                       │
                       ▼
                    FLUTTER
```

The final dependency direction SHALL be validated and minimized during domain design.

---

## 19. Definition of Ready — bounded context

A bounded context is `DOMAIN READY` only when all applicable items are agreed:

```text
[ ] scope and ownership
[ ] aggregates
[ ] entities/value objects
[ ] invariants
[ ] lifecycle/state machine
[ ] DB schema
[ ] PK/FK/unique constraints
[ ] indexes
[ ] optimistic concurrency
[ ] public/application DTOs
[ ] API/application ports
[ ] pagination/filtering/sorting
[ ] authorization
[ ] error codes
[ ] idempotency
[ ] failure behavior
[ ] concurrency behavior
[ ] acceptance tests
```

---

## 20. Definition of Done — implementation

Implementation completion follows:

```text
approved spec
    ↓
Liquibase migration
    ↓
domain/application implementation
    ↓
persistence adapters
    ↓
REST/Admin/internal adapters
    ↓
unit tests
    ↓
integration tests
    ↓
architecture tests
    ↓
OpenAPI/contract qualification
    ↓
CI green
```

---

## 21. P0 execution order

The approved design order is:

```text
P0.0  Common Contract & Domain Conventions
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

`P0.0` and `P0.1` SHALL be completed before production domain entities/controllers are created because they define shared identity, revision, state, pagination, error and concurrency semantics.

---

## 22. P0 exit criteria

P0 is complete only when:

1. every bounded context has a documented owner and explicit non-goals;
2. cross-module dependencies are agreed;
3. integrated PostgreSQL ERD is consistent with domain ownership;
4. learner/admin/internal APIs are contractually defined;
5. TTS/media/manifest failure semantics are documented;
6. pagination and retention behavior are deterministic;
7. ADRs capture the principal architecture decisions;
8. the architecture baseline can be frozen for implementation.

After P0 exit, P1 may begin with the executable Spring Boot/Flutter/TTS-worker foundation.
