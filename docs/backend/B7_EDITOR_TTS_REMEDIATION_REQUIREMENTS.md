# VoxPrep — B7 Editor / TTS Remediation Requirements

**Document version:** 1.0  
**Status:** Normative implementation baseline  
**Branch:** `feat/b7-editor-tts-remediation`  
**Baseline:** `fcd3a93729d753bc3635dbc9572c80e4b7d57cfa`  
**Scope:** B7 completion only; defects in Content→TTS planning, role-aware audio binding, publication validation and Content Studio MVC qualification.  
**Out of scope:** B8 monetization, new learner features, Worker rewrite, TTS engine replacement, QUESTION/PRACTICE_TEST TTS expansion.

---

## 1. Purpose

This document freezes the remediation required before `B7 ACCEPTED`.

The current lower TTS execution pipeline is accepted as the baseline:

```text
tts_job
  → lease/claim
  → Worker
  → Piper
  → MP3
  → FileAsset
```

The missing production boundary is above that pipeline:

```text
ContentRevision
  → authoritative audio-role policy
  → deterministic text planning
  → TTS job preparation
  → role-aware content asset binding
  → publication validation
  → Content Studio MVC
```

The implementation SHALL fix this missing boundary without moving content semantics into the Worker and without introducing a second authoring or media stack.

---

## 2. Architectural decisions

The following decisions are frozen for this remediation stream.

### 2.1 Worker remains a synthesis executor

The Worker SHALL continue to receive a prepared immutable claim containing at least:

```text
contentRevisionId
audioRole
normalizedTtsText
language
voiceModel identity
fingerprint
lease identity
```

The Worker MUST NOT know about JPA entities, MVC forms, publication lifecycle or content-type-specific extraction rules.

### 2.2 One authoritative Content→TTS policy

Content audio semantics SHALL be defined once in backend domain/application code and reused by:

```text
TTS planning
TTS job preparation
MVC projections / 🔊 indicators
publication validation
automated tests
```

Thymeleaf, JavaScript, Worker code and controllers MUST NOT duplicate ContentType→audioRole rules.

### 2.3 Existing v1 audio-role policy is authoritative

Supported v1 mappings are:

| Content type | Audio role | Requirement |
| --- | --- | --- |
| `VOCABULARY` | `pronunciation` | `OPTIONAL` |
| `PHRASE` | `pronunciation` | `RECOMMENDED` |
| `INTERVIEW` | `question` | `RECOMMENDED` |
| `INTERVIEW` | `sampleAnswer` | `RECOMMENDED` |
| `TOPIC` | `narration` | `OPTIONAL` |
| `SHADOWING` | `shadowing` | `REQUIRED` |

`QUESTION` and `PRACTICE_TEST` SHALL remain unsupported for TTS in v1.

Unknown role/content-type combinations MUST fail closed.

### 2.4 TTS process entity is not learner truth

`TtsJob` represents generation work. The durable product-level result SHALL be a role-aware binding:

```text
ContentRevision + audioRole → FileAsset
```

Learner/publication logic MUST NOT use `TtsJob` as the source of truth for final content audio selection.

### 2.5 MVC remains a thin adapter

The Content Studio SHALL use:

```text
Spring MVC + Thymeleaf + HTMX
```

and SHALL follow:

```text
HTML Form
  → Form DTO
  → mapper / application command
  → existing application/domain services
```

MVC controllers MUST NOT contain business rules or access repositories directly.

---

## 3. TTS-R1 — Domain audio policy

### 3.1 Required types

Add a typed role model equivalent to:

```java
ContentAudioRole
AudioRequirement
ContentAudioPolicyEntry
ContentAudioPolicy
```

Required wire roles:

```text
pronunciation
question
sampleAnswer
narration
shadowing
```

### 3.2 Required behavior

The policy SHALL expose supported roles for a `ContentType` and SHALL reject invalid combinations.

Minimum qualification matrix:

```text
VOCABULARY + pronunciation  → allowed
VOCABULARY + narration      → rejected
PHRASE + pronunciation      → allowed
INTERVIEW + question        → allowed
INTERVIEW + sampleAnswer    → allowed
SHADOWING + shadowing       → allowed
QUESTION + any role         → rejected
PRACTICE_TEST + any role    → rejected
```

### 3.3 Compatibility

