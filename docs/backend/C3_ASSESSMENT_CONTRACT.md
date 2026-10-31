# C3 Assessment Contract

**Status:** IMPLEMENTING  
**Baseline:** C2 accepted at `92a8a2e01575869b8f94ec874a6d77b0cc7fee16`  
**Normative component contract:** `contracts/c3-assessment-v1.yaml`

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

Question order is contiguous from zero. The same exact question revision cannot appear twice in one test revision.

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
missing answer                 = incorrect / zero points
answer outside option set      = fail closed
answer for unknown order       = fail closed
missing exact QuestionRevision = fail closed
newer QuestionRevision         != old referenced revision
passed                         = scoreBasisPoints >= passingScoreBasisPoints
```

A completed historical attempt can therefore be reproduced from the exact `PracticeTestRevision`, exact referenced `QuestionRevision` set and captured answers.

## Checksum rule

C3 immutable projections use the C2 RFC 8785 / SHA-256 canonicalization rule. A projection checksum covers its complete immutable body while omitting only its own top-level `checksum` member from the digest input. Nested ref checksums remain included.

## Implementation slices

```text
C3.1 PracticeTest / PracticeTestRevision contract       IMPLEMENTING
C3.2 Question / QuestionRevision typed body            IMPLEMENTING
C3.3 exact ordered TestQuestionRef                      IMPLEMENTING
C3.4 deterministic scoring                             IMPLEMENTING
C3.5 production decoder/gateway                        PENDING
C3.6 Drift assessment persistence                      PENDING
C3.7 offline/restart reproducibility                    PENDING
C3.8 adversarial qualification                          PENDING
C3.9 exact-SHA full production CI                       PENDING
```

## Acceptance direction

C3 is not accepted until production delivery and persistence prove:

```text
exact test/question revisions survive restart/offline
scoring is reproducible after newer revisions are published
unsupported/malformed assessment payloads fail closed
production repository no longer uses unavailable/mock assessment source
full exact-SHA production CI is green
```

Endpoint/publication composition remains C4. C3 freezes the component semantics first so backend assessment tables are derived from domain invariants rather than from the current Flutter mock objects.
