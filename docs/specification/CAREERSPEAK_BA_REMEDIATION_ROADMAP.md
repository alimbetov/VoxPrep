# CareerSpeak / VoxPrep — BA Product Contract Remediation Roadmap

**Status:** Reconciled / implementation-complete for Flutter BA scope  
**Branch:** `feat/ba-product-contract-remediation`  
**Purpose:** Historical traceability of the product/business-analysis remediation that established the CareerSpeak v1 learner contract.

Normative current sources:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`](CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md)

This roadmap no longer re-opens feature scope. If any historical item below conflicts with those normative documents, the normative documents win.

---

## 1. Remediation objective

The remediation stream removed product ambiguity around:

```text
Vertical ownership
3-step onboarding
learner selection ownership
Continue Learning
exact revision completion
PracticeTest lifecycle
Review / Due
learner media boundary
MVP scope freeze
```

Primary rule:

```text
one business rule
→ one normative definition
→ one ownership decision
→ measurable acceptance criteria
→ traceable implementation/tests
```

---

## 2. Frozen product model

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

Backend owns catalogue/product truth. Flutter owns device-local learner state and synchronized CURRENT projections.

---

## 3. Remediation decisions

### BA-01 — Vertical normative hierarchy — ACCEPTED

`Vertical` is the learner-facing root of every Goal/Track/Collection chain. A Goal belongs to exactly one Vertical. Adding a Vertical requires backend catalogue data, not a permanent Flutter enum or dedicated code path.

### BA-02 — Onboarding — ACCEPTED

Exactly three learner decisions:

```text
1. Vertical + LearningGoal
2. B1 / B2 / C1 / Not sure
3. support language
```

Skippable, account-free, restart-safe, CURRENT-validated. Skip preserves explicit choices and never fabricates a learning direction.

### BA-03 — Learner selection ownership — ACCEPTED

Persist:

```text
selectedGoalCode?
selectedTrackCode?
```

Current Vertical derives from the selected CURRENT Goal.

The previously proposed automatic sibling fallback is **cancelled**. Normative fail-closed behavior is:

```text
Track inactive/missing
→ clear Track
→ preserve active Goal

Goal inactive/missing
→ clear Goal + Track
→ current Vertical unset
→ Choose learning direction

