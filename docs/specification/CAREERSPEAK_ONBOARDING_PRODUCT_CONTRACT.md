# CareerSpeak — Onboarding Product Contract

**Document version:** 1.0  
**Status:** Normative MVP product contract  
**Applies to:** CareerSpeak v1  

## 1. Purpose

This document freezes BA-01 and BA-02 product decisions for the learner hierarchy and first-run onboarding.

The normative learner hierarchy is:

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

`Vertical` is a backend-owned subject/professional learning area. `LearningGoal` is a learner intention inside exactly one Vertical.

Examples:

```text
JAVA
  → JOB_INTERVIEW
  → JAVA_SENIOR_INTERVIEW
  → SPRING_INTERVIEW

MEDICAL_ENGLISH
  → PATIENT_COMMUNICATION
  → MEDICAL_B1
  → PATIENT_HISTORY
```

A Vertical is data, not a Flutter enum. Adding a new Vertical does not require a compatible Flutter release unless it introduces a new executable content capability.

## 2. Ownership and identity

Backend owns:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
all active/inactive and sort-order product truth
```

Flutter owns only learner selections/preferences and locally synchronized projections.

Each active `LearningGoal` belongs to exactly one active `Vertical` in a learner-deliverable snapshot.

### Durable selection rule

Flutter SHALL persist:

```text
selectedGoalCode?
selectedTrackCode?
selfAssessedLevelCode?
translationLocale
uiLocale
onboardingCompleted
```

Flutter SHALL NOT persist an independent `selectedVerticalCode` as a second source of truth when a Goal is selected.

Current Vertical is derived deterministically:

```text
selectedGoalCode
  → CURRENT LearningGoal.verticalCode
  → current Vertical
```

This prevents impossible state such as:

```text
selectedVertical = JAVA
selectedGoal = MEDICAL_PATIENT_COMMUNICATION
```

A transient UI navigation selection may contain a Vertical code, but it is not the durable learner preference source of truth.

## 3. Three-step onboarding

MVP onboarding remains exactly three learner decisions:

```text
Step 1 — Learning direction
         Vertical + LearningGoal

Step 2 — Approximate English level
         B1 / B2 / C1 / Not sure

Step 3 — Support language
         Backend-published SupportedLocale
```

No account, accent/voice choice, download choice, notification permission or profile questionnaire is added to onboarding.

## 4. Step 1 — Learning direction

The learner-facing question is conceptually:

> What do you want to practise?

The UI may first show Vertical cards and then Goal choices inside the selected Vertical, but this remains one onboarding step and one product decision.

Examples of learner-facing entries:

```text
Java interviews
DevOps interviews
Medical English
Workplace English
IELTS
```

The exact presentation may be cards, a master/detail layout or an adaptive two-stage selector. Business semantics do not change with layout.

Rules:

1. Only `active` Verticals with at least one active Goal are selectable.
2. Only active Goals belonging to the selected Vertical are selectable.
3. Backend `sortOrder`, then stable code, determines deterministic ordering.
4. A Goal code is the durable selection identity.
5. Vertical is derived from the selected Goal after selection.
6. A Vertical with zero active Goals is not offered as a selectable onboarding destination.
7. Unknown or malformed parent/child relationships fail closed and are never offered.

## 5. Step 2 — English level

Allowed learner choices:

```text
B1
B2
C1
Not sure
```

The actual backend Level catalogue remains backend-owned. The onboarding UI maps only currently supported learner-facing level choices to stable level codes.

`Not sure` stores no invented level and must not block browsing.

The level is a preference/filtering hint, not an authorization boundary and not a mandatory prerequisite for content access.

## 6. Step 3 — Support language

The support-language list comes from the current backend-owned `SupportedLocale` catalogue.

Only active locales that are translation-supported for the current product policy are selectable.

The selected support language becomes `translationLocale`.

`uiLocale` remains independent and follows the globalization contract. Selecting a support language MUST NOT silently change UI locale unless the learner explicitly chooses that UI locale through supported application settings.

Missing optional localized fields such as `hint`, `translation` or `explanation` do not make canonical English content unavailable.

## 7. Skip policy

Onboarding is skippable from every step.

Skip SHALL:

```text
set onboardingCompleted = true
preserve any decisions already explicitly made
leave missing Goal/Track/Level preferences unset
select a deterministic support-language fallback only when needed for application operation
open normal Browse/Home experience
```

Skip MUST NOT silently choose an arbitrary career Vertical or Goal.

If no Goal is selected, the app opens in browse mode and invites the learner to choose a learning direction without blocking access to compatible catalogue browsing.

## 8. Restart safety

Onboarding progress is persisted after each explicit learner decision.

After process kill/restart:

```text
completed Step 1 → resume at Step 2
completed Steps 1–2 → resume at Step 3
completed onboarding → do not reopen onboarding automatically
```

The app SHALL validate saved stable codes against CURRENT backend-owned catalogue projections before resuming.

A partially completed onboarding flow must never create a contradictory Goal/Vertical relationship.

## 9. Inactive/deleted selection policy

When a previously selected item is no longer learner-deliverable:

### Selected Track inactive or missing

```text
clear selectedTrackCode
preserve selectedGoalCode if still active
show current Goal and allow learner to choose another Track
```

Do not silently switch to another Track as durable preference.

### Selected Goal inactive or missing

```text
clear selectedGoalCode
clear selectedTrackCode
therefore current Vertical becomes unset
show "Choose learning direction"
```

Do not silently move the learner to another Goal or another Vertical.

### Vertical inactive

Because Vertical is derived from Goal, an inactive/missing parent invalidates that Goal selection using the same rule above.

The application remains usable in browse/offline mode where valid CURRENT content is still available under retention/publication rules.

## 10. Track selection

Track selection is intentionally not a fourth onboarding step.

After onboarding, the learner may select a Track from Home/Learn/Goal detail. If a Goal has exactly one active Track, the UI MAY auto-focus or present it as the obvious next action, but durable `selectedTrackCode` is written only under deterministic product policy or explicit user action.

The product must not require a Track to declare onboarding complete.

## 11. Home after onboarding

After completion:

```text
selected Goal exists
  → Home shows current Vertical/Goal context and next learning action

