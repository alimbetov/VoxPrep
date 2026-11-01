# CareerSpeak Backend Design Baseline v1

**Status:** FROZEN BACKEND DESIGN INPUT  
**Branch baseline:** `feat/flutter-adversarial-hardening`  
**Flutter baseline SHA at freeze start:** `6fe88340d905add4e0ae701a56d6c8d8c311f974`  
**Purpose:** authoritative input for backend domain/schema/API design. This document does **not** implement Spring Boot.

## 1. Decision

The Flutter side is sufficiently specified and adversarially hardened to begin backend design without inventing product semantics in the backend.

Backend design SHALL treat the following as fixed external behavior:

```text
publication identity and exact revision membership
installation identity/token lifecycle
learner API endpoint shapes and exact-target semantics
backend-authorized media delivery
localization identity
assessment revision identity
universal Vertical → Goal → Track → Collection hierarchy
fail-closed behavior on inconsistent publication data
local ownership of learner progress/review/attempt state
```

If a future backend proposal conflicts with this baseline, the backend proposal changes — not the Flutter contract — unless a deliberately versioned cross-system contract change is approved.

---

## 2. Normative precedence

Use documents in this order:

1. `docs/specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`
2. `docs/specification/CAREERSPEAK_MVP_DELIVERY_SCOPE.md`
3. `docs/specification/CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`
4. **this document**
5. `docs/architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`
6. focused frozen contracts:
   - `C4_ATOMIC_PUBLICATION_CONTRACT.md`
   - `C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`
   - `C5_MEDIA_SECURITY_CONTRACT.md`
   - `C1_LOCALIZATION_FALLBACK_CONTRACT.md`
   - `C2_TYPED_CONTENT_CATALOG_CONTRACT.md`
   - `C3_ASSESSMENT_CONTRACT.md`
   - `UNIVERSAL_VERTICAL_CATALOGUE_CONTRACT_FREEZE_V1_1.md`
7. TTS contracts
8. gap audits / remediation plans / historical roadmaps

Gap audits describe how the architecture reached the current state. They MUST NOT override a newer frozen contract.

---

## 3. System boundary

CareerSpeak v1 has four infrastructure/runtime boundaries:

```text
Flutter App
   ↓ /api/v1/**
Backend modular monolith
   ├── PostgreSQL
   ├── private RustFS
   └── /internal/v1/tts/**
          ↓
       TTS Worker
```

Security actors remain exactly:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

Recommended backend shape for v1 is a **modular monolith**, not microservices. Domain modules may be separated internally, but publication must retain one transactional consistency boundary.

---

## 4. Ownership — do not duplicate Flutter learner state on the server

### Backend owns product truth

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
Content + immutable ContentRevision
ContentLocalizationRevision
PracticeTest + immutable PracticeTestRevision
Question + immutable QuestionRevision
Catalogues / taxonomy / locale capabilities
PublicationSnapshot
FileAsset / media metadata
TTS voice/model/job state
Installation security state
Admin authoring/review/publication state
```

### Flutter owns learner truth in MVP

```text
onboardingCompleted
selectedGoalCode
selectedTrackCode
selfAssessedLevelCode
uiLocale
translationLocale
preferredAccent / preferredVoiceCode
favorites
listened/completed markers
last opened / continue-learning state
reviewStage / nextReviewAt / lastReviewOutcome
active PracticeTest attempt
PracticeTest completion/history
local media cache / playback position
```

Backend MUST NOT introduce a learner profile/account aggregate merely to persist these fields in v1.

`selectedVerticalCode` is not durable learner state. Flutter derives Vertical from the selected CURRENT Goal.

---

## 5. Core business hierarchy

The only v1 learning hierarchy is:

```text
Vertical
 ↓
LearningGoal
 ↓
LearningTrack
 ↓
LearningCollection
 ↓
exact ContentRevision / PracticeTestRevision membership
```

Stable business `code` is the cross-system identity for catalogue entities.

Numeric database IDs may exist internally but MUST NOT become Flutter learner-domain identity.

Deactivation/removal is fail-closed. Backend must never require Flutter to guess a replacement sibling.

---

## 6. Backend aggregate boundaries

Recommended aggregate/module boundaries:

### 6.1 Catalogue

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
CatalogueRevision
```

