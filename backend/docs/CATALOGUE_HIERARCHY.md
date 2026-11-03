# B1-P2 Catalogue Hierarchy

Status: production persistence baseline for the first Backend-owned learner catalogue hierarchy.

## Ownership

The normalized persistence chain is:

```text
Vertical
  -> LearningGoal
      -> LearningTrack
          -> LearningCollection
```

Each row has an immutable globally unique code within its table, UUID technical identity, optimistic-lock version and audit timestamps inherited from the B1-P1 persistence foundation.

`LearningTrack` does not persist a second `vertical_id`, and `LearningCollection` does not persist a second `vertical_id`. Vertical ownership is derived through the parent FK chain. Learner/publication projections may expose `verticalCode`, but persistence does not maintain redundant ownership columns that can drift.

## Contract fields retained in B1-P2

`Vertical` persists `section_code` and `icon_asset_id` because the accepted universal catalogue projection requires them.

`LearningTrack` persists `level_code` and optional `career_track_code`.

`LearningCollection` persists explicit `FREE | FULL` access level.

`section_code`, `level_code`, `career_track_code` and `icon_asset_id` are scalar references in this slice. Their owning catalogue/asset tables are outside B1-P2, so no fake target tables or premature foreign keys are introduced. Later slices add referential constraints when those owning tables exist.

Collection members are also intentionally absent from B1-P2. Content and PracticeTest exact-revision membership is added only after the owning revision persistence exists. Mutable authoring may therefore create an empty collection; publication validation remains responsible for the learner-facing non-empty-members invariant.

## Database invariants

PostgreSQL enforces:

- UUID primary keys;
- unique stable codes per catalogue table;
- uppercase catalogue code format;
- non-negative sort order;
- explicit `ACTIVE | INACTIVE` availability;
- explicit `FREE | FULL` collection access;
- nonblank bounded title/description fields;
- parent foreign keys with `ON DELETE RESTRICT`;
- deterministic parent/order/code indexes.

All four production tables are created under `SET ROLE voxprep_owner`, so the NOLOGIN owner role owns schema objects while `voxprep_migrator` remains only the migration login and `voxprep_backend` remains the runtime DML identity.

## Ordering

Sibling ordering is deterministic:

```text
sort_order ASC, code ASC
```

Equal sort orders are allowed. Stable code is the deterministic tie-breaker.

## Non-goals of B1-P2

This slice does not add:

- REST/HTTP catalogue CRUD;
- Content Studio screens;
- catalogue publication snapshots;
- VerticalSection persistence;
- Level/CareerTrack taxonomy persistence;
- collection member persistence;
- content or assessment persistence.
