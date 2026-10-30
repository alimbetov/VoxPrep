# CareerSpeak — P0.12.7 ContentSyncCoordinator State Machine

**Document version:** 0.1  
**Status:** Working design / P0.12.7  
**Applies to:** CareerSpeak v0.8+  
**Branch:** `feat/p0-domain-contracts`

---

## 1. Goal

`ContentSyncCoordinator` is the single application service responsible for moving CareerSpeak from one valid local content snapshot to another without breaking offline usage.

The coordinator SHALL guarantee:

```text
last-known-good snapshot remains usable
partial downloads never become active
unsupported schema never replaces compatible local data
crash during sync is recoverable
content/tombstones activate atomically
explicit offline packs remain atomically usable
sync does not download all media by default
```

---

## 2. Ownership boundaries

```text
ContentSyncCoordinator
├── ApiClient / ManifestRepository
├── PackRepository
├── Drift database
├── DownloadManager
├── AssetResolver metadata
├── StorageRetentionManager
└── InstallationSession
```

The coordinator does NOT:

```text
render UI
play audio
perform TTS
score tests
own learner progress
proxy raw HTTP into widgets
```

---

## 3. Fundamental invariants

### SYNC-INV-001 — One active coordinator run

Only one non-terminal sync run may mutate staging state at a time.

Multiple triggers are coalesced through `resync_requested` rather than starting parallel syncs.

### SYNC-INV-002 — Last-known-good remains active

A failed or interrupted sync SHALL NOT deactivate the currently active snapshot.

### SYNC-INV-003 — Network work outside DB transaction

No network download or long filesystem operation is performed while a Drift write transaction is held open.

### SYNC-INV-004 — Short atomic activation

Visibility switches only inside one short SQLite transaction after all required staging verification succeeds.

### SYNC-INV-005 — Tombstones are commit data

A tombstone is not destructively applied when first observed. It becomes visible only during the same activation commit as the target manifest version.

### SYNC-INV-006 — Binary policy depends on retention intent

Normal streaming/cache sync does not download every media file.

`EXPLICIT_DOWNLOAD` / `PINNED` pack updates require all `required_offline` assets before activation.

### SYNC-INV-007 — Content and learner state are independent

Tombstones/supersession may remove disposable content snapshots but SHALL NOT remove favorites, progress, review history or test attempts.

### SYNC-INV-008 — Repeated sync is idempotent

Re-running the same target manifest/version SHALL produce the same active result without duplicated content/assets.

---

## 4. Sync triggers

Accepted triggers:

```text
STARTUP
MANUAL
LOCALE_CHANGE
PACK_DOWNLOAD
PERIODIC_FRESHNESS
RECOVERY
```

Priority guidance:

```text
RECOVERY
MANUAL / PACK_DOWNLOAD
LOCALE_CHANGE
STARTUP
PERIODIC_FRESHNESS
```

Priority affects scheduling only; correctness is identical.

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

Terminal states:

```text
SUCCEEDED
DEFERRED_OFFLINE
BLOCKED_SCHEMA
FAILED_RETRYABLE
FAILED_FATAL
CANCELLED
```

A later trigger creates a new run rather than mutating an old terminal run back to active.

---

## 6. Global state machine

```text
                    ┌─────────┐
                    │ CREATED │
                    └────┬────┘
                         ▼
                 ┌───────────────┐
                 │ CHECKING_LOCAL│
                 └───────┬───────┘
                         ▼
                 ┌───────────────┐
                 │CHECKING_REMOTE│
                 └───┬─────┬─────┘
                     │     │
               offline│     │schema unsupported
                     │     │
                     ▼     ▼
             DEFERRED   BLOCKED_SCHEMA
             _OFFLINE
                     
                         │ remote valid
                         ▼
                    ┌────────┐
                    │PLANNING│
                    └───┬────┘
                        ▼
                    ┌───────┐
                    │STAGING│
                    └───┬───┘
                        ▼
                  ┌───────────┐
                  │ VERIFYING │
                  └─────┬─────┘
                        ▼
                  ┌───────────┐
                  │COMMITTING │
                  └─────┬─────┘
                        ▼
                  ┌───────────┐
                  │ CLEANING  │
                  └─────┬─────┘
                        ▼
                   ┌─────────┐
                   │SUCCEEDED│
                   └─────────┘
```

