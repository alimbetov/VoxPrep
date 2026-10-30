# P2.10.2 Atomic Payload Projection

## Status

Implementation slice for the production repository cutover. This stage connects the exact-revision content payload contract from P2.10.0 to the immutable read model introduced in P2.10.1.

## Canonical ownership

CareerSpeak teaches English only. Canonical English learning content and audio are stored once. `locale:<bcp47>` variants contain translation/support deltas such as hints, explanations and localized labels.

`content_catalog_reads` is therefore the canonical English learner projection. Locale packs do not duplicate it and do not independently fetch canonical `ContentPayload` rows.

## Remote contract

Canonical payload is fetched through:

```text
GET /api/v1/content/{contentType}/{contentCode}/revisions/{revision}
```

The installation-authenticated response must match the requested:

```text
contentCode + contentType + revision + checksum
```

and also carries explicit taxonomy identity plus canonical labels:

```text
categoryCode  + categoryLabel
levelCode     + levelLabel
```

`categoryCode` and `levelCode` are stable uppercase business codes. The schema-v4 learner read model continues to persist only the canonical display labels in its existing `category` and `level` columns. Codes are not inferred from labels and are not silently added to Drift during this slice.

A target mismatch fails closed with `CONTENT_PAYLOAD_MISMATCH`. Invalid or missing taxonomy wire fields fail closed with `CONTENT_PAYLOAD_INVALID`.

## Staging sequence

For each changed or repair-required canonical pack:

```text
root manifest target
        ↓
pack manifest
        ↓
fetch every exact canonical ContentPayload
        ↓
validate identity + revision + checksum + wire taxonomy
        ↓
local staging transaction
   ├─ pack metadata
   ├─ local content revision metadata
   ├─ content_catalog_reads canonical labels
   ├─ pack membership
   └─ asset references
        ↓
READY_TO_COMMIT
```

Network calls are never performed inside the Drift transaction. Locale pack metadata follows the same metadata staging path but does not fetch or create canonical read rows.

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

Before switching visible state, the sync commit validates canonical target content has:

1. exact local metadata;
2. exact learner payload;
3. matching payload/metadata checksum.

Only after validation does the same transaction perform CURRENT switching. A failed commit may leave immutable staged rows for later reuse, but the last-known-good CURRENT projection remains learner-visible.

## Upgrade and repair semantics

Schema v3 → v4 preserves existing CURRENT metadata while `content_catalog_reads` starts empty.

`DriftSyncJournal.readLocalSnapshot()` keeps the factual CURRENT pack set unchanged and separately reports CURRENT **canonical** packs whose exact read payload is missing or checksum-inconsistent as:

```text
contentPayloadRepairPacks
```

`ContentSyncPlanner` treats a repair pack as changed even when root version/checksum and pack revision are unchanged. This backfills the read model without waiting for a new backend publication.

Locale packs never enter `contentPayloadRepairPacks`.

## Acceptance matrix

```text
AP01 exact payload endpoint uses installation authentication
AP02 payload decoder rejects malformed domain payloads
AP03 response identity/revision/checksum mismatch fails closed
AP04 stable categoryCode/levelCode are separated from display labels
AP05 canonical payloads are fetched before local pack staging
AP06 locale packs do not fetch/duplicate canonical payload
AP07 metadata and canonical payload stage transactionally
AP08 immutable payload conflict never overwrites an existing revision
AP09 commit validates canonical payload before CURRENT switching
AP10 commit conflict preserves previous CURRENT snapshot
AP11 staged replacement payload remains invisible after commit failure
AP12 v3→v4 missing canonical payload produces explicit repair work
AP13 repair keeps factual CURRENT pack represented
AP14 same immutable root schedules canonical repair deterministically
AP15 production composition injects HttpContentPayloadGateway
AP16 Drift schema remains v4 with zero generated baseline drift
AP17 format/analyze/full-test exact-SHA qualification passes
```

## Non-goals

P2.10.2 does not switch `ContentRepository` to Drift; that is P2.10.3. Locale support projections and preference-driven locale composition remain later work and must not be collapsed into the canonical read model. Persisting taxonomy codes in Drift is also deferred to an explicit read-model evolution rather than hidden inside this accepted schema-v4 slice.
