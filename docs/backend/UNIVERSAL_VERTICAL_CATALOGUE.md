# Universal Vertical Catalogue

## Status

Architecture proposal for VoxPrep multi-vertical expansion.

This document defines how VoxPrep should support multiple learning verticals without embedding product-specific logic in Flutter or creating backend code paths per vertical.

## Goal

VoxPrep must support an open-ended set of learning verticals such as:

- Java Interview
- QA Interview
- DevOps Interview
- AWS
- Kubernetes
- IELTS Technical Vocabulary
- Medical English
- Sales English
- Banking English

Adding a new vertical must be a backend content/catalogue operation, not a new Flutter release and not a new backend controller/repository hierarchy.

Core rule:

```text
Vertical is content taxonomy, not application logic.
```

The backend owns what verticals exist. Flutter owns how a vertical card/list is rendered.

## Target hierarchy

```text
Vertical
  ↓
LearningGoal
  ↓
LearningTrack
  ↓
LearningCollection
  ↓
Ordered CollectionMember
  ├── exact ContentRevision
  └── exact PracticeTestRevision
```

The same content, assessment, publication, localization and media engines are reused for every vertical.

## Vertical model

A vertical is a stable backend-owned business identity.

Recommended mutable authoring entity:

```text
learning_vertical
-----------------
id
authoring_code
title
description
icon_asset_id
sort_order
active
created_at
updated_at
```

`code` is stable and must not be derived from the title.

Example codes:

```text
JAVA_INTERVIEW
QA_INTERVIEW
DEVOPS_INTERVIEW
AWS
KUBERNETES
IELTS_TECH
MEDICAL_ENGLISH
SALES_ENGLISH
BANKING_ENGLISH
```

Do not model the set of verticals as a Java enum or Dart enum. The set must remain data-driven.

## Publication projection

Mutable authoring rows must never be consumed directly by Flutter.

```text
Admin mutable Vertical
        ↓
publication builder
        ↓
immutable vertical catalogue revision
        ↓
PublicationSnapshot
        ↓
Flutter exact catalogue consumption
```

Example immutable catalogue payload:

```json
{
  "kind": "verticals",
  "revision": 7,
  "checksum": "<sha256>",
  "items": [
    {
      "code": "JAVA_INTERVIEW",
      "title": "Java Interview",
      "description": "Java backend interview preparation",
      "iconAssetId": "vertical-java-v1",
      "sortOrder": 10,
      "active": true
    }
  ]
}
```

## Required fields in VerticalProjection

Minimum learner-facing projection:

```text
code
  stable business identity

title
  display title owned by backend content

description
  optional/required depending on final UX contract

iconAssetId
  stable publication asset identity; never a signed URL

sortOrder
  deterministic backend-owned ordering

active
  publication-visible activation state
```

Recommended Flutter domain type:

```dart
final class VerticalProjection {
  final String code;
  final String title;
  final String description;
  final String? iconAssetId;
  final int sortOrder;
  final bool active;
}
```

Flutter must not contain a registry such as:

```dart
enum Vertical {
  javaInterview,
  qaInterview,
  medicalEnglish,
}
```

A vertical code is generic data.

## Icon ownership

Do not place `iconUrl` or signed media URLs inside the vertical catalogue.

Use:

```text
VerticalProjection.iconAssetId
        ↓
PublicationSnapshot asset membership
        ↓
ManifestAssetDescriptor
        ↓
AssetResolver
        ↓
local file / short-lived media access grant
```

The immutable publication owns:

```text
assetId
checksumSha256
deliveryKey
sizeBytes
mediaType
```

C5/runtime security owns:

```text
signed URL
access grant TTL
authorization
```

Signed URLs must never participate in publication checksum or durable catalogue state.

This keeps vertical icons available offline after successful asset synchronization.

## CatalogueKind extension

Extend the C4 catalogue set from:

```text
learning-goals
learning-tracks
learning-collections
categories
levels
skills
supported-locales
tts-voices
```

to:

```text
verticals
learning-goals
learning-tracks
learning-collections
categories
levels
skills
supported-locales
tts-voices
```

Recommended wire name:

```text
verticals
```

Recommended Flutter change:

```dart
CatalogueKind.verticals('verticals')
```

## Vertical ownership of the learning graph

Goal/Track/Collection projections should be scoped to a vertical.

Recommended learner projections:

```text
LearningGoalProjection
  code
  verticalCode
  title
  description
  sortOrder
  active

LearningTrackProjection
  code
  verticalCode
  goalCode
  title
  description
  levelCode
  careerTrackCode?
  sortOrder
  active

LearningCollectionProjection
  code
  verticalCode
  trackCode
  title
  description
  sortOrder
  active
  ordered exact content/test membership
```

Although `verticalCode` can be derived through parent relationships, explicitly carrying it in learner projections is useful as a fail-closed integrity boundary. Flutter can reject cross-vertical graph corruption instead of silently displaying it.

Examples of invalid graph edges:

```text
JAVA_INTERVIEW goal
  → MEDICAL_ENGLISH track

BANKING_ENGLISH collection
  → JAVA_INTERVIEW-owned content
```

The publication validator must reject such a graph before CURRENT changes.

## Categories and skills

Categories and skills must also be usable across multiple verticals.

Avoid one uncontrolled global category namespace such as:

```text
Java
Spring
Cardiology
Loans
AWS
Sales Negotiation
```

