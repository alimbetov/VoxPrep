# CareerSpeak — P0.12.4 Drift ERD

**Document version:** 0.1  
**Status:** Working design / P0.12.4  
**Applies to:** CareerSpeak v0.8+  
**Branch:** `feat/p0-domain-contracts`

---

## 1. Goal

This document defines the local SQLite/Drift persistence model that forms the foundation of the CareerSpeak offline-first Flutter application.

The local database has three responsibilities:

```text
SYSTEM / SYNC STATE
    ↓
CONTENT SNAPSHOTS / PACKS / ASSETS
    ↓
DURABLE LEARNER STATE
```

The design SHALL keep re-downloadable content independent from durable learner progress.

---

## 2. Core decisions

1. Server numeric database IDs are not the mobile domain identity. Flutter uses stable business codes/revisions from API contracts.
2. `installationId` and the installation token are stored in platform Secure Storage. The token is NEVER stored in Drift.
3. Drift stores only non-secret installation runtime metadata.
4. Content synchronization metadata is generic, but searchable learner content SHALL use typed feature read-model tables. A single giant JSON content table is not the primary learner query model.
5. Published content revisions are immutable. Local rows are versioned by stable code + revision.
6. Staged content never becomes visible until the sync commit transaction succeeds.
7. Learner state tables intentionally do not cascade-delete when cached content is evicted.
8. Physical media files are content-addressed by checksum and may be shared by multiple logical assets/content items.
9. All persisted instants use UTC semantics. Local timezone is applied only for presentation/scheduling UX.
10. Destructive `delete-and-recreate database` migration is not an accepted production migration strategy.

---

## 3. Data zones

```text
┌─────────────────────────────────────────────────────────────┐
│ SYSTEM                                                      │
│ app_preferences                                             │
│ installation_runtime_state                                  │
├─────────────────────────────────────────────────────────────┤
│ SYNC                                                        │
│ content_manifest_state                                      │
│ sync_run                                                    │
│ sync_pack_update                                            │
│ sync_tombstone                                              │
├─────────────────────────────────────────────────────────────┤
│ CONTENT                                                     │
│ content_pack_revision                                       │
│ local_content_record                                        │
│ pack_content_ref                                            │
│ asset_catalog                                               │
│ local_asset_file                                            │
│ content_asset_ref                                           │
│ pack_asset_ref                                              │
│ content_cache_entry                                         │
│ offline_pack_state                                          │
│ download_task                                               │
│ + typed feature read models                                 │
├─────────────────────────────────────────────────────────────┤
│ LEARNER                                                     │
│ favorite                                                    │
│ recent_content                                              │
│ vocabulary_progress                                         │
│ topic_progress                                              │
│ review_schedule                                             │
│ test_attempt                                                │
│ test_attempt_question                                       │
│ test_answer                                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Relationship overview

```text
content_manifest_state
        │
        │ target content version
        ▼
     sync_run
        │
        ├───────────────┐
        ▼               ▼
sync_pack_update   sync_tombstone
        │
        ▼
content_pack_revision
        │
   ┌────┴──────────────┐
   ▼                   ▼
pack_content_ref   pack_asset_ref
   │                   │
   ▼                   ▼
local_content_record  asset_catalog
   │                   │
   └──── content_asset_ref ──┘
                           │
                           ▼
                    local_asset_file

local_content_record is disposable/versioned metadata.

