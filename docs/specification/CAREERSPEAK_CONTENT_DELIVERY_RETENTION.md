# CareerSpeak — Content Delivery, Availability & Local Retention Requirements

**Document version:** 2.0  
**Status:** Normative specification  
**Applies to:** CareerSpeak v0.9+

Related standard:

- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)

---

## 1. Purpose

This specification defines how Backend delivers published content to Flutter and how Flutter retains/reclaims local metadata and media.

It covers:

```text
backend availability
root/pack manifests
cursor pagination
tombstones
metadata CURRENT state
offline READY state
stream/cache behavior
explicit offline download
TTL/LRU/quota retention
shared asset references
safe eviction
```

---

## 2. Backend learner-delivery rule

Backend owns:

```text
revision_status
availability_status
```

Learner-deliverable content is exactly:

```text
revision_status = PUBLISHED
AND
availability_status = ACTIVE
```

Meaning:

```text
visible in learner contracts where applicable
included in applicable manifest snapshot
available for stream/download
associated published assets deliverable
```

`PUBLISHED + INACTIVE` is retained for audit/history but not offered for new learner delivery.

---

## 3. Learner pagination

Learner collection APIs use cursor/keyset pagination.

Example:

```text
GET /api/v1/vocabulary?cefr=B2&limit=50&cursor=...
```

Response shape:

```json
{
  "items": [],
  "page": {
    "nextCursor": "...",
    "hasMore": true
  }
}
```

Sort order must be deterministic with a unique tie-breaker.

Admin Content Studio may use ordinary page/size pagination.

---

## 4. Root manifest

Flutter uses one root learner-delivery snapshot:

```text
contentVersion
```

Conceptual response:

```json
{
  "schemaVersion": 1,
  "contentVersion": 108,
  "publishedAt": "2026-10-30T09:30:00Z",
  "packs": [
    {
      "code": "JAVA_SENIOR",
      "variant": "canonical",
      "revision": 8,
      "checksum": "..."
    },
    {
      "code": "JAVA_SENIOR",
      "variant": "locale:kk",
      "revision": 4,
      "checksum": "..."
    }
  ],
  "tombstones": []
}
```

Locale variants are pack members inside the root snapshot. They do not create unrelated root epochs.

---

## 5. Pack manifest

Example:

```text
GET /api/v1/content/packs/{code}/manifest?variant=canonical&revision=8
```

A pack manifest identifies immutable:

```text
pack code
variant
revision
schema version
checksum
content identities/revisions
asset descriptors/checksums
required_offline flags where applicable
```

Flutter downloads only changed/missing metadata/assets required by current intent.

---

## 6. Flutter metadata lifecycle

Flutter local metadata states:

```text
STAGING
VERIFIED
CURRENT
SUPERSEDED
FAILED
```

`CURRENT` = the local metadata/read-model revision used by learner repositories.

Do not call this state `ACTIVE`; `ACTIVE` is reserved for Backend availability.

Metadata switch is atomic at root `contentVersion` level for MVP.

---

## 7. Offline lifecycle

Offline pack state is independent from metadata `CURRENT`:

```text
NOT_DOWNLOADED
QUEUED
DOWNLOADING
VERIFYING
READY
UPDATING
FAILED
```

`READY` means the required offline asset set is locally verified.

Supported state:

```text
metadata revision 8 = CURRENT
offline revision 7 = READY
offline revision 8 = UPDATING
```

Revision 7 remains usable offline until rev 8 verifies successfully.

---

## 8. Stream/cache vs explicit download

Normal learner behavior:

```text
CURRENT metadata
→ asset requested
→ local verified copy if present
→ otherwise CDN stream/download
```

Normal metadata sync SHALL NOT download every audio/image file.

Explicit offline behavior:

```text
user requests Download/Pin
→ DownloadManager obtains required_offline assets
→ checksum/size verification
→ atomic local placement
→ offline READY
```

---

## 9. Tombstones

Backend emits explicit tombstones for previously delivered content that is no longer learner-deliverable, including deactivation.

Example:

```json
{
  "code": "JAVA_QUESTION_001",
  "revision": 3,
  "reason": "INACTIVE"
}
```

Flutter applies tombstones during metadata activation:

```text
remove/retire disposable CURRENT content
release disposable references
preserve learner history
```

Missing objects from paginated list responses are never interpreted as deletion.

---

## 10. Durable vs disposable local state

Durable learner state:

```text
favorites
progress
test attempts/answers
review schedule
completed topics
settings
locale/theme preferences
```

Disposable/re-downloadable state:

```text
pack metadata snapshots
audio/images
cached asset bytes
downloadable theme assets
```

Cache/media eviction never deletes durable learner state.

---

## 11. Retention classes

```text
AUTO_CACHE
EXPLICIT_DOWNLOAD
PINNED
```

Rules:

```text
AUTO_CACHE
→ TTL/LRU/quota eligible

EXPLICIT_DOWNLOAD
→ protected from ordinary automatic eviction

PINNED
→ protected from ordinary automatic eviction
```

Favorites are not automatically storage pins.

---

## 12. TTL + LRU + quota

Automatic disposable-storage management uses:

```text
TTL
+
LRU
+
local managed-storage quota
```

Baseline cleanup priority:

```text
1. invalid/tombstoned/obsolete disposable data
2. expired AUTO_CACHE data
3. least-recently-used AUTO_CACHE data
4. protect explicit download/pinned data during normal cleanup
```

Exact TTL/quota values are configurable policy, not immutable domain constants.

---

## 13. Shared asset references

The same immutable asset may be referenced by multiple current/offline content items.

Logical model:

```text
asset_catalog
local_asset_file
content_asset_ref
pack_asset_ref
```

Physical file deletion is allowed only when no retained/current/offline-ready reference requires the file.

Quota accounting counts unique local physical files, not repeated logical references.

---

## 14. Media delivery

Published learner media path:

```text
Flutter
→ AssetResolver
→ local verified file OR CDN/edge
→ RustFS published origin
```

Spring Boot does not proxy normal learner MP3/image bytes.

Database/domain identity does not persist environment-specific CDN hostnames.

---

## 15. Locale reuse

Canonical English content/audio is shared across locales.

Example:

```text
JAVA_SENIOR canonical rev 8
JAVA_SENIOR locale:ru rev 5
JAVA_SENIOR locale:kk rev 4
```

Changing translation locale should download the locale delta only when canonical assets are unchanged.

---

## 16. Cleanup triggers

Correctness does not depend solely on mobile OS background scheduling.

Evaluate cleanup at:

```text
startup
manifest sync
pack replacement
after large download
quota pressure
user-triggered Free space
```

---

## 17. HTTP/cache behavior

May use:

```text
ETag / If-None-Match
immutable CDN caching
local Drift/filesystem cache
```

Do not add Redis solely for MVP learner catalog caching.

---

## 18. Acceptance scenarios

Must prove:

```text
cursor traversal without duplicate/skip corruption
PUBLISHED + INACTIVE absent from learner delivery
deactivation produces tombstone/current removal
metadata N→N+1 atomic CURRENT transition
streaming works without full offline bundle
offline READY rev N survives update to CURRENT rev N+1
offline READY switches only after verification
progress survives tombstone/cache eviction
favorites do not force permanent media retention
quota cleanup removes LRU auto-cache
shared file survives while another reference exists
locale change reuses English audio
```

---

## 19. Standard terminology

```text
Backend ACTIVE
= deliverable/downloadable

Flutter CURRENT
= selected local metadata revision

Flutter offline READY
= complete locally verified offline bundle
```

This terminology is mandatory.
