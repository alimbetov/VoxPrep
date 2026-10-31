# Managed Asset Download Qualification

All learner-visible remote media is required to use one production path:

```text
immutable publication asset descriptor
  -> assetId
  -> POST /api/v1/media/access
  -> short-lived HTTPS signed URL
  -> binary GET with redirects disabled
  -> size/SHA-256 verification
  -> managed local file
  -> Image.file / local audio playback
```

Additional invariants:

- catalogue section and vertical icons resolve through the typed `image/*` path;
- content audio resolves through the typed `audio/*` path;
- UI code cannot issue direct network media requests;
- `requiredOffline=true` assets form a pre-commit barrier and must be verified locally before CURRENT can switch;
- `requiredOffline=false` media remains lazy/cacheable and does not block publication;
- a failed required-offline download leaves the previous CURRENT publication authoritative.
