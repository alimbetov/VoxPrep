# CareerSpeak — Flutter Mobile Application Requirements

**Document version:** 1.0  
**Status:** Normative mobile architecture specification  
**Applies to:** VoxPrep / CareerSpeak v0.8+  
**Target platforms:** Android, iOS

---

## 1. Purpose

This document defines the implementation contract for the learner-facing CareerSpeak Flutter application.

It covers:

```text
application architecture
feature/module boundaries
state management
navigation
installation identity/token
API access
offline-first startup
SQLite/Drift local model
manifest synchronization
offline packs
download management
asset resolution
audio playback
shadowing
assessment
review scheduling
localization/locale fallback
RTL readiness
storage retention
error/recovery behavior
mobile acceptance tests
```

The mobile application SHALL remain usable with previously downloaded content when the backend, CDN or TTS Worker is unavailable.

---

## 2. Product role of Flutter

Flutter is the only learner-facing application in MVP.

It is responsible for:

```text
browse published content
read/listen/repeat/shadow
complete tests
store learner progress locally
manage favorites/review schedule
manage offline downloads
synchronize manifests/content packs
select UI/translation locale
apply Study Ambience / Focus Mode
reclaim disposable local storage
```

Flutter SHALL NOT perform:

```text
content authoring
content publication
TTS generation
speech recognition
pronunciation scoring
server-side learner profile management
```

---

## 3. Mobile technology baseline

Baseline:

```text
Flutter stable
Dart
Riverpod for application/state dependency management
go_router for declarative navigation
Drift + SQLite for structured local persistence
platform secure storage abstraction for installation token
local filesystem for downloaded binary assets
HTTP client adapter for backend REST
platform-qualified audio playback adapter
```

Exact package versions SHALL be pinned during implementation qualification.

The application SHALL avoid package-specific types leaking into domain models where a small internal abstraction is practical.

---

## 4. Architecture style

CareerSpeak mobile SHALL use feature-first modular architecture.

Recommended root structure:

```text
mobile/careerspeak_mobile/
└── lib/
    ├── app/
    ├── core/
    ├── features/
    └── infrastructure/
```

Feature map:

```text
features/
├── onboarding/
├── home/
├── vocabulary/
├── interview/
├── topics/
├── phrases/
├── shadowing/
├── assessment/
├── review/
├── favorites/
├── downloads/
├── settings/
└── storage_management/
```

A feature MAY use internal layers:

```text
feature/
├── domain/
├── data/
└── presentation/
```

Do not organize the whole application as global `screens/`, `services/`, `models/`, `repositories/` buckets.

---

## 5. Dependency direction

Recommended dependency direction:

```text
presentation
    ↓
domain/application contracts
    ↑
data/infrastructure adapters
```

Rules:

1. Widgets SHALL NOT issue raw HTTP calls.
2. Widgets SHALL NOT execute SQL directly.
3. Domain/application logic SHALL NOT depend on concrete REST/SQLite/audio packages.
4. Repositories coordinate remote/local sources.
5. Cross-feature dependencies SHOULD go through explicit application/domain contracts rather than importing another feature's implementation internals.

---

## 6. State management

Riverpod is the baseline state-management/dependency mechanism.

Use it for:

```text
repository/provider wiring
AsyncValue-style loading/error/data state
screen/application controllers
installation/session state
manifest synchronization state
download state
audio playback state
settings/locale/theme state
```

Do not maintain duplicate global mutable state in singleton service locators.

Ephemeral widget-only state MAY stay inside widgets/controllers where it has no persistence or cross-screen meaning.

---

## 7. Navigation contract

`go_router` is the baseline router.

Initial route model:

```text
/
├── /ielts
├── /vocabulary
│   └── /:code
├── /interview
│   └── /:code
├── /topics
│   └── /:code
├── /phrases
├── /shadowing/:code
├── /tests
│   └── /:code
├── /review
├── /favorites
├── /downloads
├── /settings
└── /settings/storage
```

Routes use stable content business codes rather than database numeric IDs where practical.

Navigation SHALL support restoration to a meaningful screen after process recreation when local data is available.

Deep-link support MAY be introduced without changing domain identity because routes use stable codes.

---

## 8. Home information architecture

Initial Home composition:

```text
Continue Learning
Daily Review
IELTS
Job Interview
Professional English
Quick Test
Downloads
```

Home SHOULD render immediately from local state/content cache and SHALL NOT wait for a network manifest sync before becoming usable.

---

## 9. Installation identity

There is no personal learner account.

First launch:

```text
Flutter generates cryptographically random installationId
→ POST installation registration
→ backend issues installation token
→ token stored in platform secure storage
```

`installationId` is app-specific and SHALL NOT be derived from:

```text
IMEI
IMSI
MAC
hardware serial
advertising ID
phone number
email
Apple/Google account identity
```

Installation token is the API credential; `installationId` alone is not a credential.

Do not derive a credential locally as `SHA256(installationId)` or equivalent.

---

## 10. Installation/token lifecycle

The app SHALL support these states:

```text
UNREGISTERED
REGISTERING
REGISTERED
TOKEN_REFRESH_REQUIRED
REGISTRATION_FAILED
```

Startup behavior:

```text
secure token exists?
├── yes → use it
└── no  → register installation when network is available
```

If the device is offline and no token exists, the application MAY still show purely bundled onboarding/settings content but cannot fetch protected learner APIs until registration succeeds.

A previously registered app with downloaded content SHALL remain usable offline even when token validation cannot currently reach the backend.

---

## 11. API client contract

All learner REST calls pass through one API client abstraction.

Responsibilities:

```text
base URL/environment
installation token header
locale headers/query parameters where required
timeouts
JSON serialization
backend error-envelope mapping
trace/correlation ID capture where returned
401/403 handling
retry policy for safe requests
```

Presentation code SHALL consume typed repository/application results rather than HTTP response objects.

Unsafe state-changing operations SHALL NOT be blindly retried unless their contract is idempotent.

---

## 12. Offline-first source priority

Read path priority:

```text
verified local content snapshot
        ↓
render immediately
        ↓
background/scheduled freshness check
```

Network is primarily used for:

```text
installation registration/token lifecycle
manifest synchronization
new/updated content metadata
downloaded assets
explicit searches where local index is insufficient
```

A temporary network failure SHALL NOT blank screens that have usable local content.

---

## 13. Application startup

Required startup sequence:

```text
START
 ↓
initialize Drift/local filesystem
 ↓
load settings + locale + theme
 ↓
load secure installation token state
 ↓
load active local content manifest/snapshots
 ↓
render usable Home/UI
 ↓
perform installation registration if required and possible
 ↓
start manifest freshness check in parallel
 ↓
run bounded cleanup/recovery checks
```

The application SHALL NOT block the learner behind a network synchronization splash screen when valid local content exists.

---

## 14. UI localization vs content localization

Two localization channels are deliberately separate.

### 14.1 UI localization

Flutter-owned interface strings use the normal Flutter localization toolchain:

```text
ARB resources
Flutter gen-l10n
compile-time application resources
```

Examples:

```text
Home
Settings
Download
Retry
Free space
Correct / Incorrect
```

Adding a fully supported new UI locale normally requires a mobile release.

### 14.2 Content localization

Educational translations/hints/explanations are backend-driven:

```text
manifest
→ content pack / locale delta
→ Drift/local snapshot
```

Examples:

```text
vocabulary translation
question hint
answer explanation
profession/category display labels where data-driven
```

These MAY be published without a new Flutter release when the UI already supports presenting the locale/script.

---

## 15. Locale dimensions

Flutter SHALL distinguish:

```text
uiLocale
translationLocale
preferredAccent
```

Learning language is fixed:

```text
learningLanguage = en
```

Example:

```text
uiLocale          = ru
translationLocale = kk
preferredAccent   = UK
```

`uiLocale` and `translationLocale` may be different.

---

## 16. Locale selection

Initial UI locales:

```text
en
ru
kk
```

Selection precedence on first launch:

```text
1. explicit saved CareerSpeak choice
2. OS per-app locale
3. OS preferred languages
4. OS region as a weak fallback hint
5. English
```

CareerSpeak SHALL NOT request GPS solely to choose language.

The user can change `uiLocale` and `translationLocale` independently in Settings.

---

## 17. Locale fallback

UI strings:

```text
requested supported UI locale
→ English
```

Backend content localization:

```text
requested regional locale
→ base language
→ English support content where defined
```

Examples:

```text
pt-BR → pt → en
es-MX → es → en
ru-KZ → ru → en
kk-KZ → kk → en
```

Canonical English learning text/audio never depends on translation availability.

---

## 18. RTL readiness

The mobile architecture SHALL be RTL-ready before Arabic/Urdu rollout.

Requirements:

```text
use directional start/end instead of hardcoded left/right where appropriate
mirror directional navigation/icons where platform semantics require it
support text direction per locale/content block
avoid fixed-width assumptions for translated strings
qualify mixed English + RTL support text
```

