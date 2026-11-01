# CareerSpeak — Flutter Mobile Application Requirements

**Document version:** 2.5  
**Status:** Normative MVP mobile baseline  
**Applies to:** CareerSpeak v1  
**Target platforms:** Android, iOS

Normative parent:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)

Related contracts:

- [`CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`](CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md)
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
selected goal/track/level preferences
browse/search local synced content
read/listen/repeat/shadow
tests
local progress/favorites/review
manifest synchronization
offline downloads
storage retention
locale/theme preferences
adaptive Material 3 UI
```

Flutter does not own backend product/catalog truth or object-storage access.

Backend-owned product structure:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
Category
Level
Skill
SupportedLocale
TtsVoice catalogue
Content / PracticeTest definitions
```

---

## 2. Product hierarchy

Normative hierarchy:

```text
Vertical
    ↓
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
Content / PracticeTest
```

`Vertical` is the learner-facing subject/professional scope. `LearningGoal` is a learner intention inside exactly one Vertical.

No mobile/backend `LearningActivity` entity is required.

The learning loop remains:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

Flutter derives available actions from content/test capabilities and local learner state.

---

## 3. Technology

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

Widgets do not issue raw HTTP/SQL calls. Production Flutter has no object-storage credential boundary.

---

## 4. Navigation

Primary routes include conceptually:

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
/favorites
/downloads
/settings
```

Technical content routes may remain for direct navigation.

Hierarchy routes MUST validate full parent ownership. A Goal/Track/Collection reached under the wrong parent fails closed.

Resize/process recreation should preserve meaningful route/state.

---

## 5. Onboarding

MVP onboarding consists of exactly three learner decisions:

```text
1. Learning direction        → Vertical + LearningGoal
2. approximate English level → B1 / B2 / C1 / Not sure
3. support language          → Backend-published SupportedLocale
```

Step 1 MAY render Vertical and Goal selection as two visual panes/subviews, but it remains one logical onboarding step.

Requirements:

```text
skippable
account-free
restart-safe
uses backend-published catalogue values
only active Vertical/Goal chains are selectable
skip preserves explicit decisions already made
skip does not fabricate a default Vertical or Goal
never blocks normal browsing
```

### Durable selection ownership

Flutter persists:

```text
selectedGoalCode?
selectedTrackCode?
selfAssessedLevelCode?
```

Flutter MUST NOT persist an independent `selectedVerticalCode` as a conflicting source of truth when a Goal exists.

Current Vertical is derived:

```text
selectedGoalCode
→ CURRENT Goal.verticalCode
→ current Vertical
```

### Restart

Onboarding state is persisted after each explicit decision:

```text
Step 1 completed → restart resumes at Step 2
Steps 1–2 completed → restart resumes at Step 3
completed onboarding → onboarding does not reopen automatically
```

### Inactive selection

```text
Track inactive/missing
→ clear Track, preserve active Goal

Goal inactive/missing
→ clear Goal + Track
→ current Vertical becomes unset
→ show Choose learning direction

Vertical inactive/missing
→ invalidate its selected Goal using the same rule
```

Flutter MUST NOT silently switch to another Vertical.

Accent/voice and download choices remain in Settings/Download flows.

Detailed rules are normative in [`CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`](CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md).

---

## 6. Home

Priority:

```text
Continue current/last item
Current Vertical / Goal / Track
Review due
Browse current track/collections
Choose learning direction when Goal is unset
Secondary statistics
```

No recommendation engine is required.

`Recommended` may only mean deterministic editorial order or local continuation logic.

---

## 7. Learn

MVP discovery:

```text
Current Vertical / Goal / Track
Verticals
Collections
Categories
Browse / Search
```

Search and learner-state filters remain available.

Vertical/Goal/Track selections may be changed from Learn or Settings under the same ownership rules used by onboarding.

Do not make technical content types the only navigation model.

---

## 8. Material Design 3 / adaptive UI

One design system only:

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

Keep custom components small and evidence-driven. No second visual framework.

Onboarding Step 1 may adapt between stacked cards and master/detail presentation, but product state and selection semantics remain identical.

---

## 9. Learner-facing copy

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

Raw HTTP/database/storage exceptions are not shown directly.

Empty/error states should state the problem and a safe next action where possible.

---

## 10. Installation identity

```text
random installationId
→ backend registration
→ backend-issued token
→ Secure Storage
```

No learner account.

Credential-specific `401` recovery:

```text
clear rejected token only
→ preserve installationId + learner state
→ re-register once
→ retry safe request once where policy permits
→ fail closed if rejected again
```

The same installation credential boundary protects JSON API and learner media authorization.

---

## 11. Offline-first startup

```text
open Drift/filesystem
→ load local settings/goal/track
→ load secure credential
→ load CURRENT metadata
→ validate Goal/Track against CURRENT Vertical hierarchy
→ load learner progress/review
→ render usable UI
→ recover interrupted work
→ check backend when available
```

Network is not required to use valid cached learning content or to resume onboarding when a valid CURRENT catalogue exists.

If no usable catalogue has ever been synchronized and backend is unavailable, onboarding shows a recoverable connectivity state and does not invent Vertical/Goal options.

---

## 12. Synchronization

High-level flow:

```text
CHECK LOCAL
→ CHECK REMOTE
→ PLAN
→ STAGE
→ VERIFY
→ ATOMIC CURRENT SWITCH
→ CLEAN
```

A failed update never replaces the last-known-good CURRENT snapshot.

Backend-owned catalogues are synchronized as local projections, including Vertical/Goal/Track/Collection ownership.

---

## 13. Localization

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where applicable
```

