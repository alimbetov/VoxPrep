# C4 — Atomic Publication Implementation Roadmap

**Status:** FROZEN IMPLEMENTATION ORDER  
**Parent contract:** `docs/backend/C4_ATOMIC_PUBLICATION_CONTRACT.md`

Current implementation status:

```text
C4.1  PublicationSnapshot identity          IMPLEMENTED
C4.2  exact revision membership             IMPLEMENTED
C4.3  atomic root/snapshot switch           IMPLEMENTED
C4.4  immutable publication manifest        IMPLEMENTED
C4.5  collection → content/test membership  IMPLEMENTED
C4.6  tombstone/publication interaction     IMPLEMENTED
C4.7  Flutter snapshot consumption          IMPLEMENTED / QUALIFICATION PENDING
C4.8  offline/restart consistency           QUALIFICATION IN PROGRESS
C4.9  adversarial atomicity                 PENDING
C4.10 exact-SHA qualification               PENDING
```

Implementation proceeds strictly in this order:

```text
C4.1  PublicationSnapshot identity
C4.2  exact revision membership
C4.3  atomic root/snapshot switch
C4.4  immutable publication manifest
C4.5  collection → content/test membership
C4.6  tombstone/publication interaction
C4.7  Flutter snapshot consumption
C4.8  offline/restart consistency
C4.9  adversarial atomicity
C4.10 exact-SHA qualification
```

## C4.1 — PublicationSnapshot identity

Freeze the authoritative publication aggregate identity:

```text
contentVersion
schemaVersion
minimumAppContractVersion
publishedAt
root checksum
ETag semantics
```

Rules:

- `contentVersion` is monotonic and never reused;
- publication identity is deterministic and immutable after publish;
- installation/token/session/signed-URL state is excluded from identity;
- failed publication may consume a version; gaps are valid.

Acceptance proves two installations observe identical publication identity for the same snapshot.

## C4.2 — Exact revision membership

A snapshot contains exact immutable references, never floating/current references.

Minimum membership categories:

```text
pack revision refs
canonical content revision refs
localized revision refs
assessment/test revision refs
catalogue revision refs
asset refs/checksums
```

Every ref must resolve during publication validation. Missing/dangling refs fail publication before CURRENT changes.

## C4.3 — Atomic root/snapshot switch

Introduce one transactional CURRENT pointer.

```text
build + validate complete snapshot
→ persist immutable snapshot
→ switch CURRENT
→ COMMIT
```

Any failure rolls back pointer change; previous CURRENT remains authoritative.

Concurrent publishers must serialize at the database boundary.

## C4.4 — Immutable publication manifest

Materialize learner-visible root/pack manifests from the published snapshot, not from mutable authoring tables.

Rules:

- exact ordering is deterministic;
- checksum/ETag are stable;
- published manifests cannot be edited in place;
- corrections produce a new publication version;
- expiring media grants are never embedded in manifest identity.

## C4.5 — Collection → content/test membership

Freeze publication membership for product navigation:

```text
LearningCollection
  → ordered exact Content refs
  → ordered exact PracticeTest refs
```

Membership must be snapshot-owned and reproducible. A later content/test edit must not rewrite an older published collection.

No floating `latest revision` lookup is allowed in a published collection.

## C4.6 — Tombstone/publication interaction

A tombstone is publication state, not an out-of-band delete command.

Rules:

- retirement becomes effective only through a new publication;
- tombstone targets stable business identity;
- tombstone revision records the last learner-deliverable canonical revision before retirement;
- old immutable revisions remain retained according to exact-resource retention policy;
- reactivation requires a later publication and explicit membership again.

## C4.7 — Flutter snapshot consumption

Flutter consumes one snapshot coherently:

```text
root
→ exact packs
→ exact content/localization/test/catalogue refs
→ assets
→ validate
→ atomic Drift projection
```

C5 token replacement may occur mid-sync but must retry the same exact resource and never change publication selection.

Implemented Flutter invariants:

- locale materialization preserves snapshot-owned `practiceTests[]` and `catalogues[]` unchanged;
- exact assessment and catalogue revisions are staged before publication completion;
- learner content, practice-test and catalogue reads are fenced by `ContentManifestStates.currentContentVersion`;
- practice tests and catalogues never select `latest`, `MAX(revision)` or another floating revision alias;
- pack-level no-op sync still repairs missing exact assessment/catalogue auxiliary projection;
- same-version auxiliary repair invalidates active UI streams without changing publication identity;
- production Riverpod composition uses Drift CURRENT-snapshot repositories rather than mock/unavailable adapters;
- catalogue delivery uses exact `kind + revision` addressing from publication membership.

C4.7 remains `QUALIFICATION PENDING` until the normal quality and focused C4 workflows pass on the same clean branch state. Exact-SHA closure remains owned by C4.10.

## C4.8 — Offline/restart consistency

Prove restart-safe synchronization:

- committed local CURRENT survives app/process restart;
- staged next snapshot never becomes learner-visible before atomic commit;
- interrupted download/sync resumes or safely restarts without mixing versions;
- if backend CURRENT advances during offline time, Flutter still opens its last committed snapshot before attempting refresh;
- exact historical resources required by in-flight recovery remain retrievable within the retention window.

## C4.9 — Adversarial atomicity

Attack the publication path with at least:

```text
dangling exact refs
wrong checksums
duplicate membership
order permutations
missing READY asset
late tombstone conflict
collection ref to retired content
concurrent publishers
transaction failure before CURRENT switch
transaction failure after snapshot inserts but before pointer switch
backend CURRENT advances during Flutter sync
401/token rotation mid-sync
exact resource disappears unexpectedly
repeated/reordered delivery
```

Expected result is always deterministic success or fail-closed behavior; never a mixed/partial learner-visible publication.

## C4.10 — Exact-SHA qualification

C4 closes only on one exact commit SHA proving all qualification gates together.

Required evidence:

```text
backend unit/integration tests        PASS
Liquibase migration tests            PASS
publication concurrency tests        PASS
learner OpenAPI contract tests        PASS
Flutter decoder/mapper tests          PASS
Flutter sync/restart tests            PASS
C4.9 adversarial suite                PASS
no unresolved C4 blockers             PASS
```

The exact SHA, workflow/run IDs and relevant artifact/test evidence must be recorded before declaring `C4 CLOSED`.

## Implementation rule

Do not skip from early persistence work directly to `C4 CLOSED`.

Each slice must preserve the previous invariants, and any later defect that invalidates an earlier slice reopens that slice until requalified on the final exact SHA.
