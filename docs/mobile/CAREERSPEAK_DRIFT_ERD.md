# CareerSpeak — P0.12.4 Drift ERD

**Document version:** 1.0  
**Status:** Normative mobile persistence baseline  
**Applies to:** CareerSpeak v0.9+

Related standards:

- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md`](CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md)
- [`CAREERSPEAK_ADAPTIVE_UI.md`](CAREERSPEAK_ADAPTIVE_UI.md)

---

## 1. Persistence zones

```text
SYSTEM
├── app_preferences
└── installation_runtime_state

SYNC
├── content_manifest_state
├── sync_run
├── sync_pack_update
└── sync_tombstone

CONTENT / CACHE
├── content_pack_revision
├── local_content_record
├── pack_content_ref
├── asset_catalog
├── local_asset_file
├── content_asset_ref
├── pack_asset_ref
├── content_cache_entry
├── offline_pack_state
└── download_task

LEARNER
├── favorite
├── recent_content
├── vocabulary_progress
├── topic_progress
├── review_schedule
├── test_attempt
├── test_attempt_question
└── test_answer
```

Rules:

1. re-downloadable content/cache is separate from learner state;
2. cache eviction never deletes progress/favorites/test history;
3. published content identity uses stable business code + revision;
4. all persisted instants use UTC semantics;
5. installation token is never stored in Drift.

---

## 2. System tables

### `app_preferences`

```text
id                    INTEGER PK CHECK(id = 1)
ui_locale             TEXT NOT NULL
translation_locale    TEXT NOT NULL
preferred_accent      TEXT NULL
theme_code            TEXT NOT NULL
focus_mode            INTEGER NOT NULL DEFAULT 0
storage_quota_bytes   INTEGER NULL
created_at            DATETIME NOT NULL
updated_at            DATETIME NOT NULL
```

### `installation_runtime_state`

Operational state only:

```text
id                       INTEGER PK CHECK(id = 1)
registration_state       TEXT NOT NULL
last_registration_at     DATETIME NULL
last_token_refresh_at    DATETIME NULL
last_success_at          DATETIME NULL
last_error_code          TEXT NULL
updated_at               DATETIME NOT NULL
```

Allowed states:

```text
UNREGISTERED
REGISTERING
REGISTERED
TOKEN_REFRESH_REQUIRED
REGISTRATION_FAILED
```

Source of truth for `installationId + installationToken` is platform Secure Storage.

---

## 3. Root manifest state

CareerSpeak has one backend root learner snapshot epoch:

```text
contentVersion
```

Locale data is represented by pack variants inside that root snapshot; it does not create an independent root epoch.

### `content_manifest_state`

Singleton row:

```text
id                         INTEGER PK CHECK(id = 1)
schema_version             INTEGER NOT NULL
current_content_version    INTEGER NOT NULL
current_manifest_checksum  TEXT NOT NULL
remote_content_version_seen INTEGER NULL
remote_manifest_checksum   TEXT NULL
etag                       TEXT NULL
last_checked_at            DATETIME NULL
last_successful_sync_at    DATETIME NULL
updated_at                 DATETIME NOT NULL
```

Important distinction:

```text
remote_content_version_seen
!=
current_content_version
```

The latter advances only after atomic metadata activation succeeds.

---

## 4. Durable sync journal

### `sync_run`

```text
run_id                 TEXT PK
trigger                 TEXT NOT NULL
translation_locale     TEXT NOT NULL
from_content_version   INTEGER NULL
target_content_version INTEGER NULL
target_schema_version  INTEGER NULL
state                   TEXT NOT NULL
resync_requested        INTEGER NOT NULL DEFAULT 0
attempt_count           INTEGER NOT NULL DEFAULT 0
retryable               INTEGER NOT NULL DEFAULT 0
error_code              TEXT NULL
error_message           TEXT NULL
started_at              DATETIME NOT NULL
updated_at              DATETIME NOT NULL
finished_at             DATETIME NULL
```

Triggers:

```text
STARTUP
MANUAL
LOCALE_CHANGE
PACK_DOWNLOAD
PERIODIC_FRESHNESS
RECOVERY
```

### `sync_pack_update`

```text
run_id               TEXT NOT NULL
pack_code            TEXT NOT NULL
variant_key          TEXT NOT NULL
target_revision      INTEGER NOT NULL
target_checksum      TEXT NOT NULL
state                 TEXT NOT NULL
required_asset_count INTEGER NOT NULL DEFAULT 0
verified_asset_count INTEGER NOT NULL DEFAULT 0
error_code            TEXT NULL
updated_at            DATETIME NOT NULL

