# CareerSpeak — Content Studio Hardening Addendum

**Document version:** 1.0  
**Status:** Normative addendum to `CAREERSPEAK_CONTENT_STUDIO_REQUIREMENTS.md`  
**Applies to:** CareerSpeak v1 B1 authoring implementation

This addendum records small gaps discovered during the 2026-11-02 light audit. It does not create a new feature stream.

---

## 1. Minimal asset / cover authoring

The learner application already supports an optional exact-revision `coverImage` asset. B1 authoring therefore needs the smallest safe way to create and bind that asset.

Required v1 behavior:

```text
Content draft
  ↓
Upload image
  ↓
validate
  ↓
store private binary in RustFS
  ↓
create Asset metadata + SHA-256 + size + contentType
  ↓
bind role = coverImage to exact draft revision
  ↓
publication validation
```

Supported cover formats:

```text
PNG
JPEG
WebP
```

SVG/GIF are not accepted as v1 cover media.

The upload boundary SHALL validate at least:

```text
configured maximum file size
actual binary/media signature where practical
supported decoded image type
non-empty dimensions
safe generated storage key
SHA-256
```

The original client filename is presentation/audit metadata only and is never trusted as a storage path.

Binary media MUST NOT be embedded in XML. XML may reference a stable asset identity already known to Backend.

A new upload linked to a `PUBLISHED` revision MUST NOT mutate that revision in place; normal create-new-draft revision rules apply.

Image authoring is limited to upload/bind/remove-from-draft. Cropping, image generation, galleries, captions and rich DAM functionality remain out of v1 scope.

---

## 2. Temporary upload/import storage

XML and binary uploads SHALL use bounded temporary storage.

Requirements:

- temporary filenames are server-generated;
- temporary directories are outside public static resources;
- successful/failed imports/uploads are cleaned according to a bounded retention policy;
- restart cleanup handles abandoned temporary files;
- temporary files never become the authoritative published asset path;
- errors never expose host filesystem paths.

---

## 3. ADMIN authentication/session hardening

The existing `/admin/**` + CSRF requirement is necessary but not sufficient.

V1 SHALL additionally require:

```text
no default production ADMIN password
ADMIN credential material injected as secret/config, not source code
strong password hashing through Spring Security PasswordEncoder
session fixation protection
HttpOnly session cookie
Secure cookie in production
SameSite policy appropriate to same-origin admin use
logout invalidates the server session
no credentials in URLs/logs
```

The login endpoint SHOULD implement bounded throttling/backoff against repeated failures. A generic authentication failure message is preferred over account-existence disclosure.

Production Content Studio SHALL run behind TLS.

Recommended security headers include a restrictive Content Security Policy, clickjacking protection (`frame-ancestors` or equivalent), MIME sniffing protection and an explicit referrer policy.

No MFA/IdP/Keycloak dependency is required for v1.

---

## 4. Audit log hardening

Authoring audit records SHOULD include enough information to reconstruct high-level operator intent without storing secrets:

```text
auditId
actor
operation
entity/code/revision
source = VISUAL | XML_IMPORT | ASSET_UPLOAD
request/import correlation id
before fingerprint when applicable
after fingerprint when applicable
result
createdAt
```

Normal Content Studio CRUD operations SHALL NOT delete or rewrite historical audit entries.

Raw passwords, session cookies, authorization headers and RustFS/database secrets are forbidden in audit payloads.

---

## 5. Asset failure semantics

Asset upload is separate from publication visibility.

Required safe behavior:

```text
RustFS write fails
→ no Asset metadata commit

metadata transaction fails after object write
→ object is orphan candidate
→ background/manual cleanup may remove it later
→ no broken published reference

publication validation finds missing/checksum-invalid object
→ publication fails closed
```

The implementation SHALL prefer orphaned private objects over committed metadata that points to missing bytes.

---

## 6. Backup/restore relationship

Authoring and asset retention SHALL respect the infrastructure backup contract.

Published immutable assets referenced by retained database/publication backups MUST NOT be physically deleted before the matching backup retention window expires.

A restore qualification SHALL verify both metadata and the bytes/checksums of representative cover/audio assets.

---

## 7. Acceptance additions

The existing Content Studio acceptance list is extended with:

```text
H01 ADMIN production credential is not a source-controlled/default password
H02 production session cookie is Secure + HttpOnly and session fixation is protected
H03 repeated failed login is bounded/throttled
H04 valid PNG/JPEG/WebP cover can be uploaded and bound to one draft revision
H05 SVG/GIF/non-image/corrupt cover payload fails closed
H06 asset upload stores SHA-256/size/content type and uses a server-generated storage key
H07 binary upload failure cannot produce committed metadata pointing at missing bytes
H08 a cover change for PUBLISHED content creates/uses a mutable draft revision rather than mutating history
H09 abandoned XML/binary temporary files are bounded and cleanable across restart
H10 publication rejects a missing or checksum-invalid required asset
H11 audit records contain correlation/fingerprint evidence without secret leakage
H12 restored PostgreSQL + RustFS data reproduces representative published asset integrity
```

These requirements remain subordinate to B1/A1 and do not add a new MVP stage.
