# CareerSpeak — Learner Selection Ownership & Normalization Contract

**Document version:** 1.0  
**Status:** Normative MVP product contract  
**Applies to:** CareerSpeak v1  
**BA item:** BA-03

## 1. Purpose

This document freezes learner-selection ownership and normalization after BA-01/BA-02.

The catalogue hierarchy is:

```text
Vertical
  ↓
LearningGoal
  ↓
LearningTrack
  ↓
LearningCollection
```

The learner may have no current selection. An absent selection is a valid product state and must not be repaired by inventing a default career direction.

## 2. Durable source of truth

Flutter persists only learner-owned stable selections:

```text
selectedGoalCode: String?
selectedTrackCode: String?
selfAssessedLevelCode: String?
```

`selectedVerticalCode` is NOT an independent durable preference.

Current Vertical is derived from the CURRENT catalogue:

```text
selectedGoalCode
  → LearningGoal.verticalCode
  → currentVerticalCode
```

This prevents contradictory durable states.

## 3. Selection invariants

A normalized learner selection must satisfy all applicable invariants:

```text
selectedGoalCode == null
→ selectedTrackCode == null

selectedGoalCode != null
→ Goal exists in CURRENT
→ Goal.active == true
→ Goal parent Vertical exists in CURRENT
→ Vertical.active == true

selectedTrackCode != null
→ selectedGoalCode != null
→ Track exists in CURRENT
→ Track.active == true
→ Track.goalCode == selectedGoalCode
→ Track.verticalCode == selected Goal.verticalCode
```

A malformed CURRENT graph remains a catalogue/publication defect and fails closed. The learner-selection normalizer does not repair broken backend ancestry.

## 4. Normalization ownership

There is one logical normalization policy used by:

```text
application bootstrap
CURRENT publication activation
onboarding resume
Home/Learn selection read model
explicit Goal/Track changes
```

UI widgets must not implement competing fallback rules.

The normalization service consumes:

```text
persisted learner selection
+
CURRENT UniversalCatalogueGraph
```

and returns a normalized selection plus optional reason metadata for UI/telemetry.

Conceptual result:

```text
LearnerSelectionNormalizationResult
├── selectedGoalCode?
├── selectedTrackCode?
├── derivedVerticalCode?
├── changed: bool
└── reason?
```

Reason codes are implementation-facing and should be stable if persisted/telemetried, e.g.:

```text
GOAL_MISSING
GOAL_INACTIVE
VERTICAL_MISSING
VERTICAL_INACTIVE
TRACK_MISSING
TRACK_INACTIVE
TRACK_WRONG_GOAL
TRACK_WRONG_VERTICAL
```

## 5. Deterministic normalization table

| Persisted state | CURRENT state | Normalized result |
|---|---|---|
| Goal null, Track null | any valid graph | unchanged |
| Goal null, Track set | any graph | clear Track |
| Goal valid, Track null | valid active Goal/Vertical | unchanged |
| Goal valid, Track valid child | valid active ancestry | unchanged |
| Goal valid, Track missing/inactive | Goal remains valid | clear Track only |
| Goal valid, Track belongs to another Goal | Goal remains valid | clear Track only |
| Goal missing/inactive | any Track | clear Goal + Track |
| Goal parent Vertical missing/inactive | any Track | clear Goal + Track |
| Graph malformed / duplicate identity | invalid publication/read model | fail closed; do not invent selection |

No rule selects the first active sibling automatically.

## 6. Explicit user changes

### Selecting a Goal

When the learner explicitly selects Goal G:

```text
validate G exists/active in CURRENT
validate G parent Vertical exists/active
persist selectedGoalCode = G
if existing selectedTrackCode does not belong to G
  → clear selectedTrackCode
```

Selecting a Goal does not automatically select a Track.

### Selecting a Track

When the learner explicitly selects Track T:

```text
validate T exists/active in CURRENT
validate T Goal exists/active
validate T Vertical ancestry is consistent
persist selectedGoalCode = T.goalCode
persist selectedTrackCode = T.code
```

This is an explicit learner action, not normalization fallback.

### Clearing learning direction

The learner may intentionally clear/change direction:

```text
clear selectedGoalCode
clear selectedTrackCode
```

Historical progress/favorites/test attempts remain untouched.

## 7. Publication change semantics

When CURRENT changes N → N+1:

```text
1. atomically activate validated catalogue snapshot
2. read learner selection
3. normalize against new CURRENT graph
4. persist only required selection clears
5. preserve all unrelated learner state
```

Normalization may remove now-invalid pointers but must never:

```text
choose another Goal
choose another Vertical
rewrite progress history
rewrite completion history
rewrite favorites
rewrite test attempts
```

If normalization persistence cannot complete safely, startup/publication handling must remain deterministic and must not expose a contradictory selection to UI.

## 8. Offline/restart semantics