favorite / progress / review / test history reference stable business codes
and DO NOT depend on the continued existence of cached content rows.
```

---

# 5. System tables

## 5.1 `app_preferences`

Singleton row.

```text
app_preferences
────────────────────────────────────
id                    INTEGER PK CHECK(id = 1)
ui_locale             TEXT NOT NULL
translation_locale    TEXT NOT NULL
preferred_accent      TEXT NULL
theme_code            TEXT NOT NULL
focus_mode             INTEGER NOT NULL DEFAULT 0
storage_quota_bytes   INTEGER NULL
created_at             DATETIME NOT NULL
updated_at             DATETIME NOT NULL
```

Rules:

```text
ui_locale          = compile-time supported Flutter UI locale
translation_locale = content translation locale
learning language  = always English and is not persisted as a selectable value
```

`storage_quota_bytes = NULL` means use application default policy.

---

## 5.2 `installation_runtime_state`

Singleton operational metadata only.

```text
installation_runtime_state
────────────────────────────────────
id                       INTEGER PK CHECK(id = 1)
registration_state       TEXT NOT NULL
last_registration_at     DATETIME NULL
last_token_refresh_at    DATETIME NULL
last_success_at          DATETIME NULL
last_error_code          TEXT NULL
updated_at               DATETIME NOT NULL
```

Allowed `registration_state`:

```text
UNREGISTERED
REGISTERING
REGISTERED
TOKEN_REFRESH_REQUIRED
REGISTRATION_FAILED
```

The following SHALL NOT be persisted here:

```text
installation token
worker/admin credentials
RustFS credentials
```

Source of truth for `installationId + installation token` is platform Secure Storage.

---

# 6. Manifest and sync tables

## 6.1 `content_manifest_state`

Stores the last committed root-manifest state per manifest scope.

A scope allows canonical content and locale-specific delta state to evolve independently.

```text
content_manifest_state
──────────────────────────────────────────
scope_key                    TEXT PK
schema_version               INTEGER NOT NULL
active_content_version       INTEGER NOT NULL
active_manifest_checksum     TEXT NOT NULL
remote_content_version_seen  INTEGER NULL
remote_manifest_checksum     TEXT NULL
etag                         TEXT NULL
last_checked_at              DATETIME NULL
last_successful_sync_at      DATETIME NULL
updated_at                   DATETIME NOT NULL
```

Initial scope examples:

```text
canonical
locale:ru
locale:kk
```

This model allows a locale delta to change without duplicating canonical English/audio state.

---

## 6.2 `sync_run`

Durable coordinator state for crash recovery.

```text
sync_run
──────────────────────────────────────────
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

Only one non-terminal `sync_run` may be owned by `ContentSyncCoordinator` at a time.

---

## 6.3 `sync_pack_update`

One row for each pack/variant change in a sync plan.

```text
sync_pack_update
──────────────────────────────────────────
run_id                  TEXT NOT NULL
pack_code               TEXT NOT NULL
variant_key             TEXT NOT NULL
target_revision         INTEGER NOT NULL
target_checksum         TEXT NOT NULL
state                    TEXT NOT NULL
required_asset_count    INTEGER NOT NULL DEFAULT 0
verified_asset_count    INTEGER NOT NULL DEFAULT 0
error_code               TEXT NULL
updated_at               DATETIME NOT NULL

PK (run_id, pack_code, variant_key)
FK run_id -> sync_run(run_id)
```

Variant examples:

```text
canonical
locale:ru
locale:kk
```

---

## 6.4 `sync_tombstone`

Persists planned removals so a crash cannot lose the sync plan.

```text
sync_tombstone
──────────────────────────────────────────
run_id          TEXT NOT NULL
content_code    TEXT NOT NULL
content_type    TEXT NOT NULL
revision        INTEGER NULL
reason          TEXT NOT NULL
state           TEXT NOT NULL
applied_at      DATETIME NULL

PK (run_id, content_code, content_type)
FK run_id -> sync_run(run_id)
```

States:

```text
PLANNED
APPLIED
IGNORED_ALREADY_ABSENT
```

Tombstones affect disposable synced content, not learner history.

---

# 7. Pack and content snapshot tables

## 7.1 `content_pack_revision`

Stores concurrently staged and active pack revisions.

```text
content_pack_revision
──────────────────────────────────────────
pack_code          TEXT NOT NULL
variant_key        TEXT NOT NULL
revision           INTEGER NOT NULL
schema_version     INTEGER NOT NULL
checksum           TEXT NOT NULL
state              TEXT NOT NULL
source_content_ver INTEGER NOT NULL
staged_at          DATETIME NOT NULL
verified_at        DATETIME NULL
activated_at       DATETIME NULL
superseded_at      DATETIME NULL

PK (pack_code, variant_key, revision)
```

States:

```text
STAGING
VERIFIED
ACTIVE
FAILED
SUPERSEDED
```

Invariant:

```text
at most one ACTIVE revision per (pack_code, variant_key)
```

Use a SQLite partial unique index where supported by the Drift migration strategy, otherwise enforce transactionally and verify with tests.

---

## 7.2 `local_content_record`

Generic sync envelope, not the primary feature payload store.

```text
local_content_record
──────────────────────────────────────────
content_code        TEXT NOT NULL
content_type        TEXT NOT NULL
revision            INTEGER NOT NULL
checksum            TEXT NOT NULL
sort_order          INTEGER NULL
published_at        DATETIME NULL
snapshot_state      TEXT NOT NULL
source_schema_ver   INTEGER NOT NULL
created_at          DATETIME NOT NULL

PK (content_code, content_type, revision)
```

