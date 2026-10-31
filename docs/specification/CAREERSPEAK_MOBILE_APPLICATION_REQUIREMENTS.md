# CareerSpeak — Flutter Mobile Application Requirements

**Document version:** 2.3  
**Status:** Normative MVP mobile baseline  
**Applies to:** CareerSpeak v1  
**Target platforms:** Android, iOS

Normative parent:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)

Related contracts:

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

Flutter does not own backend product/catalog truth.

Backend-owned product structure:

```text
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

Minimal hierarchy:

```text
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
Content / PracticeTest
```

No mobile/backend `LearningActivity` entity is required.

The learning loop remains:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

Flutter derives the available actions from content/test capabilities and local learner state.

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
HTTP abstraction
audio abstraction
```

Widgets do not issue raw HTTP/SQL calls.

---

## 4. Navigation

Primary routes include:

```text
/onboarding
/
/learn
/goals/:code
/tracks/:code
/collections/:code
/tests/:code
/review
/favorites
/downloads
/settings
```

Technical content routes may remain for direct navigation.

Resize/process recreation should preserve meaningful route/state.

---

## 5. Onboarding

MVP onboarding asks only:

```text
1. LearningGoal
2. approximate level / Not sure
3. support language
```

Requirements:

```text
skippable
account-free
restart-safe
uses backend-published catalogue values
skip uses deterministic defaults
never blocks normal browsing
```

Accent/voice and download choices remain in Settings/Download flows.

---

## 6. Home

Priority:

```text
Continue current/last item
Current goal/track
Review due
Browse current track/collections
Secondary statistics
```

No recommendation engine is required.

`Recommended` may only mean deterministic editorial order or local continuation logic.

---

## 7. Learn

MVP discovery:

```text
Current track
Collections
Categories
Browse / Search
```

Search and learner-state filters remain available.

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

Raw HTTP/database exceptions are not shown directly.

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
→ retry safe startup once
→ fail closed if rejected again
```

---

## 11. Offline-first startup

```text
open Drift/filesystem
→ load local settings/goal/track
→ load secure credential
→ load CURRENT metadata
→ load learner progress/review
→ render usable UI
→ recover interrupted work
→ check backend when available
```

Network is not required to use valid cached learning content.

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

Backend-owned catalogues are synchronized as local projections.

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
selected goal/track/level
favorites
LISTENED / COMPLETED
review schedule
test history
playback progress
```

Cache cleanup never erases learner state.

---

## 15. Download / assets

`DownloadManager` owns bounded download, retry, temp file, size/checksum verification and atomic final placement.

`AssetResolver` returns verified local assets to playback/feature code.

Metadata sync does not automatically download all media.

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

Scheduling is deterministic/local and survives restart/cache cleanup.

---

## 20. Storage retention

Disposable storage uses:

```text
TTL + LRU + quota + explicit-download protection + reference-safe deletion
```

Learner state is never deleted by cache cleanup.

---

## 21. Failure/recovery

Must preserve useful local state through:

```text
backend offline
CDN failure
interrupted sync/download
checksum mismatch
401 recovery
process kill during onboarding/test/audio/review
storage pressure
Drift migration
```

---

## 22. Acceptance

MVP mobile acceptance proves:

```text
3-step onboarding complete/skip/restart
selected goal/track persistence
CURRENT atomic sync
locale switch/offline reopen
real audio/local asset resolution
FAVORITE/LISTENED/COMPLETED persistence
Due based only on nextReviewAt
review survives restart/cache cleanup
test attempt restoration
Home starts with Continue/current goal
Learn exposes track/collection discovery
adaptive/light/dark/RTL/large-text behavior
storage cleanup preserves learner state
learner-facing copy contains no implementation terminology
```

Prefer a small explicit implementation over additional abstraction layers.
