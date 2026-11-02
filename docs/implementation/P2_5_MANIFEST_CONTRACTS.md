# P2.5 — Manifest Contracts

**Branch:** `feat/p2-flutter-production-adapters`  
**Parent stage:** P2.4 typed API client foundation  
**Database schema impact:** none (`CareerSpeakDatabase.schemaVersion = 1`)

## Goal

P2.5 freezes the learner-delivery manifest schema consumed by the future `ContentSyncCoordinator` without implementing synchronization or production repository cutover.

```text
CareerSpeak Backend
        ↓
root manifest / pack manifest JSON
        ↓
ContentManifestDecoder
        ↓
ContentManifestGateway
        ↓
P2.6 ContentSyncCoordinator
```

The manifest boundary is framework-independent above `data/remote/**`. Raw JSON and endpoint mechanics do not enter feature presentation or the P2.6 state machine.

## Contract versions

The original P2.5 baseline introduced manifest schema version 1. The current Flutter decoder supports the compatible range:

```text
manifest schemaVersion = 1..2
app contract version    = 1
```

A manifest schema newer than `supportedContentManifestSchemaVersion` is not partially interpreted. It fails closed as `SCHEMA_UNSUPPORTED`, preserving the last compatible local `CURRENT` snapshot.

A root manifest whose `minimumAppContractVersion` is newer than the installed application fails as `APP_UPDATE_REQUIRED`.

The learner OpenAPI contract must keep its root and pack `schemaVersion.maximum` aligned with the Flutter decoder. IMG-UI.1 corrected both to `2`.

## Root manifest v1 baseline

Concrete baseline wire shape:

```json
{
  "schemaVersion": 1,
  "contentVersion": 108,
  "minimumAppContractVersion": 1,
  "publishedAt": "2026-10-30T09:30:00Z",
  "checksum": "<sha256>",
  "packs": [
    {
      "code": "JAVA_SENIOR",
      "variant": "canonical",
      "revision": 8,
      "checksum": "<sha256>"
    },
    {
      "code": "JAVA_SENIOR",
      "variant": "locale:kk",
      "revision": 4,
      "checksum": "<sha256>"
    }
  ],
  "tombstones": [
    {
      "contentCode": "JAVA_QUESTION_001",
      "contentType": "interview",
      "revision": 3,
      "reason": "INACTIVE"
    }
  ]
}
```

Root invariants:

1. `schemaVersion`, `contentVersion`, `minimumAppContractVersion`, and revisions are positive integers;
2. `publishedAt` uses canonical ISO-8601 UTC (`...Z`) and calendar-invalid timestamps are rejected rather than normalized;
3. root and pack `checksum` values are SHA-256 hex digests;
4. `(packCode, variant)` is unique inside one root snapshot;
5. variants are `canonical` or `locale:<BCP-47>`;
6. tombstone identity is `(contentCode, contentType)` and is unique inside one root snapshot;
7. unknown additive fields may be ignored only inside a supported schema version; required fields remain strict.

### Content identity erratum

Earlier P0 conceptual tombstone examples showed only `code + revision`. That is insufficient for the implemented mobile identity because P2.2 deliberately permits the same business code to exist under different `ContentType` values.

Therefore manifest contracts use:

```text
contentCode
+
contentType
```

for every content reference and tombstone. Flutter must never guess a destructive target from `contentCode` alone.

## Pack manifest baseline

Endpoint:

```text
GET /api/v1/content/packs/{code}/manifest
    ?variant=canonical|locale:<bcp47>
    &revision=<exact revision>
```

Concrete baseline shape:

```json
{
  "schemaVersion": 1,
  "code": "JAVA_SENIOR",
  "variant": "canonical",
  "revision": 8,
  "checksum": "<sha256>",
  "contents": [
    {
      "contentCode": "JAVA_QUESTION_001",
      "contentType": "interview",
      "revision": 3,
      "checksum": "<sha256>",
      "sortOrder": 10,
      "publishedAt": "2026-10-29T11:00:00Z"
    }
  ],
  "assets": [
    {
      "assetId": "asset-1",
      "checksumSha256": "<sha256>",
      "deliveryKey": "audio/java/question-001.mp3",
      "sizeBytes": 2048,
      "mediaType": "audio/mpeg",
      "requiredOffline": true
    }
  ],
  "contentAssets": [
    {
      "contentCode": "JAVA_QUESTION_001",
      "contentType": "interview",
      "contentRevision": 3,
      "assetId": "asset-1",
      "role": "audio"
    }
  ]
}
```

Pack invariants:

