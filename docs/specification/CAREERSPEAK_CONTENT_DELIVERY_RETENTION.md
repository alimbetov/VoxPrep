# CareerSpeak — Content Delivery, Availability & Local Retention Requirements

**Document version:** 1.0  
**Status:** Architecture baseline / normative addendum  
**Applies to:** VoxPrep / CareerSpeak v0.6+

---

## 1. Purpose

This specification defines how CareerSpeak delivers large content catalogs to Flutter clients without excessive API/database cost or uncontrolled local-storage growth.

It covers:

- learner API pagination;
- moderator pagination;
- content publication versus availability;
- deactivation without destructive deletion;
- content manifests and tombstones;
- offline pack manifests;
- local Flutter retention;
- TTL/LRU eviction;
- local storage quotas;
- pinning/manual-download protection;
- asset reference tracking and safe deletion.

This document is normative for the v0.6 architecture baseline.

---

## 2. Design principles

1. Published content SHALL remain immutable by revision.
2. Publication lifecycle and learner availability SHALL be separate concepts.
3. Consumer catalog APIs SHALL be paginated.
4. Flutter SHALL NOT retain all downloaded media forever.
5. Local progress SHALL be independent from local media/cache eviction.
6. Server-side deactivation SHALL propagate to clients through manifest tombstones.
7. Shared local assets SHALL be removed only when no retained content references them.
8. Manual/pinned offline content SHALL be protected from normal automatic eviction.
9. Retention decisions SHALL remain local and privacy-preserving.
10. Cleanup SHALL be deterministic and testable.

---

## 3. Publication lifecycle versus availability

CareerSpeak SHALL maintain two independent state dimensions.

### 3.1 Publication lifecycle

Revision workflow:

```text
DRAFT
  ↓
READY_FOR_AUDIO
  ↓
AUDIO_PENDING
  ↓
AUDIO_GENERATING
  ↓
AUDIO_READY
  ↓
REVIEW
  ↓
PUBLISHED
  ↓
ARCHIVED
```

Publication status answers:

> Is this revision valid, reviewed and historically publishable?

### 3.2 Availability status

Learner availability answers:

> Should the currently published revision be visible/consumable by learner clients now?

Initial values:

```text
ACTIVE
INACTIVE
```

Future extension MAY include:

```text
SCHEDULED
```

A consumer-visible item normally requires:

```text
revision_status = PUBLISHED
AND
availability_status = ACTIVE
```

`ACTIVE` SHALL NOT be added as another publication lifecycle status.

---

## 4. Deactivation semantics

Deactivation is non-destructive.

Example:

```text
revision_status      = PUBLISHED
availability_status  = INACTIVE
```

The record remains in PostgreSQL for:

- auditability;
- rollback;
- historical test snapshots;
- publication history;
- moderation investigation.

Normal deactivation SHALL NOT execute physical `DELETE` against published domain content.

Reasons for deactivation MAY include:

```text
CONTENT_ERROR
AUDIO_QUALITY
OUTDATED_CONTENT
LICENSE_REVIEW
POLICY
TEMPORARY_WITHDRAWAL
OTHER
```

Optional metadata:

```text
deactivated_at
deactivated_by
deactivation_reason
deactivation_note
```

---

## 5. Consumer query contract

Learner-facing repositories/endpoints SHALL exclude inactive/unpublished revisions by default.

Logical predicate:

```text
publication_status = PUBLISHED
AND
availability_status = ACTIVE
```

Administrative queries MAY include all states.

The learner API SHALL NOT require the mobile client to filter unpublished/inactive rows after retrieval.

---

## 6. Learner API pagination

Large learner catalogs SHALL use cursor/keyset pagination.

Examples:

```text
GET /api/v1/vocabulary?limit=50&cursor=<opaque>
GET /api/v1/interviews?limit=30&cursor=<opaque>
GET /api/v1/topics?limit=30&cursor=<opaque>
GET /api/v1/tests?limit=30&cursor=<opaque>
```

Response shape:

```json
{
  "items": [],
  "nextCursor": "opaque-value",
  "hasMore": true
}
```

Cursor values SHALL be opaque to Flutter.

Recommended deterministic sort keys:

```text
sort_order + id
```

or for time-ordered feeds:

```text
published_at DESC + id DESC
```

