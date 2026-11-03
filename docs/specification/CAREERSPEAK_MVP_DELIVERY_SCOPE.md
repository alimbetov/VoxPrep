# CareerSpeak MVP Delivery Scope

**Status:** Normative MVP delivery boundary  
**Applies to:** CareerSpeak v1

Related reconciliation record:

- [`CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`](CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md)

When an older roadmap/backlog conflicts with this document, this MVP delivery boundary wins unless a newer versioned product requirement explicitly supersedes it.

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

`R1` is functionally implemented on the Flutter remediation branch. Its remaining closure condition is exact-revision engineering qualification, not an unresolved product decision.

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

Required activation semantics:

```text
stage complete candidate
→ validate refs/revisions/checksums
→ single atomic CURRENT activation
→ readers observe only one publication identity
```

An incomplete/corrupt candidate never replaces the last-known-good CURRENT. Restart must preserve or deterministically recover the previous valid CURRENT.

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

Registration/re-registration must be idempotent for the same installation identity where the contract permits.

Required bounded recovery:

```text
401
 ↓
invalidate stale token only
 ↓
preserve installationId + learner state
 ↓
re-register once
 ↓
retry a safe request once through the normal client boundary
 ↓
fail closed on repeated rejection
```

No mandatory learner account is introduced.

### B1 — Backend schema + implementation

Implement the accepted contracts as a Spring Boot modular monolith backed by PostgreSQL and private RustFS integration.

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

The secured Content Studio and XML bulk authoring defined by [`CAREERSPEAK_CONTENT_STUDIO_REQUIREMENTS.md`](CAREERSPEAK_CONTENT_STUDIO_REQUIREMENTS.md) are allowed **inside B1** as internal authoring/productivity tooling for the already normative `ADMIN` actor. They do not create a sixth feature stream or an independent MVP release gate. V1 authoring must remain deliberately small: server-rendered admin UI, secure XML validation/preview/diff/apply, draft editing and publication preparation only as required to populate the accepted Backend domain.

### A1 — Cross-system acceptance

Qualify the real production path:

```text
Backend publication
 ↓
HTTP learner API
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

Acceptance must include stale/corrupt/replay/interruption/restart adversarial cases and exact-revision reproducibility.

## 2. Flutter feature boundary

After R1, Flutter learner-domain architecture is feature-frozen for MVP.

The following existing capabilities remain part of the MVP contract:

```text
3-step onboarding
Vertical / Goal / Track / Collection discovery
Continue Learning
content read/listen/repeat
PracticeTest lifecycle
FAVORITE / LISTENED / COMPLETED learner markers
Review / Due
verified offline asset use
local restart-safe learner state
```

The following convenience surfaces are **not** MVP release gates and SHALL NOT reopen new feature streams before C4/C5/B1/A1:

```text
standalone Favorites screen/area
user-managed Downloads dashboard
collection download library/storage dashboard
```

`FAVORITE` remains a durable local marker/filter. Offline support remains mandatory through sync/download/verification/AssetResolver infrastructure; a dedicated Downloads UI is deferred.

## 3. Learner media decision

CareerSpeak v1 uses one Flutter-facing media boundary:

```text
Flutter installation token
→ authenticated Backend learner media API
→ Backend-controlled byte delivery
→ local size/checksum verification
→ verified local asset
```

Normative invariants:

```text
Flutter receives no RustFS/object-storage credentials
Flutter does not interpret deliveryKey as a remote URL
Backend owns learner media authorization
verified local assets remain usable offline
```

A signed object-storage grant model is not part of the v1 contract and requires a separately versioned future decision if introduced.

## 4. Cancelled / out-of-MVP development

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
standalone Favorites feature stream
user-managed Downloads feature stream
```

## 5. Allowed minimal UX polish

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

## 6. Architecture freeze rule

After R1, Flutter learner-domain architecture is considered feature-frozen for MVP.

New Flutter domain/application subsystems SHALL NOT be added before C4/C5/backend/cross-system acceptance unless they are required to fix a demonstrated correctness defect in an accepted contract.

Mocks/demo catalogues may remain test fixtures only. Production catalogue/runtime state originates from Backend API + synchronized local CURRENT projection.

## 7. MVP completion path

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
