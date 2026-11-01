# Managed Asset Download Qualification

All learner-visible remote media is required to use one production path:

```text
immutable publication asset descriptor
  -> assetId
  -> authenticated GET /api/v1/media/assets/{assetId}/content
  -> Spring Boot resolves FileAsset/deliveryKey internally
  -> Spring Boot streams bytes from Backend-owned storage
  -> size/SHA-256 verification
  -> managed local file
  -> Image.file / local audio playback
```

Additional invariants:

- Flutter communicates only with Spring Boot for remote media;
- RustFS/S3/CDN hostnames, credentials, signed URLs, buckets and object paths are forbidden in Flutter production code;
- `deliveryKey` is immutable metadata but is never used by Flutter as a URL or download path;
- Backend redirects to object storage are rejected because the client transport has `followRedirects = false`;
- catalogue section and vertical icons resolve through the typed `image/*` path;
- content audio resolves through the typed `audio/*` path;
- UI code cannot issue direct network media requests;
- `requiredOffline=true` assets form a pre-commit barrier and must be verified locally before CURRENT can switch;
- `requiredOffline=false` media remains lazy/cacheable and does not block publication;
- a failed required-offline download leaves the previous CURRENT publication authoritative;
- deleting a local asset is a recoverable cache miss: the same `assetId` is fetched again from Backend with the current installation token and re-verified before use.
