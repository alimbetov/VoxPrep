# VoxPrep — B7 Learner Content Media Contract

**Status:** Normative companion to `B7_EDITOR_TTS_REMEDIATION_REQUIREMENTS.md`  
**Branch:** `feat/b7-editor-tts-remediation`

## Goal

The final B7 learner boundary MUST deliver to Flutter one publication-scoped content view composed from the exact CURRENT publication:

```text
CURRENT publication
  → exact ContentRevision
  → exact approved localization at publication boundary
  → exact role-aware FileAsset bindings
  → learner DTO
```

Flutter must be able to render the complete learner experience without querying mutable authoring state.

## Learner-visible aggregate

Conceptually the learner response/read model contains:

```text
content identity
contentVersion
rootSha256
revisionNumber
checksumSha256

text/body
localized text where selected

audioAssets[]
imageAssets[]
```

Text remains authoritative structured content from `ContentRevision` plus deterministic localization resolution.

Binary media remains `FileAsset`-backed and MUST be exposed through role-aware publication-scoped bindings.

## Media model

TTS-R1..R3 are audio-specific because they define synthesis semantics.

TTS-R4 MUST NOT introduce an audio-only persistence concept that blocks image delivery. The durable content/media relation SHALL be generic enough to represent at least:

```text
TTS_AUDIO
COVER_IMAGE
CONTENT_IMAGE
```

A binding conceptually represents:

```text
exact content revision
+ media role
+ FileAsset kind
→ exact FileAsset
```

Audio-role semantics remain governed by `ContentAudioPolicy`.

Image roles are separate media semantics and MUST NOT be encoded as TTS roles.

Minimum image roles for the commercial learner experience are:

```text
cover
content
```

The implementation MAY introduce a typed generic role/value model such as `ContentAssetRole`, while preserving typed audio-policy validation for synthesized audio.

## Publication invariants

Learner media MUST satisfy all of the following:

1. binding belongs to the exact published `ContentRevision`;
2. referenced `FileAsset` exists;
3. asset status is `READY`;
4. asset kind/media type matches the binding semantics;
5. no mutable/latest lookup is used after publication;
6. arbitrary asset UUID knowledge does not grant learner access;
7. old publication snapshots do not change when new assets are authored later.

## Flutter boundary

Flutter MUST receive only learner-safe projections. It MUST NOT receive RustFS credentials, private object keys as authorization, TTS job internals, draft bindings, or unpublished asset references.

Recommended learner projection shape:

```text
LearnerContentSnapshot
  identity/version fields
  text/body/localization
  media[]
    role
    kind
    mediaType
    sizeBytes
    sha256
    learner content URL/ref
```

The learner media URL/ref MUST remain publication-scoped and authorization-safe.

## Relationship to remediation roadmap

```text
TTS-R1  typed audio policy
TTS-R2  text extraction/planning
TTS-R3  synthesis job preparation
TTS-R4  GENERIC role-aware ContentAsset binding (audio + images)
TTS-R5  publication validation for required media
TTS-R6  product acceptance
MVC-R*  authoring/editing controls for text, audio and images
```

B7 cannot be declared accepted until the production path proves that Flutter can obtain publication-safe text, audio and image references for an exact CURRENT publication.