Persistence/API wire values MAY remain strings where needed, but conversion into the typed policy MUST occur before semantic use.

---

## 4. TTS-R2 — Deterministic ContentTtsPlanner

### 4.1 Required component

Add an application/domain service equivalent to:

```java
ContentTtsPlanner
```

with a deterministic output equivalent to:

```java
TtsUtterance(
    ContentAudioRole role,
    AudioRequirement requirement,
    String normalizedText,
    String language,
    String fingerprintInput
)
```

### 4.2 Field mapping

The following mapping is frozen for v1.

#### VOCABULARY

```text
term → pronunciation
```

`definition`, `partOfSpeech` and `examples[]` are text-only in v1.

#### PHRASE

```text
phrase → pronunciation
```

`usage` and `examples[]` are text-only in v1.

#### INTERVIEW

```text
prompt      → question
modelAnswer → sampleAnswer
```

`keyPoints[]` are text-only in v1.

#### TOPIC

One audio asset SHALL represent the complete topic narration.

Deterministic source:

```text
ordered sections[].text
  → normalized
  → joined with exactly one blank line between sections
  → narration
```

Section headings SHALL NOT be spoken in v1.

#### SHADOWING

```text
transcript → shadowing
```

One audio asset SHALL represent the full shadowing revision. `segments[]` remain learner timing/segmentation metadata and SHALL NOT create separate TTS roles.

#### QUESTION / PRACTICE_TEST

TTS planning MUST reject these content types in v1.

### 4.3 Text normalization

Add one reusable deterministic normalizer equivalent to:

```java
TtsTextNormalizer
```

It SHALL at minimum:

- reject null/blank text;
- normalize line endings to `\n`;
- strip surrounding whitespace;
- normalize repeated horizontal whitespace deterministically;
- normalize blank-line runs deterministically;
- apply one explicit Unicode normalization form;
- produce the same output for the same semantic source text.

Normalizer behavior SHALL be versioned logically because it affects fingerprints and regeneration semantics.

---

## 5. TTS-R3 — TtsJobPreparationService and idempotency

### 5.1 Required service

Add one application service equivalent to:

```java
TtsJobPreparationService
```

Input SHALL identify at least:

```text
exact content revision
audio role
language
voice/model selection
```

### 5.2 Required flow

```text
load exact ContentRevision
  → validate supported role
  → call ContentTtsPlanner
  → obtain normalized utterance
  → resolve active voice/model
  → compute canonical fingerprint
  → reuse existing semantic job/result when applicable
  → otherwise create one PENDING job
```

### 5.3 Fingerprint contract

The fingerprint SHALL include enough immutable semantic input to prevent accidental reuse across materially different synthesis requests.

Minimum components:

```text
fingerprint schema/version
contentRevision identity
audioRole
normalizedTtsText
language
voiceModel immutable identity/version
normalizer version
audio profile where relevant
```

### 5.4 Idempotency

Repeated generation requests with identical semantic input MUST NOT create duplicate semantic synthesis work.

Acceptance:

```text
Generate TTS
Generate TTS
same revision/role/text/model
→ one canonical semantic job/result
```

Retry/recovery SHALL use existing job lifecycle semantics rather than silently manufacturing new semantic jobs.

---

## 6. TTS-R4 — Role-aware ContentAsset binding

### 6.1 Required domain result

Introduce or reuse exactly one existing role-aware binding model representing:

```text
(content_revision_id, audio_role) → file_asset_id
```

If no suitable existing entity exists, add one equivalent to `ContentAssetBindingEntity`.

### 6.2 Required invariants

- one active binding per `(contentRevisionId, role)`;
- referenced asset exists;
- referenced asset is `READY` before becoming publication-valid;
- referenced media type begins with `audio/` for audio roles;
- binding role is allowed by `ContentAudioPolicy`;
- asset belongs to the exact content revision generation context;
- replacement creates/repoints the binding without mutating historical immutable FileAsset content.

### 6.3 Stale semantics

If the source TTS text changes while an older binding still exists, the older audio SHALL be considered `STALE` for the mutable draft.

It MUST NOT be deleted automatically.

Regeneration SHALL produce a new semantic result and update the draft binding.

---

## 7. TTS-R5 — Publication audio validation

Add one backend validator equivalent to:

```java
ContentAudioPublicationValidator
```

It SHALL evaluate exact revisions and exact role-aware asset bindings.

