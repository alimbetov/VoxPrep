# C3 Assessment Contract

**Status:** ACCEPTED  
**Accepted exact-SHA baseline:** `49937959a1ce71322abec159dd36a41e72137bd0`  
**Normative contract:** `contracts/c3-assessment-v1.yaml`

## Scope

C3 closes `BGA-004` by freezing production assessment semantics before backend persistence/schema design.

Minimum immutable model:

```text
PracticeTest
PracticeTestRevision
Question
QuestionRevision
TestQuestionRef
```

C1 and C2 remain frozen. C3 does not change root/localization or typed content semantics.

## Question model

The MVP assessment question kind is intentionally narrow:

```text
singleChoice
```

A `QuestionRevision` is immutable and identified by:

```text
(questionCode, revision, checksum)
```

`SingleChoiceQuestionBody` contains:

```text
prompt
options[]
correctOptionIndex
skillCode
explanation
```

Unknown question kinds are not accepted implicitly. New kinds require an explicit future contract extension.

## Test revision

A `PracticeTestRevision` is immutable and identified by:

```text
(practiceTestCode, revision, checksum)
```

It owns:

```text
title
subtitle
mode
passingScoreBasisPoints
questionRefs[]
```

Every `TestQuestionRef` carries:

```text
order
exact QuestionRevision identity
points
```

`questionRefs[]` array order is semantic and checksum-covered. The array must already be contiguous `0..N-1`; Flutter never sorts or repairs it. The same `questionCode + revision` cannot occur twice, even with different checksums.

## Exact payload delivery

C3 owns exact immutable assessment payload delivery:

```text
GET /api/v1/assessment/practice-tests/{practiceTestCode}/revisions/{revision}
GET /api/v1/assessment/questions/{questionCode}/revisions/{revision}
```

The expected checksum comes from the exact immutable ref and is verified against the response. A same-code/same-revision payload with another checksum is an integrity mismatch and fails closed.

C4 owns **publication membership**: which exact `PracticeTestRevision` is current/referenced by a published collection/root. C3 does not add a competing mutable assessment-list endpoint.

## Deterministic scoring

Scoring uses integer points and integer basis points only:

```text
earnedPoints
---------------- * 10000
 totalPoints
```

The result uses integer floor division. No floating-point rounding is part of the contract.

Rules:

```text
missing answer                    = incorrect / zero points
answer outside option set         = fail closed
answer for unknown order          = fail closed
Missing exact `QuestionRevision`  = fail closed
newer QuestionRevision            != old referenced revision
passed                            = scoreBasisPoints >= passingScoreBasisPoints
```

A completed historical attempt can therefore be reproduced from the exact `PracticeTestRevision`, exact referenced `QuestionRevision` set and captured answers.

## Checksum rule

C3 immutable projections use the C2 RFC 8785 / SHA-256 canonicalization rule. A projection checksum covers its complete immutable body while omitting only its own top-level `checksum` member from the digest input. Nested ref checksums remain included.

## Implementation slices

```text
C3.1 PracticeTest / PracticeTestRevision contract       ACCEPTED
C3.2 Question / QuestionRevision typed body            ACCEPTED
C3.3 exact ordered TestQuestionRef                      ACCEPTED
C3.4 deterministic scoring                             ACCEPTED
C3.5 production decoder/gateway                        ACCEPTED
C3.6 Drift assessment persistence / schema v8          ACCEPTED
C3.7 offline/restart reproducibility                    ACCEPTED
C3.8 adversarial qualification                          ACCEPTED
C3.9 exact-SHA full production CI                       ACCEPTED
```

## Acceptance evidence

Accepted exact-SHA baseline:

```text
49937959a1ce71322abec159dd36a41e72137bd0
ci(c3): qualify Drift v8 production baseline
```

`Flutter Production Adapters` run `41207314641` completed successfully on that exact SHA with:

```text
format                         PASS
Drift v8 reproducibility       PASS
flutter analyze                PASS
full flutter test              PASS
```

`C3 Drift v8 Qualification` run `41207305741` completed successfully on the same exact SHA with:

```text
Drift v8 generation            PASS
schema v8 assertions           PASS
flutter analyze                PASS
targeted C3 lifecycle          PASS
full regression                PASS
```

This proves:

```text
exact test/question revisions survive restart/offline
scoring is reproducible after newer revisions are published
unsupported/malformed assessment payloads fail closed
same logical revision with conflicting checksum fails closed
production exact-revision reads do not depend on mock assessment objects
full exact-SHA production CI is green
```

The legacy `PracticeTestRepository` list/current projection is intentionally not forced into C3. Its current-membership source is publication metadata and therefore belongs to C4. C3 creates the production exact-revision boundary that C4 will compose into the learner-visible assessment catalogue.
