# CareerSpeak — P0.12.7 ContentSyncCoordinator State Machine

**Document version:** 1.0  
**Status:** Normative mobile synchronization baseline  
**Applies to:** CareerSpeak v0.9+

Related standards:

- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`CAREERSPEAK_DRIFT_ERD.md`](CAREERSPEAK_DRIFT_ERD.md)

---

## 1. Responsibility

`ContentSyncCoordinator` moves Flutter from one valid local metadata snapshot to another while preserving offline usability.

It owns:

```text
root manifest check
pack/locale-variant planning
metadata staging
metadata verification
atomic CURRENT switch
tombstone application
sync crash recovery
coordination with DownloadManager
post-commit cleanup scheduling
```

It does not own:

```text
raw byte transfer mechanics
audio playback
learner progress
TTS
UI rendering
```

---

## 2. Core invariants

```text
SYNC-001 one coordinator mutation run at a time
SYNC-002 last-known-good CURRENT snapshot survives failed sync
SYNC-003 network/filesystem work occurs outside Drift write transactions
SYNC-004 metadata visibility switches only in one short atomic transaction
SYNC-005 tombstones apply during that metadata commit
SYNC-006 repeated sync to same immutable target is idempotent
SYNC-007 learner state is never deleted by metadata replacement
SYNC-008 normal metadata sync does not require all media bytes
SYNC-009 explicit offline replacement does not destroy old READY bundle early
SYNC-010 backend ACTIVE, Flutter CURRENT and offline READY remain separate concepts
```

---

## 3. Root version model

Backend publishes one root:

```text
contentVersion
```

The root references exact pack variants:

```text
JAVA_SENIOR / canonical / rev 8
JAVA_SENIOR / locale:kk / rev 4
```

Flutter stores:

```text
remoteContentVersionSeen
currentContentVersion
```

`currentContentVersion` advances only after metadata activation commits.

---

## 4. Triggers

```text
STARTUP
MANUAL
LOCALE_CHANGE
PACK_DOWNLOAD
PERIODIC_FRESHNESS
RECOVERY
```

If a trigger arrives while a run is active:

```text
resync_requested = true
```

Do not run parallel metadata mutation coordinators.

---

## 5. Global run states

```text
CREATED
CHECKING_LOCAL
CHECKING_REMOTE
PLANNING
STAGING
VERIFYING
COMMITTING
CLEANING
SUCCEEDED

DEFERRED_OFFLINE
BLOCKED_SCHEMA
FAILED_RETRYABLE
FAILED_FATAL
CANCELLED
```

Terminal runs remain immutable history; a retry creates a new run.

---

## 6. State machine

```text
CREATED
   ↓
CHECKING_LOCAL
   ↓
CHECKING_REMOTE
   ├── no network ─────────► DEFERRED_OFFLINE
   ├── unsupported schema ─► BLOCKED_SCHEMA
   ↓
PLANNING
   ↓
STAGING
   ↓
VERIFYING
   ↓
COMMITTING
   ↓
CLEANING
   ↓
SUCCEEDED
```

Classified failures transition to:

```text
FAILED_RETRYABLE
FAILED_FATAL
```

The prior CURRENT snapshot remains available whenever possible.

---

## 7. Startup recovery

Before starting a fresh sync, inspect non-terminal `sync_run` state.

### Before COMMITTING

```text
preserve existing CURRENT snapshot
inspect/reuse safe verified files
clean unsafe temp files
close interrupted run as retryable/recovery-cancelled
start RECOVERY run when possible
```

### During COMMITTING

SQLite decides:

```text
transaction committed
→ new CURRENT snapshot is consistent

transaction rolled back
→ old CURRENT snapshot remains consistent
```

### During CLEANING

New metadata is already CURRENT. Cleanup is idempotent and resumes later.

---

## 8. CHECKING_LOCAL

Read/validate:

```text
content_manifest_state
CURRENT pack revisions
translationLocale
offline pack intents
unfinished downloads
local schema capabilities
```

Cheap invariants:

```text
at most one CURRENT revision per pack variant
CURRENT manifest references resolvable CURRENT pack rows
no learner query reads STAGING content
```

Do not checksum every local file on every startup.

---

## 9. CHECKING_REMOTE

Preconditions:

```text
network reachable
installation token usable
```

Request:

```text
GET /api/v1/content/manifest?locale=<translationLocale>
If-None-Match: <etag>
```

Root response must provide enough information to determine:

```text
schemaVersion
contentVersion
manifest checksum/etag
pack code
variant key
pack revision
pack checksum
tombstones
compatibility policy
```

`304 Not Modified` or equivalent may finish as no-op unless local repair/offline-download work remains.

---

## 10. Offline behavior

If remote check fails because device is offline:

```text
CURRENT local snapshot exists
→ DEFERRED_OFFLINE
→ learning continues

no CURRENT local snapshot
→ DEFERRED_OFFLINE
→ bundled/onboarding shell only
```

Offline is not data corruption.

---

## 11. Schema compatibility gate

Before staging:

```text
remote schema supported?
├── yes → continue
└── no  → BLOCKED_SCHEMA
```

`BLOCKED_SCHEMA` keeps the last compatible CURRENT snapshot and may show an application-update requirement.

---

## 12. PLANNING

Compute deterministic plan from:

```text
CURRENT root snapshot
remote root snapshot
CURRENT pack variants
translationLocale
offline pack intent
verified local asset hashes
```

Plan contains:

```text
changed canonical variants
changed locale variants
tombstones
new/changed asset descriptors
metadata to supersede
optional offline replacement tasks
```

Persist plan before large transfers.

---

## 13. Locale change

UI strings are bundled with Flutter and are not synced here.

When `translationLocale` changes:

```text
reuse CURRENT canonical English variant
fetch/stage required locale variant
reuse canonical English audio descriptors/files
```

If locale variant is unavailable offline, canonical English remains usable according to fallback policy.

---

## 14. Pack metadata states

Per planned pack variant:

```text
PLANNED
FETCHING_MANIFEST
STAGING_METADATA
VERIFYING
READY_TO_COMMIT
COMMITTED

FAILED
SUPERSEDED
```

Offline asset work is tracked separately in `offline_pack_state` / `download_task`.

A metadata pack does not stay blocked merely because optional streamable media is not locally present.

---

## 15. STAGING metadata

For each changed variant, write staged rows in short Drift transactions:

```text
content_pack_revision(STAGING)
local_content_record(STAGED)
pack_content_ref
asset_catalog descriptors
content_asset_ref
pack_asset_ref
typed feature read-model staging rows
```

Learner repositories exclude STAGING rows.

Staging uses idempotent UPSERT semantics for the same immutable target.

---

## 16. Metadata verification

A variant becomes `READY_TO_COMMIT` when:

```text
pack identity/revision/checksum matches root manifest
schema is supported
stable business identities are valid
all referenced asset descriptors exist
typed read-model validation passes
required locale payload policy passes
```

This verification does not require all optional media bytes to be downloaded.

---

## 17. Root metadata barrier

For MVP, all changed metadata variants referenced by target root `contentVersion` must become `READY_TO_COMMIT` before switching the local root snapshot.

```text
all changed metadata READY_TO_COMMIT
        ↓
one Drift activation transaction
```

This guarantees no half-old/half-new local metadata root snapshot.

It does not mean all audio/image files are local.

---

## 18. COMMITTING

No network or filesystem I/O inside the transaction.

Atomic transaction:

```text
1. verify target run/manifest is still accepted
2. new pack revisions VERIFIED/STAGING → CURRENT
3. previous CURRENT pack revisions → SUPERSEDED
4. switch typed feature read-model rows
5. local content rows → CURRENT
6. apply tombstones
7. switch pack/content asset references
8. update content_manifest_state.current_content_version/checksum
9. mark pack updates COMMITTED
10. move run to CLEANING
```

Any DB failure:

```text
ROLLBACK
→ prior CURRENT snapshot remains intact
```

---

## 19. Tombstones

