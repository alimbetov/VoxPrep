# CareerSpeak — Flutter Mobile Application Requirements

**Document version:** 2.6  
**Status:** Normative MVP mobile baseline  
**Applies to:** CareerSpeak v1  
**Target platforms:** Android, iOS

Normative parents:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`](CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md)

Related contracts:

- [`CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`](CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md)
- [`CAREERSPEAK_CONTINUE_LEARNING_PRODUCT_CONTRACT.md`](CAREERSPEAK_CONTINUE_LEARNING_PRODUCT_CONTRACT.md)
- [`CAREERSPEAK_REVIEW_POLICY.md`](CAREERSPEAK_REVIEW_POLICY.md)
- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`../mobile/CAREERSPEAK_DRIFT_ERD.md`](../mobile/CAREERSPEAK_DRIFT_ERD.md)
- [`../mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md`](../mobile/CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md)
- [`../mobile/CAREERSPEAK_ADAPTIVE_UI.md`](../mobile/CAREERSPEAK_ADAPTIVE_UI.md)
- [`../mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md`](../mobile/CAREERSPEAK_MATERIAL_DESIGN_3.md)
- [`../mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md`](../mobile/CAREERSPEAK_LEARNER_CONTENT_STATE.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)

---

## 1. Responsibility

Flutter owns:

```text
3-step onboarding
selected Goal/Track/Level preferences
browse/search local synced content
read/listen/repeat/shadow
PracticeTest lifecycle
local progress/FAVORITE/LISTENED/COMPLETED markers
review scheduling
manifest/publication synchronization
offline verified asset use
storage retention
locale/theme preferences
adaptive Material 3 UI
```

Flutter does **not** own backend product/catalog truth, object-storage credentials, a server learner profile or runtime recommendation logic.

Backend-owned hierarchy:

```text
Vertical
 ↓
LearningGoal
 ↓
LearningTrack
 ↓
LearningCollection
 ↓
exact ContentRevision / PracticeTestRevision members
```

---

## 2. Technology and boundaries

```text
Flutter stable
Dart
Material Design 3
Riverpod
go_router
Drift + SQLite
Secure Storage
local filesystem
Backend HTTP abstraction
audio abstraction
```

Widgets do not issue raw HTTP/SQL calls. Production Flutter has no direct RustFS/object-storage credential boundary.

Mocks/demo catalogues are test fixtures only. Production catalogue truth flows from Backend HTTP through synchronized local CURRENT projections.

---

## 3. Navigation

Conceptual primary routes:

```text
/onboarding
/
/catalogue
/catalogue/vertical/:verticalCode
/catalogue/vertical/:verticalCode/goal/:goalCode
/catalogue/vertical/:verticalCode/goal/:goalCode/track/:trackCode
/catalogue/vertical/:verticalCode/goal/:goalCode/track/:trackCode/collection/:collectionCode
/learn
/tests/:code
/review
/settings
```

A standalone `/favorites` or `/downloads` route is optional post-MVP convenience and is not a release gate.

Hierarchy routes MUST validate full parent ownership. Wrong-parent Goal/Track/Collection navigation fails closed.

Resize/process recreation preserves meaningful durable state.

---

## 4. Onboarding and selection

MVP onboarding consists of exactly three decisions:

```text
1. Learning direction        → Vertical + LearningGoal
2. approximate English level → B1 / B2 / C1 / Not sure
3. support language          → Backend-published SupportedLocale
```

Requirements:

```text
skippable
account-free
restart-safe
CURRENT-catalogue validated
skip preserves explicit decisions
skip never fabricates Vertical/Goal
browsing is never blocked by skip
```

Flutter persists:

```text
selectedGoalCode?
selectedTrackCode?
selfAssessedLevelCode?
```

Flutter MUST NOT persist `selectedVerticalCode` as a competing source of truth. Current Vertical derives from `selectedGoalCode → CURRENT Goal.verticalCode`.

Invalid selection is fail-closed:

```text
Track inactive/missing
→ clear Track, preserve active Goal

