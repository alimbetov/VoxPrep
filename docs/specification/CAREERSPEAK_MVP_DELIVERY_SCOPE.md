# CareerSpeak MVP Delivery Scope

**Status:** Normative MVP delivery boundary  
**Applies to:** CareerSpeak v1

## 1. Final delivery roadmap

Only these five major implementation stages remain in scope for MVP:

```text
R1  Deterministic Review Policy
 ↓
C4  Atomic Publication
 ↓
C5  Installation / Security
 ↓
B1  Backend schema + modular-monolith implementation
 ↓
A1  Cross-system acceptance
```

### R1 — Deterministic Review Policy

Implement a small local policy:

```text
incorrect / hard / correct / known
        ↓
reviewStage transition
        ↓
nextReviewAt
```

Requirements:
- deterministic;
- local/device-owned;
- no ML/AI scheduler;
- no FSRS/SM-2 dependency for MVP;
- restart-safe through existing `content_review_states` persistence;
- `Due` remains strictly `nextReviewAt <= now`.

### C4 — Atomic Publication

Backend publication must expose one coherent CURRENT snapshot covering the mutable learning graph and exact immutable payload references.

Required consistency boundary:

```text
Vertical
Goal
Track
Collection
Content revisions
PracticeTest revisions
Localization
Assets / audio references
```

Flutter must never observe a mixed CURRENT publication assembled from unrelated publication versions.

### C5 — Installation / Security

MVP security remains installation-scoped:

```text
installationId
  ↓
registration
  ↓
installationToken
  ↓
authorized learner API
```

Required recovery:

```text
401
 ↓
invalidate stale token
 ↓
re-register installation
 ↓
retry through the normal client boundary
```

No mandatory learner account is introduced.

### B1 — Backend schema + implementation

Implement the accepted contracts as a Spring Boot modular monolith backed by PostgreSQL and RustFS.

Target modules:

```text
installation
catalogue
publication
content
assessment
localization
asset
tts
```

The TTS Worker remains a separate worker process because it is a distinct computational workload; this does not justify decomposing the backend into microservices.

### A1 — Cross-system acceptance

Qualify the real production path:

```text
Backend publication
 ↓
HTTP API
 ↓
Flutter sync
 ↓
Drift CURRENT
 ↓
offline
 ↓
restart
 ↓
content / audio / PracticeTest / Review
```

Acceptance must include stale/corrupt/replay/restart adversarial cases and exact-revision reproducibility.

## 2. Cancelled / out-of-MVP development

The following work is explicitly cancelled for CareerSpeak v1 unless a later versioned requirement reintroduces it with evidence:

```text
AI recommendation engine
recommendation microservice
AI personalization
LearningActivity backend aggregate
workflow / rules engine
server learner profile
mandatory learner accounts
email/password authentication
Google/Apple learner login
microservice decomposition
API Gateway
Kafka / RabbitMQ for learner-domain flows
Redis as an architectural dependency
Keycloak
advanced SRS / FSRS / SM-2 integration
ML review scheduler
runtime STT
pronunciation scoring
learner audio upload
runtime mobile TTS generation
Hero transition system
complex animation choreography
Rive / Lottie dependency
analytics domain / warehouse before telemetry approval
achievement / badge economy
leaderboards
social graph
remote UI schema
generic EAV content model
```

## 3. Allowed minimal UX polish

UX work before MVP release is limited to defects, accessibility, clarity and small native Flutter transitions that do not create a new feature stream.

Allowed examples:

```text
basic route transitions
favorite/selected-state feedback
basic test-state transition
reduced-motion support
error/empty-state copy fixes
```

These are subordinate to correctness and cross-system acceptance.

## 4. Architecture freeze rule

After R1, Flutter learner-domain architecture is considered feature-frozen for MVP.

New Flutter domain/application subsystems SHALL NOT be added before C4/C5/backend/cross-system acceptance unless they are required to fix a demonstrated correctness defect in an accepted contract.

## 5. MVP completion path

```text
R1 Review Policy
  ↓
C4 Atomic Publication
  ↓
C5 Installation/Security
  ↓
Backend schema freeze
  ↓
Backend modular monolith
  ↓
real Backend ↔ Flutter acceptance
  ↓
offline/restart/corruption hardening
  ↓
minimal UX polish
  ↓
MVP release
```