Vertical inactive/missing
→ selected Goal invalid
→ same Goal rule
```

Never select the first active Track/Goal automatically and never cross to another Vertical silently.

### BA-04 — Continue Learning — ACCEPTED / IMPLEMENTED

Priority:

```text
1. resumable active PracticeTest attempt
2. unfinished last-opened Content
3. next incomplete current-Collection member
4. next eligible Collection in current Track
5. current Track / current Vertical browse entry
6. Choose learning direction
```

Every candidate is revalidated against CURRENT. Tombstoned, inactive, dangling and revision-mismatched targets are skipped, not repaired by guessing.

### BA-05 — Completion/revision semantics — ACCEPTED / IMPLEMENTED

Ordinary Content completion is explicit learner intent. `LISTENED` never implies `COMPLETED`.

PracticeTest completion occurs on valid submit.

Completion is exact-revision aware:

```text
Completed revision N
!=
automatically Completed revision N+1
```

Historical learner state is not rewritten by publication updates.

### BA-06 — Assessment — ACCEPTED AT MVP CONTRACT LEVEL

PracticeTest attempts are restart-safe and revision-pinned. Submitted completion/history preserves exact test revision identity.

No recommendation service, universal pass threshold or AI dependency is required by the v1 product contract.

Any richer LEARN/EXAM/QUICK presentation behavior that is not already implemented is not a reason to reopen the Flutter learner-domain architecture before C4/C5/B1/A1.

### BA-07 — Review policy — ACCEPTED / IMPLEMENTED

Strict Due semantics:

```text
Due = nextReviewAt <= now
Due != !Completed
```

Normative deterministic v1 outcome policy is defined in [`CAREERSPEAK_REVIEW_POLICY.md`](CAREERSPEAK_REVIEW_POLICY.md).

Review state:

```text
nextReviewAt
reviewStage
lastReviewOutcome
```

The scheduler is local, deterministic, UTC-based and restart-safe.

### BA-08 — Favorites / Downloads — RECONCILED, NO NEW FEATURE STREAM

The older roadmap proposed dedicated Favorites and Downloads screens. That scope is superseded.

CareerSpeak v1 requires:

```text
FAVORITE durable local marker/filter
verified offline asset download/cache infrastructure
AssetResolver offline use
learner state preserved across cache/media cleanup
```

CareerSpeak v1 does **not** require:

```text
standalone Favorites screen/area
user-managed Downloads dashboard
collection download library/storage dashboard
```

Those convenience surfaces are post-MVP.

### BA-09 — Device-local learner state — ACCEPTED

MVP intentionally has no learner account/cloud learner profile.

```text
uninstall / device loss / app-data reset
→ local learner state may be lost
```

Cloud sync is a future capability, not an implicit v1 promise.

### BA-10 — Collection continuation/completion — ACCEPTED FOR MVP CONTINUATION

Continue Learning only proposes a Collection when it has at least one exact incomplete CURRENT member. A fully completed Collection cannot create a continuation loop.

No optional-member curriculum engine is introduced in v1.

### BA-11 — Search scope — ACCEPTED

Search defaults to current Vertical when a current direction exists. Cross-Vertical expansion must be explicit and search results retain enough hierarchy context to explain ownership.

### BA-12 — Empty/error states — ACCEPTED AS UX POLICY

Normal learner states include no Review due, no search results, unavailable optional audio/translation and empty hierarchy levels. UI must use learner-safe copy and avoid raw engineering terminology/exceptions.

### BA-13 — Admin workflow — ACCEPTED

One ADMIN is sufficient. `READY_FOR_REVIEW` is a content process state, not a security role. A single admin may author, prepare/review audio and publish, subject to publication validation.

### BA-14 / BA-15 — Metrics and telemetry — DEFERRED

Success metrics may be defined for product validation, but no analytics platform/domain is an MVP architectural dependency until telemetry/privacy requirements are explicitly approved.

### BA-16 — Commercial mode — DEFERRED / NO ENTITLEMENT CONTRACT

Payments/subscriptions/marketplace are outside CareerSpeak v1. No entitlement behavior may be invented inside learner/backend implementation.

### BA-17 — Learner media delivery — ACCEPTED

The earlier A/B decision is resolved for v1.

Normative path:

```text
Flutter installation token
→ authenticated Backend learner media API
→ Backend-controlled byte delivery
→ Flutter size/checksum verification
→ verified local asset
```

Rules:

```text
Flutter receives no RustFS/object-storage credentials
Flutter does not treat deliveryKey as a remote URL
Backend owns learner media authorization
verified local files remain usable offline
```

A direct/signed object-storage grant is not part of v1 and would require a separate versioned future contract.

---

## 4. Traceability expectations

Every active MVP capability should map to:

| Layer | Evidence |
|---|---|
| Business outcome | learner/system value |
| Business rule | deterministic normative rule |
| Acceptance | positive + negative/adversarial behavior |
| Backend contract | ownership/API/publication impact |
| Flutter | state/navigation/application impact |
| Persistence | durable/restart impact |
| Tests | unit/integration/widget/E2E as appropriate |

Line coverage alone is not proof of business completeness.

---

## 5. Final remediation closure

Business/functional remediation is sufficient when:

```text
[✓] Vertical → Goal → Track → Collection is normative everywhere
[✓] onboarding has one final 3-decision definition
[✓] current learner selection is fail-closed and deterministic
[✓] Continue Learning priority is deterministic and CURRENT-revalidated
[✓] completion/test semantics preserve exact revision identity
[✓] Review/Due policy is deterministic and restart-safe
[✓] Favorites/Downloads no longer create mandatory feature streams
[✓] device-local state limitation is explicit
[✓] learner media uses one Backend-authorized contract
[✓] telemetry/commercial work is explicitly deferred rather than implied
[✓] remaining delivery gates are explicit
```

The remaining active MVP delivery sequence is not another BA feature backlog:

```text
R1 exact-revision engineering qualification
 ↓
C4 Atomic Publication
 ↓
C5 Installation / Security
 ↓
B1 Backend schema + modular-monolith implementation
 ↓
A1 Backend ↔ Flutter cross-system acceptance
```

No new Flutter learner-domain stream should be created before these gates unless required to correct a demonstrated defect in an accepted contract.
