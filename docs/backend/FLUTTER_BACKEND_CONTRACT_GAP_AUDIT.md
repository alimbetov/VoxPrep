# Flutter ↔ Backend Contract Gap Audit

Status: **AUDIT / DESIGN INPUT**  
Source baseline: `feat/p2-flutter-production-adapters` @ `c59c653475732cc1008d112306abe4248693afd9`

## Purpose

This document freezes the current observations about the Flutter ↔ Backend boundary before backend domain implementation starts.

The goal is not to mirror Flutter classes in the backend. The goal is to define which product data is **backend-owned**, which state is **device-owned**, and which missing contracts must be added so Flutter does not become the source of truth for product catalogs or learning content.

## Current state

The production content path is already structurally correct:

```text
Backend
  ↓
RootContentManifest / PackContentManifest / ContentPayload
  ↓
remote DTO + decoder + mapper
  ↓
Drift projection
  ↓
ContentRepository
  ↓
Flutter domain model
  ↓
UI
```

The current backend learner API already covers:

- installation registration;
- root content manifest;
- pack manifests;
- immutable content payload revisions;
- content tombstones;
- asset descriptors;
- content ↔ asset relations;
- revision and checksum semantics.

The current content types are:

- `vocabulary`
- `interview`
- `topic`
- `shadowing`
- `phrase`

The current `ContentPayload` already carries product-owned display data:

- `contentCode`
- `contentType`
- `revision`
- `checksum`
- `title`
- `subtitle`
- `description`
- `categoryCode`
- `categoryLabel`
- `levelCode`
- `levelLabel`
- `minutes`
- `hasAudio`

This is the correct direction: Flutter projects backend-owned data into local read models instead of inventing product content in the UI layer.

---

# Ownership boundary

## Backend-owned

The backend must remain the source of truth for product and publication data:

| Area | Ownership | Notes |
|---|---|---|
| Learning content | Backend | Canonical immutable revisions |
| Content type | Backend contract | Stable wire enum/code |
| Content publication | Backend | Revision, availability, tombstones |
| Packs/manifests | Backend | Snapshot and synchronization source |
| Assets | Backend | Identity, checksum, media type, delivery key |
| Content ↔ asset relation | Backend | Role and revision relation |
| Taxonomy | Backend | Category, level, skill catalogs |
| Practice tests | Backend | Test definitions and questions |
| Supported locales | Backend | Product capability catalog |
| TTS voice catalog | Backend | Available voices/models/capabilities |
| Localization availability | Backend | Which localized packs exist |

## Device-owned

The mobile application should own local runtime state and user-local preferences:

| Area | Ownership | Notes |
|---|---|---|
| Installation ID generation | Device | Registered with backend |
| Secure installation token storage | Device | Token is backend-issued |
| Favorite marker | Device | Learner state |
| Listened marker | Device | Learner state |
| Completed marker | Device | Learner state |
| Playback position | Device | Resume state |
| Download/cache state | Device | Runtime storage concern |
| Theme | Device | UI preference |
| Focus mode | Device | UI preference |
| Storage quota preference | Device | Local runtime preference |
| Selected UI locale | Device | User selection from backend-supported catalog |
| Selected translation locale | Device | User selection from backend-supported catalog |
| Selected voice/accent | Device | User selection from backend-supported catalog |

The key rule is:

```text
Backend defines what exists.
Device defines what the user selected and what the device has cached/progressed.
```

---

# GAP-01 — PracticeTest is not production-backed

Severity: **HIGH**

Flutter already contains domain models for:

- `PracticeTest`
- `PracticeTestSummary`
- `PracticeQuestion`
- `PracticeTestMode`

However, production wiring currently uses `UnavailablePracticeTestRepository`.

Therefore Practice Test is not currently backend-driven and does not participate in the same production content lifecycle as normal learning content.

## Required backend contract

Minimum model:

```text
PracticeTest
├── code
├── revision
├── title
├── subtitle
├── mode
├── sortOrder
├── active/published state
└── questions[]
      ├── code
      ├── prompt
      ├── options[]
      ├── correctIndex
      ├── skillCode
      └── explanation
```

Recommended wire separation:

```text
PracticeTestSummaryDto
PracticeTestPayloadDto
PracticeQuestionDto
```

The backend entity model does not have to equal the DTO model.

