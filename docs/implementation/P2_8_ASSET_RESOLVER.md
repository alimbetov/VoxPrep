# P2.8 — AssetResolver

## Scope

Resolve an immutable asset ID, or an exact content revision and asset role,
into a verified local path. This connects the existing Drift metadata graph
to the P2.7 download pipeline without changing schema version 3 or feature UI.

Production composition:

```text
AssetResolver
  → AssetCatalogRepository / DriftAssetCatalogRepository
  → AssetFileStore / FileSystemAssetStore
  → AssetDownloadManager / HttpAssetByteSource
  → ResolvedAsset(assetId, localPath, mediaType)
```

`assetResolverProvider` composes the production adapters. Consumers can call
`resolve(assetId)` or `resolveContent(content, revision, role, variant)`.
The default variant is `canonical`; locale variants must be explicit.

## Resolution rules

| Condition | Result |
| --- | --- |
| Verified local file exists | Local path, no network |
| Missing/corrupt file, `localOnly` (default) | `ASSET_NOT_AVAILABLE_OFFLINE` |
| Missing/corrupt file, `downloadIfMissing` | Existing DownloadManager downloads, verifies and atomically finalizes |
| No current asset binding | `ASSET_NOT_CURRENT` |
| Multiple distinct assets match a content role | `ASSET_REFERENCE_AMBIGUOUS` |
| Invalid persisted descriptor | `ASSET_CATALOG_INVALID` |
| Catalog storage cannot be read | `ASSET_CATALOG_READ_FAILED` |
| File/network/integrity failure | Original P2.7 failure, with retryability preserved |

`requiredOffline` is metadata, not permission to perform a network request.
No remote URI or partial/unverified file is returned to a consumer.
Concurrent requests for the same immutable asset ID share the pending download
within one resolver instance. `localOnly` does not wait for that download.
Failed requests are removed from the pending map, allowing a later retry.

## Metadata visibility

Lookup by asset ID requires membership in a `CURRENT` pack revision. Content
lookup additionally requires the exact content identity, revision, role and
variant, a `CURRENT` content record, and asset membership in the same pack
revision. Staged/superseded packs and tombstoned content are not selected.
Identical bindings shared by several packs collapse to one descriptor; multiple
distinct matches are an error rather than an arbitrary selection.

Each lookup reads the graph in one SQL statement and does not cache bindings.
An in-progress resolution is bound to the immutable descriptor selected at its
start. A later metadata activation affects the next lookup; it does not cancel
an already-running download. Playback lifecycle policy belongs to P2.9.

`CURRENT` describes metadata availability, not local audio readiness. An audio
file may still need downloading after successful metadata synchronization.
An old pinned offline pack's independent READY lifecycle is not implemented by
this current-snapshot resolver.

## Acceptance

`test/acceptance/p2_8_asset_resolution_test.dart` exercises the production Drift
catalog, filesystem store, DownloadManager and Riverpod composition. Only the
remote byte source is replaced by a deterministic fixture.

Coverage includes verified download/reuse, no-network local policy, equal-size
file corruption and repair, size/checksum rejection, partial-file exclusion,
unknown bindings, staging/superseded/tombstoned visibility, exact revision/type/
role/variant selection, same-pack membership, shared and ambiguous bindings,
CURRENT activation, concurrent calls, retry after delivery failure, malformed
metadata, and closing/reopening the on-disk database and resolver offline.

The byte fixture proves asset integrity and restart resolution, not MP3 decoding
or audible playback. P2.9 owns the real player; P2.10 owns UI cutover; P2.11 owns
full application/backend/device offline acceptance. No P2 completion claim is
made by this slice.