States:

```text
STAGED
ACTIVE
SUPERSEDED
TOMBSTONED
```

The actual searchable/display fields belong in typed feature read models, for example later:

```text
vocabulary_item_read
interview_question_read
topic_read
topic_section_read
phrase_read
practice_test_read
question_read
```

These feature tables SHALL share the same `(business code, revision)` identity and participate in the same activation transaction.

Do not make `payload_json` the only query source for all learning features.

---

## 7.3 `pack_content_ref`

```text
pack_content_ref
──────────────────────────────────────────
pack_code       TEXT NOT NULL
variant_key     TEXT NOT NULL
pack_revision   INTEGER NOT NULL
content_code    TEXT NOT NULL
content_type    TEXT NOT NULL
content_revision INTEGER NOT NULL

PK (
  pack_code,
  variant_key,
  pack_revision,
  content_code,
  content_type,
  content_revision
)
```

Purpose:

- determine which content belongs to a staged/active pack revision;
- release old references after supersession;
- avoid destructive guesses based only on missing API pages.

---

# 8. Asset model

## 8.1 `asset_catalog`

Logical immutable asset descriptor received from manifests.

```text
asset_catalog
──────────────────────────────────────────
asset_id          TEXT PK
checksum_sha256   TEXT NOT NULL
asset_kind        TEXT NOT NULL
mime_type         TEXT NOT NULL
size_bytes        INTEGER NOT NULL
duration_ms       INTEGER NULL
delivery_key      TEXT NOT NULL
created_at        DATETIME NOT NULL
```

`delivery_key` is a stable relative delivery/object key, not a permanent CDN hostname.

Asset kinds may include:

```text
AUDIO
IMAGE
THEME_ASSET
OTHER
```

---

## 8.2 `local_asset_file`

Physical verified file cache keyed by content hash.

```text
local_asset_file
──────────────────────────────────────────
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

Because the physical file is keyed by checksum, two logical `asset_id` values with identical bytes may reuse the same local file.

---

## 8.3 `content_asset_ref`

```text
content_asset_ref
──────────────────────────────────────────
content_code       TEXT NOT NULL
content_type       TEXT NOT NULL
content_revision   INTEGER NOT NULL
asset_id           TEXT NOT NULL
asset_role         TEXT NOT NULL
required_offline   INTEGER NOT NULL DEFAULT 0

PK (content_code, content_type, content_revision, asset_id, asset_role)
FK asset_id -> asset_catalog(asset_id)
```

Example roles:

```text
QUESTION_AUDIO
ANSWER_AUDIO
WORD_AUDIO
EXAMPLE_AUDIO
TOPIC_AUDIO
COVER_IMAGE
```

---

## 8.4 `pack_asset_ref`

For pack-level assets not naturally owned by one content item.

```text
pack_asset_ref
──────────────────────────────────────────
pack_code        TEXT NOT NULL
variant_key      TEXT NOT NULL
pack_revision    INTEGER NOT NULL
asset_id         TEXT NOT NULL
required_offline INTEGER NOT NULL DEFAULT 0

PK (pack_code, variant_key, pack_revision, asset_id)
FK asset_id -> asset_catalog(asset_id)
```

---

# 9. Retention and offline-download state

## 9.1 `content_cache_entry`

```text
content_cache_entry
──────────────────────────────────────────
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

Favorites are not automatically `PINNED`.

---

## 9.2 `offline_pack_state`

Persists user intent separately from the currently active content revision.

```text
offline_pack_state
──────────────────────────────────────────
pack_code           TEXT NOT NULL
variant_key         TEXT NOT NULL
desired_mode        TEXT NOT NULL
offline_state       TEXT NOT NULL
ready_revision      INTEGER NULL
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

Important activation rule:

```text
normal/streaming pack
→ metadata may activate once metadata/schema is verified

EXPLICIT_DOWNLOAD or PINNED pack
→ a new revision does not activate until all required_offline assets are verified
```

This keeps an explicitly offline pack atomically usable.

---

## 9.3 `download_task`

```text
download_task
──────────────────────────────────────────
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

Task types:

```text
ASSET
PACK_REQUIRED_ASSET
LOCALE_DELTA_ASSET
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

---

# 10. Durable learner state

## 10.1 `favorite`

```text
favorite
──────────────────────────────────────────
content_code   TEXT NOT NULL
content_type   TEXT NOT NULL
created_at     DATETIME NOT NULL