Required rules:

### SHADOWING

```text
missing shadowing binding        → ERROR
asset not READY                  → ERROR
mediaType not audio/*            → ERROR
```

Publication MUST be blocked.

### INTERVIEW

```text
missing question                 → WARNING
missing sampleAnswer             → WARNING
```

Publication MAY proceed.

### PHRASE

```text
missing pronunciation            → WARNING
```

Publication MAY proceed.

### VOCABULARY

Missing `pronunciation` is allowed without warning.

### TOPIC

Missing `narration` is allowed without warning.

Invalid/unknown role bindings MUST be blocking errors.

---

## 8. TTS-R6 — Production acceptance

Keep the existing low-level real Worker/Piper acceptance as an infrastructure test.

Add a second product-level acceptance that MUST exercise:

```text
ContentRevision
  → ContentTtsPlanner
  → TtsJobPreparationService
  → PENDING tts_job
  → Worker claim
  → real Piper synthesis
  → MP3
  → FileAsset READY
  → role-aware ContentAsset binding
```

The product-level acceptance MUST NOT create `tts_job` by direct SQL as the authoritative path.

Minimum scenarios:

1. PHRASE pronunciation end-to-end success.
2. INTERVIEW creates independent `question` and `sampleAnswer` plans/jobs.
3. Duplicate prepare is idempotent.
4. SHADOWING without READY audio blocks publication.
5. Changed source text marks prior binding stale and requires regeneration.

---

## 9. MVC-R1 — Content Studio foundation

Only after TTS-R1..R6 contracts are stable, implement MVC on top of them.

Required surface:

```text
/admin/**
```

with ADMIN authentication and CSRF protection.

Required technical baseline:

```text
Spring MVC
Thymeleaf
HTMX
Bootstrap / existing admin styling
Form DTOs
MapStruct or explicit structural mappers
```

MVC MUST NOT bind directly to JPA entities.

---

## 10. MVC-R2 — Content edit forms

The visual editor SHALL expose real current ContentRevision fields.

### VOCABULARY

```text
term              🔊 pronunciation
definition
partOfSpeech
examples[]
```

### PHRASE

```text
phrase            🔊 pronunciation
usage
examples[]
```

### INTERVIEW

```text
prompt            🔊 question
modelAnswer       🔊 sampleAnswer
keyPoints[]
```

### TOPIC

```text
sections[].heading
sections[].text
narration status/control is shown once for the whole revision
```

### SHADOWING

```text
transcript        🔊 shadowing
segments[].text
segments[].startMs
segments[].endMs
```

### QUESTION / PRACTICE_TEST

No TTS marker or Generate TTS control in v1.

The `🔊` marker SHALL come from backend audio policy/projection and MUST NOT be separately hard-coded as a second policy in the template.

---

## 11. MVC-R3 — Audio/TTS controls

For each supported role the form SHALL show an audio state.

Required states:

```text
MISSING
PENDING
PROCESSING
READY
FAILED
STALE
```

Recommended controls by state:

```text
MISSING    → Generate TTS
PENDING    → status only
PROCESSING → status only
READY      → Play / Regenerate
FAILED     → error summary / Retry or Regenerate
STALE      → Regenerate
```

The UI SHALL show role and requirement (`OPTIONAL`, `RECOMMENDED`, `REQUIRED`) clearly enough for the operator to understand publication readiness.

For INTERVIEW the UI SHALL expose two independent controls:

```text
Question audio
Sample answer audio
```

They MUST NOT share a single ambiguous audio state.

---

## 12. MVC-R4 — MVC and mapper qualification

### 12.1 Unit tests

Required coverage includes:

```text
ContentAudioPolicyTest
ContentTtsPlannerTest
TtsTextNormalizerTest
TtsFingerprintTest
Form DTO ↔ application command mapper tests
```

### 12.2 Integration tests

Required coverage includes:

```text
TtsJobPreparationIntegrationTest
ContentAssetBindingIntegrationTest
ContentAudioPublicationValidationTest
```

### 12.3 MVC tests

Use `@WebMvcTest` / `MockMvc` or equivalent focused MVC qualification.

Minimum scenarios:

