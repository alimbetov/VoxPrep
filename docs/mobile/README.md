# CareerSpeak Mobile Architecture — P0.12

Working design index for the Flutter offline-first architecture.

## Normative parent

- [`../specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](../specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)

## Current design slices

- [`CAREERSPEAK_DRIFT_ERD.md`](CAREERSPEAK_DRIFT_ERD.md) — **P0.12.4 Drift ERD**, working design v0.1
- [`CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md`](CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md) — **P0.12.7 ContentSyncCoordinator state machine**, working design v0.1

## Core consistency rule

```text
REMOTE
  ↓
CHECK
  ↓
PLAN
  ↓
STAGE
  ↓
VERIFY
  ↓
ATOMIC COMMIT
  ↓
CLEAN
```

The last-known-good active local snapshot remains learner-visible until the commit succeeds.

## Persistence split

```text
SYSTEM / SYNC STATE
        ↓
VERSIONED CONTENT / PACK / ASSET STATE
        ↓
DURABLE LEARNER STATE
```

Re-downloadable content/media may be reclaimed. Favorites, progress, review schedules and test history are durable local learner state and are not deleted by cache eviction.

## Next P0.12 slices

```text
P0.12.4a typed Drift feature read models
P0.12.4b Drift migration/versioning contract
P0.12.7a root/pack manifest DTO contract alignment with backend P0.10
P0.12.7b DownloadManager interaction contract
P0.12.7c sync crash/failure qualification matrix
```
