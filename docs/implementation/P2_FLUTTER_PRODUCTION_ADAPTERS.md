# P2 — Flutter Production Adapters

**Branch:** `feat/p2-flutter-production-adapters`  
**Base:** P1 accepted mock UI merged to `main` at `6f2e06f51c33df979340e12859d1407a215dfd4e`.

## Goal

Replace in-memory adapters behind stable application ports without rewriting learner-facing Material 3 UI.

```text
Feature UI
    ↓
Riverpod application query providers
    ↓
application ports
    ↓
┌─────────────────────────────┐
│ mock adapters   (temporary) │
│ Drift adapters  (P2.2+)     │
│ API adapters    (P2.4+)     │
└─────────────────────────────┘
```

## P2 sequence

```text
P2.0   production adapter boundary
P2.0.1 production-contract hardening
P2.1   Drift database foundation
P2.2   learner-state persistence
P2.3   installation identity + Secure Storage
P2.4   API client
P2.5   manifest DTOs / delivery contracts
P2.6   ContentSyncCoordinator
P2.7   DownloadManager
P2.8   AssetResolver
P2.9   real audio playback
P2.10  mock → production repository cutover
P2.11  offline / restart / recovery qualification
```

## P2.0 — adapter boundary

Accepted at exact SHA:

```text
7502809c771ca9901f7b2bfe01bbd7adf303eef5
```

Acceptance:

- feature screens do not import `data/mock/**` repositories;
- content and assessment access go through application repository ports;
- Riverpod composition providers own concrete adapter selection;
- mock adapters implement the same ports production adapters will implement;
- P1.7 adaptive/widget acceptance remains green;
- repository composition tests are green;
- architecture guard prevents feature → concrete mock adapter imports;
- `flutter analyze` and `flutter test` are green on the exact branch SHA.

## P2.0.1 — production-contract hardening

Accepted baseline SHA before P2.1 source work:

```text
419c6d1bc1be675a488a772fccab65a27c4019a8
```

Contract changes:

```text
MockPracticeTest  → PracticeTest
MockQuestion      → PracticeQuestion
MockTestMode      → PracticeTestMode
```

Repository semantics:

```text
watchContent(ContentQuery)
  → Stream<Result<Page<ContentItem>>>

getByCode(code)
  → Future<Result<ContentItem?>>

watchTests(PracticeTestQuery)
  → Stream<Result<Page<PracticeTestSummary>>>

getByCode(code)
  → Future<Result<PracticeTest?>>
```

Common primitives:

```text
PageRequest
Page<T>
ContentQuery
PracticeTestQuery
Result<T>
ApplicationFailure
```

The production contract therefore no longer assumes synchronous in-memory reads. Drift can emit reactive read models, while future API adapters can implement asynchronous queries without changing feature widgets.

CI baseline is deterministic:

```text
Flutter 3.47.9
Dart format gate
flutter analyze
flutter test
```

## P2.1 — Drift database foundation

Accepted at exact SHA:

```text
c23a4002874b517255df946d809cccf3e9645192
```

P2.1 introduces local persistence infrastructure only. It does **not** switch learner-facing repositories to Drift yet.

Dependencies are pinned for the slice:

```text
drift 2.35.3
drift_flutter 0.3.1
drift_dev 2.35.2
build_runner 2.17.1
```

Database:

```text
CareerSpeakDatabase
schemaVersion = 1
migration.onCreate = createAll()
```

Initial schema is intentionally smaller than the final P0.12.4 ERD.

### SYSTEM

```text
app_preferences
installation_runtime_states
```

`installation_runtime_states` contains operational registration state only. Installation ID and installation token remain in platform Secure Storage and MUST NOT be persisted in Drift.

### CONTENT FOUNDATION

```text
content_manifest_states
content_pack_revisions
local_content_records
```

This is sufficient to establish root manifest state and versioned local metadata identity before `ContentSyncCoordinator` is introduced.

### LEARNER FOUNDATION

```text
favorites
content_learning_states
```

These tables prove the critical separation:

```text
disposable content/cache
        ≠
durable learner state
```

Deleting a local content record must not cascade into favorites or learning progress.

### Explicit non-goals for P2.1

Do not add yet:

```text
sync_run / sync_pack_update / sync_tombstone
download_task / offline_pack_state
asset_catalog / local_asset_file / asset refs
review scheduler persistence
test attempt persistence
HTTP / backend DTOs
Secure Storage implementation
ContentSyncCoordinator
DownloadManager
AssetResolver
real audio
```

Those remain owned by later P2 slices.

### P2.1 acceptance

P2.1 is accepted only when all of the following are true:

1. `CareerSpeakDatabase` opens both the production Flutter database and an injected in-memory executor for tests;
2. schema version is exactly `1`;
3. migration `onCreate` creates every P2.1 table;
4. singleton system tables enforce `id = 1`;
5. composite identities reject duplicates for versioned content and learner identity;
6. deleting disposable `local_content_records` leaves `favorites` and `content_learning_states` intact;
7. the installation runtime table contains no installation credential fields;
8. Drift generated code is committed and reproducible;
9. `pubspec.lock` is committed;
10. CI runs pinned Flutter, strict formatting, Drift code generation validation, `flutter analyze`, and full `flutter test`;
11. P1.7 adaptive acceptance and P2 architecture guards remain green on the exact P2.1 SHA.

## P2.2 — learner-state persistence

P2.2 performs the first production persistence cutover. Catalog and assessment content remain mock-backed; only learner-owned mutable state moves to Drift.

Architecture:

```text
Feature UI
    ↓
contentMarkersProvider
    ↓
LearnerStateRepository
    ↓
DriftLearnerStateRepository
    ↓
CareerSpeakDatabase
    ├── favorites
    └── content_learning_states
```

Stable learner identity is explicit:

```text
ContentIdentity
├── business code
└── ContentType
```

The database identity remains `(content_code, content_type)`. A business code reused by two content types must not merge their learner state.

Repository commands are idempotent set operations rather than toggle operations:

```text
watchMarkers()
setFavorite(identity, favorite)
setListened(identity, listened)
setCompleted(identity, completed)
savePlaybackPosition(identity, positionMs)
```

The adapter persists and projects at least:

```text
FAVORITE
LISTENED
COMPLETED
last_position_ms
listen_count
completion_source
last_revision_seen
```

`ContentMarkerState` is a framework-agnostic domain value. Riverpod providers belong to the composition layer, not `domain/`.

### P2.2 invariants

1. favorite state is stored only in `favorites`;
2. listened/completed/playback state is stored only in `content_learning_states`;
3. replaying the same desired-state command is idempotent;
4. setting listened to `true` twice without an intervening reset does not increment `listen_count` twice;
5. clearing listened/completed does not destroy unrelated learner state such as playback position;
6. `savePlaybackPosition` rejects negative positions;
7. learner state survives closing `CareerSpeakDatabase`, constructing a new database instance for the same SQLite file, and reopening it;
8. UI never imports `data/local/**` or `DriftLearnerStateRepository` directly;
9. production content repositories remain mock-backed in this slice;
10. schema version remains `1`; P2.2 uses the tables introduced in P2.1 and does not create a migration merely for adapter code.

### Explicit non-goals for P2.2

Do not add yet:

```text
review_schedule persistence
test_attempt / test_answer persistence
installation ID/token persistence
Secure Storage
HTTP/API client
manifest sync
ContentSyncCoordinator
downloads/offline packs
real audio engine
backend learner profile or cloud sync
```

### P2.2 acceptance

P2.2 is accepted only when:

1. `LearnerStateRepository` is an application port and `DriftLearnerStateRepository` implements it;
2. composition root selects the Drift learner-state adapter;
3. Home, Learn, Review, ContentCard and ContentDetail read learner markers through the reactive provider;
4. favorite/listened/completed mutations write through the repository rather than a Riverpod in-memory map;
5. `FAVORITE`, `LISTENED`, `COMPLETED` and playback position survive a real database close/reopen test;
6. marker projection distinguishes the same business code used by different `ContentType` values;
7. widget acceptance uses an injected in-memory Drift database and remains green;
8. architecture guard rejects feature imports of both mock and local concrete adapters;
9. Drift schema/codegen/lockfile reproducibility gates remain green without schema changes;
10. pinned Flutter format/analyze/full-test CI is green on the exact P2.2 SHA.

## Architecture rule

Presentation code may depend on domain/application contracts and Riverpod composition providers. It must not choose a concrete persistence or transport implementation.

The adapter selected by the composition root may change without changing feature widgets.