Errors from active stages route to `FAILED_RETRYABLE` or `FAILED_FATAL` according to classified cause.

---

## 7. Pack-update states

Each changed pack/variant is tracked independently inside the run.

```text
PLANNED
FETCHING_MANIFEST
STAGING_METADATA
WAITING_ASSETS
VERIFYING
READY_TO_COMMIT
COMMITTED

FAILED
SUPERSEDED
```

Pack state machine:

```text
PLANNED
  ↓
FETCHING_MANIFEST
  ↓
STAGING_METADATA
  ↓
retention requires offline assets?
 ├── no  ───────────────┐
 └── yes → WAITING_ASSETS
                    │
                    ▼
                VERIFYING
                    ↓
             READY_TO_COMMIT
                    ↓
                COMMITTED
```

`SUPERSEDED` means the remote target changed while the current staged pack was still being prepared. It is discarded without activation.

---

## 8. Startup recovery before normal sync

Every startup calls recovery before starting a fresh remote check.

Algorithm:

```text
load non-terminal sync_run
        ↓
none?
 ├── yes → normal startup sync
 └── no
      ↓
inspect state
```

Recovery rules:

### Run was before COMMITTING

```text
CREATED / CHECKING_* / PLANNING / STAGING / VERIFYING
→ preserve ACTIVE snapshot
→ inspect/remove unsafe temporary files
→ keep reusable VERIFIED files
→ mark old run FAILED_RETRYABLE or CANCELLED_BY_RECOVERY
→ start RECOVERY run when network is available
```

### Crash during COMMITTING

SQLite transaction semantics decide outcome:

```text
transaction committed
→ new active manifest/pack states are already consistent
→ continue CLEANING

transaction did not commit
→ SQLite rollback preserved old snapshot
→ retry staging/commit later
```

### Crash during CLEANING

```text
new snapshot is already ACTIVE
→ cleanup is repeatable/idempotent
→ resume cleanup
```

---

## 9. Phase A — acquire coordinator ownership

`ContentSyncCoordinator` serializes triggers.

Conceptual behavior:

```text
trigger arrives
 ↓
active run exists?
├── no  → create new sync_run
└── yes → set resync_requested = true
          return/observe current run
```

An in-memory mutex is acceptable for process-local serialization, but durable `sync_run` state remains the crash-recovery source of truth.

---

## 10. Phase B — CHECKING_LOCAL

Read:

```text
active content_manifest_state
active content_pack_revision rows
current translationLocale
explicit/pinned offline pack intents
unfinished download tasks
local schema/app build capabilities
```

Validate local invariants cheaply:

```text
active manifest exists → active packs must resolve
ACTIVE pack uniqueness
required DB schema tables available
no ACTIVE rows pointing only to failed STAGING state
```

Expensive full-file checksum scans are not required on every startup.

---

## 11. Phase C — CHECKING_REMOTE

Preconditions:

```text
network available
installation token available/usable
```

Fetch root manifest for the current translation locale.

Conceptual request:

```text
GET /api/v1/content/manifest?locale=kk
If-None-Match: <etag when available>
```

Expected minimum data:

```text
schemaVersion
contentVersion
manifest checksum/etag
pack revisions/checksums
locale variant metadata
tombstones
minimum compatible app/schema policy where introduced
```

If backend returns not modified and no local repair/download intent exists, run may finish `SUCCEEDED` as a no-op.

---

## 12. Offline behavior

If remote check cannot occur because the network is unavailable:

```text
valid local active snapshot exists
→ DEFERRED_OFFLINE
→ learner continues normally

no active snapshot exists
→ DEFERRED_OFFLINE
→ app may show bundled/onboarding shell only
```

Network absence is not logged as fatal application corruption.

---

## 13. Schema compatibility gate

Before planning any mutation:

```text
remote schemaVersion supported?
├── yes → continue
└── no  → BLOCKED_SCHEMA
```

`BLOCKED_SCHEMA` behavior:

```text
keep last compatible ACTIVE snapshot
show/update-app guidance when appropriate
never activate partially understood content
```

No destructive migration is attempted based only on a remote manifest.

---

## 14. Phase D — PLANNING

The coordinator calculates a deterministic plan from:

```text
active manifest state
remote root manifest
active pack revisions
requested translationLocale
explicit/pinned offline pack state
local verified asset checksums
```

Plan items:

```text
changed canonical packs
changed locale-delta packs
new assets/descriptors
required offline binaries
tombstones
superseded staged work
obsolete pack revisions
```

The plan is persisted before large downloads begin.

---

## 15. Locale-change planning

UI strings are bundled and are not downloaded by `ContentSyncCoordinator`.

Changing `translationLocale` may create locale-delta plan items while reusing canonical English/audio.

Example:

```text
current locale: ru
new locale: kk

canonical JAVA_SENIOR rev 8 already ACTIVE
English audio checksums already VERIFIED

plan:
→ fetch locale:kk variant
→ stage kk translation/hint/explanation rows
→ no duplicate English audio download
```

If offline and the new locale delta is unavailable:

```text
new translationLocale preference may remain selected
→ localized content falls back to English
→ previously cached other-locale data is not immediately destroyed
```

---

## 16. Phase E — fetch pack manifests

For each changed pack/variant:

```text
PLANNED
→ FETCHING_MANIFEST
```

Validate:

```text
pack code matches request
target revision/checksum matches root manifest
schema compatible
business-code uniqueness
asset descriptor shape valid
content revision references valid
```

A mismatching pack manifest is a sync failure and SHALL NOT be trusted.

---

## 17. Phase F — stage metadata

Write staging rows in a short Drift transaction:

```text
content_pack_revision(state=STAGING)
local_content_record(state=STAGED)
pack_content_ref
asset_catalog descriptors
content_asset_ref
pack_asset_ref
typed feature read-model staging rows
```

Important:

```text
ACTIVE repository queries exclude STAGED rows
```

Staging may be repeated with UPSERT semantics for the same immutable target revision.

---

## 18. Binary-download policy

This is deliberately separated from metadata synchronization.

### Normal streaming/cache pack

Activation does NOT require every audio/image to exist locally.

Required before activation:

```text
metadata/schema valid
asset descriptors valid
all mandatory non-binary references resolvable
```

Missing media may be streamed through CDN later and cached on demand.

### EXPLICIT_DOWNLOAD / PINNED pack

If the user asked for offline availability:

```text
all assets marked required_offline
→ DownloadManager
→ checksum verified
→ local_asset_file = VERIFIED
→ only then pack may become READY_TO_COMMIT
```

This prevents an "offline downloaded" pack from becoming active in a partially usable state.

---

## 19. DownloadManager interaction

Coordinator creates/observes `download_task` rows; DownloadManager owns transfer mechanics.

Coordinator SHALL NOT duplicate:

```text
byte-range resume
HTTP transfer progress
file temp naming
checksum calculation
retry backoff
atomic final-file rename
```

It waits for the required task results.

Downloaded file flow:

```text
remote bytes
→ temporary file
→ checksum/size verification
→ atomic move to content-addressed final path
→ local_asset_file VERIFIED
```

---

## 20. Phase G — VERIFYING

A pack update becomes `READY_TO_COMMIT` only if all activation requirements are met.

Verification baseline:

```text
pack manifest checksum valid
staged content count/identity valid
no duplicate stable business identity inside revision
all referenced asset descriptors exist
typed read-model validation passes
required locale rows valid according to pack policy
required_offline binaries verified when pack is explicit/pinned
```

