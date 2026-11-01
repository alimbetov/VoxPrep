# CareerSpeak — Product Requirements Specification

**Document version:** 1.3  
**Status:** Normative MVP product baseline  
**Applies to:** CareerSpeak v1  
**Target platforms:** Android, iOS

Related normative documents:

- [`CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`](CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md)
- [`CAREERSPEAK_SYSTEM_REQUIREMENTS.md`](CAREERSPEAK_SYSTEM_REQUIREMENTS.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)
- [`CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md`](CAREERSPEAK_GLOBALIZATION_REQUIREMENTS.md)
- [`CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`](CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md)
- [`CAREERSPEAK_CONTINUE_LEARNING_PRODUCT_CONTRACT.md`](CAREERSPEAK_CONTINUE_LEARNING_PRODUCT_CONTRACT.md)
- [`CAREERSPEAK_REVIEW_POLICY.md`](CAREERSPEAK_REVIEW_POLICY.md)
- [`../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md`](../architecture/CAREERSPEAK_DOMAIN_CONTRACT_PLAN.md)

This document defines product intent and ownership. The MVP delivery boundary defines which accepted capabilities are release gates for v1. Historical roadmaps do not override these documents.

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

## 2. Target learner and jobs-to-be-done

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

## 3. MVP principles

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
fail closed rather than invent learner intent
exact immutable revision identity
no unnecessary infrastructure or domain layers
```

---

## 4. Normative learner hierarchy

The only normative MVP hierarchy is:

```text
Vertical
    ↓
LearningGoal
    ↓
LearningTrack
    ↓
LearningCollection
    ↓
ordered CollectionMember
    ├─ exact ContentRevision
    └─ exact PracticeTestRevision
```

`Vertical` is the backend-owned subject/professional learning area. `LearningGoal` is the learner intention inside exactly one Vertical. `LearningTrack` is a learning path. `LearningCollection` is an ordered practical unit/topic.

No backend `LearningActivity` aggregate or workflow engine is required.

Keep taxonomy distinct:

```text
CareerTrack = professional taxonomy
LearningTrack = learning path
Vertical = top-level learner-facing product scope
```

---

## 5. Backend-owned product catalogues

Backend owns mutable product truth for:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
Category
Level
Skill
SupportedLocale
TtsVoice learner-facing projection
published Content revisions
published PracticeTest revisions
asset/audio descriptors
```

Core ownership invariants:

- a Goal belongs to exactly one Vertical;
- a Track belongs to exactly one Goal;
- a Collection belongs to exactly one Track;
- Collection members reference exact immutable content/test revisions;
- stable business code is identity; labels are presentation;
- active/inactive and publication status are backend-owned;
- Flutter does not invent mutable catalogue values.

---

## 6. Device-owned learner state

Flutter stores locally:

```text
onboardingCompleted / onboarding progress
selectedGoalCode?
selectedTrackCode?
selfAssessedLevelCode?
uiLocale
translationLocale
preferredAccent / preferredVoiceCode?
favorites
listened/completed markers
review schedule
test attempt/history
playback progress
```

`selectedVerticalCode` is not an independent durable source of truth. Current Vertical is derived from:

```text
selectedGoalCode
→ CURRENT Goal.verticalCode
→ CURRENT Vertical
```

Invalid selection is **fail-closed**:

```text
Track inactive/missing
→ clear Track
→ preserve active Goal

Goal inactive/missing
→ clear Goal + Track
→ current Vertical unset
→ show Choose learning direction

Vertical inactive/missing
→ its Goal is invalid
→ apply the same Goal rule
```

Flutter MUST NOT silently select the first sibling Track/Goal or switch the learner to another Vertical.

No server learner profile is required in MVP. Cache cleanup must not erase learner preferences/progress.

Device uninstall, app-data reset or device loss may remove local learner state in v1; cloud learner-state sync is post-MVP.

---

## 7. First-run onboarding

Onboarding is short, skippable, account-free and restart-safe.

Exactly three learner decisions:

```text
1. Learning direction        → Vertical + LearningGoal
2. Approximate English level → B1 / B2 / C1 / Not sure
3. Support language          → published SupportedLocale
```

Step 1 may visually present Vertical then Goal, but remains one logical product step.

Rules:

- only active CURRENT Vertical/Goal chains are selectable;
- skip preserves explicit choices already made;
- skip leaves missing choices unset and never fabricates a direction;
- onboarding progress persists after each explicit decision;
- restart resumes at the next incomplete decision;
- browsing is not blocked after skip;
- accent/voice and storage/offline management are outside onboarding.

---

## 8. Home and Continue Learning

Home answers first: **What should I do next?**

Priority:

```text
1. resumable active PracticeTest attempt
2. unfinished last-opened Content item
3. next incomplete member in the current Collection
4. next eligible Collection in the current Track
5. current Track / current Vertical browse entry
6. Choose learning direction
```

Every candidate is revalidated against CURRENT publication before navigation. Tombstoned, inactive, dangling or revision-mismatched candidates are skipped; they are never repaired by guessing another entity.

Home presentation order:

```text
Continue
Current Vertical / Goal / Track
Review due
Browse current track/collections or Choose learning direction
Secondary statistics
```

