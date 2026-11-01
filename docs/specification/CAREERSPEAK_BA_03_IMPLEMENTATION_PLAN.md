# CareerSpeak — BA-03 Learner Selection Implementation Plan

**Status:** Ready for implementation  
**Scope:** learner Goal/Track ownership, normalization, persistence and UI integration  
**Normative parent:** `CAREERSPEAK_LEARNER_SELECTION_CONTRACT.md`

## 1. Current runtime gap

Current production Flutter already has:

```text
UniversalCatalogueRepository
LearnerStateRepository
AppPreferencesRepository
```

but the existing `LearnerStateRepository` owns content markers/playback only:

```text
favorite
listened
completed
playback position
```

and `AppPreferencesRepository` owns UI/locale/theme/storage preferences.

Neither is the correct owner for Goal/Track learning selection.

Therefore BA-03 introduces a separate learner-selection boundary instead of overloading content progress or generic application preferences.

## 2. New domain model

Add a small immutable domain model, conceptually:

```text
LearnerSelection
├── selectedGoalCode: String?
├── selectedTrackCode: String?
└── selfAssessedLevelCode: String?
```

Do not add `selectedVerticalCode` as durable state.

Optional onboarding-progress fields should remain separate or clearly grouped with onboarding state; they are not required to define selection identity.

## 3. New application port

Introduce:

```text
LearnerSelectionRepository
```

Recommended capabilities:

```dart
Stream<Result<LearnerSelection>> watchSelection();
Future<Result<LearnerSelection>> getSelection();
Future<Result<void>> selectGoal(String? goalCode);
Future<Result<void>> selectTrack(String? trackCode);
Future<Result<void>> setSelfAssessedLevel(String? levelCode);
Future<Result<void>> replaceNormalized(LearnerSelection selection);
```

Prefer higher-level invariant-preserving mutations over generic arbitrary field updates.

`selectTrack(trackCode)` application service must validate/align the parent Goal before committing.

## 4. Persistence

Add a dedicated Drift learner-selection row/table or an equivalent durable record.

Recommended logical columns:

```text
id = 1
selected_goal_code nullable
selected_track_code nullable
self_assessed_level_code nullable
updated_at
revision/generation if needed for stale-write protection
```

Constraints possible locally:

- singleton row;
- nonblank stable codes when non-null.

Parent/active validation cannot be expressed only as static DB FK because CURRENT catalogue revisions change. It belongs to the normalization/application boundary.

Migration must preserve existing learner markers/preferences.

## 5. Selection normalizer

Introduce one application service, e.g.:

```text
LearnerSelectionNormalizer
```

Inputs:

```text
LearnerSelection persisted
UniversalCatalogueGraph CURRENT
```

Output:

```text
normalized LearnerSelection
changed flag
reason(s)
derivedVerticalCode?
```

Rules are exactly the BA-03 normalization table:

```text
Goal null + Track set
→ clear Track

Goal valid + Track invalid/missing/wrong parent
→ preserve Goal, clear Track

Goal invalid/missing/inactive
→ clear Goal + Track

Goal parent Vertical invalid/missing/inactive
→ clear Goal + Track
```

No sibling auto-selection.

Normalization must be idempotent.

## 6. Explicit selection service

Do not make UI call the repository with unchecked codes.

Recommended application service:

```text
LearnerSelectionService
```

Operations:

```text
chooseGoal(goalCode, CURRENT graph)
chooseTrack(trackCode, CURRENT graph)
clearDirection()
setLevel(levelCode?)
normalize(CURRENT graph)
```

### chooseGoal

```text
validate Goal + parent Vertical active
persist Goal
clear incompatible Track
```

### chooseTrack

```text
validate Track + Goal + Vertical ancestry
persist Goal = Track.goalCode
persist Track = Track.code
```

### clearDirection

```text
clear Goal + Track
preserve level and all historical learner state
```

## 7. Bootstrap integration

Target startup order:

```text
open Drift
→ load CURRENT catalogue
→ load learner selection
→ normalize selection against CURRENT
→ persist normalization if changed
→ expose normalized state to Home/Learn/router/onboarding
```

If CURRENT is unavailable but an earlier valid CURRENT exists locally, use it.

If there is no usable CURRENT catalogue, do not clear selection merely because remote validation cannot occur.

## 8. Publication activation integration

After successful CURRENT snapshot switch:

```text
CURRENT N+1 activated
→ normalize learner selection against N+1
→ persist required clears
→ invalidate/rebuild learner context providers
```

This process must not affect:

```text
favorites
content markers
review state
attempt history
playback history
```

## 9. Stale-write / race protection