Optional media for streaming packs may remain absent locally.

---

## 21. Global activation barrier

CareerSpeak v0.8 uses a conservative global activation barrier per target root manifest version.

Meaning:

```text
all changed plan items READY_TO_COMMIT
        ↓
one atomic Drift activation transaction
```

A failed unrelated pack therefore keeps the complete prior root snapshot active until the target root version is fully qualified.

This favors snapshot consistency over fastest partial publication propagation for MVP.

A later ADR may allow independent pack epochs if scale/content operations justify it.

---

## 22. Phase H — COMMITTING

No network or filesystem work occurs in this transaction.

Single Drift transaction performs:

```text
1. verify run still targets latest accepted manifest
2. mark new pack revisions ACTIVE
3. mark previous pack revisions SUPERSEDED
4. switch typed feature read models to active revisions
5. activate local_content_record rows
6. apply tombstones
7. release superseded pack/content asset references
8. update content_manifest_state active content version/checksum
9. mark sync_pack_update COMMITTED
10. mark sync_run ready for CLEANING
```

If any DB operation fails:

```text
ROLLBACK
→ prior snapshot remains completely active
```

---

## 23. Tombstone semantics

Tombstone processing inside commit:

```text
find disposable content snapshot by stable identity
→ mark TOMBSTONED / remove active feature read-model row
→ release its content/asset references
→ DO NOT delete durable learner state
```

Preserve:

```text
favorite
progress
review schedule
test history
recent-content metadata where product UX wants historical continuity
```

If content later returns with a new valid revision, durable state may resolve to it again by stable business code.

---

## 24. Phase I — CLEANING

After DB commit, cleanup is safe and repeatable.

Tasks:

```text
delete obsolete STAGING/SUPERSEDED rows when retention window permits
remove unreferenced local files selected by retention policy
remove abandoned temp files
compact old terminal sync/download rows by policy
update storage usage metadata
```

File deletion uses:

```text
VERIFIED
→ DELETE_PENDING
→ filesystem delete
→ delete local_asset_file row
```

A cleanup failure does not roll back the already-valid active snapshot.

---

## 25. Manifest version advancement

`active_content_version` advances only after the activation transaction commits.

`remote_content_version_seen` may advance earlier after a valid remote check.

This distinction prevents:

```text
"we saw version 120"
```

from being confused with:

```text
"version 120 is fully active locally"
```

---

## 26. Retry classification

### Retryable

Examples:

```text
OFFLINE
TIMEOUT
HTTP 5xx
CDN temporary failure
presigned/asset URL expired when refresh contract exists
transient filesystem busy
```

Result:

```text
FAILED_RETRYABLE
```

Use bounded exponential backoff.

### Fatal/blocking for this target

Examples:

```text
unsupported schema
manifest checksum mismatch after refetch
pack identity mismatch
invalid immutable revision contract
persistent local DB invariant violation
```

Result:

```text
BLOCKED_SCHEMA
or
FAILED_FATAL
```

The previous ACTIVE snapshot remains usable whenever possible.

---

## 27. Authentication failure

401/403 handling:

```text
401 installation token expired/revoked
→ delegate token refresh/re-registration contract
→ retry safe manifest request once after credential recovery

403 installation not allowed
→ do not loop
→ surface controlled application state
```

A credential failure SHALL NOT delete downloaded content.

---

## 28. Content changed during sync

If a newer root manifest appears while staging an older target:

```text
current run may finish only if its target remains acceptable
or
mark staged work SUPERSEDED and schedule resync
```

MVP conservative rule:

Before COMMITTING, perform a lightweight target-validity check when practical.

If root ETag/contentVersion changed:

```text
current staged target → SUPERSEDED
resync_requested = true
no activation
```

This prevents immediately activating a known-stale target.

---

## 29. Idempotency rules

Repeated execution is safe because:

```text
pack revisions are immutable and keyed by code+variant+revision
asset files are content-addressed by checksum
staging writes use deterministic keys/UPSERT
activation checks exact target revision
applying an already-applied tombstone is harmless
cleanup checks actual references before deletion
```

---

## 30. Concurrent triggers

Examples:

```text
startup sync running
+ user presses Refresh
+ locale changes
```

Do not start three coordinators.

Behavior:

```text
current run continues or is superseded according to target compatibility
resync_requested = true
on terminal state → immediately evaluate newest desired state
```

Locale change may invalidate the current locale-variant plan and should normally request supersession before commit if the target locale changed.

---

## 31. Interaction with app startup

Home rendering and sync are decoupled:

```text
open Drift
→ read ACTIVE local snapshot
→ render Home
→ start ContentSyncCoordinator
```

UI may show unobtrusive freshness/download state but SHALL NOT block valid cached content behind sync completion.

---

## 32. Interaction with AssetResolver

After activation:

```text
feature asks for asset_id
→ AssetResolver reads asset_catalog
→ checksum has VERIFIED local_asset_file?
   ├── yes → local path
   └── no  → CDN/edge URI from delivery metadata
```

Content synchronization therefore does not require binary prefetch for normal online use.

---

## 33. Suggested coordinator API

Conceptual Dart application contract:

```text
ContentSyncCoordinator

sync(trigger)
recoverInterruptedRun()
requestResync(trigger)
observeState()
```

Suggested state exposed to Riverpod/UI:

```text
idle
checking
updating(progress)
upToDate
waitingForNetwork
requiresAppUpdate
failedRecoverable
```

UI-facing state is intentionally simpler than the persisted internal state machine.

---

## 34. Failure simulations required

Qualification SHALL include at least:

1. app killed before root manifest fetch completes;
2. app killed after plan persistence;
3. app killed halfway through metadata staging;
4. app killed halfway through asset download;
5. app killed after asset verification but before commit;
6. app killed during SQLite commit;
7. app killed after commit but before cleanup;
8. network lost while fetching pack manifest;
9. CDN lost while downloading explicit offline assets;
10. checksum mismatch;
11. unsupported remote schema;
12. remote root version changes before commit;
13. tombstone arrives for favorited content;
14. tombstone arrives for content present in completed test history;
15. locale changes during sync;
16. token expires during sync;
17. disk fills during download;
18. cleanup filesystem delete fails;
19. two UI triggers arrive concurrently;
20. explicit offline pack revision changes while old revision remains usable.

---

## 35. Acceptance criteria for P0.12.7

The state machine is accepted when tests prove:

```text
SYNC-001 valid local content renders before network sync completes
SYNC-002 partial staging never becomes active
SYNC-003 crash before commit preserves old active snapshot
SYNC-004 crash after commit resumes cleanup without reverting content
SYNC-005 root active_content_version advances only after successful commit
SYNC-006 tombstones do not erase learner history
SYNC-007 streaming sync does not eagerly download all media
SYNC-008 explicit/pinned offline pack activates only with verified required assets
SYNC-009 locale delta reuses canonical English/audio
SYNC-010 unsupported schema keeps last compatible snapshot
SYNC-011 repeated same-version sync is idempotent
SYNC-012 concurrent triggers are serialized/coalesced
SYNC-013 checksum mismatch blocks activation
SYNC-014 stale remote target can be superseded before commit
SYNC-015 cleanup never deletes referenced shared assets
```

---

## 36. Resulting offline-first contract

```text
REMOTE
  ↓
CHECK
  ↓
PLAN
  ↓
STAGE
  ↓
VERIFY
  ↓
ATOMIC COMMIT
  ↓
CLEAN

while throughout:

LAST-KNOWN-GOOD ACTIVE SNAPSHOT
remains the learner-visible source until COMMIT succeeds.
```

This state machine is the central consistency mechanism for CareerSpeak mobile content synchronization.