Catalogue entities use stable business codes and mutable authoring state. Learner delivery uses immutable revisioned projections referenced by publication.

### 6.2 Learning content

```text
Content
ContentRevision
TypedContentBody
ContentLocalizationRevision
```

`ContentRevision` is immutable once published. Do not model the public polymorphic DTO as one generic EAV table.

Typed bodies must support the product types frozen in C2, including at least:

```text
VOCABULARY
INTERVIEW
TOPIC
PHRASE
SHADOWING
```

Shared envelope fields and type-specific bodies should be distinct persistence/domain concepts.

### 6.3 Assessment

```text
PracticeTest
PracticeTestRevision
Question
QuestionRevision
PracticeTestQuestionRef
```

A PracticeTestRevision references exact QuestionRevision identities and deterministic order. Historical revisions are never rewritten.

### 6.4 Publication

```text
PublicationSnapshot
PublicationPackRef
PublicationCatalogueRef
PublicationPracticeTestRef
Tombstone
```

This is the release barrier for learner-visible truth.

### 6.5 Media

```text
FileAsset
ContentAssetRef
PackAssetRef
```

`FileAsset` holds backend storage identity/metadata; Flutter receives only stable `assetId`, media metadata and checksum, never RustFS credentials or storage URLs.

### 6.6 Installation security

```text
Installation
InstallationCredential/TokenVerifier
```

Installation identity is app-installation identity, not user identity and not hardware identity.

### 6.7 TTS

```text
TtsVoice
TtsVoiceModel
TtsJob
FileAsset output
```

Worker remains an execution agent and owns no PostgreSQL/RustFS credentials.

---

## 7. Publication invariant — highest-priority backend rule

Backend MUST never build the learner root dynamically from whatever mutable rows happen to be current at request time.

Required flow:

```text
DRAFT/authoring data
      ↓
materialize immutable exact revisions
      ↓
validate complete publication candidate
      ↓
calculate deterministic checksums
      ↓
allocate monotonic contentVersion
      ↓
persist immutable PublicationSnapshot + exact refs
      ↓
atomically switch current learner root
      ↓
COMMIT
```

A failed transaction exposes **none** of the candidate.

Required properties:

- `contentVersion` is monotonic and never reused for different content;
- one `contentVersion` maps to exactly one immutable root checksum;
- every pack/catalogue/content/localization/test ref is exact by revision/checksum;
- no half-old/half-new publication is observable;
- auth/token rotation never changes publication identity;
- storage/signed-delivery state never changes publication identity;
- tombstones are explicit publication evidence, not inferred from absence.

Flutter is intentionally fail-closed when CURRENT membership exists but its exact local payload is missing/corrupt. Backend must provide enough exact identity to make this invariant enforceable.

---

## 8. Frozen learner API surface consumed by Flutter

The following paths are already represented by production Flutter gateways and therefore form the backend v1 design surface.

### Anonymous configuration

```http
GET /api/v1/configuration/locales?countryCode=KZ
```

Anonymous. Response contains exactly:

```json
{
  "countryCode": "KZ",
  "defaultLocale": "ru",
  "locales": [
    {"code": "ru", "label": "Русский"}
  ]
}
```

### Installation credential issuance

```http
POST /api/v1/installations
```

Anonymous request:

```json
{
  "installationId": "<random app-scoped UUID-v4 identity>"
}
```

Success: HTTP 200 with a fresh opaque token.

```json
{
  "installationToken": "opaque-token"
}
```

Every cold bootstrap asks for a fresh token using the same installationId.

### Root publication manifest

```http
GET /api/v1/content/manifest
If-None-Match: <etag>   # optional
```

Authenticated.

Allowed success semantics:

```text
200 + immutable root body (+ ETag)
304 only when request contained a valid If-None-Match
```

Root identity is locale-independent.

### Exact pack manifest

```http
GET /api/v1/content/packs/{packCode}/manifest?variant={variant}&revision={revision}
```

Authenticated. Returned code/variant/revision/checksum MUST match the exact root ref.

### Exact universal catalogue payload

```http
GET /api/v1/catalogues/{kind}/revisions/{revision}
```

Authenticated.

Response wire envelope is exactly:

```json
{
  "kind": "learning-goals",
  "revision": 14,
  "checksum": "<sha256>",
  "items": []
}
```

The payload must not add request/session/token-specific fields because catalogue checksum is publication identity.

