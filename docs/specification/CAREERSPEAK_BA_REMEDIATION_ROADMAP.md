# CareerSpeak / VoxPrep — BA Product Contract Remediation Roadmap

**Status:** Proposed remediation baseline  
**Branch:** `feat/ba-product-contract-remediation`  
**Purpose:** Close product/business-analysis gaps discovered after merging the universal vertical catalogue foundation into `main`.

---

## 1. Objective

The technical foundation is already strong: universal backend-owned catalogue, offline-first content delivery, immutable publication snapshots, localized payloads, audio/TTS boundaries, adaptive UI and adversarial qualification.

This remediation stream does **not** introduce a new product architecture. Its purpose is to remove remaining product ambiguity before the next large implementation phase.

Primary rule:

```text
one business rule
→ one normative definition
→ one ownership decision
→ measurable acceptance criteria
→ traceable implementation/tests
```

---

## 2. Current product model to freeze

The learner catalogue hierarchy is:

```text
Vertical
 ↓
LearningGoal
 ↓
LearningTrack
 ↓
LearningCollection
 ↓
Ordered CollectionMember
 ├─ exact ContentRevision
 └─ exact PracticeTestRevision
```

Definitions:

- `Vertical` = subject/professional learning domain, e.g. `JAVA`, `DEVOPS`, `MEDICAL_ENGLISH`.
- `LearningGoal` = learner intention/result within one Vertical.
- `LearningTrack` = concrete learning path within one Goal.
- `LearningCollection` = ordered learner unit/topic.
- `CollectionMember` = exact immutable content or assessment revision.

Backend owns catalogue/product truth. Flutter owns local learner state and current local projections.

---

## 3. Priority model

### P0 — contract inconsistencies / blockers

Must be resolved before the next product-domain freeze.

### P1 — important learner-journey gaps

Must be resolved before MVP production acceptance.

### P2 — product maturity / measurement

May be implemented after core learner journeys are stable, but decisions should be recorded now.

---

# 4. P0 remediation backlog

## BA-01 — Make Vertical normative everywhere

### Problem

The Universal Vertical Catalogue uses:

```text
Vertical → Goal → Track → Collection
```

while older Product/System/Mobile requirements still describe:

```text
Goal → Track → Collection
```

### Decision

`Vertical` becomes the normative top-level catalogue dimension for all learner journeys and contracts.

### Required updates

- Product Requirements
- System Requirements
- Mobile Application Requirements
- Cross-system documentation where hierarchy is described
- onboarding stories
- Home/Learn discovery stories
- analytics/event vocabulary

### Acceptance criteria

- no normative document defines Goal as the top-level catalogue root;
- Goal has exactly one Vertical;
- route/backend/catalogue ownership semantics are consistent;
- adding a new Vertical requires no Flutter enum or dedicated screen.

---

## BA-02 — Freeze final onboarding flow

### Problem

Existing normative requirements define three steps as Goal → Level → Support Language, while current Flutter only has locale onboarding and the product now has Vertical.

### Decision

MVP onboarding remains three-step and account-free:

```text
1. Learning direction
   → user-facing Vertical/Goal selection
2. Approximate English level
   → B1 / B2 / C1 / Not sure
3. Support / translation language
   → active backend-published SupportedLocale
```

The first screen may visually combine Vertical and Goal; the persisted business identities remain explicit.

### Rules

- skippable;
- restart-safe;
- no mandatory account;
- inactive selections fall back deterministically;
- browsing is never blocked if onboarding is skipped;
- accent/voice/download preferences remain outside onboarding.

### Acceptance criteria

Positive:

- complete all three steps;
- skip from each step;
- resume after process restart;
- select arbitrary backend-published Vertical/Goal;
- choose `Not sure` level.

Negative/adversarial:

- selected Vertical/Goal becomes inactive between steps;
- locale catalogue unavailable but existing local catalogue exists;
- backend offline after first launch with staged/local values.

---

## BA-03 — Define current learner selection ownership

### Problem

Existing state references `selectedGoalCode` / `selectedTrackCode`, but the product now has Vertical.

### Decision

Do **not** maintain `selectedVerticalCode` as an independent durable source of truth when Goal has exactly one Vertical.

Normative relation:

```text
selectedGoalCode
→ Goal.verticalCode
→ current Vertical
```

`selectedTrackCode` must belong to `selectedGoalCode`.

### Invariants

Invalid states must never persist:

```text
selectedGoal.vertical != displayed/current Vertical
selectedTrack.goal != selectedGoal
```

### Deterministic fallback

```text
Track inactive
→ first active Track of same Goal

Goal inactive
→ first active Goal of same Vertical

Vertical inactive / no active Goal
→ clear current learning selection
→ show Choose learning direction
```

Never silently switch the learner to an unrelated Vertical.

---

## BA-04 — Freeze Continue Learning algorithm

### Goal

Home must deterministically answer: **What should I do next?**

### Priority

```text
1. resumable active PracticeTest attempt
2. unfinished last-opened Content item
3. next incomplete member in current Collection
4. next Collection in current Track
5. current Track / current Vertical browse entry
6. Choose learning direction
```