Backend emits tombstones for content no longer deliverable, including deactivated content.

During metadata commit Flutter:

```text
retires CURRENT disposable content
removes it from learner query read models
releases disposable asset refs
preserves learner history
```

Preserved:

```text
favorite
progress
review schedule
test attempts/answers
```

Content absence from paginated API results is never treated as a tombstone.

---

## 20. Offline bundle update is independent

Backend `PUBLISHED + ACTIVE` means content/assets are available for delivery/download.

Metadata may become CURRENT before a newly requested offline bundle is READY.

Supported transition:

```text
metadata rev 8 = CURRENT
ready_revision = 7
offline_state = UPDATING
updating_revision = 8
```

DownloadManager fetches all `required_offline` assets for rev 8.

Only after verification:

```text
ready_revision = 8
offline_state = READY
```

Then rev 7-only physical assets may be released if no other references protect them.

This guarantees continuous offline usability during bundle replacement.

---

## 21. DownloadManager boundary

DownloadManager owns:

```text
HTTP bytes
range/resume where supported
progress
temp-file naming
retry/backoff
checksum/size verification
atomic final-file move
```

Coordinator owns intent and observes task completion.

File flow:

```text
remote bytes
→ temp file
→ verify checksum/size
→ atomic move to content-addressed location
→ local_asset_file VERIFIED
```

---

## 22. CLEANING

After metadata commit:

```text
remove obsolete staged/superseded metadata by policy
release unreferenced disposable files
remove abandoned temp files
compact terminal sync/download journal rows
```

Cleanup failure never rolls back already valid CURRENT metadata.

Physical delete:

```text
VERIFIED
→ DELETE_PENDING
→ filesystem delete
→ remove local_asset_file row
```

---

## 23. Retry classification

Retryable:

```text
OFFLINE
TIMEOUT
HTTP 5xx
CDN temporary failure
expired temporary URL when refresh is supported
transient filesystem busy
```

Fatal/blocking target:

```text
unsupported schema
persistent manifest checksum mismatch
pack identity mismatch
invalid immutable revision contract
persistent local invariant violation
```

Use bounded exponential backoff.

---

## 24. Authentication recovery

For `401` learner API response:

```text
mark token refresh/re-registration required
invoke installation credential recovery contract
retry safe read only after credential recovery
```

Do not destroy CURRENT local learning data because authentication temporarily fails.

---

## 25. Superseded remote target

If Backend publishes a newer root version while current target is still staging:

```text
current target may finish only if still accepted by consistency policy
otherwise mark staged work SUPERSEDED
set resync_requested
plan newest root
```

Never claim an unseen/staged version as `currentContentVersion`.

---

## 26. Error exposure

Coordinator exposes typed application state, not transport exceptions.

Examples:

```text
OFFLINE
SYNC_FAILED
SCHEMA_UNSUPPORTED
AUTH_REQUIRED
CHECKSUM_FAILED
LOCAL_DATA_CORRUPT
```

Raw HTTP/SQLite stack details remain logs/diagnostics.

---

## 27. Observability

Keep local operational diagnostics such as:

```text
runId
trigger
from/target contentVersion
state
started/finished time
pack counts
error code
retryability
```

Do not attach learner progress/profile data to backend installation identity for telemetry.

---

## 28. Acceptance matrix

Must prove:

```text
same-version no-op
metadata N→N+1 atomic switch
network loss before staging
network loss during pack fetch
crash before commit
crash during commit
crash after commit before cleanup
unsupported schema
locale change reusing canonical audio
content deactivation/tombstone
progress survives tombstone
CURRENT rev 8 while offline rev 7 remains READY
successful offline rev 8 replacement
failed offline rev 8 replacement preserving rev 7
concurrent sync triggers coalesce
401 credential recovery
newer remote target appears during staging
```

---

## 29. Final state distinction

```text
Backend ACTIVE
    = content is deliverable/downloadable

Flutter CURRENT
    = metadata revision currently used

Flutter READY
    = complete offline bundle locally verified
```

This distinction is mandatory across all CareerSpeak specifications.