Goal inactive/missing
→ clear Goal + Track
→ current Vertical unset
→ Choose learning direction

Vertical inactive/missing
→ selected Goal invalid
→ same Goal rule
```

Flutter MUST NOT choose the first active sibling Track/Goal automatically.

Onboarding progress is persisted after each explicit decision and resumes at the next incomplete step after restart.

---

## 5. Home / Continue Learning

Decision priority:

```text
1. active resumable PracticeTest attempt
2. unfinished last-opened Content
3. next incomplete current-Collection member
4. next eligible current-Track Collection
5. current Track / current Vertical browse entry
6. Choose learning direction
```

Candidates are revalidated against CURRENT before navigation. Stale, tombstoned, inactive, dangling or revision-mismatched candidates are skipped, not repaired by guessing.

Home presentation priority:

```text
Continue
Current Vertical / Goal / Track
Review due
Browse current track/collections or Choose learning direction
Secondary statistics
```

No recommendation engine is required.

---

## 6. Learn / discovery

MVP discovery:

```text
Current Vertical / Goal / Track
Verticals
Collections
Categories
Browse / Search
```

Search/filters operate on synchronized local data. Search defaults to current Vertical when a current direction exists; cross-Vertical expansion must be explicit.

---

## 7. Material Design 3 / adaptive UI

One design system:

```text
Material Design 3
→ CareerSpeak theme/tokens
→ small reusable component set
→ adaptive screens
```

Width classes:

```text
COMPACT   < 600
MEDIUM    600–839
EXPANDED  840–1199
LARGE     >= 1200
```

Presentation changes do not fork business state/logic.

---

## 8. Learner-facing copy

Production UI does not expose:

```text
repository
adapter
persistence
manifest
DTO
qualification
Drift
RustFS
```

Raw HTTP/database/storage exceptions are never shown directly. Error/empty states provide a learner-safe problem statement and next action where possible.

---

## 9. Installation identity

```text
random installationId
→ backend registration
→ backend-issued token
→ Secure Storage
```

No learner account.

Credential-specific recovery is bounded:

```text
401
→ clear rejected token only
→ preserve installationId + learner state
→ re-register once
→ retry safe request once where policy permits
→ fail closed if rejected again
```

The installation credential protects JSON and learner media APIs.

---

## 10. Offline-first startup

```text
open Drift/filesystem
→ load local settings/Goal/Track
→ load secure credential
→ load last-known-good CURRENT publication
→ validate Goal/Track/Vertical hierarchy
→ load learner progress/review/active test
→ render usable local UI
→ recover interrupted local work
→ check Backend when available
```

Network is not required to use valid cached learning content.

If no usable CURRENT publication exists and Backend is unavailable, show a recoverable connectivity state and never invent catalogue options.

---

## 11. Atomic synchronization

High-level C4 target:

```text
CHECK LOCAL
→ CHECK REMOTE
→ PLAN
→ STAGE COMPLETE CANDIDATE
→ VERIFY refs/revisions/checksums
→ ATOMIC CURRENT ACTIVATION
→ CLEAN
```

The consistency boundary includes:

```text
Vertical / Goal / Track / Collection
Content revisions
PracticeTest revisions
Localization
Assets/audio references
```

Readers MUST NOT observe mixed CURRENT publications. A failed/incomplete candidate leaves last-known-good CURRENT active across restart.

---

## 12. Localization

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where applicable
```

UI strings are Flutter ARB/gen-l10n. Content translations/hints/explanations come from Backend locale payloads. Root identity is locale-independent.

Missing optional hint/translation/explanation does not block canonical English content.

---

## 13. Local persistence

Drift separates:

```text
SYSTEM / SYNC
PRODUCT CONTENT / CACHE
LOCAL LEARNER STATE
```

