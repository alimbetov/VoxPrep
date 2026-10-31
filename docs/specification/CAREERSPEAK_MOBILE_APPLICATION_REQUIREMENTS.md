# CareerSpeak — Flutter Mobile Application Requirements

**Document version:** 2.2  
**Status:** Normative mobile application baseline  
**Applies to:** CareerSpeak v1+  
**Target platforms:** Android, iOS

Normative parent:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)

Related detailed contracts:

- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`../mobile/CAREERSPEAK_DRIFT_ERD.md`](../mobile/CAREERSPEAK_DRIFT_ERD.md)
- [`../mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md`](../mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md)
- [`../mobile/CAREERSPEAK_ADAPTIVE_UI.md`](../mobile/CAREERSPEAK_ADAPTIVE_UI.md)
- [`../mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md`](../mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md)
- [`../mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md`](../mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md`](CAREERSPEAK_CONTENT_DELIVERY_RETENTION.md)

---

## 1. Product responsibility

Flutter is the only learner-facing application in MVP.

It owns:

```text
goal-based onboarding
local learner intent and selected goal/track
browse/search learner content
track/collection/activity presentation
read/listen/repeat/shadow
complete tests
local progress/favorites/review
LISTENED / COMPLETED / FAVORITE learner markers
manifest/pack synchronization
offline downloads
local retention/storage management
UI/translation locale preferences
adaptive learner UI
Material Design 3 presentation system
learner-facing copy/state presentation
```

It does not own:

```text
content authoring/publication
mutable LearningGoal/LearningTrack/LearningCollection catalog truth
mutable Category/Level/Skill/SupportedLocale/TtsVoice catalog truth
TTS generation
speech recognition/pronunciation scoring
server learner profile
business availability decisions
```

Flutter SHALL project backend-owned product structure into local Drift/read models rather than invent product catalogues in presentation code.

---

## 1A. Product experience contract

Learner-facing hierarchy follows:

```text
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
LearningActivity
    ↓
Content / PracticeTest
```

`CareerTrack` is career taxonomy. `LearningTrack` is a curriculum path. The mobile model and UI SHALL NOT treat them as aliases.

Technical content types such as `vocabulary`, `interview`, `topic`, `phrase` and `shadowing` remain useful domain classifications but are not the sole information architecture.

---

## 2. Technology baseline

```text
Flutter stable
Dart
Material Design 3
Riverpod
go_router
Drift + SQLite
platform Secure Storage
local filesystem
HTTP client abstraction
audio playback abstraction
```

Exact dependency versions are pinned during implementation qualification.

Package-specific types should not leak into domain/application contracts where a small internal abstraction is practical.

---

## 3. Architecture style

Feature-first structure:

```text
lib/
├── app/
├── core/
├── infrastructure/
└── features/
    ├── onboarding/
    ├── home/
    ├── learn/
    ├── goals/
    ├── tracks/
    ├── collections/
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

Dependency direction:

```text
presentation
    ↓
domain/application contracts
    ↑
data/infrastructure adapters
```

Widgets never issue raw HTTP or SQL calls.

---

## 4. State management

Riverpod is the baseline dependency/state mechanism for:

```text
repositories
screen/application controllers
installation/session state
sync state
download state
audio state
learner marker state
review schedule state
local learner intent
settings/locale/theme
```

Ephemeral widget-only state may remain local.

Do not duplicate global mutable state in unmanaged service locators.

---

## 5. Navigation

`go_router` is the baseline router.

Stable business codes are used in product/content routes where practical.

Initial route families:

```text
/onboarding
/
/learn
/goals/:code
/tracks/:code
/collections/:code
/ielts
/vocabulary/:code
/interview/:code
/topics/:code
/phrases
/shadowing/:code
/tests/:code
/review
/favorites
/downloads
/settings
/settings/storage
```

Process recreation/layout resizing should restore a meaningful route when local state exists.

---

## 5A. Goal-based onboarding

First-run onboarding is required product behavior, but it is skippable and account-free.

Recommended sequence:

```text
1. choose LearningGoal
2. choose/confirm approximate level or Not sure
3. choose support/translation locale
4. choose preferred accent/voice where available
5. offer recommended starter offline pack
```

Local learner-intent state includes at least:

```text
onboardingCompleted
selectedGoalCode
selectedTrackCode?
selfAssessedLevelCode?
```

Rules:

```text
onboarding survives restart
skip produces deterministic defaults
skip never blocks browsing
selected codes come from backend-owned published catalogues
catalog deactivation triggers deterministic fallback rather than crash
cache cleanup never erases learner intent
```

No learner account is introduced for onboarding.

---

## 6. Adaptive UI

Adaptive UI follows:

```text
docs/mobile/CAREERSPEAK_ADAPTIVE_UI.md
```

Width classes:

```text
COMPACT   < 600
MEDIUM    600–839
EXPANDED  840–1199
LARGE     >= 1200
```

Rules:

```text
adapt to available window, not device name
layout changes do not fork business logic
route/test/audio/marker/review/onboarding state survives resize
phone/tablet/split-screen use same domain controllers
large text and RTL are first-class qualification cases
```

---

## 6A. Material Design 3

Material Design 3 is the **single and exclusive UI design system** for CareerSpeak.

Authoritative contract:

```text
docs/mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md
```

Design hierarchy:

```text
Material Design 3
        ↓
CareerSpeak Theme + Design Tokens
        ↓
CareerSpeak reusable Material components
        ↓
Adaptive feature presentation
```

Rules:

```text
ThemeData / ColorScheme is the application theme source
light / dark / system modes are supported
Material NavigationBar / NavigationRail are the adaptive navigation baseline
spacing/radius/type/motion tokens are centralized
feature widgets do not define a second visual system
Study Ambience is decorative and not a second design system
Material/BuildContext concerns never enter domain/application code
```

CareerSpeak branded components SHOULD include where relevant:

```text
Learning Card
Goal / Track Card
Collection Card
Audio Practice Card
Interview Question Card
Review Card
Goal Progress block
Empty State
Status Chip
```

They are built from Material 3 primitives rather than introducing a second visual framework.

---

## 6B. Learner-facing copy policy

Production learner UI SHALL NOT expose implementation vocabulary such as:

```text
repository
adapter
persistence
manifest
DTO
qualification
production adapter
sync journal
Drift
RustFS
```

Use learner-benefit/state language instead.

Raw transport/database exceptions are never rendered directly to the learner.

Empty/error states SHOULD communicate:

```text
what happened
why it matters
what safe next action is available
```

The UI distinguishes at least:

```text
no published content
no downloaded content
filter returned zero results
network unavailable
update/sync failed
storage unavailable/full
```

---

## 7. Installation identity

There is no learner account.

First launch:

```text
random cryptographic installationId
→ backend registration
→ backend-issued installation token
→ platform Secure Storage
```

Do not derive identity/credential from hardware or advertising identifiers.

Do not store the installation token in Drift.

Credential-specific `401` recovery SHALL preserve `installationId`, clear/re-establish only the rejected token, retry the safe startup path once, then fail closed on repeated rejection.

---

## 8. API client

All learner HTTP calls pass through one typed API abstraction responsible for:

```text
base URL/environment
installation token
timeouts
JSON serialization
error-envelope mapping
traceId capture
401/403 handling
429 / Retry-After handling where defined
safe bounded retry policy
```

Presentation receives typed application/repository results, not raw HTTP objects.

---

## 9. Offline-first startup

Startup sequence:

```text
initialize Drift/filesystem
→ load settings/local learner intent/locales/theme
→ load secure installation credential state
→ load CURRENT local metadata
→ load durable learner markers/progress/review schedules
→ render usable UI
→ recover interrupted local work
→ register/re-establish installation if required and possible
→ check remote manifest in background
→ bounded cleanup
```

Valid local content is shown without waiting for network sync.

---

## 10. Localization

Flutter distinguishes:

```text
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where available
learningLanguage = en
```

UI strings:

```text
ARB + Flutter gen-l10n
```

Content translations/hints/explanations:

```text
Backend locale pack variants + immutable localized payloads
```

Canonical English/audio is shared across locales.

Root manifest identity is locale-independent. Translation locale selects which published locale delta Flutter materializes/uses.

RTL/mixed-direction behavior follows adaptive UI/globalization specs.

---

## 11. Local persistence

Authoritative schema:

```text
docs/mobile/CAREERSPEAK_DRIFT_ERD.md
```

Core separation:

```text
SYSTEM/SYNC
PRODUCT CONTENT/CACHE
DURABLE LEARNER STATE
LOCAL LEARNER INTENT
```

Backend `ACTIVE`, Flutter metadata `CURRENT`, and offline `READY` are separate states.

Learner intent, progress, review schedules and markers are never deleted merely because cache/content files are reclaimed.

---

## 12. Content synchronization

Authoritative state machine:

```text
docs/mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md
```

High-level flow:

```text
CHECK LOCAL
→ CHECK REMOTE
→ PLAN
→ STAGE METADATA
→ VERIFY METADATA
→ ATOMIC CURRENT SWITCH
→ CLEAN
```

A partial/failed update never replaces the last-known-good CURRENT metadata snapshot.

Mutable product catalogues such as goal/track/collection/taxonomy/capability data are backend-owned and versioned/published; Flutter stores local projections.

---

## 13. Root/pack contract

Backend publishes one locale-independent root:

```text
contentVersion
```

Root snapshot references exact pack variants/revisions/checksums.

Locale deltas are pack variants:

```text
canonical
locale:ru
locale:kk
locale:<BCP-47>
```

Flutter stores separate `remoteContentVersionSeen` and `currentContentVersion` concepts.

---

## 14. Download Manager

Dedicated `DownloadManager` owns:

```text
bounded concurrency
progress
resume where supported
retry/backoff
storage precheck
temp files
checksum/size verification
atomic final placement
```

Download states:

```text
QUEUED
DOWNLOADING
PAUSED
VERIFYING
READY
FAILED
CANCELLED
```

Metadata synchronization does not download all media by default.

---

## 15. AssetResolver

Presentation/audio asks for an asset by immutable identity.

```text
verified local file exists?
├── yes → local file
└── no  → explicit resolution policy
          ├── localOnly → ASSET_NOT_AVAILABLE_OFFLINE
          └── downloadIfMissing → CDN/edge download
                                  → verify size + SHA-256
                                  → local file
```

Feature UI does not implement separate online/offline playback paths.

P2.8 returns verified local sources only. A CDN URI is used internally by DownloadManager, not returned directly to the player. Streaming is outside this slice. See [P2.8 implementation contract](../implementation/P2_8_ASSET_RESOLVER.md).

---

## 16. Offline pack semantics

Explicit download/pin has an independent lifecycle:

```text
NOT_DOWNLOADED
QUEUED
DOWNLOADING
VERIFYING
READY
UPDATING
FAILED
```

Supported:

```text
metadata rev 8 = CURRENT
offline rev 7 = READY
offline rev 8 = UPDATING
```

The old READY revision remains usable until replacement verifies.

---

## 17. Storage retention

Automatic disposable-storage control uses:

```text
TTL
+
LRU
+
managed quota
+
explicit-download/pin protection
+
reference-safe shared-file deletion
```

Favorites do not automatically pin media.

Storage UI exposes at least:

```text
managed storage summary
Manage downloads
Free space
remove offline pack
```

---

## 18. Audio service

Shared `AudioPlaybackController` supports:

```text
load via AssetResolver
play/pause/stop/seek
position/state
speed
repeat
skip backward/forward
qualified playback completion event
```

Playback states:

```text
IDLE
LOADING
READY
PLAYING
PAUSED
COMPLETED
ERROR
```

One primary learning-audio session owns playback at a time unless later UX explicitly changes this rule.

Audio completion is reported to the learner-state application layer; UI widgets do not directly persist `LISTENED`.

Speaking-practice UX MAY support listen → repeat aloud → replay/compare without adding runtime STT or pronunciation scoring.

---

## 18A. Learner content markers

Authoritative contract:

```text
docs/mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md
```

Independent durable local states:

```text
FAVORITE
= learner explicitly saved the item

LISTENED
= qualified audio playback completed

COMPLETED
= pedagogical unit completed according to feature policy
```

A content item may hold any valid combination, including:

```text
FAVORITE + LISTENED + COMPLETED
```

Markers use stable `content_code + content_type` identity and survive cache/media eviction.

Catalogs/search SHOULD support local filters where useful:

```text
Favorites
Listened
Not listened
Completed
Not completed
```

Favorite does not imply offline pinning. Listened does not imply Completed. Completed does not erase or merge audio history.

---

## 19. Shadowing

MVP:

```text
0.75x / 1.0x / 1.25x
repeat 1 / 3 / 5 / infinite
pause/resume
seek
segment repeat
skip back/forward
```

Backend publishes stable segment/order metadata where highlighting/repeat depends on segmentation.

Flutter does not infer pedagogical segmentation from punctuation.

---

## 20. Assessment

Local execution supports:

```text
LEARN
EXAM
QUICK
```

Persist:

```text
test attempt
exact test revision
question snapshots/revisions
selected answers
current position
score/results
```

In-progress attempt survives process recreation.

Completed attempt remains reviewable after source pack cache eviction.

Test completion MAY drive the relevant `COMPLETED` learner marker through application policy without replacing the immutable test-attempt history.

Completed assessment UX SHOULD provide:

```text
score/result
question explanations
strong skills
weak skills
recommended next learning action
```

Skill-based feedback uses stable backend-owned `skillCode` identity.

---

## 21. Review scheduler

MVP uses deterministic local review scheduling.

Normative review state:

```text
nextReviewAt
reviewStage
lastReviewedAt
lastReviewOutcome
```

Possible outcomes include:

```text
incorrect
hard
correct
known
```

Mandatory semantic rule:

```text
Due = nextReviewAt <= now
Due != !Completed
```

`Not completed` remains a separate filter/state and SHALL NOT be relabeled as `Due`.

The scheduling policy maps outcomes to deterministic future intervals and survives restart/cache eviction. No ML/runtime AI is required.

---

## 22. Home experience

Home prioritizes learner action, not counters.

Required hierarchy:

```text
1. Next best action / Continue
2. Current LearningGoal / LearningTrack
3. Goal/track progress
4. Review due
5. Recommended next collection/content
6. Library shortcuts
7. Secondary statistics
```

`Completed`, `Listened`, `Favorites` and similar counters are secondary.

A section labelled `Recommended` must have a deterministic basis such as selected goal/track/level, current progress, due review state or published editorial order.

---

## 23. Learn / discovery experience

Recommended hierarchy:

```text
Learn
├── Continue your track
├── Goals / tracks
├── Recommended
├── Collections
├── Categories
└── Browse all / Search
```

Search and marker filters remain available, but Learn SHALL NOT be only a flat catalogue of technical content types.

---

## 24. Learning activity progression

The product loop is:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

Where backend-published `LearningActivity` metadata applies, Flutter presents current/completed/next activity state without inventing a different sequence.

Activity ordering is guidance, not a universal hard lock unless a specific track/collection marks an activity required.

---

## 25. Errors

Mobile domain errors may include:

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

Raw transport/database exceptions are not learner-facing strings.

---

## 26. Failure/recovery

Must preserve usable local state through:

```text
backend offline
CDN failure
interrupted sync
interrupted download
checksum mismatch
unsupported schema
401 credential recovery
process kill during onboarding
process kill during test
process kill during audio flow
process kill during review update
storage pressure
Drift migration
```

A failed sync does not require deleting the local database.

Durable learner intent, review schedule and FAVORITE/LISTENED/COMPLETED state must survive recoverable cache/sync failures.

---

## 27. Product activation semantics

The app considers a learner product-activated only after:

```text
onboarding is completed or explicitly skipped deterministically
AND
at least one meaningful learning activity completes
```

Meaningful activity includes:

```text
qualified audio listen
content completion
completed practice test
completed review
```

No server-side learner analytics are required in MVP. Future telemetry requires a separate privacy/data contract.

---

## 28. Acceptance qualification

Mobile architecture/product experience is accepted when tests prove at least:

```text
first launch online/offline
goal-based onboarding complete/skip/restart behavior
selected goal/track persistence and fallback
installation credential lifecycle
CURRENT metadata atomic update
tombstone + learner-state preservation
explicit offline READY replacement
shared asset safety
locale delta reuse
Material Design 3 is the single design system
CareerSpeak branded components use the shared token/theme layer
light/dark/system theme qualification
adaptive resize without route/test/audio/marker/review state loss
text scale 2.0 core-flow usability
RTL/mixed-direction readiness
LISTENED / COMPLETED / FAVORITE persistence and coexistence
favorite does not pin media automatically
local marker filters return correct results
Due is driven by nextReviewAt and never merely !completed
review schedule survives restart/cache cleanup
Home prioritizes next action/current goal before statistics
Learn exposes goal/track/collection discovery, not only flat content types
assessment feedback can identify stable skills and explanations
in-progress test restoration
storage cleanup without intent/progress/marker deletion
schema incompatibility fallback
production learner copy contains no implementation terminology
```

This is the authoritative Flutter application baseline for CareerSpeak v1.
