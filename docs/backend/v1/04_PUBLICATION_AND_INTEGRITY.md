# 04 — Publication and Integrity

**Status:** FROZEN DESIGN INPUT

## 1. Core rule

Backend publication is an immutable release transaction, not a live query over mutable authoring tables.

Required flow:

```text
authoring data
→ materialize immutable revisions
→ validate complete candidate
→ calculate deterministic checksums
→ allocate new contentVersion
→ persist PublicationSnapshot + exact refs
→ atomically switch backend CURRENT pointer
→ commit
```

No partial candidate may become learner-visible.

## 2. Publication identity

```text
PublicationSnapshot
├── contentVersion
├── schemaVersion
├── publishedAt UTC
├── root checksum
├── exact pack refs
├── exact catalogue refs
├── exact PracticeTest refs
└── tombstones
```

Rules:

- contentVersion is monotonic;
- one contentVersion maps to one immutable root checksum;
- contentVersion is never reused;
- failed publication does not consume/expose a conflicting reusable identity;
- old snapshots remain immutable facts.

## 3. Exact membership

Every publication reference must identify an exact immutable target.

Examples:

```text
PackRef        = code + variant + revision + checksum
CatalogueRef   = kind + revision + checksum
ContentRef     = type + code + revision + checksum
LocalizationRef = content identity + canonical revision + locale + localization revision + checksum
PracticeTestRef = code + revision + checksum
AssetRef       = assetId + size + SHA-256 + media metadata
```

Never use “latest” resolution during sync of an already selected publication.

## 4. Universal catalogue completeness

Manifest schema v2 must represent a complete coherent universal catalogue membership, including the hierarchy required by Flutter:

```text
vertical-sections
verticals
vertical-presentation
learning-goals
learning-tracks
learning-collections
```

A publication lacking required catalogue membership is invalid.

## 5. Checksum canonicalization

Checksums are protocol identity.

Backend must implement the same deterministic canonical meaning expected by Flutter for:

```text
RootContentManifest
PackContentManifest
CataloguePayload
ContentPayload
LocalizedContentPayload
assessment revisions where contracted
FileAsset exact bytes
```

Canonicalization must be independent of:

```text
installationId
authorization token
traceId
request time
server node
storage URL
signed URL expiry
DB surrogate IDs
```

JSON serialization used for checksums must be deterministic and contract-tested against shared fixtures.

## 6. ETag semantics

ETag on root publication represents immutable root identity.

```text
same publication body → same ETag semantics
changed publication → changed validator
```

A 304 response is valid only when the request supplied a validator.

Locale change must not change root identity for the same publication.

## 7. Tombstones

Deletion/deactivation evidence is explicit.

```text
Tombstone
= business identity intentionally retired/deactivated in publication
```

Absence from a query/list is never deletion evidence.

Flutter uses tombstones during atomic activation while preserving learner history.

## 8. Backend CURRENT vs Flutter CURRENT

Backend CURRENT:

```text
which PublicationSnapshot is currently learner-deliverable
```

Flutter CURRENT:

```text
which fully validated local projection is atomically active
```

They are independent transactional boundaries.

Flutter may continue using publication N while backend CURRENT is N+1 until N+1 is fully staged and verified locally.

## 9. Corruption behavior

Flutter intentionally fails closed when CURRENT membership points to missing/corrupt exact local data.

Therefore backend must never rely on fallback semantics such as:

```text
exact revision missing → send latest
exact checksum missing → ignore checksum
pack target missing → return empty success
```

Correct server behavior is to return the exact target or a typed failure.

## 10. Publication concurrency

Concurrent publish attempts must serialize around the CURRENT switch/contentVersion allocation.

Design must prevent:

```text
duplicate contentVersion
lost CURRENT update
snapshot refs from different candidates
half-committed catalogue/content sets
```

Recommended implementation uses one database transaction and explicit locking/serialization around publication finalization.

## 11. Asset publication rule

A required learner asset must be READY and integrity-known before a publication that requires it is exposed.

Optional assets may follow the explicitly contracted optional/offline policy, but their stable asset identity must already be deterministic.

Expiring delivery authorization is never part of publication checksum.

## 12. Acceptance conditions

Backend publication is accepted only if tests prove:

```text
candidate failure leaves old CURRENT untouched
concurrent publish cannot mix candidates
same contentVersion cannot map to different checksum
exact old revision remains readable
all root refs resolve exactly
malformed/incomplete manifest is rejected
locale does not fork root identity
token rotation does not alter publication identity
tombstone removal is explicit
```
