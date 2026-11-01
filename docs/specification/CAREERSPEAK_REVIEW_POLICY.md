# CareerSpeak — Review Scheduling Policy

**Status:** Normative MVP policy  
**Applies to:** CareerSpeak v1 local review scheduling

## 1. Scope

This policy defines the minimal deterministic transition from an explicit learner review outcome to the next local review schedule.

Input:

```text
current reviewStage
review outcome = incorrect / hard / correct / known
now
```

Output:

```text
next reviewStage
nextReviewAt
lastReviewOutcome
```

The policy is device-owned and deterministic. It is not an implementation of FSRS, SM-2, ML scheduling or adaptive prediction.

## 2. Stage model

`reviewStage` is a non-negative integer.

MVP policy:

```text
incorrect → stage 0
hard      → max(currentStage, 1)
correct   → currentStage + 1
known     → currentStage + 2
```

No outcome may produce a negative stage.

## 3. Interval table

The interval is derived only from the resulting stage and outcome.

### incorrect

```text
next stage: 0
interval: 10 minutes
```

### hard

```text
next stage: max(currentStage, 1)
interval: 1 day
```

### correct

Resulting-stage interval:

```text
stage 1 → 2 days
stage 2 → 4 days
stage 3 → 7 days
stage 4 → 14 days
stage 5+ → 30 days
```

### known

Resulting-stage interval:

```text
stage 2 → 7 days
stage 3 → 14 days
stage 4 → 30 days
stage 5+ → 60 days
```

## 4. Determinism

For the same `(currentStage, outcome, now)` the policy MUST return the same result.

`nextReviewAt` is computed as:

```text
now.toUtc() + deterministic interval
```

No randomness, server recommendation, analytics state, content popularity or hidden learner score may influence the result.

## 5. Due semantics

The existing product rule remains unchanged:

```text
Due = nextReviewAt <= now
```

`Not completed` is not `Due`.

## 6. Persistence

The result is persisted through the existing `ReviewScheduleRepository` / `content_review_states` boundary.

The policy itself is a pure application/domain service and MUST NOT read or write SQLite directly.

## 7. Non-goals

MVP does not include:

```text
FSRS
SM-2
ML scheduler
per-skill forgetting curves
difficulty estimation
server-side learner profile
cross-device review synchronization
```

Any later replacement must be introduced as a versioned product-policy change rather than silently changing intervals.