PK (content_code, content_type)
```

No FK to `local_content_record` by design.

A favorite survives cache/content eviction and is resolved again if content is re-downloaded.

---

## 10.2 `recent_content`

```text
recent_content
──────────────────────────────────────────
content_code      TEXT NOT NULL
content_type      TEXT NOT NULL
last_revision     INTEGER NULL
resume_locator    TEXT NULL
last_opened_at    DATETIME NOT NULL

PK (content_code, content_type)
```

Used by `Continue Learning`.

`resume_locator` is a feature-owned stable locator, e.g. a topic section code or test question position token.

---

## 10.3 `vocabulary_progress`

```text
vocabulary_progress
──────────────────────────────────────────
word_code            TEXT PK
last_seen_revision   INTEGER NULL
familiarity_level    INTEGER NOT NULL DEFAULT 0
correct_count        INTEGER NOT NULL DEFAULT 0
incorrect_count      INTEGER NOT NULL DEFAULT 0
last_practiced_at    DATETIME NULL
updated_at            DATETIME NOT NULL
```

No FK to disposable vocabulary content.

---

## 10.4 `topic_progress`

```text
topic_progress
──────────────────────────────────────────
topic_code            TEXT PK
last_seen_revision    INTEGER NULL
last_section_code     TEXT NULL
completed             INTEGER NOT NULL DEFAULT 0
progress_percent      INTEGER NOT NULL DEFAULT 0
last_opened_at        DATETIME NULL
updated_at             DATETIME NOT NULL
```

---

## 10.5 `review_schedule`

```text
review_schedule
──────────────────────────────────────────
content_code        TEXT NOT NULL
content_type        TEXT NOT NULL
due_at              DATETIME NOT NULL
interval_days       INTEGER NOT NULL
last_result         TEXT NULL
last_reviewed_at    DATETIME NULL
updated_at           DATETIME NOT NULL

PK (content_code, content_type)
```

The review scheduler is deterministic/local in MVP.

---

# 11. Assessment durability

## 11.1 `test_attempt`

```text
test_attempt
──────────────────────────────────────────
attempt_id            TEXT PK
test_code             TEXT NOT NULL
test_revision         INTEGER NOT NULL
mode                   TEXT NOT NULL
state                  TEXT NOT NULL
current_position       INTEGER NOT NULL DEFAULT 0
score                  REAL NULL
correct_count          INTEGER NULL
question_count         INTEGER NOT NULL
started_at             DATETIME NOT NULL
updated_at             DATETIME NOT NULL
completed_at           DATETIME NULL
```

States:

```text
IN_PROGRESS
COMPLETED
ABANDONED
```

Modes:

```text
LEARN
EXAM
QUICK
```

---

## 11.2 `test_attempt_question`

Durable question snapshot for reproducible historical review even if the source pack is later evicted.

```text
test_attempt_question
──────────────────────────────────────────
attempt_id            TEXT NOT NULL
position              INTEGER NOT NULL
question_code         TEXT NOT NULL
question_revision     INTEGER NOT NULL
question_type         TEXT NOT NULL
question_snapshot     TEXT NOT NULL

PK (attempt_id, position)
FK attempt_id -> test_attempt(attempt_id) ON DELETE CASCADE
```

`question_snapshot` may be a versioned compact JSON payload because it is an immutable attempt-history snapshot, not a general catalog query model.

This is an intentional exception to the no-generic-JSON primary-content rule.

---

## 11.3 `test_answer`

```text
test_answer
──────────────────────────────────────────
attempt_id          TEXT NOT NULL
position            INTEGER NOT NULL
answer_payload      TEXT NOT NULL
is_correct          INTEGER NULL
answered_at         DATETIME NOT NULL

PK (attempt_id, position)
FK (attempt_id, position)
  -> test_attempt_question(attempt_id, position)
  ON DELETE CASCADE