PK (run_id, pack_code, variant_key)
FK run_id -> sync_run(run_id)
```

Variant examples:

```text
canonical
locale:ru
locale:kk
```

### `sync_tombstone`

```text
run_id          TEXT NOT NULL
content_code    TEXT NOT NULL
content_type    TEXT NOT NULL
revision        INTEGER NULL
reason          TEXT NOT NULL
state           TEXT NOT NULL
applied_at      DATETIME NULL

PK (run_id, content_code, content_type)
```

Tombstones never delete durable learner state.

---

## 5. Pack revisions

### `content_pack_revision`

```text
pack_code          TEXT NOT NULL
variant_key        TEXT NOT NULL
revision           INTEGER NOT NULL
schema_version     INTEGER NOT NULL
checksum           TEXT NOT NULL
state              TEXT NOT NULL
source_content_ver INTEGER NOT NULL
staged_at          DATETIME NOT NULL
verified_at        DATETIME NULL
current_at         DATETIME NULL
superseded_at      DATETIME NULL

PK (pack_code, variant_key, revision)
```

Standard local metadata states:

```text
STAGING
VERIFIED
CURRENT
SUPERSEDED
FAILED
```

Invariant:

```text
at most one CURRENT revision per (pack_code, variant_key)
```

`ACTIVE` is forbidden as a Flutter local revision state; Backend reserves `ACTIVE` for learner-delivery availability.

---

## 6. Generic content envelope

### `local_content_record`

```text
content_code       TEXT NOT NULL
content_type       TEXT NOT NULL
revision           INTEGER NOT NULL
checksum           TEXT NOT NULL
sort_order         INTEGER NULL
published_at       DATETIME NULL
snapshot_state     TEXT NOT NULL
source_schema_ver  INTEGER NOT NULL
created_at         DATETIME NOT NULL

PK (content_code, content_type, revision)
```

States:

```text
STAGED
CURRENT
SUPERSEDED
TOMBSTONED
```

This is a synchronization envelope, not the only learner query model.

Searchable content uses typed Drift read models, e.g.:

```text
vocabulary_item_read
interview_question_read
topic_read
topic_section_read
phrase_read
practice_test_read
question_read
```

Typed read models share stable `(businessCode, revision)` identity and are switched in the same metadata activation transaction.

---

## 7. Pack/content membership

### `pack_content_ref`

```text
pack_code          TEXT NOT NULL
variant_key        TEXT NOT NULL
pack_revision      INTEGER NOT NULL
content_code       TEXT NOT NULL
content_type       TEXT NOT NULL
content_revision   INTEGER NOT NULL

PK (
  pack_code,
  variant_key,
  pack_revision,
  content_code,
  content_type,
  content_revision
)
```

This table makes pack replacement deterministic and avoids destructive inference from missing paginated API results.

---

## 8. Asset model

### `asset_catalog`

Logical immutable descriptor:

```text
asset_id          TEXT PK
checksum_sha256   TEXT NOT NULL
asset_kind        TEXT NOT NULL
mime_type         TEXT NOT NULL
size_bytes        INTEGER NOT NULL
duration_ms       INTEGER NULL
delivery_key      TEXT NOT NULL
created_at        DATETIME NOT NULL
```

`delivery_key` is relative/stable and never stores a permanent CDN hostname.

### `local_asset_file`

Physical verified cache:

```text
checksum_sha256   TEXT PK
relative_path     TEXT NOT NULL UNIQUE
size_bytes        INTEGER NOT NULL
state             TEXT NOT NULL
verified_at       DATETIME NULL
last_accessed_at  DATETIME NULL
created_at        DATETIME NOT NULL
```

States:

```text
DOWNLOADING
VERIFIED
CORRUPT
DELETE_PENDING
```

Physical cache is checksum-addressed so identical bytes may be reused.

### `content_asset_ref`

```text
content_code       TEXT NOT NULL
content_type       TEXT NOT NULL
content_revision   INTEGER NOT NULL
asset_id           TEXT NOT NULL
asset_role         TEXT NOT NULL
required_offline   INTEGER NOT NULL DEFAULT 0

