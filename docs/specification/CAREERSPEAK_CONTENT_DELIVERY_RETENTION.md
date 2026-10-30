# CareerSpeak — Content Delivery, Availability & Local Retention Requirements

**Document version:** 1.1  
**Status:** Architecture baseline / normative specification  
**Applies to:** VoxPrep / CareerSpeak v0.7+

---

## 1. Purpose

This document defines how CareerSpeak delivers growing content catalogs to Flutter while preventing uncontrolled backend queries and uncontrolled device-storage growth.

It covers:

```text
cursor pagination
publication vs availability
manifest/tombstones
offline packs
TTL/LRU cleanup
local quota
pinning
shared-asset reference tracking
safe local eviction
```

---

## 2. Core rules

1. Published revisions remain immutable.
2. Publication lifecycle and learner availability are separate.
3. Learner catalog APIs are paginated.
4. Learner APIs expose only `PUBLISHED + ACTIVE` content.
5. Deactivation does not destructively delete backend history.
6. Flutter does not retain re-downloadable media forever.
7. Local media eviction never erases learner progress.
8. Shared assets are deleted only when no retained local content references them.
9. Explicitly pinned/manual offline content is protected from normal automatic cleanup.

---

## 3. Publication and availability

Content revision lifecycle:

```text
DRAFT
READY_FOR_AUDIO
READY_FOR_REVIEW
PUBLISHED
ARCHIVED
```

Availability:

```text
ACTIVE
INACTIVE
```

Consumer visibility condition:

```text
revision_status = PUBLISHED
AND
availability_status = ACTIVE
```

Example:

```text
PUBLISHED + ACTIVE   → visible to Flutter
PUBLISHED + INACTIVE → retained historically, hidden from learner API
```

ADMIN may deactivate and later reactivate a published revision without deleting its historical data.

---

## 4. Learner pagination

Learner collection APIs SHALL use cursor/keyset pagination.

Example:

```text
GET /api/v1/vocabulary?cefr=B2&limit=50&cursor=...
```

Recommended response:

```json
{
  "items": [],
  "page": {
    "nextCursor": "...",
    "hasMore": true
  }
}
```

Cursor sorting SHALL be deterministic and use a unique tie-breaker, for example:

```text
sort_order + id
```

or:

```text
published_at DESC + id DESC
```

Large learner catalogs SHOULD NOT depend on deep OFFSET pagination.

---

## 5. Admin pagination

Internal Content Studio lists MAY use ordinary page/size pagination because they are low-volume administrative workflows.

Example:

```text
/admin/vocabulary?page=0&size=50
```

ADMIN filtering may include publication status, availability, category, locale readiness and audio readiness.

---

## 6. Root manifest

Flutter uses a compact root manifest to discover changed content packs.

Example:

```text
GET /api/v1/content/manifest
```

Conceptual response:

```json
{
  "schemaVersion": 1,
  "contentVersion": 107,
  "publishedAt": "...",
  "packs": [
    {
      "code": "JAVA_SENIOR",
      "revision": 8,
      "checksum": "..."
    }
  ],
  "tombstones": []
}
```

The root manifest SHOULD remain compact.

---

## 7. Pack manifest

Large content is divided into packs such as:

```text
IELTS_VOCABULARY_B2
IELTS_SPEAKING
GENERAL_INTERVIEW
JAVA_JUNIOR
JAVA_SENIOR
DEVOPS
BUSINESS_ANALYST
```

Example:

```text
GET /api/v1/content/packs/{code}/manifest
```

A pack manifest may reference content metadata and immutable assets/checksums required by that pack.

Flutter downloads only missing/changed assets.

---

## 8. Tombstones

When previously distributed content becomes unavailable, the server SHALL communicate removal/deactivation through tombstones or equivalent manifest delta semantics.

Example:

```json
{
  "code": "JAVA_QUESTION_001",
  "revision": 3,
  "reason": "INACTIVE"
}
```

Flutter SHALL:

```text
remove obsolete local content snapshot
release its asset references
remove unreferenced disposable assets
preserve learner progress/history where meaningful
```

A missing object from a normal page response alone is not sufficient evidence for destructive local cleanup.

---

## 9. Local state separation

Flutter persistence separates durable learner state from disposable/re-downloadable content.

### Durable learner state

```text
favorites
progress
test attempts/test answers
review schedule
completed topics
settings
selected locale
selected ambience/focus preference
```

### Disposable/re-downloadable state

```text
pack snapshots
audio files
remote images
cached metadata
future downloadable theme packs
```