If a valid CURRENT graph exists locally:

```text
restart offline
→ normalize against local CURRENT
→ render usable learner experience
```

Network availability is not required to validate durable Goal/Track selections.

If no usable CURRENT graph exists:

```text
selection cannot be positively validated
→ do not fabricate a normalized alternative
→ preserve durable learner data where safe
→ render recoverable catalogue/connectivity state
```

A temporary backend failure alone does not clear a previously valid selection.

## 9. Onboarding interaction

BA-02 uses the same selection contract.

Step 1 commits an explicit Goal selection. Vertical is derived.

On onboarding resume:

```text
load CURRENT graph
→ normalize saved selection
→ determine next onboarding step
```

If the previously selected Goal became invalid before onboarding completed:

```text
clear Goal + Track
→ return to Step 1
```

If only Track became invalid, onboarding is unaffected because Track is not required for onboarding completion.

## 10. Home semantics

### Goal selected

Home may show:

```text
current Vertical
current Goal
selected Track when present
Continue / next action
```

### Goal not selected

Home shows:

```text
Choose learning direction
Browse learning areas
```

Home must not manufacture a default Goal to avoid an empty card.

## 11. Learn semantics

Learn is always capable of catalogue discovery independent of whether a current Goal exists.

With a Goal selected:

```text
prioritize current Vertical/Goal context
```

Without a Goal selected:

```text
show Vertical discovery
```

Changing Goal or Track uses the explicit-user-change rules from this contract.

## 12. Historical learner-state isolation

Selection is a navigation/preference pointer, not ownership of learner history.

Therefore clearing/changing selection MUST NOT delete:

```text
favorites
LISTENED markers
COMPLETED markers
review history
test attempts
playback history
```

Historical entries remain keyed by their own content/test identities and revisions.

## 13. Concurrency and atomicity

Concurrent events may include:

```text
publication activation
user changes Goal
app restart/bootstrap
settings/reset action
```

The persisted result must satisfy the invariants in section 3.

Preferred implementation rule:

```text
selection mutation + invariant validation
→ serialized/transactional repository boundary
```

At minimum, stale normalization based on CURRENT N must not overwrite an explicit learner selection made against CURRENT N+1.

## 14. Acceptance scenarios

### Positive

1. Goal + valid child Track survive restart unchanged.
2. Goal without Track is a valid stable state.
3. Explicit Track selection also aligns Goal to the Track parent.
4. Changing Goal clears incompatible Track.
5. Offline restart with valid CURRENT preserves selection.

### Negative / normalization

1. orphan Track with Goal null → Track cleared.
2. missing/inactive Track with valid Goal → Track cleared only.
3. Track from different Goal → Track cleared only.
4. missing/inactive Goal → Goal + Track cleared.
5. inactive/missing Vertical parent → Goal + Track cleared.
6. malformed graph → fail closed, no sibling auto-selection.
7. backend temporarily unavailable while local CURRENT is valid → selection is not cleared.

### Adversarial / race

1. normalization of old publication races with explicit Goal change on new publication → explicit new valid selection wins; stale normalization must not overwrite it.
2. process dies after Goal write but before Track clear → repository/bootstrap normalization restores valid invariant.
3. repeated normalization is idempotent.
4. publication N+1 repeatedly reopened produces the same normalized selection.

## 15. Required test layers

### Unit/domain

- normalization table exhaustive tests;
- derived Vertical tests;
- idempotency;
- explicit Goal/Track mutation invariants.

### Repository/persistence

- atomic/serialized Goal+Track mutation;
- reopen/restart preservation;
- crash/recovery from inconsistent legacy state;
- publication-version race protection.

### Widget

- Home no-selection state;
- Home selected context;
- Learn discovery with/without selection;
- Goal change clears incompatible Track in visible UI.

### E2E

```text
select JAVA / JOB_INTERVIEW / JAVA_SENIOR
→ restart offline
→ same context
→ activate publication where JAVA_SENIOR inactive
→ Track cleared, Goal preserved
→ activate publication where JOB_INTERVIEW inactive
→ Goal + Track cleared
→ Home asks learner to choose direction
```

## 16. Definition of Done

BA-03 is closed when:

```text
[ ] one durable selection model exists
[ ] selectedVerticalCode is not a competing source of truth
[ ] one normalization policy is used across bootstrap/publication/onboarding/Home/Learn
[ ] inactive/missing Track clears Track only
[ ] inactive/missing Goal/Vertical clears Goal + Track
[ ] no normalization rule silently chooses a sibling Goal/Track/Vertical
[ ] explicit user Goal/Track changes preserve invariants
[ ] historical learner state survives selection changes
[ ] offline/restart behavior is deterministic
[ ] repeated normalization is idempotent
[ ] race/atomicity acceptance is defined
[ ] unit/repository/widget/E2E traceability exists
```