Offset pagination SHOULD NOT be the primary learner strategy for large growing datasets.

---

## 7. Cursor stability

Keyset pagination SHALL define a stable total ordering.

The backend SHALL include a unique tie-breaker such as `id` after a non-unique sort column.

Example conceptual predicate for ascending order:

```text
(sort_order > :lastSortOrder)
OR
(sort_order = :lastSortOrder AND id > :lastId)
```

The cursor MAY encode these values and SHOULD be integrity-protected or otherwise treated as opaque transport state.

Changing filters invalidates/restarts pagination.

---

## 8. Consumer filtering

Endpoints MAY support bounded filters such as:

```text
cefr
category
profession
careerTrack
seniority
skill
locale
query
```

Example:

```text
GET /api/v1/vocabulary?cefr=B2&category=TECHNOLOGY&limit=50&cursor=...
```

Database indexes SHALL be designed from actual accepted filter/sort combinations, not by adding indexes to every column.

---

## 9. Content Studio pagination

The internal Spring MVC Content Studio MAY use conventional page/size pagination because moderator traffic is low and page numbers are useful for administrative navigation.

Example:

```text
/admin/vocabulary?page=0&size=50
/admin/interviews?page=3&size=50
```

Spring Data `Pageable` is acceptable for this internal workflow.

Admin tables SHOULD expose at least:

```text
code/title
revision
publication status
availability status
localization state
audio state
updated_at
published_at
```

Admin filters SHOULD support:

```text
ACTIVE / INACTIVE
DRAFT / PUBLISHED / ARCHIVED
missing audio
stale audio
missing localization
profession/category/skill
```

---

## 10. Content manifest hierarchy

Flutter SHALL use manifests for synchronization rather than treating paginated catalog endpoints as a complete offline synchronization protocol.

### 10.1 Root manifest

Example:

```text
GET /api/v1/content/manifest
```

Conceptual response:

```json
{
  "schemaVersion": 1,
  "contentVersion": 104,
  "publishedAt": "2026-10-30T00:00:00Z",
  "packs": [
    {
      "code": "JAVA_SENIOR",
      "revision": 8,
      "checksum": "..."
    },
    {
      "code": "IELTS_B2",
      "revision": 14,
      "checksum": "..."
    }
  ],
  "tombstonesVersion": 17
}
```

The root manifest SHOULD remain compact.

### 10.2 Pack manifests

Large packs SHOULD have separate manifests:

```text
GET /api/v1/content/packs/{packCode}/manifest
```

A pack manifest may include:

```text
pack revision
content records/checksums
asset ids
asset checksums
asset sizes
removed references
```

This prevents one enormous global manifest as the catalog grows.

---

## 11. Tombstones

A client needs an explicit signal when previously synchronized content becomes unavailable.

Manifest synchronization SHALL support tombstones/removal records.

Conceptual representation:

```json
{
  "contentVersion": 105,
  "tombstones": [
    {
      "contentCode": "TOPIC_JAVA_014",
      "revision": 3,
      "reason": "INACTIVE"
    }
  ]
}
```

Possible reasons:

```text
INACTIVE
ARCHIVED
REPLACED
PACK_REMOVED
LICENSE_WITHDRAWAL
```

Flutter SHALL use tombstones to remove obsolete cached content/media while preserving independent learner progress where appropriate.

---

## 12. Version replacement

When a new content/pack revision supersedes an old one:

```text
v7 downloaded
   ↓
v8 available
   ↓
download v8
   ↓
verify checksums
   ↓
commit local v8 state atomically
   ↓
release unreferenced v7 assets
```

Old assets SHALL NOT be removed before the replacement is safely installed and verified.

---

## 13. Flutter local storage domains

Flutter SHALL separate learner state from disposable content/media cache.

### 13.1 Durable local learner state

Examples:

```text
favorites
vocabulary_progress
test_attempts
test_answers
review_schedule
completed_topics
settings
selected_locale
selected_theme
focus_mode
```

These records SHALL NOT be deleted merely because cached media expires.

### 13.2 Disposable/re-downloadable state

Examples:

```text
content pack metadata
downloaded JSON/catalog snapshots
audio files
remote images
covers
future downloadable theme assets
```

These records/assets are subject to retention policy.

---

## 14. Local cache entry model

Recommended Drift/SQLite concept:

```text
content_cache_entry
────────────────────────────────
content_code
content_revision
pack_code nullable
downloaded_at
last_accessed_at
last_played_at nullable
expires_at nullable
size_bytes
pinned
explicit_download
cache_state
```

Suggested `cache_state` values:

```text
CACHED
DOWNLOADING
STALE
EXPIRED
EVICTED
ERROR
```

`last_accessed_at` SHALL be updated on meaningful content use, not on every widget rebuild.

---

## 15. TTL policy

Automatically cached content MAY use a sliding TTL based on learner interest.

Example baseline:

```text
expires_at = last_accessed_at + retentionPeriod
```

A candidate initial retention period is:

```text
30 days
```

The exact default SHALL be configurable and qualified through usage/storage testing.

Opening/listening to relevant content MAY extend the TTL.

TTL applies to re-downloadable cached assets, not to the learner's durable progress/history.

---

## 16. Storage quota

TTL alone is insufficient because a learner may download a large amount of content within the TTL window.

Flutter SHALL support a configurable local cache quota.

Possible policy inputs:

```text
max cache bytes
free device storage
explicit offline downloads
pinned content
asset last access
pack priority
```

When quota is exceeded, eviction is triggered even for non-expired auto-cache entries.

The product SHOULD expose current downloaded/cache storage size and a `Free space` action.

---

## 17. LRU eviction

Normal automatic eviction priority SHOULD be approximately:

```text
1. server-deactivated/tombstoned assets
2. superseded old revisions
3. expired auto-cache entries
4. least-recently-used unpinned auto-cache entries
5. low-priority large packs when quota remains exceeded
```

Protected content SHALL be excluded from normal LRU selection.

A future deterministic interest score MAY refine ordering, but is not required for MVP.

---

## 18. Pinning and explicit downloads

Retention classes:

```text
PINNED
EXPLICIT_DOWNLOAD
AUTO_CACHE
```

Baseline behavior:

```text
PINNED
  → never removed by normal auto-cleanup

EXPLICIT_DOWNLOAD
  → retained until user removes it or an exceptional storage policy is explicitly invoked

AUTO_CACHE
  → TTL + LRU + quota controlled
```

A `favorite` flag SHALL NOT automatically imply permanent media pinning. Favorites may outnumber reasonable device-storage capacity.

---

## 19. Shared asset registry

Content can share identical immutable assets. Flutter SHALL avoid unsafe deletion and MAY avoid duplicate storage.

Recommended local tables:

```text
local_asset
────────────────────────
asset_id
checksum
local_path
size_bytes
last_accessed_at
state
```

```text
content_asset_ref
────────────────────────
content_code
content_revision
asset_id
```

An asset file SHALL be physically deleted only when no retained local content references it.

Conceptually:

```text
reference_count == 0
```

or equivalent referential query.

---

## 20. Asset integrity

Downloaded immutable assets SHALL be verified using server-provided checksum metadata where available.

Failed verification SHALL NOT mark the asset as ready.

Recommended states:

```text
DOWNLOADING
VERIFYING
READY
CORRUPT
```

Corrupt/incomplete files SHALL be safe to retry and SHALL NOT replace a previously valid local revision before verification succeeds.

---

## 21. Cleanup triggers

CareerSpeak SHALL NOT rely solely on background timers, because mobile platforms may suspend background execution.

Cleanup SHOULD run at deterministic opportunities such as:

```text
application startup
manifest synchronization
after successful pack update
after large download
when cache quota is exceeded
user selects Free space
```

Platform-supported background maintenance MAY be used as an optimization, not as the only correctness mechanism.

---

## 22. Cleanup transaction safety

Local metadata and filesystem deletion SHALL be coordinated so interrupted cleanup does not corrupt the local catalog.

Recommended pattern:

```text
mark asset EVICTING / remove references transactionally
    ↓
delete physical file
    ↓
remove/mark local_asset row
```

Recovery on next startup SHALL detect orphaned database records or orphaned cache files and reconcile them.

---

## 23. Manual storage management UI

Flutter SHOULD expose a storage screen with concepts such as:

```text
Downloaded content
Automatic cache
Total CareerSpeak storage
Free space
Downloaded packs
Pinned packs
```

Possible actions:

```text
Remove pack
Pin / Unpin
Clear automatic cache
Free space
```

