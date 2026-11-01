# C5 — Media Security Contract

**Status:** FROZEN MVP CONTRACT  
**Scope:** learner media authorization and delivery for immutable C4 assets.  
**Related contracts:**

- `docs/backend/C4_ATOMIC_PUBLICATION_CONTRACT.md`
- `docs/backend/C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`
- `contracts/learner-api-v1.yaml`

## 1. Decision

Learner media is private and **all Flutter media traffic terminates at Spring Boot**.

RustFS/S3-compatible storage is Backend-internal infrastructure. Flutter MUST NOT receive, construct, persist, follow or resolve RustFS/S3/CDN URLs, presigned URLs, bucket names, object paths or storage credentials.

```text
C4 stable asset descriptor
        ↓
Flutter AssetResolver
        ↓
authenticated Backend media endpoint
        ↓
validate current installation token
        ↓
validate exact learner-deliverable assetId
        ↓
Backend resolves FileAsset + deliveryKey internally
        ↓
Backend reads/streams bytes from RustFS
        ↓
Flutter receives bytes from Backend only
        ↓
C4 size + SHA-256 validation
        ↓
atomic local promotion
```

The public learner boundary is therefore:

```text
Flutter ↔ Spring Boot
```

not:

```text
Flutter ↔ RustFS / S3 / CDN
```

---

## 2. Ownership boundary

### C4 owns

```text
assetId
checksumSha256
deliveryKey
sizeBytes
mediaType
requiredOffline
publication membership
immutable asset identity
```

`deliveryKey` is immutable publication/storage metadata but is never a client-authority input and never a Flutter network locator.

### C5 owns

```text
installation authorization
learner media endpoint
asset eligibility validation
rate limiting / abuse controls
revocation behavior
Backend streaming semantics
```

### Backend storage adapter owns

```text
RustFS endpoint
bucket
object key resolution from deliveryKey
S3-compatible credentials
TLS/storage client
object retrieval
storage retries/timeouts
```

No RustFS/S3 credential or storage URL crosses the Backend boundary.

---

## 3. Learner media API

Normative endpoint:

```http
GET /api/v1/media/assets/{assetId}/content
Authorization: Bearer <current-installation-token>
Accept: <expected media type>
```

Example:

```http
GET /api/v1/media/assets/audio-java-001/content
Authorization: Bearer eyJ...
Accept: audio/mpeg
```

Successful response:

```http
HTTP/1.1 200 OK
Content-Type: audio/mpeg
Content-Length: 153822
ETag: "<sha256>"

<binary bytes>
```

The Backend MAY use `deliveryKey` internally to locate the RustFS object. Flutter MUST NOT submit `deliveryKey`, bucket, object key, storage path, signed URL or storage hostname.

`assetId` is the only learner-facing storage identity because Backend can validate it against authoritative `FileAsset` and publication membership.

---

## 4. Authorization rules

The Backend streams media only when all are true:

```text
installation token is current and valid
installation status is ACTIVE
assetId exists
asset is READY/published
asset is learner-deliverable
asset belongs to an allowed retained/current publication graph
```

Backend MUST NOT proxy arbitrary storage keys supplied by clients.

A revoked installation cannot download new media.

Already verified local offline media remains usable without a network token until local retention removes it or publication semantics retire it.

---

## 5. Backend-only storage rule

The following are explicitly forbidden in Flutter production code:

```text
RustFS hostnames
S3 SDKs
MinIO SDKs
bucket names
object-store access key / secret key
presigned URL generation
presigned URL consumption
CDN/media-origin URLs
redirects from Backend media endpoint to storage
using deliveryKey as an HTTP path or URL
```

The Backend media endpoint MUST return bytes itself. A `3xx` redirect to RustFS/S3/CDN is not a valid learner response.

Worker follows the same infrastructure boundary: it downloads models and uploads output through Backend internal APIs only. Worker has no permanent RustFS credentials and does not address RustFS directly.

---

## 6. Flutter download behavior

```text
ManifestAssetDescriptor
      ↓
AssetResolver
      ↓
verified local file?
  ├─ yes → use local file
  └─ no
      ↓
GET Backend /media/assets/{assetId}/content
      ↓
stream to staging file
      ↓
verify sizeBytes
      ↓
verify checksumSha256
      ↓
atomic local promotion
```

Rules:

1. local file is authoritative only after size + SHA-256 verification;
2. missing local bytes are a recoverable cache miss;
3. corrupted local bytes are removed and recovered through Backend;
4. token `401` follows bounded installation-token recovery policy;
5. storage failures remain hidden behind Backend error semantics;
6. Flutter never retries against a storage origin because no storage origin is exposed;
7. `deliveryKey` never participates in Flutter URL construction;
8. successful verified local media remains usable offline.

---

## 7. Deleted-file recovery

Required behavior:

```text
CURRENT publication metadata retained
+ local MP3 deleted
        ↓
next Play
        ↓
AssetResolver finds exact CURRENT assetId
        ↓
GET Backend media endpoint with current installation token
        ↓
Backend resolves assetId → FileAsset → deliveryKey
        ↓
Backend reads RustFS
        ↓
Flutter verifies size + SHA-256
        ↓
local file restored
        ↓
playback
```

Token rotation does not change immutable asset identity.

---

## 8. Integrity boundary

Backend authorization does not replace C4 integrity validation.

Flutter still validates:

```text
response byte count == sizeBytes
SHA-256(bytes) == checksumSha256
```

An HTTP `200` with invalid bytes MUST never be promoted to trusted local storage.

The Backend MAY also expose checksum as `ETag`, but publication metadata remains the integrity source of truth.

---

## 9. Range support

MVP Flutter downloads the complete artifact before trusted local playback, so HTTP Range is not required for the first production release.

Backend endpoint MAY add standards-compliant `Range` support later for large media/streaming without exposing RustFS. The public endpoint remains the same Backend URL.

---

## 10. Rate limiting and observability

Backend media reads SHOULD support:

```text
per-installation rate limit
burst limit
asset eligibility checks
traceId
safe assetId logging
latency / byte metrics
```

Do not log installation bearer tokens or storage credentials.

RustFS-specific exceptions and paths are mapped to Backend error semantics before crossing the API boundary.

---

## 11. Error semantics

Stable learner errors:

```text
401 INSTALLATION_UNAUTHORIZED
403 MEDIA_ACCESS_FORBIDDEN / INSTALLATION_REVOKED
404 ASSET_NOT_FOUND
409 ASSET_NOT_READY
429 RATE_LIMITED
500/502/503/504 MEDIA_ACCESS_UNAVAILABLE
```

Flutter never sees RustFS/S3-specific error classes.

---

## 12. Explicitly rejected MVP models

C5 does not use:

```text
public RustFS bucket
Flutter → RustFS
Worker → RustFS
public stable object URL embedded in publication
RustFS/S3 credentials in Flutter or Worker
client-supplied storage key lookup
signed/presigned URL returned to Flutter
long-lived storage URLs stored in Drift
redirect from Backend to object storage
```

Spring Boot is the sole network boundary for Flutter and Worker.

---

## 13. Acceptance scenarios

### C5-M01 — valid installation streams media through Backend

```text
valid token
+ learner-deliverable assetId
→ GET Backend media endpoint
→ 200 binary bytes
→ size/checksum valid
```

### C5-M02 — token rotation preserves asset identity

```text
T1 downloads asset A
local A removed
T2 becomes current token
T2 downloads asset A again through Backend
```

Required:

```text
assetId unchanged
checksum unchanged
deliveryKey unchanged in publication metadata
storage URL never exposed
```

### C5-M03 — revoked installation fails closed

```text
installation REVOKED
→ Backend media GET
→ 401/403
→ no storage request from Flutter
```

### C5-M04 — arbitrary storage access is impossible

Flutter cannot submit bucket, deliveryKey, object path or URL. Unknown `assetId` returns `404`/typed failure.

### C5-M05 — integrity remains C4-owned

Backend streams bytes whose checksum does not match publication metadata:

```text
→ Flutter rejects
→ temp bytes removed
→ never promoted to trusted local media
```

### C5-M06 — Backend never redirects to storage

```text
Backend 3xx Location: RustFS/S3/CDN
→ Flutter rejects response
→ no redirect followed
```

### C5-M07 — local deletion is recoverable

```text
verified local file deleted
→ next resolve(downloadIfMissing)
→ Backend-only GET
→ same immutable asset restored
```

---

## 14. Frozen rule

> Flutter and TTS Worker communicate only with Spring Boot. RustFS is Backend-internal infrastructure. Backend resolves `assetId`/`deliveryKey`, accesses RustFS and streams or accepts bytes. No storage URL, presigned grant or object-store credential crosses into Flutter or Worker.
