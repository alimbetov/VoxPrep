# CareerSpeak — BA-01 / BA-02 Implementation Plan

**Status:** Ready for implementation  
**Scope:** Vertical normative hierarchy + final three-step onboarding  

## 1. Contract status

The product contract is now frozen as:

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

Onboarding is exactly:

```text
Step 1  Learning direction → Vertical + Goal
Step 2  Approximate English level → B1 / B2 / C1 / Not sure
Step 3  Support language → active SupportedLocale
```

No independent durable `selectedVerticalCode` is introduced. Current Vertical is derived from selected Goal.

## 2. Current implementation gap

Current Flutter onboarding is locale-only:

```text
/onboarding/locale
→ country selection
→ locale selection
→ Home
```

Current `ApplicationPreferences.needsLocaleOnboarding` is derived only from `countryCode == null`.

Therefore the current runtime does not yet satisfy the normative product contract.

## 3. Required Flutter state model

Introduce an onboarding state that is separate from generic UI preferences.

Minimum durable state:

```text
onboardingCompleted: bool
selectedGoalCode: String?
selectedTrackCode: String?
selfAssessedLevelCode: String?
translationLocale: existing preference
```

Recommended ownership:

- `ApplicationPreferences` continues to own UI/theme/locale preferences.
- learner learning-selection repository owns Goal/Track/Level.
- onboarding completion/progress may be stored with learner-selection state or in a small dedicated onboarding state repository.
- do not overload `countryCode` as onboarding completion.

## 4. Required router behavior

Replace locale-only redirect semantics with product onboarding state:

```text
onboardingCompleted == false
→ /onboarding

onboardingCompleted == true
→ normal app routes
```

The router must not infer onboarding completion from `countryCode`.

A completed onboarding must not reopen merely because locale capability refresh fails.

## 5. Required Step 1 behavior

Step 1 consumes the CURRENT Universal Catalogue graph.

Presentation:

```text
active Vertical cards
  ↓
active Goals belonging to selected Vertical
```

Rules:

- filter inactive Vertical/Goal;
- hide Vertical with zero active Goals;
- order by `sortOrder`, then stable code;
- wrong-parent or malformed graph entries are fail-closed;
- committing Step 1 stores only selected Goal code;
- current Vertical is derived from Goal ownership.

## 6. Required Step 2 behavior

Choices:

```text
B1
B2
C1
Not sure
```

The implementation must map learner-facing choices to CURRENT backend Level codes where defined.

`Not sure` means no level preference; it is not a synthetic backend code unless the backend catalogue explicitly defines one.

## 7. Required Step 3 behavior

Step 3 uses the current backend-owned locale capability catalogue.

Rules:

- show active translation-supported locales;
- persist `translationLocale`;
- do not silently change `uiLocale`;
- missing localized optional content remains allowed;
- locale fallback remains Backend-owned.

Country may remain a locale-discovery hint if product still needs it, but it is not one of the three normative onboarding decisions and does not determine onboarding completion.

## 8. Skip semantics

Skip from any step:

```text
preserve explicit selections already committed
leave missing Goal/Track/Level unset
complete onboarding
open Home/Browse
```

Skip must not choose first Vertical/Goal automatically.

## 9. Restart semantics

Persist progress after each explicit step.

Suggested durable progress representation:

```text
onboardingCompleted
hasLearningDirection
hasLevelDecision
hasSupportLanguageDecision
```

or an equivalent deterministic representation derived from persisted decisions plus explicit "Not sure" state.

Important: `Not sure` must be distinguishable from "Step 2 was never answered".

## 10. Inactive selection normalization

On CURRENT publication activation or app bootstrap:

```text
selectedTrack invalid
→ clear Track only

selectedGoal invalid OR parent Vertical invalid
→ clear Goal + Track
→ current Vertical unset
```

Do not automatically select the first active sibling/parent alternative.

The learner chooses a new direction explicitly.

## 11. Home/Learn impact

Home:

```text
Goal selected
→ current Vertical/Goal context

Goal unset
→ Choose learning direction
```

Learn must expose Vertical discovery and allow changing learning direction after onboarding.

Changing Goal later applies the same invariant checks and clears an incompatible selected Track.

## 12. Backend impact

No new entity is required beyond the already frozen universal catalogue model.

Backend must guarantee learner-deliverable catalogue consistency:

```text
Goal.verticalCode references existing Vertical
Track.goalCode references existing Goal
Track.verticalCode agrees with Goal.verticalCode
Collection ancestry is consistent
inactive parents do not expose active descendants as learner-selectable paths
```

## 13. Persistence impact

Drift/local persistence must prove:

- Goal selection survives restart;
- Track selection survives restart;
- `Not sure` decision survives restart distinctly from unanswered Step 2;
- onboarding completion survives restart;
- cache cleanup cannot erase these values;
- catalogue sync may normalize invalid selections but cannot invent new selections.

## 14. Acceptance test matrix

### Unit/domain

1. derive Vertical from selected Goal.
2. reject Track whose parent Goal differs.
3. normalize inactive Track by clearing Track only.
4. normalize inactive Goal by clearing Goal + Track.
5. never auto-select another Vertical.
6. distinguish `Not sure` from unanswered level step.

### Repository

1. persist/reopen onboarding progress.
2. persist/reopen Goal/Track/Level.
3. publication change normalizes invalid selections atomically or deterministically during bootstrap.

### Widget

1. Step 1 shows only active Verticals with active Goals.
2. selecting Vertical filters Goals.
3. Step 1 survives long localization / small viewport / large text.
4. Step 2 supports B1/B2/C1/Not sure.
5. Step 3 uses supported locale projection.
6. Skip from all three steps.
7. no empty/invalid parent option becomes interactive.

### E2E

```text
fresh install
→ Step 1 JAVA / JOB_INTERVIEW
→ restart
→ Step 2 B2
→ restart
→ Step 3 ru
→ complete
→ Home shows JAVA / JOB_INTERVIEW context
```

Adversarial:

```text
complete Step 1
→ backend publication inactivates selected Goal
→ restart/sync
→ Goal + Track cleared
→ app requests explicit new direction
→ no cross-Vertical silent selection
```

Skip:

```text
fresh install
→ Skip
→ Home opens
→ no Goal selected
→ Choose learning direction visible
→ Browse remains available
```

Offline:

```text
valid CURRENT catalogue exists
→ restart offline during onboarding
→ remaining steps can use local product/locale projections
```

## 15. Definition of Done

BA-01/BA-02 implementation is complete only when:

```text
[ ] locale-only onboarding is removed/reworked
[ ] onboarding completion is no longer `countryCode != null`
[ ] Step 1 uses Universal Catalogue Vertical + Goal
[ ] selected Vertical is derived from Goal
[ ] Step 2 persists explicit level decision / Not sure
[ ] Step 3 persists support language
[ ] skip is non-blocking and does not fabricate learning direction
[ ] restart resumes correctly
[ ] inactive Goal/Vertical never silently switches domains
[ ] Home/Learn handle no-selection state
[ ] positive, negative, restart, offline and adaptive tests pass
```