### Exact canonical content payload

```http
GET /api/v1/content/{contentType}/{contentCode}/revisions/{revision}
```

Authenticated. Identity/revision/checksum must exactly match the PackContentRef.

### Exact localized content payload

```http
GET /api/v1/content/{contentType}/{contentCode}/revisions/{contentRevision}/localizations/{locale}/revisions/{localizationRevision}
```

Authenticated. Identity includes:

```text
contentCode
contentType
contentRevision
locale
localizationRevision
checksum
```

Localized payload must not duplicate or redefine canonical English/audio identity.

### Assessment

```http
GET /api/v1/assessment/practice-tests/{practiceTestCode}/revisions/{revision}
GET /api/v1/assessment/questions/{questionCode}/revisions/{revision}
```

Authenticated. Returned exact identities must match publication/test membership.

### Learner media

```http
GET /api/v1/media/assets/{assetId}/content
Authorization: Bearer <installationToken>
```

Backend streams bytes itself in v1. No redirect to RustFS/CDN/object storage.

Important media statuses consumed by Flutter:

```text
2xx → byte stream
401 → installation credential rejected
403 → asset not permitted
404 → published asset not found
409 → asset not ready
408/429/5xx → transient/retryable source failure
```

---

## 9. Authentication and token model

`installationId` generation belongs to Flutter and uses a cryptographically secure random 128-bit UUID-v4-shaped value.

Explicitly forbidden as identity source:

```text
IMEI
serial number
MAC address
advertising identifier
other hardware/tracking identifier
MD5 or another hash of hardware identity
```

Backend stores installation status and token verification state. Plaintext tokens should not be persisted or logged.

Cold bootstrap:

```text
installationId
→ POST /api/v1/installations
→ fresh installationToken
→ Flutter atomically replaces old token
```

401 recovery:

```text
request
→ 401
→ one single-flight re-issuance for same installationId
→ replace token
→ replay safe request once
→ second 401 = fail closed
```

Revoked installation must not be bypassed by silently creating a different installation identity.

---

## 10. Checksum and immutable DTO rule

Checksums are part of the cross-system consistency protocol, not cosmetic metadata.

Backend must define one deterministic canonicalization implementation for:

```text
RootContentManifest
PackContentManifest
CataloguePayload
ContentPayload
LocalizedContentPayload
PracticeTestRevision / referenced question identity where contract requires
FileAsset bytes = SHA-256 over exact bytes
```

Never include these in publication checksums:

```text
Authorization token
installationId
request timestamp
traceId
signed URL / URL expiry
storage endpoint
server-local numeric ID
```

Flutter validates exact revision/checksum targets and fails closed on mismatch.

---

## 11. Error contract

JSON errors use stable machine-readable codes and safe messages:

```json
{
  "code": "SOME_STABLE_CODE",
  "message": "Safe external message",
  "traceId": "optional-trace-id",
  "details": {}
}
```

Do not expose SQL exceptions, filesystem paths, RustFS credentials, stack traces, tokens or internal exception text.

Backend should consistently support:

```text
400 contract/input violation
401 invalid/rejected installation credential
403 authenticated but forbidden
404 exact published object absent
409 state conflict / asset not ready where contracted
429 rate limited (+ Retry-After)
5xx transient/internal failure
```

---

## 12. Retry and idempotency

Safe immutable GETs may be retried with bounded policy.

`POST /api/v1/installations` must be replay-safe for the same installationId and is the only learner-facing mutation currently required by Flutter bootstrap.

Backend must not rely on client infinite retry.

429 responses should provide `Retry-After` where possible.

---

## 13. Storage boundary

RustFS is private backend infrastructure.

```text
Flutter → Backend → RustFS
Worker  → Backend → RustFS
```

Forbidden:

```text
Flutter → RustFS endpoint
Flutter → bucket/object key as URL
Flutter → storage credentials
Worker → RustFS credentials
Worker → PostgreSQL
```

`deliveryKey` is backend-internal storage metadata. It is stable enough to participate in backend asset resolution but is not a client URL or authorization token.

---

## 14. TTS backend design

Keep the already accepted PostgreSQL durable queue model:

```sql
SELECT ...
FROM tts_job
WHERE status = 'PENDING'
ORDER BY created_at
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

Required lifecycle includes:

```text
PENDING
→ leased/processing
→ heartbeat
→ output upload
→ READY
or FAILED/retry
```

Claim/heartbeat/complete/fail is lease-token protected. Expired/stale worker completion must be rejected.

Recommended backend implementation stream remains:

```text
B1 tts_voice + tts_voice_model catalog
B2 FileAsset + tts_job persistence
B3 atomic claim + lease
B4 model delivery API
B5 heartbeat/fail
B6 RustFS output finalization
B7 replay-safe output
B8 real acceptance
```

Do not let TTS state leak into publication identity until the resulting FileAsset is ready and explicitly selected by a published revision.

---

## 15. Suggested backend modules

Recommended package/module boundaries:

```text
catalogue
content
assessment
publication
localization
media
installation
admin
tts
shared-contract
```

Avoid generic `common-service`, EAV content, and cross-module repositories.

Database tables may be normalized differently from API DTOs. JPA entities are persistence models, not wire contracts.

---

## 16. Suggested implementation order

Backend design/implementation should proceed in this order:

```text
B0  architecture + module boundaries + contract test harness
B1  installation security
B2  immutable catalogue/content/assessment revision model
B3  universal Vertical catalogue persistence
B4  publication snapshot + atomic CURRENT pointer
B5  learner manifest/exact payload APIs
B6  localization
B7  FileAsset + Backend-authorized media streaming
B8  Admin authoring/review/publication
B9  TTS domain + Worker API + RustFS finalization
B10 cross-system acceptance
```

The exact internal numbering can change; the dependency direction should not.

Publication is not an afterthought: schemas for content/catalogues must be designed with immutable revisions and PublicationSnapshot refs from the start.

---

## 17. Database design constraints

Before writing migrations, enforce these conceptual uniqueness rules:

```text
business catalogue code unique within type
(contentCode, revision) immutable identity (plus type where code namespace is shared)
(contentCode, contentRevision, locale, localizationRevision) immutable localization identity
(practiceTestCode, revision) immutable identity
(questionCode, revision) immutable identity
publication contentVersion unique and never reused
one backend CURRENT publication pointer
assetId unique
asset checksum SHA-256 validated
installationId unique
TTS lease ownership concurrency-safe
```

Where content codes may overlap across types, use `(contentType, contentCode)` as business identity, matching Flutter.

Published data is append-only from the learner-delivery perspective. Corrections create a new revision and new publication.

---

## 18. Backend non-goals for MVP

Do **not** add these while designing v1:

```text
learner account/profile service
OAuth/OIDC/Keycloak for learners
refresh-token flow
recommendation engine
workflow/rules engine
AI personalization domain
server-side Review scheduler
server-side learner progress
social graph
leaderboards
remote UI schema
EAV learning content
microservice split of the publication transaction
RabbitMQ/Kafka only for TTS queueing
client-visible RustFS/S3 URLs
```

Admin authentication is a separate security zone and does not change learner installation auth.

---

## 19. Contract testing required before backend acceptance

Backend must provide producer tests/fixtures that are consumed against the same invariants Flutter already enforces.

Minimum contract qualification:

```text
root 200/304 semantics
root/pack canonical checksum
manifest v2 complete universal catalogue membership
exact catalogue revision match
exact content revision/checksum match
localized exact identity
assessment exact revision graph
malformed/unknown fields fail contract validation
atomic publication no half-state
concurrent publication serialization
installation token rotation + revoked installation
one-shot 401 compatibility
media auth/status/byte integrity
TTS claim lease/reclaim/stale completion
```

A backend build is not integration-ready merely because controllers return JSON.

---

## 20. Backend design readiness verdict

With this baseline and the referenced focused contracts:

```text
Product semantics          FROZEN for MVP design
Flutter ownership          FROZEN
Learner hierarchy          FROZEN
Publication model          FROZEN
Installation security      FROZEN
Media boundary             FROZEN
Localization identity      FROZEN
Assessment identity        FROZEN
TTS worker boundary        FROZEN
Backend internal schema    READY TO DESIGN
Spring Boot implementation NOT STARTED by this document
```

The next backend activity may safely be **domain/module/schema design**, followed by an explicit learner OpenAPI generated from these contracts and contract fixtures.

Do not redesign Flutter while doing normal backend persistence design. Change cross-system contracts only when an actual incompatibility is proven and versioned.