### Invalid target handling

If the previous target is:

- tombstoned;
- inactive;
- no longer a member of the current publication;
- incompatible with the current app contract;

then skip it and continue down the priority chain.

### Acceptance criteria

- deterministic after restart;
- no stale/dead deep links;
- no cross-Vertical fallback;
- updated content revision does not corrupt historical completion state.

---

## BA-05 — Define completion semantics

### Content

For MVP, content completion is explicit learner intent:

```text
Vocabulary → manual Complete
Phrase     → manual Complete
Topic      → manual Complete
Interview  → manual Complete
Shadowing  → manual Complete
```

`LISTENED` never implies `COMPLETED`.

### Assessment

`PracticeTest` is completed automatically when a valid attempt is submitted.

### Revision semantics

If the learner completed revision N and revision N+1 becomes current:

```text
historical state: Completed revision N
current content: Updated revision N+1 available
```

Do not rewrite historical completion.

Suggested UI state:

```text
Completed
Updated
[Review updated version]
```

---

## BA-06 — Freeze assessment product rules

### Supported modes

```text
LEARN
EXAM
QUICK
```

### LEARN

- answer can be changed before confirmation;
- feedback/explanation appears after confirming the question;
- learner may continue after incorrect answer;
- no global pass threshold required.

### EXAM

- answers may be changed until final Submit;
- correctness/explanations hidden until Submit;
- no timer in MVP unless explicitly configured later;
- exact immutable question revisions are retained with attempt history.

### QUICK

- small deterministic subset from the selected Collection/Track;
- selection rule must be deterministic and revision-stable;
- no AI/recommendation dependency.

### Retake

- multiple attempts allowed;
- attempts are immutable history;
- latest and best score may both be displayed, but one must not overwrite history.

### Open decisions to implement/freeze

- percentage scoring formula;
- treatment of unanswered questions;
- pass threshold, if any;
- whether all MVP questions have equal weight.

Recommended MVP:

```text
score = correct / answerable questions × 100
unanswered = incorrect
all questions equal weight
no universal pass threshold
```

---

## BA-07 — Freeze review scheduling policy

### Existing invariant

```text
Due = nextReviewAt <= now
Due != !Completed
```

### Required deterministic MVP policy

Suggested initial stages:

| Outcome | Stage effect | Next review |
|---|---:|---:|
| incorrect | reset / 0 | +10 minutes |
| hard | max(stage, 1) | +1 day |
| correct | stage +1 | 1d / 3d / 7d / 14d / 30d |
| known | stage +2, capped | 7d / 14d / 30d |

The exact table must become normative before implementation acceptance.

### Rules

- scheduler is local and deterministic;
- survives restart and cache cleanup;
- clock/timezone changes must not create duplicate reviews;
- content tombstone preserves historical review state but removes impossible active targets.

---

## BA-08 — Complete Favorites and Downloads journeys

### Favorites

User story:

> As a learner, I can save content and later open a dedicated Favorites view.

Required journey:

```text
Content → Favorite
 ↓
Favorites screen
 ↓
filter/open/remove
```

Empty state:

```text
No favorites yet
[Browse learning content]
```

### Downloads

User story:

> As a learner, I can make a Collection available offline and later remove the downloaded media without losing progress.

Preferred UX scope:

```text
Collection
[Download for offline]
```

not arbitrary low-level assets.

Downloads view must expose:

- downloaded Collections;
- size where available;
- download/update state;
- remove offline copy;
- storage used;
- retry failure.

Deleting offline media must not delete learner state.

---

# 5. P1 remediation backlog

## BA-09 — Explicit device-local learner-state policy

MVP intentionally has no learner account.

Normative product consequence:

```text
uninstall / device loss / app data reset
→ local learner progress can be lost
```

This must be documented and communicated honestly.

Future cloud sync is a separate post-MVP feature, not an implicit promise.

---

## BA-10 — Define Collection completion

Recommended MVP rule:

```text
Collection completed
= all required CollectionMembers completed
```

For MVP either:

1. every member is required; or
2. add explicit `requiredForCompletion` to CollectionMember contract.

Prefer option 1 unless product evidence requires optional members.

PracticeTest member completion = submitted attempt, not passing score unless a future track explicitly defines a threshold.

---

## BA-11 — Define Search scope

Default search scope:

```text
current Vertical
```

Optional user filter:

```text
All learning areas
```

Search must not silently mix unrelated domains unless the learner explicitly expands the scope.

Search result must preserve enough hierarchy context to explain where the result belongs.

---

## BA-12 — Define normal empty states

These are product states, not technical failures:

- Vertical with no active Goal;
- Goal with no active Track;
- Track with no active Collection;
- no Favorites;
- no Review due;
- optional audio missing;
- optional localized hint/translation missing;
- offline asset not downloaded;
- no search results.

Every empty state must define:

```text
message
+ optional explanation
+ safe next action
```

No raw engineering terminology.

---

## BA-13 — Admin workflow semantics

