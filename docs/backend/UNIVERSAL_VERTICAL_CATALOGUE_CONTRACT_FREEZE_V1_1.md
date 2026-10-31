# Universal Vertical Catalogue — Contract Freeze v1.1

**Date:** 2026-10-31  
**Branch:** `feat/universal-vertical-catalogue`  
**Status:** normative delta over `UNIVERSAL_VERTICAL_CATALOGUE.md` v1.0.

This document freezes the backend/Flutter contract decisions introduced after v1.0. Where it conflicts with v1.0 examples, this document wins.

## 1. Catalogue hierarchy

```text
VerticalSection
  -> LearningVertical
      -> LearningGoal
          -> LearningTrack
              -> LearningCollection
                  -> ordered LearningCollectionMember[]
                      -> exact ContentRevision OR exact PracticeTestRevision
```

`PracticeTest` is not a child of `Content` and MUST NOT contain `contentId`, `contentCode`, `contentRevisionId` or an equivalent direct ownership link for this MVP.

Content and tests are peers in one ordered collection stream. A test checks the learning scenario represented by the collection. Test internals continue to reference exact Question revisions according to the assessment contract.

## 2. Initial vertical dataset

The initial backend/demo seed contains eight active business verticals:

- `JAVA_INTERVIEW`
- `QA_INTERVIEW`
- `DEVOPS_INTERVIEW`
- `AWS`
- `KUBERNETES`
- `MEDICAL_ENGLISH`
- `SALES_ENGLISH`
- `BANKING_ENGLISH`

Eight is seed data, not a Flutter limit. Compatible clients MUST accept any number of backend-owned vertical records.

## 3. Presentation catalogues

The publication graph contains these additional catalogue kinds:

- `vertical-sections`
- `verticals`
- `vertical-presentation`

Supported presentation modes are `CAROUSEL`, `SHELVES`, and `GRID`. Flutter MUST NOT derive the mode from the number or business code of verticals.

## 4. LearningCollection wire contract

The previous transition shape with `contentRefs[]` plus `practiceTestRefs[]` is obsolete and MUST NOT be emitted by backend schema v2.

Normative item:

```json
{
  "code": "JAVA_DEPENDENCY_INJECTION",
  "verticalCode": "JAVA_INTERVIEW",
  "trackCode": "JAVA_SENIOR_INTERVIEW",
  "title": "Dependency Injection",
  "description": "Explain dependency injection clearly.",
  "sortOrder": 0,
  "active": true,
  "members": [
    {
      "position": 0,
      "type": "CONTENT",
      "content": {
        "contentCode": "JAVA_DI_EXPLANATION",
        "contentType": "topic",
        "revision": 3,
        "checksum": "<sha256>"
      },
      "practiceTest": null
    },
    {
      "position": 1,
      "type": "PRACTICE_TEST",
      "content": null,
      "practiceTest": {
        "practiceTestCode": "JAVA_DI_TEST",
        "revision": 2,
        "checksum": "<sha256>"
      }
    }
  ]
}
```

### Invariants

1. `members` is non-empty.
2. `position` starts at `0` and is contiguous: `0..N-1`.
3. `type=CONTENT` requires exactly one `content` reference and no `practiceTest` reference.
4. `type=PRACTICE_TEST` requires exactly one `practiceTest` reference and no `content` reference.
5. Duplicate exact member references inside one collection are rejected.
6. Every referenced revision is immutable and checksum-exact.
7. Collection, content and practice test belong to the same `verticalCode`; publication validation rejects cross-vertical membership.
8. The order is semantic and must survive publication, download, Drift persistence, restart and offline reads unchanged.

## 5. Backend DTOs

Recommended DTO names:

```text
LearningCollectionDto
  code
  verticalCode
  trackCode
  title
  description
  sortOrder
  active
  List<LearningCollectionMemberDto> members

LearningCollectionMemberDto
  position
  type: CONTENT | PRACTICE_TEST
  ContentRevisionRefDto? content
  PracticeTestRevisionRefDto? practiceTest
```

No endpoint or DTO may create a direct `PracticeTest -> Content` ownership relationship in this MVP.

## 6. Publication rule

The learner-visible catalogue remains immutable and snapshot-owned. Collection membership is part of the checksum boundary. Reordering members or replacing any exact revision creates a new catalogue revision and becomes visible only through an atomic CURRENT snapshot switch.

## 7. Demo mode

Demo data must use the same DTOs, decoder, graph validation and repository path as production. It may differ only at the source gateway and controlled latency/failure simulation. Demo fixtures must therefore use `members[]`, never the obsolete split-ref representation.