PK (content_code, content_type, content_revision, asset_id, asset_role)
```

### `pack_asset_ref`

```text
pack_code        TEXT NOT NULL
variant_key      TEXT NOT NULL
pack_revision    INTEGER NOT NULL
asset_id         TEXT NOT NULL
required_offline INTEGER NOT NULL DEFAULT 0

PK (pack_code, variant_key, pack_revision, asset_id)
```

A physical file may be deleted only when no retained/current/offline-ready reference requires it.

---

## 9. Cache retention

### `content_cache_entry`

```text
content_code       TEXT NOT NULL
content_type       TEXT NOT NULL
content_revision   INTEGER NOT NULL
pack_code          TEXT NULL
retention_class    TEXT NOT NULL
downloaded_at      DATETIME NULL
last_accessed_at   DATETIME NULL
expires_at         DATETIME NULL
estimated_bytes    INTEGER NOT NULL DEFAULT 0

PK (content_code, content_type, content_revision)
```

Retention classes:

```text
AUTO_CACHE
EXPLICIT_DOWNLOAD
PINNED
```

Favorites are not automatically pins.

---

## 10. Offline bundle state

Offline readiness is independent from metadata `CURRENT`.

### `offline_pack_state`

```text
pack_code           TEXT NOT NULL
variant_key         TEXT NOT NULL
desired_mode        TEXT NOT NULL
offline_state       TEXT NOT NULL
ready_revision      INTEGER NULL
updating_revision   INTEGER NULL
bytes_total         INTEGER NOT NULL DEFAULT 0
bytes_present       INTEGER NOT NULL DEFAULT 0
requested_at        DATETIME NULL
updated_at          DATETIME NOT NULL
last_error_code     TEXT NULL