Learner state includes:

```text
onboarding progress
selected Goal/Track/Level
FAVORITE / LISTENED / COMPLETED
review schedule
active PracticeTest + completion/history
playback progress
```

Current Vertical is derived, not persisted as a competing preference. Cache cleanup never erases learner state.

---

## 14. Assets / offline media

`DownloadManager` owns bounded download, retry, temp-file handling, size/checksum verification and atomic final placement.

`AssetResolver` returns verified local assets to feature/playback code.

CareerSpeak v1 learner media path is fixed:

```text
Flutter installation token
→ authenticated Backend media API
→ Backend-controlled byte delivery
→ Flutter size/SHA-256 verification
→ verified local file
```

Invariants:

```text
Flutter receives no storage credentials
Flutter never uses deliveryKey as a remote locator
Backend controls learner authorization
verified local assets remain usable offline
```

Metadata sync does not imply downloading every optional media asset.

A dedicated Downloads dashboard or collection-download library is deferred post-MVP. Offline readiness remains mandatory without that UI.

---

## 15. Audio

Shared playback supports:

```text
play/pause/stop/seek
speed
repeat
skip
segment repeat when segment metadata exists
qualified completion
```

UI does not persist LISTENED directly; application logic does. No runtime STT/pronunciation scoring in MVP.

---

## 16. Learner markers

Independent durable states:

```text
FAVORITE
LISTENED
COMPLETED
```

Rules:

```text
Favorite does not pin media automatically
Listened does not imply Completed
Completed does not erase test/review history
markers survive cache/media eviction
```

MVP requires favorite state/feedback/filtering where exposed by current UI. A dedicated Favorites application area is not a release gate.

---

## 17. Assessment

An active PracticeTest attempt persists:

```text
exact test revision
current position
selected answers
started/updated timestamps
```

Submission atomically records exact-revision completion and clears the matching active attempt. Historical revision N completion does not imply revision N+1 completion.

No complex recommendation engine is required.

---

## 18. Review scheduler

Minimal durable state:

```text
nextReviewAt
reviewStage
lastReviewOutcome
```

Strict rule:

```text
Due = nextReviewAt <= now
Due != !Completed
```

Outcomes:

```text
incorrect
hard
correct
known
```

Scheduling is deterministic/local and restart-safe. UI records outcomes through `ReviewScheduler`; UI does not contain interval logic.

---

## 19. Storage retention

Disposable storage uses bounded quota/retention/reference-safe deletion policies. Learner state is never deleted by cache cleanup.

Deleting a disposable verified local asset creates a recoverable cache miss; restoration occurs only through the authorized Backend media path.

A user-facing storage/download manager is post-MVP.

---

## 20. Failure / recovery

Preserve useful local state through:

```text
Backend offline
Backend media/storage failure
interrupted sync/download
checksum mismatch
401 recovery
process kill during onboarding/test/audio/review
storage pressure
Drift migration
```

Flutter never attempts direct object-storage credential fallback.

---

## 21. MVP mobile acceptance

Mobile acceptance proves:

```text
Vertical → Goal → Track → Collection ownership
3-step onboarding + skip + restart
selected Goal/Track persistence
Vertical derived from selected Goal
fail-closed inactive/missing selection handling
Continue Learning deterministic priority and CURRENT revalidation
atomic CURRENT publication visibility
locale switch/offline reopen
real audio/local asset resolution
FAVORITE/LISTENED/COMPLETED persistence
Due based only on nextReviewAt
review outcome scheduling survives restart
PracticeTest attempt/completion exact-revision lifecycle
Home/Learn current learning context
adaptive/light/dark/RTL/large-text behavior where specified
storage cleanup preserves learner state
learner-facing copy contains no implementation terminology
production catalogue/media paths have no runtime demo/mock/storage-credential bypass
```

Standalone Favorites and Downloads screens are explicitly not required for CareerSpeak v1 acceptance.