1. returned `(code, variant, revision, checksum)` must exactly match the target referenced by the root manifest;
2. content identity uses `(contentCode, contentType)`;
3. each content identity occurs at most once in one pack revision;
4. each `assetId` occurs at most once in one pack manifest;
5. every `contentAssets` row references an existing exact content revision and an existing asset descriptor;
6. `deliveryKey` is a relative immutable object key, never a CDN/origin URL;
7. `checksumSha256` is the immutable binary integrity identity;
8. `requiredOffline` controls explicit offline-bundle requirements and does not force normal metadata sync to download the bytes.

### IMG-UI.1 optional content cover binding

Content covers reuse the existing `assets + contentAssets` graph; they are not embedded URLs and do not add a second media model.

```json
{
  "assets": [
    {
      "assetId": "cover-java-question-001",
      "checksumSha256": "<sha256>",
      "deliveryKey": "images/java/question-001.webp",
      "sizeBytes": 48192,
      "mediaType": "image/webp",
      "requiredOffline": false
    }
  ],
  "contentAssets": [
    {
      "contentCode": "JAVA_QUESTION_001",
      "contentType": "interview",
      "contentRevision": 3,
      "assetId": "cover-java-question-001",
      "role": "coverImage"
    }
  ]
}
```

Additional cover invariants:

1. `coverImage` is optional; absence is a valid publication state;
2. one exact `(contentCode, contentType, contentRevision)` may bind at most one `coverImage`;
3. cover media is limited to `image/webp`, `image/jpeg`, or `image/png` for IMG-UI.1;
4. cover lookup is exact-revision; a client must never reuse a cover from another content revision;
5. the client resolves the asset through `AssetResolver`; `deliveryKey` is never treated as a client URL;
6. an unavailable or undecodable optional cover must not make otherwise valid learning content unavailable;
7. learner presentation reserves no cover slot when the image is absent or cannot be rendered.

The normative presentation and fallback rules are documented in `IMG_UI_1_CONTENT_COVER.md` and `contracts/content-cover-v1.yaml`.

## Root endpoint

```text
GET /api/v1/content/manifest?locale=<translationLocale>
If-None-Match: <etag>
```

`ContentManifestGateway` exposes a discriminated result:

```text
RootManifestChanged(manifest, etag)
RootManifestNotModified(etag)
```

`304 Not Modified` is a first-class no-change response only when the request carried a validated `If-None-Match` value. A `304` response to an unconditional request fails closed as `MANIFEST_RESPONSE_INVALID`; Flutter must never infer a local baseline that was not actually presented to the server.

Stored request ETags containing CR/LF are rejected before transport. Unsafe response ETags are not persisted back into the learner state.

The root endpoint uses installation authentication through the P2.4 transport boundary.

## Failure model

P2.5 adds/uses stable failure codes including:

```text
SCHEMA_UNSUPPORTED
APP_UPDATE_REQUIRED
MANIFEST_INVALID
PACK_MANIFEST_INVALID
MANIFEST_RESPONSE_INVALID
PACK_MANIFEST_RESPONSE_INVALID
PACK_MANIFEST_MISMATCH
LOCALE_INVALID
ETAG_INVALID
```

Existing P2.4 failures such as `OFFLINE`, `TIMEOUT`, `UNAUTHORIZED`, and `CREDENTIAL_STORE_ERROR` propagate unchanged.

Raw JSON/parser/transport exceptions are not exposed above the adapter boundary.

## Separation from P2.6

P2.5 does **not**:

```text
write manifest state to Drift
stage pack metadata
switch CURRENT contentVersion
apply tombstones
run sync recovery
schedule downloads
change learner repositories
```

Those are owned by P2.6 and later slices.

P2.5 only makes those operations possible against one deterministic, validated contract.

## Acceptance

The manifest boundary is accepted only when one exact clean SHA proves all of the following under the normal read-only CI workflow:

1. every supported root manifest schema version decodes into framework-independent immutable application models;
2. schema versions above the supported maximum fail as `SCHEMA_UNSUPPORTED` before partial deeper decoding;
3. newer `minimumAppContractVersion` fails as `APP_UPDATE_REQUIRED`;
4. root packs are unique by `(code, variant)`;
5. tombstones require `(contentCode, contentType, revision, reason)`;
6. pack manifests validate content/asset referential integrity;
7. pack response identity/revision/checksum must equal the root target;
8. root ETag / conditional `304 Not Modified` behavior is explicit, and `304` without a request validator fails closed;
9. invalid locale and unsafe request ETag fail before transport;
10. production composition selects the HTTP manifest gateway behind `ContentManifestGateway`;
11. `coverImage` is optional, exact-revision, unambiguous, media-type constrained and uses the existing asset graph;
12. no Drift schema change occurs solely for manifest decoding;
13. the learner OpenAPI schema-version range remains aligned with Flutter's decoder;
14. format, `flutter analyze`, and full `flutter test` qualification remain green for the owning implementation slice.