Critical race:

```text
normalizer reads old selection/current N
learner explicitly chooses Goal B on N+1
old normalization writes later
```

Old normalization must not overwrite the new explicit selection.

Recommended options:

1. repository generation/version compare-and-set; or
2. serialize selection mutations through one application-level mutex/queue; or
3. transaction + re-read before commit.

The implementation must have an adversarial test proving last valid explicit learner action cannot be replaced by stale normalization.

## 10. Riverpod/provider integration

Introduce production providers for:

```text
LearnerSelectionRepository
LearnerSelectionService
learnerSelectionProvider
normalizedLearnerContextProvider
```

`normalizedLearnerContextProvider` may expose:

```text
selection
currentVertical?
currentGoal?
currentTrack?
```

This read model is derived; only stable selection codes are durable.

## 11. Onboarding integration

Step 1 uses `chooseGoal`.

Step 2 uses `setLevel`.

On resume:

```text
CURRENT graph
+
saved learner selection
→ normalize
→ compute correct onboarding step
```

An invalid Goal returns onboarding to Step 1.

Track is not required for onboarding completion.

## 12. Home integration

Home reads only normalized learner context.

```text
Goal exists
→ current Vertical + Goal context

Goal absent
→ Choose learning direction
```

Home must never perform its own fallback selection.

## 13. Learn integration

Learn remains browsable with no selection.

When user changes Goal/Track from Learn:

```text
UI action
→ LearnerSelectionService
→ validated repository mutation
→ provider refresh
```

No direct persistence from widgets.

## 14. Existing repository boundaries remain intact

Do not expand `LearnerStateRepository` to carry navigation selection. It remains content-state oriented.

Do not put Goal/Track into `AppPreferencesRepository`; locale/theme/storage preferences remain separate.

Target ownership:

```text
LearnerStateRepository
→ content progress/markers/playback

LearnerSelectionRepository
→ Goal/Track/Level

AppPreferencesRepository
→ locale/theme/accent/storage UI preferences
```

## 15. Test plan

### Domain/unit

- every row of normalization table;
- derived Vertical;
- null Goal implies null Track;
- idempotent normalization;
- explicit Goal selection clears incompatible Track;
- explicit Track selection aligns parent Goal;
- clearing direction preserves Level according to product rule.

### Repository

- default empty selection;
- Goal/Track/Level persist and reopen;
- atomic Goal+Track replacement;
- legacy inconsistent row is recoverable;
- migration preserves content markers/preferences;
- generation/CAS or serialization stale-write protection.

### Application

- normalization after publication switch;
- no remote network needed when CURRENT exists;
- no CURRENT → do not destructively clear unverifiable selection;
- malformed catalogue graph fails closed.

### Widget

- Home with selection;
- Home without selection;
- Learn with/without selection;
- Goal change visibly clears incompatible Track;
- no silent sibling selection.

### E2E

```text
fresh install
→ select JAVA / JOB_INTERVIEW
→ choose JAVA_SENIOR track
→ restart offline
→ same selection
→ publication inactivates JAVA_SENIOR
→ Track cleared only
→ Goal remains
→ publication later inactivates JOB_INTERVIEW
→ Goal + Track cleared
→ Home displays Choose learning direction
```

### Race/adversarial

```text
normalization based on old state starts
→ learner chooses another valid Goal
→ stale normalization completes
→ learner's newer explicit Goal remains
```

## 16. Suggested implementation slices

```text
S1  LearnerSelection domain + repository port
S2  Drift schema/repository + migration tests
S3  LearnerSelectionNormalizer exhaustive tests
S4  LearnerSelectionService explicit mutations
S5  bootstrap + publication normalization
S6  Riverpod normalized learner context
S7  Home/Learn integration
S8  onboarding Step 1/Step 2 integration
S9  restart/offline/race E2E qualification
```

Keep all slices in the eventual implementation feature stream unless there is a concrete release-management reason to split branches.

## 17. Definition of Done

```text
[ ] separate LearnerSelectionRepository exists
[ ] no selectedVerticalCode durable duplicate exists
[ ] Drift persists Goal/Track/Level
[ ] one normalizer implements the normative table
[ ] normalization is idempotent
[ ] explicit user mutation is validated against CURRENT
[ ] stale normalization cannot overwrite newer explicit selection
[ ] bootstrap normalizes against local CURRENT
[ ] publication activation normalizes against new CURRENT
[ ] Home/Learn consume normalized context
[ ] onboarding reuses same selection service
[ ] content progress/preferences are unaffected
[ ] unit/repository/widget/E2E/adversarial tests prove the contract
```
