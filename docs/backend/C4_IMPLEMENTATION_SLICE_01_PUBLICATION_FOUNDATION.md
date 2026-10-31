# C4 — Implementation Slice 01: Publication Foundation

**Status:** READY FOR BACKEND IMPLEMENTATION  
**Parent contract:** `docs/backend/C4_ATOMIC_PUBLICATION_CONTRACT.md`  
**Wire contract:** `contracts/learner-api-v1.yaml`

## 1. Goal

Implement the smallest backend foundation that can later publish one immutable learner-visible `PublicationSnapshot` atomically.

This slice does **not** implement Admin authoring UI, learner authentication, media signing, or Flutter changes. It establishes the publication transaction boundary and persistence invariants required by C4.

## 2. Domain boundary

Introduce a dedicated publication module/package with these conceptual responsibilities:

```text
PublicationService
    ↓
validate candidate publication graph
    ↓
allocate monotonic contentVersion
    ↓
materialize immutable root snapshot
    ↓
persist exact publication refs
    ↓
atomically switch CURRENT pointer
```

C4 MUST NOT depend on installation/session/token state.

## 3. Minimum persistence model

The implementation may adapt names to project conventions, but the minimum relational model is:

```text
publication_snapshot
- id
- content_version               UNIQUE, NOT NULL
- schema_version                NOT NULL
- minimum_app_contract_version  NOT NULL
- published_at                  NOT NULL
- checksum                      NOT NULL
- state                         BUILDING | PUBLISHED
- created_at                    NOT NULL

publication_pack_ref
- publication_snapshot_id       FK
- pack_code                     NOT NULL
- variant                       NOT NULL
- revision                      NOT NULL
- checksum                      NOT NULL
- sort_order                    NOT NULL
- UNIQUE(publication_snapshot_id, pack_code, variant)

publication_tombstone
- publication_snapshot_id       FK
- content_code                  NOT NULL
- content_type                  NOT NULL
- revision                      NOT NULL
- reason                        NOT NULL
- UNIQUE(publication_snapshot_id, content_code, content_type)

publication_current
- singleton_key                 PK
- publication_snapshot_id       FK UNIQUE
```

`publication_current` is the only mutable pointer required for learner publication visibility.

## 4. Monotonic contentVersion

`contentVersion` is allocated transactionally and MUST NOT be reused.

Recommended PostgreSQL mechanism:

```text
sequence: publication_content_version_seq
```

A failed publication may consume a number. Gaps are allowed; reuse is forbidden.

Invariant:

```text
v43 failed
v44 published

VALID

v43 reused later

FORBIDDEN
```

## 5. Publication transaction

One successful publish operation executes conceptually as:

```text
BEGIN

1. allocate next contentVersion
2. validate all exact referenced revisions
3. validate required FileAssets are READY/published
4. materialize deterministic pack refs/tombstones
5. compute deterministic root checksum
6. insert immutable PublicationSnapshot
7. insert exact child refs
8. mark snapshot PUBLISHED
9. UPSERT publication_current -> new snapshot

COMMIT
```

No learner request may observe a partially built snapshot.

If any step fails:

```text
ROLLBACK
publication_current unchanged
previous published snapshot remains authoritative
```

## 6. Immutability

After `state = PUBLISHED`, these fields and child refs are immutable:

```text
contentVersion
schemaVersion
minimumAppContractVersion
publishedAt
checksum
pack refs
pack revisions/checksums
tombstones
```

Do not implement "edit published snapshot" operations.

A correction creates another publication with another `contentVersion`.

## 7. Deterministic root materialization

Before checksum calculation, all unordered inputs MUST be canonically ordered.

Minimum ordering rules:

```text
pack refs:
  packCode ASC
  variant ASC

tombstones:
  contentType ASC
  contentCode ASC
```

The canonicalization service owns checksum semantics; database row order MUST NOT affect identity.

C4 Slice 01 should expose a dedicated abstraction such as:

```text
PublicationCanonicalizer
PublicationChecksumService
```

Exact serialization format/golden vectors may be completed with BGA-016, but no ad-hoc `ObjectMapper.writeValueAsBytes(entity)` hashing is allowed.

## 8. CURRENT read model

Learner root lookup reads only the snapshot referenced by `publication_current`.

```text
publication_current
       ↓
PublicationSnapshot v42
       ↓
RootContentManifest
```

It MUST NOT dynamically assemble CURRENT from mutable content tables.

Exact historical publication resources remain addressable according to retention rules even after CURRENT moves to a newer snapshot.

## 9. C4/C5 isolation

The following are forbidden in publication tables and checksum input:

```text
installationId
installation token
session id
authorization decision
signed URL
signed URL expiry
request trace id
```

C5 may gate access to a C4 resource, but it never changes C4 identity.

## 10. Concurrency

Two concurrent Admin publish attempts MUST serialize at the publication boundary.

Recommended rule:

```text
only one CURRENT pointer switch transaction may succeed at a time
```

Implementation options include a singleton row lock on `publication_current` or equivalent PostgreSQL locking. Do not use application-memory locking as the authoritative concurrency mechanism.

## 11. First acceptance tests

### C4-I01 — first publication

```text
no CURRENT
publish candidate
→ contentVersion allocated
→ snapshot PUBLISHED
→ CURRENT points to it
```

### C4-I02 — failed validation

```text
CURRENT = v42
candidate contains missing exact revision
publish
→ failure
→ no partial snapshot learner-visible
→ CURRENT remains v42
```

### C4-I03 — failed asset validation

Required asset is not READY:

```text
publish rejected
CURRENT unchanged
```

### C4-I04 — monotonic version

```text
publish v42
failed attempt consumes v43
publish next
→ v44
```

No reuse of v43.

### C4-I05 — published snapshot immutable

Attempts to mutate refs/checksum of PUBLISHED snapshot are impossible through application service and rejected by persistence constraints/policy.

### C4-I06 — concurrent publication

Two concurrent publish operations cannot produce an ambiguous CURRENT pointer or duplicate contentVersion.

### C4-I07 — security-independent identity

Same published snapshot read under two different installation sessions maps to the same root body/checksum/ETag identity.

## 12. Suggested backend package layout

For the future Spring Boot backend module:

```text
publication/
├── domain/
│   ├── PublicationSnapshot
│   ├── PublicationPackRef
│   ├── PublicationTombstone
│   └── PublicationState
├── application/
│   ├── PublicationService
│   ├── PublicationCandidateValidator
│   └── PublicationCanonicalizer
├── persistence/
│   ├── PublicationSnapshotEntity
│   ├── PublicationPackRefEntity
│   ├── PublicationTombstoneEntity
│   └── repositories
└── api/
    └── learner manifest projection (later slice)
```

Persistence entities MUST NOT become wire DTOs.

## 13. Definition of done

Slice 01 is complete when the future backend module proves on one exact SHA:

```text
Liquibase publication tables/sequence
+ transactional PublicationService
+ deterministic candidate ordering
+ atomic CURRENT switch
+ rollback leaves prior CURRENT intact
+ monotonic contentVersion tests
+ concurrency test
+ no C5/session state in publication identity
```

After this slice, C4 Slice 02 should implement the learner root projection and exact publication read path against the frozen `learner-api-v1.yaml` contract.
