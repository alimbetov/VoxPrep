# CareerSpeak — Product Requirements Specification

**Document version:** 1.1  
**Status:** Normative MVP product baseline  
**Applies to:** CareerSpeak v1  
**Target platforms:** Android, iOS

Related normative documents:

- [`CAREERSPEAK_SYSTEM_REQUIREMENTS.md`](CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
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

IELTS remains a separate supported goal.

The product is goal-driven, but it must remain simple. MVP SHALL NOT introduce a recommendation engine, learning rules engine, remote UI model, server learner profile or complex curriculum graph.

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
simple goal-based navigation
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

The MVP hierarchy is intentionally small:

```text
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
Content / PracticeTest
```

No separate backend `LearningActivity` aggregate is required in MVP.

The learning loop:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

is implemented by Flutter using content/test capabilities and local learner state. Backend does not need a workflow engine to describe every pedagogical step.

### Career taxonomy vs learner path

Keep only one important distinction:

```text
CareerTrack
= professional domain, e.g. JAVA_BACKEND

LearningTrack
= learning path, e.g. JAVA_SENIOR_INTERVIEW
```

Do not merge them into one entity.

---

## 5. Backend-owned product catalogues

### 5.1 LearningGoal

Minimum fields:

```text
code
title
description
sortOrder
active
```

Example codes:

```text
JOB_INTERVIEW
TECH_INTERVIEW
WORKPLACE_ENGLISH
IELTS
```

These are backend data, not permanent Flutter enums.

### 5.2 LearningTrack

Minimum fields:

```text
code
goalCode
title
description
levelCode
sortOrder
active
```

A track MAY reference career/profession/seniority taxonomy where useful.

### 5.3 LearningCollection

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
title
description
sortOrder
active
contentRefs[]
practiceTestRefs[]
```

A collection does not need its own workflow/state machine.

### 5.4 Existing catalogues

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
selectedGoalCode
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

No server learner profile is required in MVP.

Cache cleanup must not erase learner preferences/progress.

If a selected backend catalogue item becomes inactive, Flutter applies a deterministic fallback without failing startup.

---

## 7. First-run onboarding

Onboarding SHALL be short, skippable, account-free and restart-safe.

MVP asks only:

```text
1. What are you preparing for?  → LearningGoal
2. Approximate English level?   → B1 / B2 / C1 / Not sure
3. Support language?            → published SupportedLocale
```

Accent/voice and offline download choices belong in normal Settings/Download flows and do not need to lengthen onboarding.

Skipping onboarding uses safe defaults and never blocks browsing.

---

## 8. Home

Home must answer one question first:

> What should I do next?

MVP hierarchy:

```text
1. Continue last/current item
2. Current goal/track
3. Review due
4. Browse current track / collections
5. Secondary statistics
```

No AI/recommendation service is required.

A `Recommended` label is allowed only when it means simple deterministic editorial ordering or continuation based on local progress.

---

## 9. Learn / discovery

MVP discovery:

```text
Learn
├── Current track
├── Collections
├── Categories
└── Browse / Search
```

Goals/tracks may be changed from Learn or Settings.

Technical content types remain internal classifications; they do not have to dominate the learner navigation.

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

Flutter may use `skillCode` and current track/collection to show a simple next-practice link.

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
Learning Card
Track/Collection Card
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
[ ] career/interview is primary focus; IELTS is a separate goal
[ ] Goal → Track → Collection → Content/Test is sufficient for navigation
[ ] CareerTrack and LearningTrack are not conflated
[ ] backend owns Goal/Track/Collection and mutable catalogues
[ ] Flutter owns local learner preferences/progress/review
[ ] onboarding is 3-step, skippable and restart-safe
[ ] Home starts with Continue/current goal rather than dashboard counters
[ ] Due means nextReviewAt <= now
[ ] assessment revisions/answers/explanations are deterministic
[ ] learner UI contains no engineering implementation language
[ ] no extra domain/infrastructure layer is introduced without a concrete MVP use case
```

---

## 17. Delivery order

```text
PR0  Product ownership + simple hierarchy
 ↓
PR1  Goal / Track / Collection contracts
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
