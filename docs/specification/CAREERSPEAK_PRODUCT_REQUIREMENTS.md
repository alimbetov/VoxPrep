# CareerSpeak — Product Requirements Specification

**Document version:** 1.0  
**Status:** Normative product baseline  
**Applies to:** CareerSpeak v1 product/domain freeze  
**Target platforms:** Android, iOS

Related normative documents:

- [`CAREERSPEAK_SYSTEM_REQUIREMENTS.md`](CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md`](../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)
- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)

The historical expert critique in [`../product/MARKETING_DESIGN_EXPERT_PANEL_REVIEW.md`](../product/MARKETING_DESIGN_EXPERT_PANEL_REVIEW.md) is design input. This document is the normative product decision produced from that audit.

---

## 1. Product definition

CareerSpeak is an **offline-first English performance coach for international career situations**.

Primary product wedge:

```text
international job interviews
+ professional / technical English
```

IELTS remains a supported, clearly separated learning goal rather than competing with career preparation in the first-touch product message.

Internal positioning statement:

```text
CareerSpeak helps non-native professionals practise the English they need
for interviews, work communication and international career progression
through structured reading, listening, repetition, testing and review
that remains usable offline.
```

The product SHALL NOT present itself primarily as a generic English content catalogue.

---

## 2. Target learner and jobs-to-be-done

Primary learner:

```text
adult non-native English speaker
preparing for international career opportunities
roughly B1-C1 working proficiency
values practical rehearsal over gamification
may need Russian/Kazakh/other-language support
may practise while commuting/travelling/offline
```

Primary jobs-to-be-done:

```text
prepare for a job interview
explain professional experience clearly
answer behavioural questions
practise technical/professional vocabulary
improve confidence before real work conversations
prepare for IELTS as a separate goal path
review weak material efficiently
```

Product information architecture SHALL be organized around learner outcomes first and implementation content types second.

---

## 3. Product principles

```text
goal-driven, not catalogue-driven
professional coaching tone
no mandatory learner account in MVP
offline-first consumption
local-first learner intent/progress
real reviewed audio
structured READ → LISTEN → REPEAT → TEST → REVIEW loop
multilingual support without changing English as learning language
low visual noise
no childish economy/gamification
one coherent Material Design 3 system
backend-owned mutable product catalogues
stable business codes across systems
```

---

## 4. Product hierarchy

The normative product hierarchy is:

```text
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
LearningActivity
    ↓
Content / PracticeTest
    ↓
ReviewSchedule / learner progress
```

This hierarchy is independent from technical content types such as `vocabulary`, `interview`, `topic`, `phrase` and `shadowing`.

### 4.1 Career taxonomy vs learning taxonomy

The following concepts MUST NOT be collapsed into one entity:

```text
Profession / CareerTrack
= what career/professional domain the learner belongs to

LearningGoal
= what outcome the learner is trying to achieve

LearningTrack
= curated learning path toward a goal
```

Example:

```text
Profession       = SOFTWARE_ENGINEERING
CareerTrack      = JAVA_BACKEND
LearningGoal     = TECH_INTERVIEW
LearningTrack    = JAVA_SENIOR_INTERVIEW
LearningCollection = BEHAVIORAL_INTERVIEW
```

---

## 5. Backend-owned product catalogues

Backend is the source of truth for mutable product structure.

### 5.1 LearningGoal

Minimum logical contract:

```text
code
canonicalTitle
canonicalDescription
sortOrder
active
optional hero/presentation metadata
```

Initial goal codes may include:

```text
JOB_INTERVIEW
TECH_INTERVIEW
WORKPLACE_ENGLISH
MANAGEMENT_INTERVIEW
IELTS
```

These are product data, not permanent Flutter enums.

### 5.2 LearningTrack

A `LearningTrack` is a curated path toward one or more goals.

Minimum logical contract:

```text
code
goalCode
title
subtitle
description
levelCode
estimatedMinutes
sortOrder
active
collectionRefs[]
```

A track MAY additionally reference profession/career/seniority/skill taxonomy.

### 5.3 LearningCollection

A `LearningCollection` groups learning activities around a concrete learner outcome.

Examples:

```text
Tell me about yourself
Behavioural interview
System design English
Meetings and status updates
Salary and negotiation
IELTS Speaking Part 2
```

Minimum logical contract:

```text
code
title
subtitle
description
goalCode
levelCode
estimatedMinutes
sortOrder
active
activityRefs[]
optional heroAssetId
```

### 5.4 LearningActivity

A `LearningActivity` describes the pedagogical action expected from the learner.

Minimum logical contract:

```text
activityType
sequence
required
contentRef OR practiceTestRef
```

Initial activity types:

```text
READ
LISTEN
REPEAT
TEST
REVIEW
```

The backend may publish a recommended sequence; Flutter owns runtime execution state.

### 5.5 Taxonomy and capability catalogues

Backend also owns mutable catalogues for:

```text
Category
Level
Skill
SupportedLocale
TtsVoice learner-facing projection
```

Stable code is identity; localized labels are presentation.

---

## 6. Device-owned learner intent

MVP has no server learner profile.

Flutter stores a local learner-intent projection such as:

```text
onboardingCompleted
selectedGoalCode
selectedTrackCode? 
selfAssessedLevelCode?
uiLocale
translationLocale
preferredAccent / preferredVoiceCode?
```

Rules:

```text
selected codes must come from backend-owned catalogues where applicable
preferences survive restart
cache eviction must not erase learner intent
invalid/deactivated catalogue selections fall back deterministically
no account is required to choose or change a goal
```

A future optional cloud profile may replicate this state, but it must not become product-content source of truth.

---

## 7. First-run onboarding

Onboarding is a product requirement, not an optional decorative screen.

It SHALL be:

```text
short
skippable
account-free
restart-safe
accessible
```

Recommended first-run questions:

```text
1. What are you preparing for?
   Interview / Workplace / IELTS / other published goal

2. What is your approximate English level?
   B1 / B2 / C1 / Not sure

3. What support language do you want?

4. Which English accent/voice do you prefer?

5. Download a recommended starter pack?
   Yes / Later
```

The exact wording is localized UI copy; goal/level/locale/voice availability is backend-owned where mutable.

Onboarding MAY be skipped. Skipping SHALL produce deterministic defaults and SHALL NOT block normal browsing.

---

## 8. Home experience

Home SHALL prioritize the learner's next useful action rather than database counters.

Required information hierarchy:

```text
1. Next best action / Continue
2. Current goal or track
3. Goal/track progress
4. Due review
5. Recommended next collection/content
6. Browse/library shortcuts
7. Secondary statistics
```

`Completed`, `Listened` and `Favorites` may be shown, but SHALL NOT dominate the primary Home hierarchy.

A generic `Recommended` section SHALL NOT imply personalization unless a deterministic recommendation basis exists.

MVP recommendation inputs may include:

```text
selected goal
selected track
level
completion/listening state
review due state
published sort/order metadata
```

No ML/runtime AI is required.

---

## 9. Learn / discovery experience

The learner-facing hierarchy SHALL favor outcomes over implementation types.

Recommended structure:

```text
Learn
├── Continue your track
├── Goals / tracks
├── Recommended
├── Collections
├── Categories
└── Browse all / Search
```

Technical content types remain valid internal/domain classifications but SHALL NOT be the only discovery model.

Search and state filters remain available for direct access and power users.

---

## 10. Learning loop

The core loop is normative:

```text
READ → LISTEN → REPEAT → TEST → REVIEW
```

A lesson/collection SHOULD make progression visible where the content supports those activities.

Example presentation semantics:

```text
Read      completed
Listen    completed
Repeat    current
Test      next
Review    scheduled
```

This is not a universal hard-lock sequence. Required/optional activity metadata determines what applies to each learning unit.

---

## 11. Review semantics

The label `Due` SHALL be used only for a real deterministic review schedule.

Normative local review state:

```text
nextReviewAt
reviewStage
lastReviewedAt
lastReviewOutcome
```

Possible outcomes include:

```text
incorrect
hard
correct
known
```

Rule:

```text
Due = nextReviewAt <= now
```

`Not completed` is a separate learner/content state and MUST NOT be presented as `Due`.

Review scheduling remains device-owned in MVP and must survive restart/cache eviction.

---

## 12. Assessment product requirements

Tests SHALL provide learning feedback, not only a score.

A completed assessment SHOULD communicate:

```text
score/result
strong skills
weak skills
question explanations
recommended next learning action
```

Skill identity SHALL use stable backend-owned `skillCode` values rather than free-text names where recommendations depend on skill semantics.

Historical attempts remain reproducible against exact immutable test/question revisions.

---

## 13. Audio and speaking practice

Career/interview learners are preparing to perform, not only consume content.

Even without speech recognition, product flows SHOULD support:

```text
listen
pause
repeat aloud
change speed
repeat segment
compare against model audio
retry
continue progress
```

Runtime STT, pronunciation scoring and learner voice upload remain MVP non-goals unless separately approved.

---

## 14. Learner-facing language policy

Production learner UI SHALL NOT expose implementation vocabulary.

Forbidden learner-facing concepts include ordinary use of terms such as:

```text
repository
adapter
persistence
manifest
DTO
qualification
production adapter
sync journal
Drift
RustFS
```

Use learner-benefit/state language instead.

Examples:

```text
Incorrect:
Assessment catalogue qualified against repository ports.

Correct:
Practise with short quizzes or timed test sessions.

Incorrect:
Offline content is managed by production adapters.

Correct:
Manage lessons saved for offline practice.
```

Raw transport/database exceptions SHALL never be used as learner-facing copy.

---

## 15. Empty, loading and failure states

Every meaningful empty/error state SHOULD answer:

```text
what happened
why it matters
what the learner can do next
```

The UI SHALL distinguish at least:

```text
no published content
no downloaded content
no results for current filter
network unavailable
sync/update failed
storage unavailable/full
```

Where a safe next action exists, provide it.

---

## 16. Visual and brand direction

Material Design 3 remains the only design system.

CareerSpeak SHALL build a recognizable component layer on top of Material primitives, including where applicable:

```text
CareerSpeak Learning Card
Goal / Track Card
Collection Card
Audio Practice Card
Interview Question Card
Review Card
Goal Progress block
CareerSpeak Empty State
CareerSpeak Status Chip
```

Desired emotional territory:

```text
confidence
clarity
competence
progress
calm preparation
```

Avoid:

```text
childish mascots
coins/virtual economy
competitive pressure
excessive confetti
high-noise gamification
```

Positive reinforcement is allowed when it supports professional coaching tone.

---

## 17. Activation and progress semantics

The product SHALL define activation in terms of meaningful learning behavior rather than installation alone.

MVP activation definition:

```text
learner selects/skips onboarding deterministically
AND completes at least one meaningful learning activity
```

A meaningful activity is one of:

```text
qualified audio listen
content completion
completed practice test
completed review
```

Product progress MAY show:

```text
track progress
collection progress
activities completed
review due count
practice time where locally measurable
```

Server-side learner analytics are not required for MVP. Any future telemetry requires a separate privacy/data contract.

---

## 18. Commercial and trust principles

Initial commercial direction remains:

```text
one-time paid app model
no ads initially
no mandatory account
```

Storefront purchase entitlement and media-delivery authorization are separate architecture decisions and must not be falsely represented as learner identity/authentication.

Product copy SHALL not claim stronger privacy/security guarantees than the implementation provides.

---

## 19. Product acceptance

Product contract freeze requires evidence that:

```text
[ ] primary positioning is career/interview first; IELTS is a separate goal path
[ ] LearningGoal is distinct from Profession/CareerTrack
[ ] LearningTrack is a curated learning path, not a career taxonomy alias
[ ] LearningCollection and activity ordering are specified
[ ] backend owns mutable goal/track/collection/taxonomy/capability catalogues
[ ] Flutter owns local learner intent/progress/review schedule
[ ] onboarding is skippable and deterministic
[ ] Home prioritizes next action/current goal before statistics
[ ] Due is based on nextReviewAt, never merely !completed
[ ] assessment feedback uses stable skills and explanations
[ ] learner-facing copy contains no architecture implementation language
[ ] core READ → LISTEN → REPEAT → TEST → REVIEW loop is representable
[ ] Material 3 remains the single design system with CareerSpeak branded components
[ ] product acceptance is reflected in system/domain/mobile requirements
[ ] learner OpenAPI can be derived without Flutter becoming product source of truth
```

Product requirements are not considered frozen while these decisions exist only in audit/review documents.

---

## 20. Delivery order

Normative product-to-implementation order:

```text
PR0  Product positioning + ownership freeze
 ↓
PR1  LearningGoal / LearningTrack / LearningCollection contract
 ↓
PR2  onboarding + local learner intent
 ↓
PR3  typed content + LearningActivity contract
 ↓
PR4  assessment + skill feedback contract
 ↓
PR5  real review scheduling semantics
 ↓
PR6  Home / Learn information architecture
 ↓
PR7  branded Material component qualification
 ↓
PR8  learner OpenAPI / persistence derivation
 ↓
PR9  cross-system acceptance
```

Backend JPA/schema design SHALL be derived after the relevant product/domain contracts are frozen, not by mirroring current Flutter DTO classes.