## Required Flutter production path

```text
Backend
  ↓
PracticeTest manifest/reference
  ↓
PracticeTest payload DTO
  ↓
Drift projection
  ↓
Production PracticeTestRepository
  ↓
PracticeTest / PracticeTestSummary
  ↓
UI
```

## Acceptance criteria

- no production `UnavailablePracticeTestRepository`;
- no runtime mock test repository;
- test definitions survive offline/restart after synchronization;
- exact test revision is reproducible;
- questions are not hardcoded in Flutter;
- scoring remains deterministic for an immutable test revision.

---

# GAP-02 — Taxonomy is embedded, not modeled as a first-class backend catalog

Severity: **MEDIUM / HIGH for future Admin**

Today content payload contains:

```text
categoryCode
categoryLabel
levelCode
levelLabel
```

This is acceptable for the current MVP read model, but it becomes limiting once taxonomy must be managed independently.

## Recommended backend-owned catalogs

```text
Category
├── code
├── sortOrder
├── active
└── localized labels

Level
├── code
├── sortOrder
├── active
└── localized labels

Skill
├── code
├── sortOrder
├── active
└── localized labels
```

Optional future fields:

- parent category / hierarchy;
- icon/image asset reference;
- description;
- visibility rules;
- product/module applicability.

## Design rule

Flutter may cache taxonomy projections, but taxonomy codes and available values should not be invented as client enums unless they are protocol-level constants.

---

# GAP-03 — Supported locale catalog is hardcoded in Flutter

Severity: **MEDIUM**

Flutter currently knows concrete supported values such as:

```text
en
ru
kk
```

The user choice should remain local, but the product capability catalog should be backend-owned.

## Recommended contract

```text
SupportedLocale
├── code
├── displayName
├── active
├── uiSupported
├── translationSupported
├── contentPackAvailable
└── fallbackLocaleCode
```

The exact shape can be simplified initially, but the backend must be able to add/remove availability without requiring a Flutter release.

## Device responsibility

Flutter stores only selections such as:

```text
selectedUiLocaleCode
selectedTranslationLocaleCode
```

and validates/falls back against the current supported catalog.

---

# GAP-04 — Accent / TTS voice availability is hardcoded or not yet connected to product catalog

Severity: **HIGH for TTS rollout**

Flutter currently contains concrete accent choices such as:

```text
en-US
en-GB
en-AU
```

These values are acceptable as stable codes, but the set of available voices, models and capabilities must come from backend catalog data.

This aligns with the planned backend TTS domain:

```text
tts_voice
tts_voice_model
```

## Recommended learner-facing catalog projection

```text
TtsVoice
├── code
├── localeCode
├── accentCode
├── displayName
├── active
├── defaultForLocale
├── capabilities[]
└── model/version metadata as needed by delivery logic
```

Flutter should store the selected `voiceCode` / `accentCode`, not own the catalog.

The learner-facing DTO should not expose internal worker/storage details that Flutter does not need.

---

# GAP-05 — Backend entity model must not mirror Flutter DTOs

Severity: **ARCHITECTURAL**

The current OpenAPI explicitly represents the wire contract consumed by Flutter. It must not be treated as a persistence schema.

Required separation:

```text
Persistence Entity
      ↓
Domain Aggregate / Service
      ↓
API Projection / DTO
      ↓
Flutter DTO
      ↓
Flutter Domain Read Model
```

Example:

```text
Backend entities:
Content
ContentRevision
ContentLocalization
Category
Level
FileAsset
ContentAsset
ContentPack
ContentPackEntry

API projection:
ContentPayloadDto
PackContentManifestDto
ManifestAssetDescriptorDto
```

Do not create a single large backend entity matching `ContentPayloadDto` field-for-field only because Flutter currently consumes that shape.

---

# GAP-06 — Stable codes vs labels must remain separated

Severity: **MEDIUM**

Codes are identity. Labels are presentation.

Correct examples:

```text
categoryCode = INTERVIEW
categoryLabel = Interview

levelCode = B1
levelLabel = Intermediate
```

Backend persistence and references should use stable codes/IDs. Labels may change, localize, or be republished without changing identity.

Avoid using display labels as foreign keys or business identifiers.

---

# GAP-07 — Product catalogs must be revisionable/cacheable

Severity: **MEDIUM**

