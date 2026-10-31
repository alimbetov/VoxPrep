# BGA-011 — Media Security Resolution

**Status:** RESOLVED  
**Original severity:** P1 HIGH / PRODUCT RISK  
**Normative contracts:**

- `docs/backend/C4_ATOMIC_PUBLICATION_CONTRACT.md`
- `docs/backend/C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`
- `docs/backend/C5_MEDIA_SECURITY_CONTRACT.md`

## Resolution

BGA-011 is closed by selecting **authenticated media resolution with short-lived signed/presigned delivery URLs** for MVP.

The project does not use public learner media as the default delivery policy.

The stable publication contract remains:

```text
assetId
checksumSha256
deliveryKey
sizeBytes
mediaType
requiredOffline
```

Flutter never treats a signed URL as durable content identity.

The delivery boundary is:

```text
Flutter
  stable assetId from C4
        ↓
Authenticated learner API
  Authorization: Bearer <current installation token>
        ↓
POST /api/v1/media/access
        ↓
Backend validates installation + asset eligibility
        ↓
short-lived RustFS/edge signed URL
        ↓
Flutter downloads directly from media origin/edge
        ↓
checksum verification
        ↓
trusted local offline asset
```

## Security consequences

- RustFS credentials never reach Flutter.
- The client cannot submit arbitrary RustFS object keys for signing.
- Revoked installations cannot mint new media access grants.
- Existing grants expire quickly and are disposable.
- Token rotation does not change asset identity.
- URL expiry does not trigger publication resynchronization.
- Media bytes do not need to be proxied through Spring Boot.

## MVP grant lifetime

```text
default: 5 minutes
maximum: 15 minutes
```

The TTL is server-owned and may change without changing C4 checksums, revisions or Flutter durable state.

## Explicitly rejected alternatives

For MVP the project does not choose:

```text
public RustFS bucket as the default learner-media policy
public stable media URL embedded in manifests
long-lived signed URL persisted in Drift
RustFS credentials in Flutter
Spring Boot byte proxy for normal media delivery
signed URL as part of PublicationSnapshot identity
```

## Acceptance

BGA-011 is considered resolved when implementation/contract tests prove:

1. valid installation token + learner-deliverable assetId yields a short-lived access grant;
2. revoked installation cannot obtain a new grant;
3. unknown/raw storage key cannot be signed;
4. same immutable asset may resolve to different URLs without changing `assetId`, `deliveryKey` or checksum;
5. expired grant can be re-resolved without publication resync;
6. downloaded bytes must pass C4 checksum verification before local promotion;
7. signed URLs and their signatures are not logged or stored as durable learner content state.