Clearing automatic cache SHALL NOT clear learning progress, favorites or test history.

---

## 24. Visual theme asset retention

Initial Study Ambience backgrounds MAY ship inside Flutter assets and therefore do not participate in cache eviction.

If remote/downloadable theme packs are introduced later, their files SHALL reuse the same local asset registry, checksum verification and quota/eviction infrastructure rather than creating a second cache subsystem.

---

## 25. Backend indexes

The ERD/index design SHALL consider consumer pagination and availability predicates.

Candidate composite indexes depend on actual query patterns, for example conceptually:

```text
(availability_status, publication_status, sort_order, id)
```

or domain-specific equivalents.

Indexes SHALL be validated with realistic `EXPLAIN (ANALYZE, BUFFERS)` queries once seed volume exists.

---

## 26. HTTP caching

Pagination/catalog APIs MAY use ETag/conditional requests where useful.

Immutable published assets SHOULD use long-lived cache semantics at the CDN layer because object keys change when content/checksum changes.

Manifest endpoints SHOULD use short/validated cache semantics suitable for rapid publication/deactivation propagation.

Server deactivation correctness SHALL NOT depend on clients waiting indefinitely for a long-lived manifest cache.

---

## 27. API examples

### Vocabulary

```text
GET /api/v1/vocabulary?limit=50&cursor=...
```

### Profession interviews

```text
GET /api/v1/interviews?profession=JAVA_BACKEND_DEVELOPER&seniority=SENIOR&limit=30&cursor=...
```

### Root manifest

```text
GET /api/v1/content/manifest
```

### Pack manifest

```text
GET /api/v1/content/packs/JAVA_SENIOR/manifest
```

Administrative page-number pagination remains separate from learner cursor pagination.

---

## 28. Observability

Backend SHOULD expose metrics such as:

```text
content.api.page.requests
content.api.page.size
content.manifest.requests
content.manifest.tombstones
content.active.count
content.inactive.count
```

Flutter SHOULD keep local diagnostic counters/logs sufficient to debug:

```text
cache bytes
asset count
evicted bytes
checksum failures
pack update failures
```

No server-side learner interest/profile collection is required for retention decisions.

---

## 29. Mandatory tests

Implementation qualification SHALL include at least:

1. keyset pagination returns every item once with stable ordering;
2. equal `sort_order` values do not lose/duplicate rows;
3. inactive content never appears in normal learner catalog results;
4. deactivation creates/propagates the expected tombstone;
5. reactivation/new revision is discoverable after manifest sync;
6. pack replacement does not delete old assets before new checksum verification;
7. expired auto-cache is evicted while progress remains;
8. pinned content survives normal cleanup;
9. explicit downloads survive normal LRU cleanup;
10. quota overflow removes least-recently-used eligible assets;
11. shared asset survives deletion of one referencing content item;
12. shared asset is removed after its final reference disappears;
13. cleanup interrupted mid-file deletion recovers on startup;
14. checksum failure does not activate corrupt content;
15. `Free space` does not erase favorites/progress/test history;
16. tombstoned content assets are removed even when their old TTL has not expired, unless retained by an explicit exceptional policy;
17. server/API pagination filters and cursor ordering use supporting indexes at representative data volume.

---

## 30. Acceptance criteria

This architecture is accepted when the following scenario works repeatedly:

```text
Backend publishes ACTIVE content v7
        ↓
Flutter discovers it through manifest/catalog
        ↓
content/assets are downloaded
        ↓
learner uses content; last_accessed_at advances
        ↓
backend publishes v8
        ↓
Flutter downloads + verifies v8
        ↓
local state switches atomically to v8
        ↓
unreferenced v7 assets are reclaimed
        ↓
learner progress remains intact
```

And:

```text
Backend deactivates content
        ↓
manifest publishes tombstone
        ↓
Flutter removes obsolete content/media
        ↓
independent progress/history remains local
```

And:

```text
auto-cache exceeds quota
        ↓
expired/LRU eligible assets are removed
        ↓
pinned/manual downloads remain protected
        ↓
application storage returns below configured threshold
```

---

## 31. Architecture rule

> CareerSpeak treats published content identity/history, current learner availability, and local device retention as three separate concerns. The backend controls what is currently available; manifests communicate changes and removals; Flutter controls how long re-downloadable assets remain on the device without deleting learner progress.