English learning text may remain LTR inside an RTL UI while surrounding localized guidance follows RTL direction.

---

## 19. Locale-aware offline packs

Canonical English content/audio is shared across locales.

Example:

```text
JAVA_SENIOR
├── canonical English content
├── English audio
├── common assets
└── locale delta
    ├── ru
    ├── kk
    └── ...
```

Changing `translationLocale` SHOULD download only the missing locale delta when canonical English/audio assets are unchanged.

---

## 20. Local persistence model

Drift/SQLite owns structured local application state.

Baseline tables/concepts:

```text
app_setting
installation_state
content_manifest_state
content_pack_state
local_content_snapshot
local_asset
content_asset_ref
content_cache_entry
favorite
vocabulary_progress
topic_progress
review_schedule
test_attempt
test_answer
download_task
sync_journal
```

Exact columns/FKs/indexes are frozen during the Flutter local ERD slice.

---

## 21. Durable vs disposable local state

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
pack snapshots
audio
remote images
cached metadata
downloadable theme assets
```

Evicting disposable data SHALL NOT erase durable learner state.

---

## 22. Manifest synchronization

Flutter SHALL use a dedicated `ContentSyncCoordinator`.

High-level flow:

```text
load active local manifest
 ↓
GET remote root manifest
 ↓
same contentVersion?
├── yes → finish
└── no
     ↓
   process tombstones
     ↓
   discover changed pack manifests
     ↓
   download/stage changed metadata/assets
     ↓
   verify checksums/schema compatibility
     ↓
   atomically activate new local snapshot
     ↓
   release old asset references
     ↓
   reclaim now-unreferenced disposable files
```

A partially downloaded or failed pack update SHALL NOT replace the last known-good active snapshot.

---

## 23. Sync crash recovery

Synchronization SHALL be crash-safe.

Recommended local states:

```text
STAGING
VERIFIED
ACTIVE
FAILED
SUPERSEDED
```

On application restart:

```text
incomplete STAGING transaction
→ inspect/clean temporary files
→ preserve previous ACTIVE snapshot
→ retry later
```

The app SHALL never require deleting the whole local database to recover from an interrupted update.

---

## 24. Schema compatibility

Root manifest contains `schemaVersion`.

Flutter SHALL:

```text
accept supported schemaVersion
reject/avoid activating unsupported future schemaVersion
continue using last compatible local snapshot
prompt for app update when required
```

Backend SHALL NOT silently publish a pack schema that an installed app cannot safely interpret without an explicit compatibility policy.

---

## 25. Download Manager

Offline asset downloads use a dedicated `DownloadManager`.

Baseline state machine:

```text
QUEUED
→ DOWNLOADING
→ VERIFYING
→ READY
```

Failure/cancel states:

```text
PAUSED
FAILED
CANCELLED
```

Responsibilities:

```text
bounded concurrency
progress reporting
resume where supported
retry/backoff
storage-space precheck
checksum verification
atomic final-file placement
cleanup of temporary partial files
```

A download is not `READY` until integrity verification succeeds.

---

## 26. Asset identity and resolution

Remote/local media identity is based on immutable asset identity/checksum, not a permanent CDN hostname.

Flutter SHALL use an `AssetResolver` abstraction:

```text
requested asset
 ↓
verified local copy exists?
├── yes → local file URI/path
└── no  → remote CDN/edge URI
```

Presentation/audio code SHALL not need separate local-vs-remote implementations.

---

## 27. Shared asset references

Multiple content items may reference the same immutable audio/image.

Local model:

```text
local_asset
content_asset_ref
```

Physical file deletion is allowed only after all retained references are released.

Conceptually:

```text
reference_count == 0
```

---

## 28. Local retention / storage manager

A dedicated storage/retention service applies:

```text
TTL
+
LRU
+
local quota
+
pin/manual-download protection
+
reference-safe deletion
```

Priority under storage pressure:

```text
1. tombstoned/obsolete disposable data
2. expired unpinned data
3. least-recently-used unpinned data
4. preserve explicit offline downloads/pins
```

Favorites are not automatically storage pins.

---

## 29. Cleanup triggers

Correctness SHALL NOT depend on mobile OS background scheduling.

Evaluate cleanup at:

```text
application startup
manifest synchronization
after pack replacement
after large download
when quota is exceeded
user-triggered Free space
```

Background tasks are optional optimizations.

---

## 30. Storage management UX

Settings SHOULD expose local storage information:

```text
Downloaded content
Audio/cache
Images/theme assets
Total managed storage
```

Actions:

```text
Manage downloads
Free space
Remove a specific offline pack
```

User actions SHALL preserve durable progress unless the UI explicitly offers a separate progress reset action.

---

## 31. Audio playback architecture

Audio is a core application service, not feature-specific duplicated code.

Recommended abstraction:

```text
AudioPlaybackController
```

Capabilities:

```text
load asset through AssetResolver
play
pause
seek
stop
speed
repeat
skip backward
skip forward
playback position/state
```

Playback source may be local or remote without changing feature UI contracts.

---

## 32. Audio playback states

Baseline:

```text
IDLE
LOADING
READY
PLAYING
PAUSED
COMPLETED
ERROR
```

Only one primary learning-audio session SHOULD own playback at a time unless a later UX explicitly requires mixing.

Audio state SHALL survive ordinary widget rebuilds/navigation within the owning learning flow.

---

## 33. Shadowing contract

MVP Shadowing supports:

```text
0.75x
1.0x
1.25x