UI strings are Flutter ARB/gen-l10n.

Content translations/hints/explanations come from backend locale payloads.

Root identity is locale-independent.

Missing optional `hint`, `translation` or `explanation` does not block canonical English content. UI does not render an empty hint affordance when no resolved hint exists.

---

## 14. Local persistence

Drift separates:

```text
SYSTEM/SYNC
PRODUCT CONTENT/CACHE
LOCAL LEARNER STATE
```

Local learner state includes:

```text
onboarding completion/progress
selected Goal/Track/Level
favorites
LISTENED / COMPLETED
review schedule
test history
playback progress
```

Current Vertical is derived from CURRENT catalogue + selected Goal and is not persisted as a competing durable preference.

Cache cleanup never erases learner state.

---

## 15. Download / assets

`DownloadManager` owns bounded download, retry, temp file, size/checksum verification and atomic final placement.

`AssetResolver` returns verified local assets to playback/feature code.

The exact remote media delivery transport is frozen separately under BA-17. Until then, Flutter business requirements rely only on these invariants:

```text
Backend authorizes learner media access
Flutter receives no storage credentials
Flutter does not use deliveryKey as a remote locator
Flutter verifies size/SHA-256 before trusting local bytes
verified local assets remain usable offline
```

Metadata sync does not automatically download all optional media.

---

## 16. Audio

Shared playback supports:

```text
play/pause/stop/seek
speed
repeat
skip
segment repeat when segment metadata exists
qualified completion
```

UI does not persist `LISTENED` directly; application logic does.

No STT/pronunciation scoring in MVP.

---

## 17. Learner markers

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

---

## 18. Assessment

Modes:

```text
LEARN
EXAM
QUICK
```

Persist:

```text
test attempt
exact test revision
question revisions/snapshots
selected answers
current position
score/result
```

Completion view may show:

```text
score
correct/incorrect answers
explanations
skillCode where available
simple next-practice link
```

No complex recommendation engine is required.

Detailed mode/scoring/retake policy is frozen under BA-06.

---

## 19. Review scheduler

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

Possible outcomes:

```text
incorrect
hard
correct
known
```

Scheduling is deterministic/local and survives restart/cache cleanup. Exact interval policy is frozen under BA-07.

---

## 20. Storage retention

Disposable storage uses:

```text
TTL + LRU + quota + explicit-download protection + reference-safe deletion
```

Learner state is never deleted by cache cleanup.

A deleted disposable local asset is a recoverable cache miss and may be restored only through the authorized learner media path.

---

## 21. Failure/recovery

Must preserve useful local state through:

```text
backend offline
backend media/storage failure
interrupted sync/download
checksum mismatch
401 recovery
process kill during onboarding/test/audio/review
storage pressure
Drift migration
```

Flutter never attempts a credentialed direct object-storage fallback.

---

## 22. Acceptance

MVP mobile acceptance proves:

```text
Vertical → Goal → Track → Collection ownership
3-step onboarding with Vertical + Goal at Step 1
onboarding complete/skip/restart
skip without fabricated learning direction
selected Goal/Track persistence
current Vertical derived from selected Goal
inactive Track clears Track only
inactive Goal/Vertical clears Goal + Track without cross-Vertical fallback
CURRENT atomic sync
locale switch/offline reopen
real audio/local asset resolution
FAVORITE/LISTENED/COMPLETED persistence
Due based only on nextReviewAt
review survives restart/cache cleanup
test attempt restoration
Home starts with Continue/current learning context
Home exposes Choose learning direction when no Goal is selected
Learn exposes Vertical/Goal/Track/Collection discovery
adaptive/light/dark/RTL/large-text behavior
storage cleanup preserves learner state
learner-facing copy contains no implementation terminology
```

Prefer a small explicit implementation over additional abstraction layers.