PK (pack_code, variant_key)
```

`desired_mode`:

```text
NONE
EXPLICIT_DOWNLOAD
PINNED
```

`offline_state`:

```text
NOT_DOWNLOADED
QUEUED
DOWNLOADING
VERIFYING
READY
UPDATING
FAILED
```

Important supported state:

```text
metadata revision 8 = CURRENT
offline ready_revision = 7
offline updating_revision = 8
offline_state = UPDATING
```

Revision 7 remains usable offline until revision 8 reaches READY.

---

## 11. Download tasks

### `download_task`

```text
task_id             TEXT PK
task_type           TEXT NOT NULL
sync_run_id         TEXT NULL
pack_code           TEXT NULL
variant_key         TEXT NULL
asset_id            TEXT NULL
checksum_sha256     TEXT NULL
state               TEXT NOT NULL
bytes_total         INTEGER NOT NULL DEFAULT 0
bytes_downloaded    INTEGER NOT NULL DEFAULT 0
temp_relative_path  TEXT NULL
attempt_count       INTEGER NOT NULL DEFAULT 0
next_retry_at       DATETIME NULL
error_code          TEXT NULL
created_at          DATETIME NOT NULL
updated_at          DATETIME NOT NULL
```

States:

```text
QUEUED
DOWNLOADING
PAUSED
VERIFYING
READY
FAILED
CANCELLED
```

A download is `READY` only after integrity verification and atomic final-file placement.

---

## 12. Durable learner state

Learner state uses stable content business identity and intentionally avoids destructive FK cascades into disposable content tables.

### `favorite`

```text
content_code   TEXT NOT NULL
content_type   TEXT NOT NULL
created_at     DATETIME NOT NULL
PK (content_code, content_type)
```

### `recent_content`

```text
content_code      TEXT NOT NULL
content_type      TEXT NOT NULL
last_opened_at    DATETIME NOT NULL
last_revision_seen INTEGER NULL
PK (content_code, content_type)
```

### `vocabulary_progress`

```text
content_code       TEXT PK
status             TEXT NOT NULL
correct_count      INTEGER NOT NULL DEFAULT 0
incorrect_count    INTEGER NOT NULL DEFAULT 0
last_reviewed_at   DATETIME NULL
updated_at         DATETIME NOT NULL
```

### `topic_progress`

```text
content_code       TEXT PK
completed          INTEGER NOT NULL DEFAULT 0
last_section_code  TEXT NULL
last_position_ms   INTEGER NULL
updated_at         DATETIME NOT NULL
```

### `review_schedule`

```text
content_code       TEXT NOT NULL
content_type       TEXT NOT NULL
review_state       TEXT NOT NULL
next_review_at     DATETIME NULL
last_result        TEXT NULL
updated_at         DATETIME NOT NULL
PK (content_code, content_type)
```

### `test_attempt`

```text
attempt_id          TEXT PK
test_code           TEXT NOT NULL
test_revision       INTEGER NOT NULL
mode                TEXT NOT NULL
state               TEXT NOT NULL
current_position    INTEGER NOT NULL DEFAULT 0
score               REAL NULL
started_at          DATETIME NOT NULL
completed_at        DATETIME NULL
updated_at          DATETIME NOT NULL
```

### `test_attempt_question`

Immutable attempt snapshot:

```text
attempt_id          TEXT NOT NULL
position            INTEGER NOT NULL
question_code       TEXT NOT NULL
question_revision   INTEGER NOT NULL
snapshot_json       TEXT NOT NULL
PK (attempt_id, position)
```

### `test_answer`

```text
attempt_id          TEXT NOT NULL
position            INTEGER NOT NULL
answer_json         TEXT NOT NULL
is_correct          INTEGER NULL
answered_at         DATETIME NOT NULL
PK (attempt_id, position)
```

Completed/in-progress attempts remain reviewable even if the source pack is later evicted.

---

## 13. Required indexes

At minimum qualify indexes for:

```text
content_pack_revision(pack_code, variant_key, state)
local_content_record(content_type, snapshot_state, sort_order)
content_asset_ref(asset_id)
pack_asset_ref(asset_id)
content_cache_entry(retention_class, expires_at, last_accessed_at)
download_task(state, next_retry_at)
sync_run(state, started_at)
review_schedule(next_review_at)
recent_content(last_opened_at)
```

Use a partial unique index for one `CURRENT` pack revision per `(pack_code, variant_key)` when supported by the Drift migration baseline; otherwise enforce transactionally and test it.

---

## 14. Transaction boundaries

Network/filesystem work never runs inside a Drift transaction.

Short activation transaction may change:

```text
pack STAGING/VERIFIED → CURRENT
old CURRENT → SUPERSEDED
local content STAGED → CURRENT
typed feature read models
pack/content refs
tombstones
content_manifest_state.current_content_version
```

Offline `READY` replacement occurs only after required files are independently verified.

---

## 15. Migration rules

1. every Drift schema change increments local schema version;
2. migrations are explicit and tested from supported previous versions;
3. learner-state tables receive priority preservation;
4. cache tables may be rebuilt only when safe and documented;
5. production recovery must not require deleting the whole app database;
6. migration failure must not silently erase learner progress.

---

## 16. Invariants

```text
DRIFT-001 token is not stored in Drift
DRIFT-002 one root current_content_version
DRIFT-003 locale variants are pack variants, not root epochs
DRIFT-004 one CURRENT revision per pack variant
DRIFT-005 learner state survives cache eviction/tombstones
DRIFT-006 CURRENT metadata does not imply offline READY
DRIFT-007 old offline READY may coexist with newer CURRENT metadata
DRIFT-008 physical file deletion is reference-safe
DRIFT-009 staged rows are invisible to learner repositories
DRIFT-010 test attempt snapshots survive source-content eviction
```

---

## 17. Acceptance scenarios

Must prove:

```text
fresh install
metadata N→N+1 atomic switch
locale variant update without duplicate English audio
explicit offline download
CURRENT rev 8 + offline READY rev 7 while rev 8 updates
crash during staging
crash after metadata commit before cleanup
checksum mismatch
shared asset reference safety
tombstone with favorite/progress preservation
in-progress test restoration
Drift migration with learner-state preservation
```

This is the authoritative local persistence baseline for CareerSpeak v0.9.
