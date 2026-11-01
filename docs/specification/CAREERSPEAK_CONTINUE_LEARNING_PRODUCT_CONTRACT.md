# CareerSpeak — Continue Learning Product Contract

**Status:** Normative MVP contract  
**Applies to:** CareerSpeak v1 learner Home / resume flow

Related documents:

- [`CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md`](CAREERSPEAK_ONBOARDING_PRODUCT_CONTRACT.md)
- [`CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)

---

## 1. Product intent

`Continue Learning` answers one deterministic question:

> What is the safest next learner action using the learner's durable local state and the CURRENT published catalogue?

MVP does not require a recommendation engine, server learner profile, workflow engine, playback heuristic or AI ranking service.

The decision is local, deterministic, restart-safe and fenced by the CURRENT publication.

---

## 2. Normative priority

The resolver SHALL use this exact priority order:

```text
1. active PracticeTest attempt
2. unfinished last-opened Content
3. next incomplete member of the current Track
4. next Collection of the current Track that still contains incomplete work
5. browse current Track / current Vertical
6. Choose learning direction
```

A lower-priority candidate SHALL NOT replace a valid higher-priority candidate.

Input ordering from storage or catalogue transport SHALL NOT change the selected result.

---

## 3. Device-owned durable facts

Flutter owns these Continue Learning facts locally.

### 3.1 Active PracticeTest attempt

Minimum durable identity/state:

```text
practiceTestCode
practiceTestRevision
currentQuestionIndex
answers
startedAt
updatedAt
```

The revision is exact and pinned when the attempt starts.

An application/process restart SHALL restore the same active attempt.

### 3.2 PracticeTest completion

Completion is recorded against the exact immutable identity:

```text
(practiceTestCode, practiceTestRevision)
```

Submitting an active attempt SHALL atomically:

```text
record exact completion
+
remove the resumable active attempt
```

Completion of revision N SHALL NOT make revision N+1 complete.

A retake MAY start after completion without deleting historical completion evidence.

### 3.3 Last-opened Content

Minimum durable identity/state:

```text
contentCode
contentType
contentRevision
openedAt
```

`openedAt` means the learner actually opened the learner-facing content detail surface.

Background repository reads, cache warming, sync, audio progress and list rendering SHALL NOT manufacture a last-opened event.

The newest durable open event wins. A delayed older write SHALL NOT overwrite a newer open event.

---

## 4. No playback heuristic

Continue Learning SHALL NOT infer "last opened" from:

```text
lastPositionMs
lastPlayedAt
listenCount
recent cache access
asset download time
repository read time
```

Playback/listening state remains useful learner progress, but it is not the identity source for the Continue Learning priority contract.

---

## 5. CURRENT publication fencing

Every resumable catalogue-backed candidate SHALL be revalidated against the single CURRENT publication before it becomes learner-visible.

Fail closed when a candidate is:

```text
missing from CURRENT
inactive through its ownership hierarchy
pointing to a stale revision
dangling from its Collection
owned by a stale selected Goal/Track
structurally inconsistent
```

The resolver itself does not repair stale data and does not guess a replacement identity.

---

## 6. Current hierarchy

The learner hierarchy is:

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

Current Vertical is derived from the selected CURRENT Goal.

If selected Track is missing/inactive but Goal remains valid, the normal learner-selection normalization rules apply.

If Goal/Vertical is no longer valid, Continue Learning SHALL eventually fall through to `Choose learning direction`; it SHALL NOT silently jump to another Vertical.

---

## 7. Exact completion semantics

A Content member is complete for Continue Learning only when the local completion evidence applies to the exact CURRENT content revision.

Conceptually:

```text
completed == true
AND
lastRevisionSeen == CURRENT member revision
```

A PracticeTest member is complete only when its exact `(code, revision)` exists in durable PracticeTest completion state.

Older-revision completion evidence does not suppress a newer CURRENT revision.

---

## 8. Deterministic member selection

For multiple incomplete CURRENT members, selection SHALL be stable and independent of query/list iteration order.

The current deterministic ordering is:

```text
Collection sortOrder
→ Collection code
→ member position
→ stable target identity tie-breaker
```

Content and PracticeTest identities retain their exact revisions throughout the decision.

---

## 9. Collection fallback

A Collection is eligible for priority #4 only if it belongs to the validated current Track and still contains at least one exact incomplete CURRENT member.

Therefore:

```text
all members completed
→ Collection is not a Continue Learning candidate
→ do not loop back to the first completed Collection
→ fall through to browse current Track
```

Priority #4 exists as a collection-level fallback; it does not override a directly resumable/incomplete member at priority #3.

---

## 10. Home integration

Home SHALL render the already-resolved Continue Learning target.

Home presentation SHALL NOT contain a parallel decision algorithm such as:

```text
first content where completed == false
first cached item
first recently played item
first catalogue item
```

The Home card MAY vary its learner-facing title/subtitle by resolved action, but navigation identity SHALL come from the validated decision.

---

## 11. Failure behavior

If durable Continue Learning state is temporarily unreadable, the application SHALL fail safely rather than fabricate a candidate.

Corrupt durable payloads SHALL surface as controlled application failures and SHALL NOT be interpreted as valid resume state.

When no valid candidate remains, the deterministic terminal fallback is:

```text
valid selected Track   → browse Track
valid selected Vertical without Track → browse Vertical
no valid direction     → Choose learning direction
```

---

## 12. Restart acceptance

The Continue Learning contract is restart-safe only when all of the following hold:

```text
active attempt survives process/repository re-instantiation
last-opened Content survives process/repository re-instantiation
exact PracticeTest completion survives process/repository re-instantiation
submitted attempt is no longer resumable
stale durable revision is rejected against CURRENT
completed exact member is not selected again
completed Collection does not loop
input order permutations do not change the decision
```

---

## 13. Explicit non-goals

Do not add for MVP Continue Learning:

```text
server learner profile
recommendation service
AI ranking
workflow engine
remote UI decision schema
playback-position-based resume identity
cross-device progress synchronization
probabilistic ranking
```

These require separate versioned product decisions if introduced later.

---

## 14. Acceptance checklist

```text
[ ] exact priority 1→6 is implemented once in the application decision layer
[ ] active PracticeTest attempt is durable and exact-revision pinned
[ ] submit atomically persists exact completion and clears active attempt
[ ] last-opened Content is an explicit durable open event
[ ] playback state is not used as a last-opened heuristic
[ ] every catalogue-backed candidate is fenced by CURRENT
[ ] stale/inactive/dangling candidates fail closed
[ ] Content completion is exact-revision aware
[ ] PracticeTest completion is exact-revision aware
[ ] member and Collection selection are deterministic
[ ] fully completed Collections cannot loop
[ ] Home consumes the resolved target and contains no competing heuristic
[ ] restart and adversarial qualification cover durable facts and decision fallbacks
```