No recommendation service is required. `Recommended` may only mean deterministic editorial/local continuation ordering.

---

## 9. Learn / discovery

MVP discovery supports:

```text
Current Vertical / Goal / Track
Verticals
Collections
Categories
Browse / Search
```

Hierarchy navigation validates full parent ownership and fails closed on a mismatched parent chain.

Search should default to current Vertical where that context exists; expanding to all learning areas must be explicit.

---

## 10. Completion and learner markers

Independent durable marker concepts:

```text
FAVORITE
LISTENED
COMPLETED
```

Rules:

```text
Favorite does not imply or pin completion
Listened does not imply Completed
Completed does not erase review/test history
cache/media eviction does not erase markers
```

Content completion is explicit learner intent for ordinary content. PracticeTest completion occurs when a valid attempt is submitted.

Completion is revision-aware: completing revision N does not rewrite or automatically complete revision N+1.

`FAVORITE` is required as a durable local marker/filter. A standalone Favorites screen is not an MVP release gate.

---

## 11. Review semantics

`Due` has exactly one meaning:

```text
Due = nextReviewAt <= now
```

`Not completed` is not `Due`.

Minimal local state:

```text
nextReviewAt
reviewStage
lastReviewOutcome
```

Outcomes:

```text
incorrect
hard
correct
known
```

Scheduling is local, deterministic, UTC-based and restart-safe. The exact v1 interval policy is normative in `CAREERSPEAK_REVIEW_POLICY.md`. No ML/AI review scheduler is required.

---

## 12. Assessment

Practice tests preserve exact immutable test/question revision identity.

MVP behavior may expose:

```text
score
correct/incorrect answers
explanations
skillCode where useful
simple next-practice link
```

An active attempt is restart-safe. Submitted completion/history must not be inferred from a newer revision.

No complex weak-skill recommendation engine is required.

---

## 13. Audio, media and offline

MVP learner audio supports:

```text
listen
pause
seek
speed
repeat
repeat aloud
segment repeat where metadata exists
```

Runtime STT, pronunciation scoring, learner audio upload and runtime mobile TTS remain non-goals.

Flutter-facing media contract for v1:

```text
installation-authenticated Backend media API
→ Backend-controlled byte delivery
→ size/checksum verification
→ atomic verified local asset
→ offline playback
```

Flutter receives no RustFS/object-storage credentials and never interprets `deliveryKey` as a remote locator.

Offline-first is a release requirement. A dedicated user-managed Downloads dashboard is not. Download/cache/AssetResolver infrastructure may manage verified assets without creating a separate Downloads feature stream.

---

## 14. Learner-facing copy and visual direction

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

Raw HTTP/database/storage exceptions are not shown directly. Empty/error states explain the learner problem and safe next action where possible.

Material Design 3 remains the only design system. Desired tone:

```text
professional
calm
clear
focused
```

Avoid childish gamification and unnecessary visual framework work.

---

## 15. Explicit non-goals

Do NOT add in MVP:

```text
LearningActivity backend aggregate
workflow/rules engine
recommendation microservice
AI personalization
server learner profile
mandatory learner account/login
remote UI JSON schema
generic EAV content model
complex achievement/badge economy
social graph
leaderboards
analytics platform before telemetry is approved
advanced SRS / FSRS / SM-2
runtime STT/pronunciation scoring
standalone Favorites feature stream
user-managed Downloads feature stream
microservice decomposition
Kafka/RabbitMQ/Redis/Keycloak for learner-domain flows
```

Future evidence may reintroduce an item only through a separate versioned requirement.

---

## 16. Product acceptance

The product/business contract is sufficient when:

```text
[✓] Vertical → Goal → Track → Collection → exact Content/Test revision is normative
[✓] every Goal belongs to exactly one Vertical
[✓] CareerTrack, LearningTrack and Vertical are distinct
[✓] backend owns mutable catalogue/publication truth
[✓] Flutter owns local learner state
[✓] current Vertical derives from selected Goal
[✓] invalid selection clears fail-closed rather than guessing a sibling
[✓] onboarding is exactly 3 decisions, skippable and restart-safe
[✓] Continue Learning priority is deterministic and CURRENT-revalidated
[✓] Due means nextReviewAt <= now
[✓] review policy is deterministic/restart-safe
[✓] assessment/completion is exact-revision aware
[✓] learner media is Backend-authorized and storage credentials are hidden
[✓] Favorites/Downloads convenience surfaces do not reopen MVP feature streams
[✓] learner UI contains no engineering implementation language
```

---

## 17. Remaining MVP delivery order

The historical PR0–PR6 contract-design sequence is complete/superseded as a planning mechanism. Remaining implementation is strictly:

```text
R1  Review policy exact-revision qualification
 ↓
C4  Atomic Publication
 ↓
C5  Installation / Security
 ↓
B1  Backend schema + modular-monolith implementation
 ↓
A1  real Backend ↔ Flutter cross-system acceptance
 ↓
MVP release hardening
```

Backend JPA/schema is derived from accepted domain invariants; it must not mirror Flutter DTOs blindly.
