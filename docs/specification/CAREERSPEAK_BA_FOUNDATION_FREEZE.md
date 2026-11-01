# CareerSpeak — BA Foundation Freeze (BA-01 / BA-02 / BA-03)

**Status:** Normative remediation decision record  
**Applies to:** CareerSpeak v1 remediation stream

## 1. Purpose

This document records the final product decisions for BA-01, BA-02 and BA-03 and resolves any earlier draft wording in `CAREERSPEAK_BA_REMEDIATION_ROADMAP.md`.

If the earlier roadmap conflicts with the normative contracts listed below, this freeze and those contracts take precedence.

Normative contracts:

- `CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`
- `CAREERSPEAK_LEARNER_SELECTION_CONTRACT.md`
- updated Product/System/Mobile requirements in this branch

## 2. Frozen hierarchy

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

`Vertical` is backend-owned data and is not a Flutter enum.

## 3. Frozen onboarding

Exactly three learner decisions:

```text
1. Learning direction → Vertical + Goal
2. Approximate English level → B1/B2/C1/Not sure
3. Support language → SupportedLocale
```

Track selection is not a fourth onboarding step.

## 4. Frozen durable selection ownership

Persist:

```text
selectedGoalCode?
selectedTrackCode?
selfAssessedLevelCode?
```

Do not persist an independent `selectedVerticalCode` source of truth.

Current Vertical is derived from selected Goal and CURRENT catalogue data.

## 5. Frozen normalization policy

Normalization only removes invalid pointers. It never invents a replacement learning direction.

```text
Track invalid/missing/inactive/wrong parent
→ clear Track only
→ preserve valid Goal

Goal invalid/missing/inactive
→ clear Goal + Track

Goal parent Vertical invalid/missing/inactive
→ clear Goal + Track
```

Explicitly superseded draft behavior:

```text
Track inactive → first active Track     ❌
Goal inactive  → first active Goal      ❌
```

There is no silent sibling fallback.

## 6. Explicit user selection

An explicit learner action may choose another Goal or Track after validation against CURRENT.

Explicit selection and automatic normalization are different operations and must not be conflated.

## 7. Repository ownership

```text
LearnerStateRepository
→ FAVORITE / LISTENED / COMPLETED / playback

LearnerSelectionRepository
→ Goal / Track / Level

AppPreferencesRepository
→ UI locale / translation locale / accent / theme / storage preferences
```

Selection changes do not erase historical learner state.

## 8. Runtime normalization points

One logical normalization policy is reused at:

```text
bootstrap
CURRENT publication activation
onboarding resume
Home/Learn learner-context construction
explicit selection mutation boundary
```

Widgets do not implement private fallback logic.

## 9. Offline rule

Valid local CURRENT is sufficient for selection validation and normalization.

Temporary backend unavailability does not clear a previously valid selection merely because remote validation cannot occur.

## 10. Concurrency rule

A stale normalization computed from older state/publication must never overwrite a newer valid explicit learner choice.

Implementation must prove this with generation/CAS, serialization, re-read-before-commit or an equivalent deterministic mechanism.

## 11. Foundation readiness

BA-01/02/03 are considered analytically frozen when:

```text
[ ] hierarchy is Vertical → Goal → Track → Collection everywhere normative
[ ] onboarding uses the final 3-step contract
[ ] Goal is the durable source from which current Vertical is derived
[ ] LearnerSelection has a dedicated ownership boundary
[ ] normalization table is unique and deterministic
[ ] no silent sibling fallback remains in implementation requirements
[ ] offline/restart/publication-change semantics are defined
[ ] stale normalization race is explicitly tested
```

After these decisions, Flutter implementation may proceed without inventing selection behavior inside UI code.
