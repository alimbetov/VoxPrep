# P2.10.1 — Minimal Production Content Read Model

**Branch:** `feat/p2-flutter-production-adapters`  
**Parent:** P2.10.0 Cutover Contract Hardening  
**Database schema:** `3 → 4`

## Goal

Add the first learner-facing production read model required to replace `MockContentRepository`, without switching repository composition yet.

The existing `local_content_record` remains the synchronization envelope. It is not expanded into a universal learner payload table.

## Table

```text
content_catalog_reads
├── content_code
├── content_type
├── revision
├── checksum
├── title
├── subtitle
├── description
├── category
├── level
├── minutes
├── has_audio
└── created_at
```

Identity:

```text
PK(content_code, content_type, revision)
```

The table is immutable-by-revision. It deliberately has no independent `CURRENT` flag.

## CURRENT ownership

Learner visibility remains owned by the synchronization envelope:

```text
local_content_records.snapshot_state = CURRENT
```

The future `DriftContentRepository` therefore projects:

```text
content_catalog_reads
    JOIN local_content_records
      ON exact (code, type, revision)
    WHERE local_content_records.snapshot_state = CURRENT
```

This prevents two independently mutable CURRENT state machines from drifting apart.

A staged payload row may exist before activation, but it is not learner-visible until the exact local content revision becomes CURRENT in the atomic metadata transaction.

## Invariants

1. content identity includes both business code and content type;
2. revision is positive;
3. estimated minutes is positive;
4. title/category/level are non-blank;
5. two revisions of one identity may coexist;
6. the same business code under different content types remains distinct;
7. schema v3 → v4 creates an empty read model and preserves all existing learner/sync state;
8. no repository cutover occurs in this slice;
9. no mock adapter is deleted in this slice.

## Next

P2.10.2 stages validated `ContentPayload` rows and proves that payload availability plus the existing metadata CURRENT switch are atomic from the repository observer's perspective.
