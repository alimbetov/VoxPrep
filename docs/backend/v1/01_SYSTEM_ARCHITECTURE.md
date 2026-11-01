# 01 — System Architecture and Ownership

**Status:** FROZEN DESIGN INPUT

## 1. Runtime topology

CareerSpeak v1 uses one backend deployment boundary:

```text
Flutter App
   │
   │ /api/v1/**
   ▼
Spring Boot modular monolith
   ├── PostgreSQL
   ├── RustFS adapter
   ├── /admin/**
   └── /internal/v1/tts/**
            │
            ▼
        TTS Worker
```

Three security actors exist:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

RustFS is not a client-facing actor/security zone.

## 2. Module boundaries

Recommended modules:

```text
catalogue
content
assessment
publication
localization
media
installation
admin
tts
shared-contract
```

Rules:

- no cross-module repository access;
- module interaction goes through application/domain interfaces;
- JPA entities remain persistence concerns;
- wire DTOs do not double as entities;
- `publication` owns the learner release barrier;
- modules involved in one publication must remain transactionally reachable inside the same monolith.

## 3. Backend ownership

Backend owns mutable product truth:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
Content
ContentRevision
ContentLocalizationRevision
PracticeTest
PracticeTestRevision
Question
QuestionRevision
Catalogue/taxonomy data
PublicationSnapshot
FileAsset/media metadata
TTS voice/model/job state
Installation status/security state
Admin authoring/review/publication state
```

## 4. Flutter ownership

Flutter owns learner state for MVP:

```text
onboardingCompleted
selectedGoalCode
selectedTrackCode
selfAssessedLevelCode
uiLocale
translationLocale
preferredAccent / preferredVoiceCode
FAVORITE
LISTENED
COMPLETED
last opened / Continue Learning
review stage / nextReviewAt / outcome
active PracticeTest attempt
PracticeTest completion/history
playback/local cache state
```

Backend MUST NOT create a learner-profile aggregate merely to duplicate these values.

`selectedVerticalCode` is not durable learner state. Flutter derives Vertical from the selected CURRENT Goal.

## 5. Learning hierarchy

The only v1 hierarchy is:

```text
Vertical
 ↓
LearningGoal
 ↓
LearningTrack
 ↓
LearningCollection
 ↓
exact ContentRevision / PracticeTestRevision membership
```

Stable business code is cross-system identity.

Database numeric IDs may exist internally but MUST NOT leak as Flutter learner-domain identity.

## 6. Fail-closed navigation semantics

When a previously selected object is no longer in CURRENT publication:

```text
invalid Track
→ clear Track
→ preserve valid Goal

invalid Goal/Vertical
→ clear Goal + Track
→ require learner to choose direction again
```

Backend must never require Flutter to auto-select a sibling or guess across Verticals.

## 7. Lifecycle vocabulary

Backend revision lifecycle:

```text
DRAFT
READY_FOR_AUDIO
READY_FOR_REVIEW
PUBLISHED
ARCHIVED
```

Availability:

```text
ACTIVE
INACTIVE
```

Learner-deliverable means:

```text
PUBLISHED + ACTIVE + member of current PublicationSnapshot
```

Flutter lifecycle is different:

```text
STAGING
VERIFIED
CURRENT
SUPERSEDED
FAILED
```

Never conflate Backend ACTIVE/PUBLISHED with Flutter CURRENT.

## 8. Architectural non-goals

Do not introduce for MVP:

```text
microservice split for catalogue/content/publication
shared distributed transaction
Kafka/RabbitMQ for content publication
learner account domain
remote UI schema
rules engine
recommendation service
server-side review scheduler
```

The v1 optimization target is correctness and deterministic publication, not distributed topology.