```

`answer_payload` is versioned JSON so future question types do not require historical schema rewrites.

---

# 12. Typed feature read models

The following are REQUIRED conceptually but are frozen with their feature contracts rather than invented generically here:

```text
vocabulary_item_read
vocabulary_example_read
vocabulary_collocation_read
interview_question_read
interview_model_answer_read
topic_read
topic_section_read
phrase_read
practice_test_read
question_read
question_option_read
localized_support_read
```

Rules:

1. Every row carries stable code + exact revision.
2. Staged rows are not returned by active repositories.
3. Activation participates in the same Drift transaction as `content_pack_revision` state changes.
4. Search/filter fields are typed/indexed rather than extracted from JSON at runtime.
5. Locale-specific read models may be independently replaced without duplicating canonical English/audio.

---

# 13. Required indexes

Minimum index plan:

```text
sync_run(state, updated_at)
sync_pack_update(run_id, state)
content_pack_revision(pack_code, variant_key, state)
local_content_record(content_type, snapshot_state, sort_order)
pack_content_ref(pack_code, variant_key, pack_revision)
asset_catalog(checksum_sha256)
local_asset_file(state, last_accessed_at)
content_asset_ref(asset_id)
content_cache_entry(retention_class, expires_at, last_accessed_at)
offline_pack_state(offline_state, desired_mode)
download_task(state, next_retry_at)
recent_content(last_opened_at DESC)
review_schedule(due_at)
test_attempt(state, updated_at DESC)
```

Feature-specific indexes are defined with feature read-model contracts.

---

# 14. Deletion and FK policy

## Disposable graph

Safe cascade is allowed inside purely disposable/staged graphs where the parent cannot be learner history.

Example:

```text
sync_run
→ sync_pack_update
→ planned staging rows
```

## Durable learner graph

Do NOT cascade from synced content into:

```text
favorite
recent_content
vocabulary_progress
topic_progress
review_schedule
test_attempt
```

These tables use stable business codes intentionally.

---

# 15. Asset deletion rule

Physical asset deletion is allowed only when all conditions are true:

```text
1. local_asset_file exists
2. no ACTIVE/STAGED-retained pack/content references require its checksum
3. no explicit/pinned offline intent requires it
4. no in-progress download/verification task owns it
5. retention policy selected it for deletion
```

Deletion flow:

```text
VERIFIED
→ DELETE_PENDING
→ filesystem delete
→ DB row delete
```

If filesystem deletion fails, keep `DELETE_PENDING` and retry later. Never delete the DB record first and orphan the file silently.

---

# 16. Migration policy

Drift schema migrations SHALL be explicit and tested.

Rules:

```text
schemaVersion increments monotonically
migration tests open previous schema and migrate forward
no production delete-and-recreate fallback
migration does not erase favorites/progress/test attempts
new columns prefer safe defaults/nullability
indexes are created as part of migration qualification
```

A broken disposable cache may be rebuilt selectively, but durable learner tables are not disposable.

---

# 17. Transaction boundaries

Use Drift transactions for:

```text
sync plan persistence
pack staging metadata writes
atomic content-version activation
apply tombstones + activate new revisions
complete test answer + update attempt position
complete attempt + result summary
asset-reference release after supersession
```

Do NOT hold a SQLite transaction open while performing network or filesystem downloads.

Network/filesystem work occurs before the short commit transaction.

---

# 18. Atomic sync activation boundary

For one target root-manifest version:

```text
network fetch/download/verify
        ↓
all required staging state READY_TO_COMMIT
        ↓
ONE SHORT DRIFT TRANSACTION
        ├── activate staged pack revisions
        ├── supersede old pack revisions
        ├── switch typed read models to active revisions
        ├── apply tombstones
        ├── update asset/content refs
        └── advance content_manifest_state
        ↓
commit
        ↓
filesystem cleanup outside transaction
```

If the transaction fails, SQLite rollback preserves the complete previous active snapshot.

---

# 19. Acceptance criteria for P0.12.4

The ERD is accepted when implementation tests prove at least:

1. installation token is never written to Drift;
2. one old ACTIVE pack remains readable while a new revision is STAGING;
3. staged content is invisible to normal repositories;
4. failed staging does not change active manifest version;
5. durable favorites/progress survive pack eviction;
6. shared physical asset is not deleted while any retained reference remains;
7. explicit/pinned pack upgrade does not activate until required offline assets verify;
8. normal streaming pack may activate metadata without downloading every binary asset;
9. completed test attempt remains reviewable after source test pack eviction;
10. interrupted download leaves recoverable temp/task state;
11. interrupted DB activation rolls back completely;
12. Drift migration from prior schema preserves durable learner state.

---

## 20. Result

The local database is intentionally split into:

```text
SYNC METADATA
    → recoverable/disposable

CONTENT READ MODELS + ASSETS
    → versioned/re-downloadable

LEARNER STATE
    → durable/local-first
```

This separation is the foundation for `ContentSyncCoordinator`, `DownloadManager`, `AssetResolver`, retention and offline-first startup.