Preferred authoring relationship:

```text
Category
  code
  vertical_id nullable
  parent_category_id nullable
  ...

Skill
  code
  vertical_id nullable
  ...
```

`vertical_id = null` can represent truly shared/global taxonomy values.

Examples:

```text
JAVA_INTERVIEW
  ├── JAVA_CORE
  ├── SPRING
  ├── DATABASE
  └── MICROSERVICES

MEDICAL_ENGLISH
  ├── ANATOMY
  ├── DIAGNOSIS
  ├── PATIENT_COMMUNICATION
  └── PHARMACOLOGY
```

Generic language skills may remain global:

```text
READING
LISTENING
SPEAKING
VOCABULARY
```

Vertical-specific skills are also allowed:

```text
JAVA_CONCURRENCY
KUBERNETES_NETWORKING
CLINICAL_COMMUNICATION
BANKING_LENDING
```

## Content model remains universal

Do not create vertical-specific backend entities such as:

```text
JavaInterviewContent
MedicalEnglishContent
BankingContent
```

Keep one shared content revision system:

```text
Content
ContentRevision
ContentLocalizationRevision
```

with vertical/taxonomy ownership expressed as data.

Example:

```text
contentCode = JAVA_HASHMAP_001
verticalCode = JAVA_INTERVIEW
contentType = INTERVIEW
```

and:

```text
contentCode = MED_PATIENT_HISTORY_001
verticalCode = MEDICAL_ENGLISH
contentType = SHADOWING
```

The same applies to assessment:

```text
PracticeTest
PracticeTestRevision
Question
QuestionRevision
```

No `JavaTest`, `MedicalTest`, `AwsTest` domain split.

## PublicationSnapshot integration

A PublicationSnapshot freezes the exact learner graph, including the vertical catalogue.

```text
PublicationSnapshot N
├── verticals catalogue revision
├── learning-goals catalogue revision
├── learning-tracks catalogue revision
├── learning-collections catalogue revision
├── categories catalogue revision
├── levels catalogue revision
├── skills catalogue revision
├── supported-locales catalogue revision
├── tts-voices catalogue revision
├── exact content revisions
├── exact practice-test revisions
└── exact asset descriptors
```

Flutter must never resolve a vertical, goal, track, collection, test or content through `latest`, `MAX(revision)` or mutable authoring state.

Learner visibility is always:

```text
CURRENT root contentVersion
        ↓
exact catalogue revision membership
        ↓
exact immutable catalogue payload
```

## Flutter target UX

The application home/navigation can become fully data-driven:

```text
CURRENT PublicationSnapshot
        ↓
verticals catalogue
        ↓
sortOrder + active
        ↓
Vertical cards
```

Example:

```text
[ Java Interview ]
[ QA Interview ]
[ DevOps Interview ]
[ AWS ]
[ Kubernetes ]
[ Medical English ]
[ Sales English ]
[ Banking English ]
```

Selecting a card drives the same generic navigation path:

```text
Vertical
  ↓
Goals
  ↓
Tracks
  ↓
Collections
  ↓
Content / Tests
```

No product-specific Flutter screen should be required for a new normal vertical.

## Localization direction

Do not introduce fixed columns/fields such as:

```text
titleRu
titleKz
titleEn
```

into the long-term public model.

The publication architecture should remain compatible with catalogue localization revisions. A first implementation may carry already-resolved `title` and `description`, but publication identity and locale ownership must remain deterministic and backend-owned.

## Backend Admin Studio

Recommended navigation:

```text
Verticals
  ↓
JAVA INTERVIEW
  ├── Goals
  ├── Tracks
  ├── Collections
  ├── Categories
  ├── Skills
  ├── Content
  ├── Tests
  └── Publish

MEDICAL ENGLISH
  ├── Goals
  ├── Tracks
  ├── Collections
  ├── Categories
  ├── Skills
  ├── Content
  ├── Tests
  └── Publish
```

Admin Studio should use vertical scope as a default safety boundary to reduce accidental cross-domain references.

## Invariants

The final implementation must enforce at least these invariants:

```text
1. Vertical code is stable and unique.
2. Vertical catalogue is immutable after publication.
3. title/description/iconAssetId are publication-owned data.
4. iconAssetId resolves to an asset belonging to the same PublicationSnapshot.
5. Goals belong to an existing vertical.
6. Tracks belong to the same vertical as their goal.
7. Collections belong to the same vertical as their track.
8. Collection exact content/test refs must belong to the same vertical/snapshot.
9. Catalogue revisions are fetched by exact revision + checksum.
10. Flutter never selects latest catalogue revisions.
11. Adding a vertical requires content/catalogue publication, not application code.
12. Runtime/security material never enters immutable catalogue payloads.
```

## Suggested implementation slice

After current C4.7 stabilization, implement this as a contained slice:

```text
V1  add CatalogueKind.verticals
V2  add VerticalProjection
V3  extend exact catalogue decoder/validator
V4  persist exact vertical catalogue revision in CURRENT snapshot store
V5  expose generic VerticalRepository
V6  add verticalCode to Goal/Track/Collection projections
V7  add cross-vertical fail-closed validation
V8  resolve iconAssetId through existing AssetResolver
V9  add generic Flutter vertical catalogue screen
V10 adversarial + restart qualification
```

This proposal should be merged into the active C4/backend work only after C4.7 is stable, so it does not destabilize the current qualification stream.