Because Flutter is offline-first, new catalogs should follow the same deterministic synchronization philosophy as content.

At minimum each backend-owned catalog must have one of:

- revision/version;
- ETag;
- immutable snapshot version;
- checksum where integrity matters.

This applies especially to:

- taxonomy;
- supported locales;
- voice catalog;
- practice tests.

The client must be able to recover after restart without rebuilding product data from hardcoded defaults.

---

# GAP-08 — No backend ownership for local learner state in P2

Severity: **NONE for current P2; future product decision**

Current learner markers are device-owned:

- favorite;
- listened;
- completed;
- playback position;
- last revision seen.

This is correct for the current production foundation.

Do not prematurely move this state to the backend merely to centralize data.

A future authenticated multi-device account sync can introduce a separate learner-state synchronization contract. That is a different bounded context and should not contaminate current content contracts.

---

# GAP-09 — UI/domain enums must be classified explicitly

Severity: **MEDIUM**

Every enum/code in Flutter should be classified into one of three groups:

### A. Protocol constants
Stable and shared with backend, for example `ContentType`.

### B. Backend catalog values
Dynamic product data, for example categories, skills, voices and supported locales.

### C. Device-only values
Local runtime/UI preferences, for example theme mode.

Do not use Dart enums for category/skill/voice catalogs if the backend is expected to add values independently.

---

# Proposed contract completion roadmap

## B0.1 Content / Manifest

Status: **DONE / baseline exists**

Covers:

- installation registration;
- root manifest;
- pack manifest;
- content payload;
- assets;
- tombstones;
- revision/checksum semantics.

## B0.2 PracticeTest contract

Status: **NEXT CONTRACT GAP**

Deliver:

- test summary/payload wire DTOs;
- question DTO;
- revision semantics;
- manifest or discovery relation;
- Flutter decoder/mapper;
- Drift projection;
- production repository.

## B0.3 Taxonomy contract

Deliver:

- Category;
- Level;
- Skill;
- stable codes;
- localized labels;
- ordering/active state;
- versioning strategy.

## B0.4 Locale / Voice catalog

Deliver:

- SupportedLocale;
- learner-facing TtsVoice catalog;
- relation to backend `tts_voice` / `tts_voice_model` domain;
- default/fallback semantics;
- client selection persistence by stable code.

## B0.5 Backend domain mapping

After B0.1-B0.4 are frozen, design persistence/domain entities independently from wire DTOs.

Suggested backend domain areas:

```text
ContentCatalog
Taxonomy
PracticeTesting
AssetDelivery
InstallationIdentity
TtsCatalog
```

Do not start from database tables alone. Start from aggregate ownership and immutable publication semantics.

---

# Target architecture

```text
                    BACKEND
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
     Content        Taxonomy       Test/TTS
     Catalog        Catalog        Catalog
        │              │              │
        └──────────────┼──────────────┘
                       ▼
                 API DTO / Manifest
                       │
                       ▼
                    Flutter
                       │
                 remote decoder
                       │
                       ▼
                     Drift
                       │
                       ▼
                  Repository
                       │
                       ▼
                       UI

Device-owned side state:
preferences + learner progress + cache/download/runtime state
```

---

# Definition of complete Flutter ↔ Backend boundary

The boundary can be considered complete for the current product scope when all of the following are true:

- production learning content is backend-driven;
- production practice tests are backend-driven;
- taxonomy values are backend-owned;
- locale availability is backend-owned;
- TTS voice availability is backend-owned;
- Flutter contains no runtime product mocks;
- Flutter does not hardcode mutable product catalogs;
- backend API DTOs are explicitly separated from persistence entities;
- all backend-owned datasets have stable identity and deterministic revision/version semantics;
- offline/restart reads use local projections without redefining product truth on the device;
- device-owned preferences and learner progress remain separate from backend product content.

---

# Recommended next decision

Before implementing backend persistence entities, freeze B0.2-B0.4 wire/domain ownership contracts.

Recommended order:

```text
B0.2 PracticeTest
      ↓
B0.3 Taxonomy
      ↓
B0.4 Locale / Voice catalog
      ↓
Backend aggregate/entity design
      ↓
Backend implementation
```

This avoids the most expensive failure mode: building backend tables first and then forcing Flutter contracts to mirror accidental persistence structure.
