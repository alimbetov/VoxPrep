# CareerSpeak — C4 Atomic Publication Contract

**Status:** Normative MVP contract  
**Scope:** Flutter local publication staging, activation and learner visibility

## 1. Single visibility authority

CareerSpeak has exactly one learner-visible publication pointer:

```text
ContentManifestStates.currentContentVersion
```

No catalogue, content, assessment, localization or asset subsystem may invent an independent `latest` or `current` publication pointer.

A row being downloaded, cached, `STAGED`, or even temporarily marked `CURRENT` in a subordinate table is not sufficient to make it learner-visible when a root row exists.

## 2. Atomic publication model

A root publication identifies one exact immutable set:

```text
RootContentManifest(contentVersion, checksum)
├── exact Pack revisions
├── exact PracticeTest revisions
├── exact Catalogue revisions
├── locale fallback policy
└── tombstones
```

Pack membership resolves exact:

```text
Content revisions
LocalizedContent revisions
Asset ids/checksums
```

The learner-visible publication is therefore the transitive closure of one exact root version.

## 3. Staging rule

Future publication data MAY be present locally before activation:

```text
root v1 CURRENT

local storage:
  v1 learner-visible
  v2 exact packs cached
  v2 exact content cached
  v2 exact assessment cached
  v2 exact catalogues cached
  v2 localization cached
  v2 assets cached/downloaded
```

While:

```text
currentContentVersion == v1
```

all learner-facing readers MUST continue to resolve only v1.

Staging v2 must not mutate the identity of v1.

## 4. Commit readiness

Before activation, the production synchronization path must have successfully prepared every required exact dependency declared by the target root:

```text
Root manifest validated
↓
exact publication membership staged
↓
exact PracticeTest bundles available
↓
exact Catalogue payloads available
↓
Universal Catalogue graph materialized when schema requires it
↓
changed Pack metadata/payloads staged
↓
required offline assets prefetched
↓
commit
```

If a required stage fails, publication activation MUST fail closed and the previous root remains authoritative.

## 5. Activation rule

Activation is one logical commit whose final visibility operation is:

```text
currentContentVersion: old → target
currentManifestChecksum: old → target
```

The root pointer must not move before target pack/content/localization validation and metadata state transitions have succeeded.

The commit transaction may update subordinate states before updating the root pointer, provided all updates and the pointer switch are in the same transaction and rollback together on failure.

## 6. Reader rules

When a root row exists, learner-facing repositories must resolve data through that root.

### Content

Exact content revision must be reachable from a pack whose:

```text
sourceContentVersion == currentContentVersion
```

### Assessment

PracticeTest must match an exact `publication_practice_test_refs` row for `currentContentVersion` and then resolve the immutable exact assessment bundle.

### Catalogue

Catalogue must match an exact `publication_catalogue_refs` row for `currentContentVersion` and the cached immutable payload revision/checksum.

### Localization

Canonical content and localized layers must be reachable through packs whose `sourceContentVersion` equals the current root.

### Assets

Asset visibility through current pack/content references must be fenced by the same current root version.

## 7. Legacy compatibility

Existing schema-v1/no-root compatibility MAY retain legacy behavior while old databases are supported.

Once `content_manifest_states.id = 1` exists, the root pointer is authoritative and legacy subordinate `CURRENT` flags cannot override it.

## 8. No-op repair

A pack-level no-op does not imply publication auxiliary state is complete.

For an already-current root the synchronizer may idempotently repair:

```text
PracticeTest publication refs
Catalogue publication refs/cache
Universal Catalogue graph projection
required-offline asset bytes
```

Such repair must preserve the immutable root identity and checksum.

## 9. Failure semantics

The system fails closed on:

```text
missing exact assessment revision
assessment checksum mismatch
missing exact catalogue revision
catalogue checksum mismatch
invalid catalogue graph
missing exact localized payload
localized checksum mismatch
missing target pack/content metadata
required offline asset prefetch failure
root/pack identity mismatch
immutable revision conflict
```

A failed future publication must not partially replace the currently visible publication.

## 10. Restart semantics

After interruption at any point before root activation:

```text
restart
↓
read existing CURRENT root
↓
future staged rows remain invisible
↓
re-stage/repair target deterministically
↓
activate only after commit readiness succeeds
```

No recovery path may infer the target publication from maximum revision, newest timestamp, subordinate `CURRENT` flags or cache recency.

## 11. Required acceptance

C4 is accepted only when tests prove:

```text
[ ] future Content remains invisible before root switch
[ ] future PracticeTest remains invisible before root switch
[ ] future Catalogue remains invisible before root switch
[ ] future Localization remains invisible before root switch
[ ] future Assets remain invisible before root switch
[ ] one root switch exposes the exact target revisions
[ ] staging failure never reaches publication activation
[ ] corrupted/missing exact dependencies fail closed
[ ] no-op can repair auxiliary publication state without changing root identity
[ ] restart before activation preserves the old visible publication
[ ] no learner reader uses MAX/latest/cache-time semantics
```

## 12. Explicit non-goals

C4 does not introduce:

```text
multiple domain publication pointers
two-phase distributed commit
server learner state
message broker coordination
microservices
remote UI state
background recommendation logic
```

The MVP implementation is a single-device SQLite atomic visibility model driven by one immutable backend publication root.
