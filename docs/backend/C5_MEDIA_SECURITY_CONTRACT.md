# C5 — Media Security Contract

**Status:** FROZEN MVP CONTRACT  
**Scope:** learner media authorization and delivery resolution for immutable C4 assets.  
**Related contracts:**

- `docs/backend/C4_ATOMIC_PUBLICATION_CONTRACT.md`
- `docs/backend/C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`
- `contracts/learner-api-v1.yaml`

## 1. Decision

Learner media is **not public by default**.

C4 publishes only stable media identity:

```text
assetId
checksumSha256
deliveryKey
sizeBytes
mediaType
requiredOffline
```

C5 authorizes an installation to resolve that stable identity into a short-lived media access grant.

```text
C4 stable asset descriptor
        ↓
Flutter authenticated API client
        ↓
C5 media access endpoint
        ↓
validate current installation token
        ↓
validate asset is learner-deliverable
        ↓
issue short-lived signed/presigned URL
        ↓
Flutter downloads bytes directly from media origin/edge
        ↓
C4 checksum validation
```

The signed URL is transport material only. It is never part of `PublicationSnapshot`, manifest checksum, ETag, asset checksum, or durable Flutter content identity.

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

### C5 owns

```text
whether the installation may resolve the asset
current learner token validation
media access grant issuance
grant lifetime
rate limiting / abuse controls
revocation behavior
```

### Infrastructure owns

```text
RustFS/S3-compatible presigning implementation
media origin/edge hostname
TLS
object retrieval
HTTP Range support where required
```

No layer may move ephemeral access material into C4 publication identity.

---

## 3. Resolution API

Normative learner boundary:

```http
POST /api/v1/media/access
Authorization: Bearer <current-installation-token>
Content-Type: application/json
```

Request:

```json
{
  "assetId": "asset-123"
}
```

Response:

```json
{
  "assetId": "asset-123",
  "url": "https://media.example/...signed...",
  "expiresAt": "2026-10-31T14:20:00Z"
}
```

The backend MAY derive the object location from `deliveryKey` internally, but Flutter MUST NOT submit arbitrary storage keys or object-store paths for signing.

`assetId` is the authorization input because it allows the backend to validate that the requested object is a known learner-deliverable `FileAsset`.

---

## 4. Authorization rules

A media access grant is issued only when all of the following are true:

```text
installation token is current and valid
installation status is ACTIVE
assetId exists
asset is READY/published
asset is learner-deliverable
asset belongs to a retained/current publication graph as permitted by retention policy
```

The backend MUST NOT create signed URLs for arbitrary RustFS keys supplied by the client.

A revoked installation cannot obtain new media grants.

An already-issued signed URL may remain usable until its short expiration unless the selected storage/edge supports active revocation. MVP does not require per-URL active revocation.

---

## 5. Grant lifetime

Media grants are deliberately short-lived.

MVP policy:

```text
default TTL: 5 minutes
maximum TTL: 15 minutes
```

The exact configured TTL is server-owned and MAY change without changing C4 publication identity or Flutter persisted content state.

Flutter MUST treat the URL as disposable and MUST NOT persist it as the durable asset locator.

Durable identity remains:

```text
assetId + checksumSha256 + deliveryKey
```

---

## 6. Flutter download behavior

The download path is:

```text
AssetDescriptor
      ↓
request media grant using assetId
      ↓
signed URL
      ↓
HTTP download to staging file
      ↓
verify size/checksum
      ↓
atomic local promotion
```

Rules:

1. signed URL is never stored as durable content metadata;
2. expiry before/during download causes a fresh access-grant request, not publication resync;
3. token `401` on the access endpoint uses normal bounded C5 renewal (`reissue once + retry once`);
4. a storage-origin `403` caused by expired signed URL causes at most one fresh grant resolution for that logical download attempt;
5. checksum mismatch is a C4 integrity failure and MUST NOT be solved by repeatedly minting URLs;
6. successful local offline media remains usable after token or URL expiry.

---

## 7. Publication independence

For one immutable asset:

```text
assetId          = constant
checksumSha256   = constant
deliveryKey      = constant
signed URL       = variable / ephemeral
```

Therefore:

```text
URL1 != URL2
```

does **not** imply a new asset revision or new publication.

Token rotation, grant expiry, presigning parameters and host changes MUST NOT alter the publication checksum.

---

## 8. Range requests and audio

Because learner media includes audio, the media origin/edge SHOULD support HTTP Range requests.

A signed/presigned grant SHOULD remain valid for normal range retrieval during its TTL.

Flutter must still validate the complete downloaded offline artifact against the C4 checksum before promoting it to trusted local storage.

Streaming behavior does not weaken offline-file integrity requirements.

---

## 9. Rate limiting and abuse controls

The access endpoint MUST be rate-limited independently from content manifest reads.

MVP controls SHOULD include:

```text
per-installation request rate
burst limit
server-side asset eligibility validation
traceable grant issuance event without logging signed URL query secrets
```

Do not log full presigned URLs because query parameters may contain credentials/signatures.

Operational metrics SHOULD record only safe identifiers such as `assetId`, installation hash/reference, result code and latency.

---

## 10. Error semantics

Recommended stable error classes:

```text
401 INSTALLATION_UNAUTHORIZED
403 INSTALLATION_REVOKED / MEDIA_ACCESS_FORBIDDEN
404 ASSET_NOT_FOUND
409 ASSET_NOT_READY
429 RATE_LIMITED
500/503 MEDIA_ACCESS_UNAVAILABLE
```

`429` SHOULD expose `Retry-After` according to the general C5 reliability contract.

Storage-origin failures after grant issuance are transport/download failures and do not mutate publication state.

---

## 11. Explicitly rejected MVP models

C5 does not use:

```text
public RustFS bucket
public stable object URL embedded in publication
RustFS credentials in Flutter
client-supplied storage key signing
long-lived signed URLs stored in Drift
signed URL inside manifest checksum
user account / DRM platform
per-byte proxying through Spring Boot
```

Spring Boot authorizes and issues access; media bytes flow directly from RustFS/edge to Flutter.

---

## 12. Acceptance scenarios

### C5-M01 — Valid installation obtains media access

```text
valid token
+ learner-deliverable assetId
→ 200 access grant
→ short-lived URL
```

### C5-M02 — Token rotation does not change asset identity

```text
T1 resolves asset A → URL1
cold bootstrap → T2
T2 resolves asset A → URL2
```

Required:

```text
assetId unchanged
checksum unchanged
deliveryKey unchanged
URL may differ
```

### C5-M03 — Expired URL is re-resolved without publication resync

```text
URL1 expires
→ request new grant for same assetId
→ URL2
→ download
→ same checksum
```

### C5-M04 — Revoked installation cannot mint new grants

```text
installation REVOKED
→ media access request
→ fail closed
```

### C5-M05 — Arbitrary object-key signing is impossible

Supplying an unknown `assetId` or attempting to provide a raw storage path MUST NOT produce a signed URL.

### C5-M06 — Integrity remains C4-owned

A successful signed URL download whose bytes do not match `checksumSha256` is rejected and never promoted to trusted local media.

### C5-M07 — Signed URL is not durable state

Restarting Flutter after URL expiry still resolves the media from stable `assetId`/`deliveryKey`; no persisted signed URL is required.

---

## 13. Frozen rule

> C4 publishes stable media identity. C5 authorizes access to that identity and may issue short-lived delivery grants. RustFS/edge serves the bytes. Ephemeral delivery credentials never become publication state.