One ADMIN remains sufficient for MVP.

`READY_FOR_REVIEW` is a **content process state**, not a security role.

Same Admin may perform:

```text
author
→ request/generate audio
→ preview
→ review
→ publish
```

Required business validation before publish:

- valid Vertical ownership;
- required localized/canonical fields according to policy;
- required audio roles present;
- exact immutable refs/checksums valid;
- no inactive/mismatched parent graph;
- preview succeeds.

---

# 6. P2 product maturity backlog

## BA-14 — Define MVP success metrics

Recommended minimal KPIs:

```text
Activation
= onboarding complete or skipped + first content opened

First value
= first content completed or first test submitted

D7 retention

Learning sessions/week

Audio adoption
= content sessions with audio playback / eligible sessions

Assessment conversion
= test started/completed after Collection use

Offline success
= offline-open sessions completed without remote dependency
```

Targets are a product decision and are not invented by implementation.

---

## BA-15 — Minimal anonymous telemetry taxonomy

No large analytics domain is required.

Recommended anonymous events:

```text
app_open
onboarding_completed
onboarding_skipped
vertical_selected
goal_selected
track_selected
collection_opened
content_opened
audio_started
audio_completed
content_completed
favorite_changed
offline_download_started
offline_download_completed
test_started
test_submitted
review_completed
```

Rules:

- no learner PII;
- no raw free text;
- stable business codes allowed where privacy policy approves;
- telemetry failure never blocks learning.

---

## BA-16 — Declare MVP commercial mode

Payments/subscriptions/marketplace remain outside this remediation stream.

Until a monetization contract exists, record MVP as:

```text
free pilot / product validation release
```

This prevents accidental assumptions that entitlement/payment behavior already exists.

---

# 7. Cross-system contract issue requiring explicit resolution

## BA-17 — Choose one learner media delivery model

There must be exactly one normative model.

Two incompatible models have appeared in project documentation/implementation history:

### Model A — Backend streaming

```text
Flutter
→ authenticated Backend media endpoint
→ Backend streams bytes
→ Flutter verifies checksum
```

### Model B — Backend-issued temporary media access grant

```text
Flutter
→ authenticated access request
→ Backend returns temporary signed grant URL
→ Flutter downloads bytes
→ Flutter verifies checksum
```

### Required decision

Before backend/media contract freeze, choose one and update **all** of:

- learner OpenAPI;
- cross-system contract;
- mobile requirements;
- media security specification;
- Flutter production adapter;
- acceptance tests.

No document may say signed URLs are forbidden while production code depends on them, or vice versa.

Decision criteria:

- object-storage credentials must never be exposed;
- grants must be short-lived and scope-bound if Model B is selected;
- redirects/storage topology must be explicitly allowed or forbidden;
- offline/local checksum verification remains mandatory;
- token/grant recovery semantics must be defined.

Priority: **P0 architecture/business contract consistency**.

---

# 8. Traceability matrix required for closure

Every remediation item must eventually map as follows:

| Layer | Required evidence |
|---|---|
| Epic | learner/business outcome |
| User Story | user value statement |
| Business Rule | deterministic normative rule |
| Acceptance Criteria | Given/When/Then positive + negative |
| Backend Contract | ownership/API/publication effect |
| Flutter | screen/state/navigation effect |
| Persistence | durable/local data impact |
| Tests | unit/integration/widget/E2E as appropriate |

A high line-coverage number is not considered proof that a business story is complete.

---

# 9. Recommended implementation order

```text
BA-01 Vertical normative hierarchy
 ↓
BA-02 onboarding
 ↓
BA-03 learner selection/fallback
 ↓
BA-04 Continue algorithm
 ↓
BA-05 completion/revision semantics
 ↓
BA-06 assessment rules
 ↓
BA-07 review policy
 ↓
BA-08 Favorites + Downloads
 ↓
BA-17 media delivery contract reconciliation
 ↓
BA-09..BA-13 remaining MVP UX/operations
 ↓
BA-14..BA-16 telemetry/KPI/commercial declaration
```

`BA-17` may be moved earlier and should be resolved before backend media implementation freezes.

---

# 10. Definition of Done for BA remediation

The remediation stream is accepted when:

```text
[ ] Vertical → Goal → Track → Collection is normative everywhere
[ ] onboarding has one final three-step definition and matching implementation plan
[ ] current learner selection and inactive fallback are deterministic
[ ] Continue Learning priority is deterministic
[ ] content/test/collection completion semantics are explicit
[ ] assessment modes/scoring/retake rules are frozen
[ ] review scheduling intervals are frozen
[ ] Favorites and Downloads have complete learner journeys
[ ] device-local progress loss policy is explicit
[ ] Search and normal empty states are specified
[ ] ADMIN review state semantics are explicit
[ ] learner media delivery uses one non-conflicting contract
[ ] MVP success metrics and minimal telemetry are approved or explicitly deferred
[ ] commercial mode is declared
[ ] every P0/P1 story has traceability to acceptance tests
```

After this point, implementation may proceed without inventing product behavior inside Flutter/backend code.