Deleting a disposable asset SHALL NOT delete the corresponding learner progress.

---

## 10. Local cache entry

Recommended concept:

```text
content_cache_entry
────────────────────────────
content_code
content_revision
pack_code
downloaded_at
last_accessed_at
expires_at
size_bytes
pinned
explicit_download
cache_state
```

`last_accessed_at` is updated when the retained content is actually used.

---

## 11. Retention policy

Automatic retention uses:

```text
TTL
+
LRU
+
local storage quota
```

Baseline behavior:

```text
AUTO_CACHE
    → TTL/LRU/quota eligible

PINNED
    → protected from normal auto-eviction

EXPLICIT_DOWNLOAD
    → protected from normal cleanup until user removes it or an explicit emergency-storage policy is invoked

INACTIVE_SERVER_CONTENT
    → remove obsolete disposable data after manifest synchronization

OLD_REVISION
    → remove after replacement is verified and asset references are released
```

Exact TTL and quota values are configuration/product decisions, not hardcoded domain constants.

---

## 12. Favorites are not pins

A learner favorite SHALL NOT automatically force every related binary asset to remain forever.

Example:

```text
favorite vocabulary item
→ favorite/progress row retained
→ audio may still be evicted
→ audio can be re-downloaded later
```

Explicit offline pinning/manual download is the storage-retention signal.

---

## 13. TTL behavior

For automatically cached content:

```text
expires_at = last_accessed_at + retentionPeriod
```

Access extends interest/retention.

Expired content becomes an eviction candidate; expiry does not require immediate deletion if storage pressure is low.

---

## 14. LRU and storage quota

TTL alone is insufficient because a learner may download a large amount of content before TTL expiry.

When local disposable storage exceeds configured quota:

```text
1. remove obsolete/tombstoned data
2. remove expired unpinned data
3. remove least-recently-used unpinned data
4. preserve protected explicit downloads/pins
```

The application SHOULD expose a user action such as `Free space` for explicit cleanup.

---

## 15. Shared local assets

The same immutable audio/image asset may be referenced by more than one retained content item.

Recommended local concepts:

```text
local_asset
────────────────
asset_id
checksum
local_path
size_bytes
last_accessed_at
```

```text
content_asset_ref
────────────────
content_code
content_revision
asset_id
```

Physical deletion is allowed only when no retained reference remains.

Conceptually:

```text
reference_count == 0
```

---

## 16. Revision replacement

When pack/content revision N+1 is downloaded and verified:

```text
activate new local snapshot
→ release references owned only by old revision N
→ delete old unreferenced disposable assets
```

Old revisions do not need to wait for ordinary TTL once a replacement is safely installed.

---

## 17. Cleanup triggers

Do not rely solely on mobile background scheduling.

Cleanup SHOULD be evaluated at predictable points:

```text
application startup
manifest synchronization
after pack update
after large download
when quota is exceeded
user-triggered Free space
```

OS background tasks may be supplementary, not required for correctness.

---

## 18. Media delivery

Published media path:

```text
Flutter
→ CDN/edge
→ RustFS published origin
```

Spring Boot SHALL NOT proxy normal learner MP3/image bytes.

Immutable versioned asset keys allow aggressive caching.

---

## 19. API/cache behavior

Published catalog/content responses MAY use HTTP cache validators such as ETag where useful.

Do not add Redis solely for catalog caching in MVP.

Primary caching layers are:

```text
Flutter local DB/files
HTTP cache semantics
CDN/edge for immutable media
PostgreSQL internal caching/buffers
```

---

## 20. Acceptance scenarios

The implementation SHALL prove at least:

1. cursor pagination returns stable non-duplicated traversal;
2. concurrent new publication does not corrupt cursor traversal semantics;
3. `PUBLISHED + INACTIVE` is absent from learner lists;
4. deactivation produces a manifest/tombstone change;
5. Flutter removes disposable data for tombstoned content;
6. learner progress survives media eviction;
7. pinned/manual download survives normal TTL cleanup;
8. quota cleanup removes LRU unpinned content;
9. shared audio is not deleted while another retained content item references it;
10. old pack revision assets are reclaimed after safe replacement.

---

## 21. Summary

```text
Backend
→ PUBLISHED + ACTIVE only
→ cursor pagination
→ root/pack manifests
→ tombstones

Flutter
→ durable learner state
→ disposable content/assets
→ TTL + LRU + quota
→ pin protection
→ reference-safe deletion
```

This is the authoritative content-delivery/local-retention baseline for CareerSpeak v0.7.
