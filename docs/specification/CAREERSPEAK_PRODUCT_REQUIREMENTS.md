# CareerSpeak — Product Requirements Specification

**Document version:** 1.2  
**Status:** Normative MVP product baseline  
**Applies to:** CareerSpeak v1  
**Target platforms:** Android, iOS

Related normative documents:

- [`CAREERSPEAK_SYSTEM_REQUIREMENTS.md`](CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`](CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md)
- [`../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md`](../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)

The expert review in [`../product/MARKETING_DESIGN_EXPERT_PANEL_REVIEW.md`](../product/MARKETING_DESIGN_EXPERT_PANEL_REVIEW.md) is design input. This document contains only the decisions needed for MVP.

---

## 1. Product definition

CareerSpeak is an **offline-first English practice application for international career situations**.

Primary focus:

```text
international job interviews
professional / technical English
```

IELTS remains a separate supported learning direction/goal.

The product is goal-driven but grouped by backend-owned learning Verticals. MVP SHALL NOT introduce a recommendation engine, learning rules engine, remote UI model, server learner profile or complex curriculum graph.

---

## 2. Target learner

Primary learner:

```text
adult non-native English speaker
preparing for interviews or professional communication
roughly B1-C1
wants practical listening/speaking/test practice
may use the application offline
```

Primary jobs-to-be-done:

```text
prepare for a job interview
practise professional vocabulary and answers
improve confidence before work conversations
prepare for IELTS as a separate path
review weak material
```

---

## 3. MVP product principles

```text
simple direction + goal-based navigation
professional tone
no mandatory learner account
offline-first
local progress
real reviewed audio
READ → LISTEN → REPEAT → TEST → REVIEW
Material Design 3
backend owns mutable product/content catalogues
Flutter owns learner preferences/progress
no unnecessary infrastructure or domain layers
```

---

## 4. Minimal product hierarchy

The normative MVP hierarchy is:

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

`Vertical` is the backend-owned subject/professional learning area. Examples include Java, DevOps, Medical English, Workplace English and IELTS-oriented English.

`LearningGoal` is the learner intention inside exactly one Vertical, for example job interview, patient communication or workplace meetings.

No separate backend `LearningActivity` aggregate is required in MVP.

The learning loop:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

is implemented by Flutter using content/test capabilities and local learner state. Backend does not need a workflow engine to describe every pedagogical step.

### Career taxonomy vs learner path

Keep the distinction:

```text
CareerTrack
= professional taxonomy, e.g. JAVA_BACKEND

LearningTrack
= learning path, e.g. JAVA_SENIOR_INTERVIEW
```

Do not merge them into one entity. `Vertical` is also not a replacement for either concept: it is the top-level learner-facing product scope.

---

## 5. Backend-owned product catalogues

### 5.1 Vertical

Minimum fields:

```text
code
title
description
iconAssetId?
sortOrder
active
```

Vertical codes are backend data, not permanent Flutter enums.

### 5.2 LearningGoal

Minimum fields:

```text
code
verticalCode
title
description
sortOrder
active
```

A Goal belongs to exactly one Vertical.

### 5.3 LearningTrack

Minimum fields:

```text
code
goalCode
verticalCode
title
description
levelCode
sortOrder
active
```

A track MAY reference career/profession/seniority taxonomy where useful.

### 5.4 LearningCollection

A collection packages content around one practical topic.

Examples:

```text
Tell me about yourself
Behavioural interview
System design English
Meetings and status updates
IELTS Speaking Part 2
```

Minimum fields:

```text
code
trackCode
verticalCode
title
description
sortOrder
active
ordered members[]
```

Members reference exact Content or PracticeTest revisions. A collection does not need its own workflow/state machine.

### 5.5 Existing catalogues

Backend also owns:

```text
Category
Level
Skill
SupportedLocale
TtsVoice learner-facing projection
```

Stable code is identity; labels are presentation.

---

## 6. Device-owned learner state

Flutter stores locally:

```text
onboardingCompleted
selectedGoalCode?
selectedTrackCode?
selfAssessedLevelCode?
uiLocale
translationLocale
preferredAccent / preferredVoiceCode?
favorites
listened/completed markers
review schedule
test history
```

`selectedVerticalCode` is not an independent durable preference when a Goal is selected. Current Vertical is derived from `selectedGoalCode → CURRENT Goal.verticalCode`.

No server learner profile is required in MVP.

Cache cleanup must not erase learner preferences/progress.

If a selected Track becomes inactive/missing, Flutter clears Track and preserves an active selected Goal. If the selected Goal or its parent Vertical becomes inactive/missing, Flutter clears Goal and Track and asks the learner to choose a learning direction. Flutter MUST NOT silently jump to another Vertical.

---

## 7. First-run onboarding

Onboarding SHALL be short, skippable, account-free and restart-safe.

MVP has exactly three learner decisions:

```text
1. Learning direction        → Vertical + LearningGoal
2. Approximate English level → B1 / B2 / C1 / Not sure
3. Support language          → published SupportedLocale
```

Step 1 may visually present Vertical cards followed by Goals inside the selected Vertical, but this remains one onboarding step and one product decision.

Only active Verticals with at least one active Goal are selectable. Only active Goals of the selected Vertical are selectable.

Skipping onboarding preserves explicit decisions already made, leaves missing Goal/Track/Level unset, never invents an arbitrary career direction, and opens browse/home mode.

Onboarding progress is persisted after each explicit decision and resumes at the next incomplete step after restart.

Accent/voice and offline download choices belong in normal Settings/Download flows and do not lengthen onboarding.

The detailed normative rules are defined in [`CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`](CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md).

---

## 8. Home

Home must answer one question first:

> What should I do next?

MVP hierarchy:

```text
1. Continue last/current item
2. Current Vertical / Goal / Track context
3. Review due
4. Browse current track / collections or choose learning direction
5. Secondary statistics
```

If no Goal is selected, Home shows a clear `Choose learning direction` action and does not manufacture a default Vertical.

No AI/recommendation service is required.

A `Recommended` label is allowed only when it means simple deterministic editorial ordering or continuation based on local progress.

---

## 9. Learn / discovery

MVP discovery:

```text
Learn
├── Current Vertical / Goal / Track
├── Verticals
├── Collections
├── Categories
└── Browse / Search
```

Vertical/Goal/Track may be changed from Learn or Settings.

Technical content types remain internal classifications; they do not have to dominate learner navigation.

---

## 10. Review semantics

`Due` has one strict meaning:

```text
Due = nextReviewAt <= now
```

`Not completed` is not `Due`.

Minimal local review state:

```text
nextReviewAt
reviewStage
lastReviewOutcome
```

Possible outcomes:

```text
incorrect
hard
correct
known
```

The interval policy is deterministic and local. No ML/AI scheduler is required.

---

## 11. Assessment

Tests provide:

```text
score
correct/incorrect answers
explanations
skillCode where useful
```

A complex recommendation engine based on weak skills is not required for MVP.

Flutter may use `skillCode` and current Vertical/Goal/Track/Collection context to show a simple next-practice link.

Historical attempts remain reproducible against exact immutable test/question revisions.

---

## 12. Audio and speaking practice

MVP supports:

```text
listen
pause
seek
speed
repeat
repeat aloud
segment repeat where content provides segments
```

Runtime STT, pronunciation scoring, learner audio upload and runtime TTS remain non-goals.

---

## 13. Learner-facing copy

Production learner UI SHALL NOT expose implementation terminology such as:

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

Use simple learner language.

Raw HTTP/database exceptions SHALL NOT be shown directly.

Empty/error states should explain the problem and provide a safe next action when possible.

---

## 14. Visual direction

Material Design 3 remains the only design system.

Do not create a large custom component framework before it is needed.

MVP may define a small reusable set:

```text
Learning Direction Card
Goal / Track / Collection Card
Audio controls
Review state
Empty state
```

Desired tone:

```text
professional
calm
clear
focused
```

Avoid childish gamification and visual noise.

---

## 15. Explicit non-goals for product-domain design

Do NOT add in MVP:

```text
LearningActivity backend aggregate
workflow/rules engine
recommendation microservice
AI personalization
server learner profile
remote UI JSON schema
generic EAV content model
complex achievement/badge economy
social graph
leaderboards
analytics domain model before telemetry is approved
```

If future evidence requires one of these, add it as a separate versioned requirement.

---

## 16. Product acceptance

MVP product contract is ready when:

```text
[ ] career/interview is primary focus; IELTS remains a supported learning direction/goal
[ ] Vertical → Goal → Track → Collection → Content/Test is the only normative learner hierarchy
[ ] every Goal belongs to exactly one Vertical
[ ] CareerTrack, LearningTrack and Vertical are not conflated
[ ] backend owns Vertical/Goal/Track/Collection and mutable catalogues
[ ] Flutter owns local learner preferences/progress/review
[ ] current Vertical is derived from selected Goal, not a conflicting durable preference
[ ] onboarding is 3-step, skippable and restart-safe
[ ] onboarding Step 1 selects Vertical + Goal
[ ] skip never silently chooses a career direction
[ ] inactive Goal/Vertical clears the selection rather than switching across Verticals
[ ] Home starts with Continue/current learning context rather than dashboard counters
[ ] Due means nextReviewAt <= now
[ ] assessment revisions/answers/explanations are deterministic
[ ] learner UI contains no engineering implementation language
[ ] no extra domain/infrastructure layer is introduced without a concrete MVP use case
```

---

## 17. Delivery order

```text
PR0  Product ownership + Vertical hierarchy
 ↓
PR1  Vertical / Goal / Track / Collection contracts
 ↓
PR2  typed Content + Assessment contracts
 ↓
PR3  localization / taxonomy / voice catalogues
 ↓
PR4  publication snapshot + learner OpenAPI
 ↓
PR5  backend aggregate/schema freeze
 ↓
PR6  Flutter UX alignment and cross-system acceptance
```

Backend JPA/schema is derived after these contracts are frozen. It must not mirror Flutter DTOs blindly.
