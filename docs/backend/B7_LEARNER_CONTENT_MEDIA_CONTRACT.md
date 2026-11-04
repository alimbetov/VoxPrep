# VoxPrep — B7 Learner Content Media Contract

**Status:** Normative companion to `B7_EDITOR_TTS_REMEDIATION_REQUIREMENTS.md`  
**Branch:** `feat/b7-editor-tts-remediation`

## Goal

The final B7 learner boundary MUST deliver to Flutter a publication-scoped content view composed from the exact CURRENT publication:

```text
CURRENT publication
  → exact ContentRevision
  → exact approved localization at publication boundary
  → exact role-aware ContentAssetBinding
  → exact READY FileAsset
  → learner DTO / learner media endpoint
```

Flutter must be able to render the complete learner experience without querying mutable authoring state.

## Learner-visible aggregate

Conceptually the learner read model contains:

```text
content identity
contentVersion
rootSha256
revisionNumber
checksumSha256

text/body
localized text where selected

media[]
  assetId
  role
  kind
  mediaType
  sizeBytes
  sha256
  learner content URL/ref
```

Text remains authoritative structured content from `ContentRevision` plus deterministic localization resolution.

Binary media remains `FileAsset`-backed and MUST be exposed only through role-aware publication-scoped `ContentAssetBinding` records.

## Media model

TTS-R1..R3 are audio-specific because they define synthesis semantics.

TTS-R4 introduces the generic durable relation:

```text
exact ContentRevision
+ ContentAssetRole
→ exact FileAsset
```

The durable content/media relation supports at least:

```text
TTS_AUDIO
COVER_IMAGE
CONTENT_IMAGE
```

Audio-role semantics remain governed by `ContentAudioPolicy`.

Image roles are separate media semantics and MUST NOT be encoded as TTS roles.

Minimum image roles for the commercial learner experience are:

```text
coverImage
contentImage
```

## Publication invariants

Learner media MUST satisfy all of the following:

1. the content revision occurs in the exact CURRENT publication manifest;
2. the binding belongs to that exact published `ContentRevision`;
3. referenced `FileAsset` exists;
4. asset status is `READY`;
5. asset kind/media type matches the binding role;
6. no mutable/latest lookup is used after publication;
7. arbitrary asset UUID knowledge does not grant learner access;
8. old publication snapshots do not change when new assets are authored later;
9. synthesized audio is publication-valid only when its binding fingerprint matches the current exact revision and a matching READY TTS result;
10. learner availability is determined by `ContentAssetBinding`, never by scanning `tts_job` as the authority.

## Flutter boundary

Flutter MUST receive only learner-safe projections. It MUST NOT receive RustFS credentials, private object keys as authorization, TTS job internals, draft bindings, or unpublished asset references.

Canonical learner media discovery endpoint:

```text
GET /api/v1/content/{contentType}/{contentCode}/media
```

Canonical publication-scoped media content endpoint:

```text
GET /api/v1/content/{contentType}/{contentCode}/media/{assetId}/content
```

The media discovery projection contains:

```text
assetId
role
kind
mediaType
sizeBytes
sha256
etag
```

The existing `/audio` endpoints remain a compatibility projection over the same publication-scoped bindings. They MUST NOT use `tts_job` as the source of learner authorization.

The learner media URL/ref remains publication-scoped and authorization-safe: knowing an arbitrary `FileAsset` UUID is insufficient unless that asset is bound to the exact CURRENT revision.

## Acceptance model

R6 qualification is compositional but production-real:

```text
A. Product orchestration acceptance
ContentRevision
  → ContentTtsPlanner
  → TtsJobPreparationService
  → finalized TTS output
  → ContentAssetBinding
  → publication validation
  → publication freeze
  → CURRENT
  → learner content + media discovery

B. Real synthesis acceptance
prepared worker snapshot
  → real Worker
  → real Piper
  → FFmpeg MP3
  → READY FileAsset
  → automatic ContentAssetBinding
```

Together A+B prove the complete production path without introducing a test-only HTTP backdoor around the authoring/application boundary.

## Relationship to remediation roadmap

```text
TTS-R1  typed audio policy
TTS-R2  text extraction/planning
TTS-R3  synthesis job preparation
TTS-R4  generic role-aware ContentAsset binding (audio + images)
TTS-R5  publication media validation
TTS-R6  product acceptance + learner media cutover
MVC-R*  authoring/editing controls for text, audio and images
```

B7 cannot be declared accepted until the exact R6 head has green backend qualification and real Backend↔Worker acceptance, and Flutter can consume the publication-safe text/audio/image contract.