repeat:
1
3
5
∞
```

Also:

```text
pause/resume
seek
skip back/forward
repeat current segment where segmentation exists
```

Text/audio segmentation SHALL use backend-published stable segment/order metadata rather than client guesses based on punctuation.

Sentence/segment highlighting is enabled only when content provides deterministic timing/segment semantics sufficient for correct behavior.

---

## 34. Vocabulary flow

Baseline learner flow:

```text
word
→ meaning/translation/hint
→ collocations/examples
→ listen
→ repeat
→ mark/favorite/review
```

Vocabulary progress is stored locally and SHALL remain usable when the word's audio is evicted and later re-downloaded.

---

## 35. Interview flow

Baseline:

```text
question
→ listen
→ learner answers aloud independently
→ reveal model answer
→ listen
→ repeat/shadow
→ optional favorite/review
```

MVP does not record/upload learner speech.

---

## 36. Assessment local engine

Test execution occurs locally against a downloaded immutable test snapshot.

Local concepts:

```text
TestSession
TestAttempt
QuestionState
SelectedAnswer
Score
SkillBreakdown
```

The app SHALL preserve the exact test/question revision identifiers used for an attempt so historical results remain meaningful after future content updates.

---

## 37. Assessment modes

### Learn mode

```text
Question
→ Answer
→ Immediate result
→ Explanation/hint
→ Continue
```

### Exam mode

```text
Question 1..N
→ Finish
→ Score
→ Skill breakdown
→ Incorrect-answer review
```

### Quick mode

```text
small deterministic/randomized selection from locally available eligible questions
→ result
```

Random selection SHALL be reproducible within an active attempt once the attempt has started.

---

## 38. Assessment persistence

An in-progress attempt SHALL survive application process termination where practical.

Persist at least:

```text
attempt id
practice_test_revision_id
started_at
mode
current position
selected answers
completion state
score/result when complete
```

Completed attempts are durable local learner state and are not removed by media/cache cleanup.

---

## 39. Review scheduler

MVP review scheduling SHALL be deterministic and local-only.

Initial simple policy may use outcome-based intervals such as:

```text
incorrect → short interval
hard      → medium-short interval
correct   → medium interval
known     → long interval
```

Exact intervals SHALL be configurable and qualified before release rather than embedded throughout UI code.

No ML/AI is required for scheduling.

---

## 40. Favorites and progress

Favorite/progress identity uses stable content business code + revision semantics appropriate to the domain.

Rules:

1. Favorite does not imply permanent binary storage.
2. Progress survives asset eviction.
3. New content revision may inherit high-level identity/progress only according to explicit domain migration rules.
4. Tombstoned content may keep historical attempt/progress records while disappearing from active learning lists.

---

## 41. Search

MVP search SHOULD prefer locally indexed downloaded/catalog metadata where sufficient.

Remote search MAY be used for broader catalog discovery.

Search results SHALL respect:

```text
published/active visibility
locale presentation
content compatibility
```

Offline mode SHALL clearly limit search to locally available/indexed content instead of failing ambiguously.

---

## 42. Study Ambience / Focus Mode

Initial themes:

```text
MINIMAL
NATURE
COSMOS
LIBRARY
COFFEE_STUDY
PROFESSIONAL
```

Rules:

```text
Study Mode may use ambience backgrounds
Focus Mode uses minimal/solid presentation
Exam/Mock Test defaults to minimal presentation
text readability has priority
```

Initial theme assets MAY ship in the application bundle.

Future downloadable theme packs use the same asset/retention infrastructure as other disposable media.

---

## 43. Error model

Mobile domain errors SHALL be mapped to user-meaningful states.

Baseline categories:

```text
OFFLINE
TIMEOUT
UNAUTHORIZED
FORBIDDEN
CONTENT_NOT_FOUND
CONTENT_INACTIVE
SCHEMA_UNSUPPORTED
DOWNLOAD_FAILED
CHECKSUM_FAILED
STORAGE_FULL
LOCAL_DATA_CORRUPT
PLAYBACK_FAILED
SYNC_FAILED
```

Do not display raw exceptions such as `SocketException`, SQL errors or stack traces to learners.

---

## 44. Retry/recovery rules

Safe GET/manifest/download operations MAY use bounded retry with backoff.

Do not create infinite retry loops.

On repeated failure:

```text
preserve last known-good content
surface concise retry action
keep offline content usable
record diagnostic log without sensitive learner history
```

Checksum/integrity failure SHALL never activate the corrupted asset/snapshot.

---

## 45. Offline UX

When offline:

```text
downloaded lessons remain available
downloaded tests remain available
local progress remains writable
favorites/review remain writable
new remote downloads/search are unavailable
sync is deferred
```

The UI SHOULD communicate offline state without blocking local learning.

---

## 46. App settings

Initial settings include:

```text
UI language
translation language
preferred accent
Study Ambience theme
Focus Mode preference
audio playback defaults
download/storage controls
```

Preferences remain local-first.

---

## 47. Accessibility/readability

Mobile UI SHALL account for:

```text
system text scaling
semantic labels for primary controls
sufficient contrast
touch-target sizing
screen-reader semantics for playback/test controls
reduced visual distraction in Focus/Exam modes
```

Decorative backgrounds MUST NOT reduce content readability.

---

## 48. Privacy/logging

Mobile logs SHALL NOT intentionally persist:

```text
learner answers/history in diagnostic logs
full installation token
personal information not otherwise collected
```

The installation token is sensitive credential material and must not be printed in logs.

MVP does not require advertising SDKs or learner voice upload.

---

## 49. Mobile test strategy

Required test layers:

```text
unit tests
repository/data-source tests
Drift migration/query tests
provider/controller tests
widget tests
navigation tests
manifest/sync integration tests
download/recovery tests
audio state tests
assessment state-machine tests
locale/fallback tests
retention/eviction tests
```

Critical offline/sync flows SHOULD be tested using deterministic fake backend/storage adapters.

---

## 50. Mandatory mobile failure scenarios

Before production acceptance verify at least:

1. first launch online registration succeeds;
2. first launch offline then later registration succeeds;
3. valid token + backend offline still allows local learning;
4. expired/revoked token does not delete local progress;
5. root manifest request fails;
6. pack download is interrupted halfway;
7. application is killed during pack staging;
8. checksum mismatch occurs;
9. unsupported manifest schema is received;
10. tombstone removes disposable content but preserves relevant history;
11. shared asset remains while another content item references it;
12. storage quota triggers LRU cleanup;
13. pinned/manual pack survives normal cleanup;
14. audio switches correctly between remote/local source;
15. app is killed during in-progress test and attempt restores;
16. UI locale changes independently from translation locale;
17. regional locale fallback works;
18. RTL UI with embedded English learning text remains readable;
19. CDN unavailable while local asset exists;
20. local DB migration succeeds with retained progress.

---

## 51. Mobile Definition of Ready

Flutter implementation is ready when these are accepted:

```text
feature/module map
Riverpod ownership/state conventions
navigation routes
Drift ERD + migration policy
installation/token contract
API client/error contract
locale/UI-content localization split
fallback + RTL rules
manifest sync state machine
download manager contract
asset resolver contract
audio/shadowing contract
assessment state machines
review scheduler contract
retention/storage manager contract
offline startup/recovery behavior
acceptance/failure tests
```

---

## 52. Mobile architecture summary

```text
Flutter UI
   │
   ▼
Riverpod controllers/providers
   │
   ▼
Feature application/domain contracts
   │
   ├────────► Drift / SQLite
   │          durable learner state + active content snapshots
   │
   ├────────► Secure Storage
   │          installation token
   │
   ├────────► Backend REST API
   │          manifests/catalog/content
   │
   └────────► AssetResolver
              ├── local verified file
              └── CDN/Edge → RustFS

Shared mobile services:
ContentSyncCoordinator
DownloadManager
StorageRetentionManager
AudioPlaybackController
ReviewScheduler
```

This is the authoritative Flutter/mobile baseline for CareerSpeak v0.8.