no selected Goal
  → Home shows Choose learning direction + Browse
```

Home must not manufacture a default career direction merely to fill the page.

## 12. Offline behavior

If CURRENT catalogue data is available locally, onboarding and selection validation use that CURRENT snapshot without requiring network access.

If the application has never synchronized a usable catalogue and backend is unavailable, onboarding shows a recoverable connectivity state and does not fabricate Vertical/Goal options.

A previously completed onboarding is not reset merely because a network request fails.

## 13. Analytics-neutral product events

If minimal telemetry is approved later, the product vocabulary SHALL distinguish:

```text
onboarding_started
learning_direction_selected
level_selected
support_language_selected
onboarding_skipped
onboarding_completed
```

No event is required for this contract to be implemented; this section only freezes terminology.

## 14. Acceptance scenarios

### Positive

1. User selects JAVA → JOB_INTERVIEW, B2, ru and completes onboarding.
2. User selects MEDICAL_ENGLISH → PATIENT_COMMUNICATION and restarts after Step 1; Step 2 resumes.
3. User selects a Goal; current Vertical is derived from Goal without an independent persisted Vertical preference.
4. User skips at Step 1; Home opens in browse mode with no fabricated Goal.
5. User completes onboarding offline using valid CURRENT catalogue data.

### Negative / fail-closed

1. Goal references wrong/nonexistent Vertical → option is not selectable.
2. Vertical has no active Goals → not offered as an onboarding destination.
3. Saved Goal becomes inactive → Goal and Track preference are cleared; no silent cross-Vertical fallback occurs.
4. Saved Track becomes inactive while Goal remains active → Track is cleared, Goal is preserved.
5. Unsupported/missing support locale → deterministic locale fallback applies without hiding canonical English content.
6. Process dies between decisions → no partial contradictory state is committed.

## 15. Definition of Done

BA-01 and BA-02 are closed when:

```text
Product Requirements use Vertical → Goal → Track → Collection
System Requirements use the same hierarchy
Mobile Requirements use the same hierarchy
onboarding is consistently defined as 3 steps
Step 1 is Vertical + Goal
selected Vertical is derived from Goal
skip/restart rules are normative
inactive-selection behavior is normative
positive + negative acceptance tests are traceable to these rules
```