```text
GET edit form                          → 200
POST valid mutable draft               → success/redirect
POST invalid form                      → validation errors
missing CSRF                           → rejected
unknown revision                       → 404
published immutable revision mutation  → rejected/new-draft flow
optimistic-lock conflict               → explicit conflict handling
Generate supported TTS role            → accepted
Generate unsupported role              → rejected
QUESTION/PRACTICE_TEST TTS request      → rejected
```

Raw stack traces, SQL details, filesystem paths, object-store secrets and Worker credentials MUST NOT be rendered in MVC error responses.

---

## 13. Publication/readiness UI

The Content Studio SHOULD expose publication readiness using backend validation results, for example:

```text
Content                         Status
------------------------------------------------
INTERVIEW question audio        READY
INTERVIEW sampleAnswer audio    MISSING / WARNING
SHADOWING shadowing audio       MISSING / ERROR
ru-KZ localization              APPROVED

Publish readiness: BLOCKED
```

The UI MUST NOT implement its own independent interpretation of REQUIRED/RECOMMENDED/OPTIONAL.

---

## 14. Explicit non-goals

The following are NOT part of this remediation stream:

- adding TTS to `QUESTION`;
- adding TTS to `PRACTICE_TEST`;
- vocabulary definition/examples audio;
- phrase examples audio;
- per-section TOPIC assets;
- per-segment SHADOWING assets;
- replacing Piper;
- rewriting Worker lease/heartbeat/recovery;
- introducing Kafka/RabbitMQ for ordinary TTS preparation;
- creating a separate admin SPA;
- B8 purchase verification or entitlement work;
- changing B6 atomic publication semantics;
- changing B7 CURRENT publication learner boundary.

Any of these requires a separate explicit scope decision.

---

## 15. No-rewrite boundaries

Unless a qualification defect proves otherwise, the remediation SHALL preserve:

```text
TtsJobLeaseService
Worker ClaimedJob contract
Worker heartbeat / lease-loss behavior
Piper adapter
RustFS output finalization
existing ContentRevision inheritance model
B6 atomic publication CURRENT model
B7 learner publication resolver
```

The goal is to fill the missing orchestration/domain boundary, not redesign stable subsystems.

---

## 16. Implementation order

The branch SHALL progress in this order:

```text
TTS-R1  typed ContentAudioPolicy
   ↓
TTS-R2  TtsTextNormalizer + ContentTtsPlanner
   ↓
TTS-R3  TtsJobPreparationService + fingerprint/idempotency
   ↓
TTS-R4  role-aware ContentAsset binding + stale semantics
   ↓
TTS-R5  publication audio validation
   ↓
TTS-R6  product-level real TTS acceptance
   ↓
MVC-R1  server-rendered Content Studio foundation
   ↓
MVC-R2  content-type edit forms
   ↓
MVC-R3  role-aware audio controls/status
   ↓
MVC-R4  unit/integration/MockMvc qualification
   ↓
B7 ACCEPTED
```

Implementation SHALL use sequential logical commits. Do not create a branch per sub-step.

---

## 17. Definition of Done

This remediation stream is complete only when all of the following are proven on one exact commit SHA:

1. Content audio roles are typed and fail closed.
2. All five supported content types have deterministic planner behavior.
3. QUESTION/PRACTICE_TEST remain explicitly unsupported for TTS.
4. Job preparation is deterministic and idempotent.
5. Worker continues to receive prepared `normalizedTtsText` and does not parse content semantics.
6. Successful Worker output becomes a role-aware content asset binding.
7. Changed source text results in STALE audio semantics until regeneration.
8. SHADOWING missing audio blocks publication.
9. INTERVIEW/PHRASE missing recommended audio produce warnings, not blockers.
10. MVC shows only policy-backed TTS controls.
11. Form DTOs do not bind directly to JPA entities.
12. Unit, integration, MVC and real product-level TTS acceptance are green.
13. Existing B1 Backend Foundation Qualification remains green.
14. Existing real Worker/Piper infrastructure acceptance remains green.
15. No B6/B7 publication invariants are weakened.

Final acceptance chain:

```text
MVC edit
  → exact mutable ContentRevision
  → ContentTtsPlanner
  → normative role + normalized text
  → TtsJobPreparationService
  → PENDING job
  → Worker/Piper
  → READY FileAsset
  → role-aware binding
  → publication validation
  → atomic publish
  → CURRENT publication
  → learner audio delivery
```

Only after this exact-SHA qualification may the project declare `B7 ACCEPTED` and continue to B8 monetization.
