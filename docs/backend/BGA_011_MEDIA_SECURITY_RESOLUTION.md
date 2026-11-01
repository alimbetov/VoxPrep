# BGA-011 — Media Security Resolution

**Status:** RESOLVED  
**Original severity:** P1 HIGH / PRODUCT RISK  
**Normative contracts:**

- `docs/backend/C4_ATOMIC_PUBLICATION_CONTRACT.md`
- `docs/backend/C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`
- `docs/backend/C5_MEDIA_SECURITY_CONTRACT.md`

## Resolution

BGA-011 is closed by selecting **authenticated Backend-proxied learner media** for MVP.

The stable publication contract remains:

```text
assetId
checksumSha256
deliveryKey
sizeBytes
mediaType
requiredOffline
```

`deliveryKey` remains immutable metadata used by Backend storage infrastructure. It is not a client network locator.

The delivery boundary is:

```text
Flutter
  stable assetId from C4
        ↓
GET /api/v1/media/assets/{assetId}/content
Authorization: Bearer <current installation token>
        ↓
Spring Boot validates installation + asset eligibility
        ↓
Spring Boot resolves assetId → FileAsset → deliveryKey
        ↓
Backend storage adapter reads RustFS
        ↓
Spring Boot streams bytes to Flutter
        ↓
Flutter verifies size + SHA-256
        ↓
trusted local asset
```

## Security consequences

- Flutter has no RustFS/S3/CDN URL or credentials.
- Worker has no RustFS/S3 credentials and addresses Backend APIs only.
- The client cannot submit arbitrary RustFS object keys.
- Backend is the single authorization, audit and error boundary.
- Revoked installations cannot download new media.
- Token rotation does not change asset identity.
- Local cache eviction does not remove publication identity.
- Deleting local bytes causes a Backend-only re-download of the same immutable asset.

## Explicitly rejected alternatives

For MVP the project does not use:

```text
Flutter → RustFS/S3/CDN
Worker → RustFS/S3
public RustFS bucket
public stable media URL embedded in manifests
signed/presigned URL returned to Flutter
storage URL persisted in Drift
RustFS credentials in Flutter or Worker
Backend redirect to object storage
client-supplied deliveryKey for download
```

## Acceptance

BGA-011 is considered resolved when implementation/contract tests prove:

1. valid installation token + learner-deliverable `assetId` yields binary media from the Backend endpoint;
2. revoked/missing installation credentials fail closed;
3. Flutter never uses `deliveryKey` as a URL/path for remote access;
4. Backend redirects to RustFS/S3/CDN are rejected by Flutter;
5. deleting a verified local asset causes re-download through Backend with the current token;
6. downloaded bytes must pass C4 size and SHA-256 verification before local promotion;
7. production Flutter code contains no RustFS/S3/CDN client boundary;
8. TTS Worker continues to download models and upload output through Backend internal APIs only.

## Frozen rule

> All Flutter and Worker network I/O terminates at Spring Boot. RustFS is Backend-internal storage and may be accessed only by Backend infrastructure adapters.
