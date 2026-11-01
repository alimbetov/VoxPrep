# CareerSpeak — R1 Review Policy Acceptance

## Scope

R1 is accepted only when all of the following are true:

```text
[ ] policy is pure and deterministic
[ ] incorrect/hard/correct/known transitions are versioned in product docs
[ ] negative/corrupt stage input fails closed to stage zero before transition
[ ] scheduler persists only through ReviewScheduleRepository
[ ] exact identity remains ContentIdentity(code,type)
[ ] Due remains nextReviewAt <= now
[ ] review outcome action reschedules immediately
[ ] restart/reopen preserves nextReviewAt, reviewStage and lastReviewOutcome
[ ] future schedule removes the item from Due without catalogue-page dependence
[ ] CURRENT lookup still filters retired/missing content fail-closed
[ ] no ML/FSRS/SM-2/server learner dependency is introduced
[ ] analyzer + full regression are green on one exact SHA before R1 is declared ACCEPTED
```

## Deterministic decision table

| Outcome | Stage transition | Interval |
|---|---|---|
| incorrect | `0` | 10 minutes |
| hard | `max(current,1)` | 1 day |
| correct | `current+1` | stage table: 2/4/7/14/30 days |
| known | `current+2` | stage table: 7/14/30/60 days |

## Architecture boundary

```text
Review UI
  ↓ explicit learner outcome
ReviewScheduler
  ↓
ReviewSchedulingPolicy
  ↓ deterministic decision
ReviewScheduleRepository
  ↓
content_review_states
```

Neither UI nor persistence may duplicate the interval table.
