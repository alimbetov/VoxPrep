# P2.10.3 — DriftContentRepository

**Branch:** `feat/p2-flutter-production-adapters`  
**Parent stage:** P2.10.2 Atomic Payload Projection  
**Database schema impact:** none (`schemaVersion = 4`)

## Goal

Expose the canonical learner catalog already staged by P2.10.2 through the stable `ContentRepository` application port without changing production composition yet.

P2.10.3 owns the production local read adapter only. Switching `contentRepositoryProvider` away from mocks remains P2.10.6.

## Read boundary

```text
Feature/application query
        ↓
ContentRepository
        ↓
DriftContentRepository
        ↓
local_content_records
        JOIN
content_catalog_reads
        ↓
CURRENT exact revision only
```

Learner visibility is owned by `local_content_records.snapshot_state = CURRENT`. `content_catalog_reads` remains an immutable payload store and does not own a second lifecycle flag.

A visible row is valid only when metadata and payload agree on:

```text
contentCode
contentType
revision
checksum
```

Missing payload, duplicate CURRENT revisions, unsupported stored content type, or checksum mismatch fail closed with `CONTENT_READ_MODEL_INVALID`.

## Query semantics

`watchContent(ContentQuery)` supports:

```text
search over title + subtitle + description
type filtering
category label filtering
level label filtering
opaque keyset pagination
```

Ordering is deterministic:

```text
sortOrder NULLS LAST
contentType
contentCode
```

The page cursor is adapter-owned and opaque to feature code. It contains enough ordering identity to distinguish the same business code reused by different `ContentType` values. Production pagination therefore does not inherit the old mock adapter's code-only cursor ambiguity.

`getByIdentity(ContentIdentity)` requires the full logical identity:

```text
contentCode + contentType
```

and returns only the exact CURRENT revision.

## Reactive semantics

The catalog stream observes both:

```text
local_content_records
content_catalog_reads
```

An atomic publication that creates/changes the CURRENT projection invalidates the query and emits the new learner page. STAGED, SUPERSEDED, and TOMBSTONED revisions remain invisible.

## Failure semantics

```text
INVALID_CONTENT_CURSOR
    malformed/blank opaque page cursor

CONTENT_READ_MODEL_INVALID
    local metadata/payload invariant violation

CONTENT_READ_FAILED
    unexpected local database/read failure
```

Read-model corruption never falls back to stale mock data.

## Explicit non-goals

P2.10.3 does not:

```text
change Drift schema
persist taxonomy codes
apply locale/support overlays
implement AppPreferences adapter
register installations over HTTP
run startup bootstrap
switch production Riverpod composition
remove MockContentRepository
implement assessment production storage
perform P2.11 adversarial recovery qualification
```

Those remain owned by later slices.

## Acceptance matrix

```text
DR01 only CURRENT metadata revisions are learner-visible
DR02 STAGED replacement payload remains invisible
DR03 metadata and payload identity/revision/checksum must agree
DR04 duplicate CURRENT revisions fail closed
DR05 getByIdentity distinguishes equal code across content types
DR06 search/type/category/level filters use canonical CURRENT projection
DR07 ordering is deterministic
DR08 opaque keyset cursor distinguishes equal codes across types
DR09 invalid cursor fails closed
DR10 catalog stream reacts to atomic CURRENT publication
DR11 unexpected local read failures are represented as Result failures
DR12 production repository provider remains unchanged in this slice
DR13 schemaVersion remains 4 with zero generated baseline drift
DR14 format/analyze/full-test exact-SHA qualification passes
```

P2.10.3 is accepted only on one exact branch SHA with the normal read-only `Flutter Production Adapters` workflow green. After acceptance, the next stage is **P2.10.4 — production preferences + locale wiring**.
