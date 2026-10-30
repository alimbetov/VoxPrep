# P2.10.2 Atomic Payload Projection

## Status

Implementation slice for the production repository cutover. This stage connects the exact-revision content payload contract from P2.10.0 to the immutable read model introduced in P2.10.1.

## Remote contract

The mobile client fetches one immutable learner payload revision through:

```text
GET /api/v1/content/{contentType}/{contentCode}/revisions/{revision}
```

The request uses installation authentication. The response must match the requested:

```text
contentCode + contentType + revision + checksum
```

A mismatch fails closed with `CONTENT_PAYLOAD_MISMATCH`.

## Staging sequence

For each changed pack:

```text
root manifest target
        ↓
pack manifest
        ↓
fetch every exact ContentPayload
        ↓
validate identity + revision + checksum
        ↓
local staging transaction
   ├─ pack metadata
   ├─ local content revision metadata
   ├─ content_catalog_reads payload
   ├─ pack membership
   └─ asset references
        ↓
READY_TO_COMMIT
```

Network calls are never performed inside the Drift transaction.

The complete payload set is fetched and validated before local pack staging starts. A remote payload failure therefore cannot publish a partial pack.

## Visibility ownership

`content_catalog_reads` deliberately has no lifecycle column. Learner visibility is owned by the exact matching row in `local_content_records`:

```text
content_catalog_reads
  JOIN local_content_records
    ON content_code
   AND content_type
   AND revision
 WHERE snapshot_state = 'CURRENT'
```

A staged read-model row is not learner-visible until the matching metadata revision becomes `CURRENT`.

## Commit boundary

Before switching any visible state, the existing sync commit transaction verifies that every target content reference has:

1. an exact local metadata row;
2. an exact learner payload row;
3. a payload checksum equal to the metadata checksum.

Only after all targets pass verification does the same transaction:

```text
old packs/content CURRENT → SUPERSEDED
new packs/content          → CURRENT
tombstones                 → TOMBSTONED
root manifest              → new CURRENT version
sync journal               → COMMITTED/CLEANING
```

This prevents a learner-visible state such as:

```text
metadata revision N+1 CURRENT
payload revision N visible
```

## Failure semantics

A failure before staging leaves no new local pack projection.

A failure after staging but before commit may leave immutable new payload rows and `STAGED` metadata rows. They remain invisible because the previous last-known-good revision retains `CURRENT` ownership.

An immutable payload conflict fails with `CONTENT_PAYLOAD_IMMUTABLE_CONFLICT` instead of overwriting the persisted revision.

## Upgrade and repair semantics

Schema v4 can be opened over an existing v3 database where metadata is already `CURRENT` while `content_catalog_reads` is initially empty.

`DriftSyncJournal.readLocalSnapshot()` therefore reports a pack as locally complete only when every pack content reference has:

- exact `CURRENT` local content metadata;
- exact read-model payload;
- matching payload/metadata checksum.

A payload-incomplete pack is omitted from the local current-pack projection. The existing deterministic planner then schedules that exact pack as a repair even when the remote root manifest version and checksum have not changed.

## Acceptance matrix

```text
AP01 exact payload endpoint uses installation authentication
AP02 payload decoder rejects malformed domain payloads
AP03 response identity/revision/checksum mismatch fails closed
AP04 all payloads are fetched before local pack staging
AP05 metadata and payload rows stage in the same Drift transaction
AP06 payload immutable conflict never overwrites an existing revision
AP07 commit verifies exact payload existence before CURRENT switching
AP08 commit verifies payload checksum against metadata
AP09 commit conflict preserves the previous CURRENT snapshot
AP10 staged replacement payload remains invisible after commit failure
AP11 v3→v4 payload-incomplete CURRENT pack schedules deterministic repair
AP12 production composition injects HttpContentPayloadGateway
AP13 Drift schema remains v4 with zero generated baseline drift
AP14 flutter analyze passes
AP15 full flutter test passes
AP16 exact-SHA GitHub Actions qualification passes
```

## Non-goals

P2.10.2 does not yet switch `ContentRepository` to Drift. That happens in P2.10.3 after the atomic learner projection is qualified.

It also does not add cleanup of superseded payload revisions. Retention and restart/recovery cleanup remain part of later cutover/recovery work.
