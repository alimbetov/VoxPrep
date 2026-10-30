# CareerSpeak Mobile Architecture — P0.12

Working design index for the Flutter offline-first architecture.

## Normative parent

- [`../specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md`](../specification/CAREERSPEAK_MOBILE_APPLICATION_REQUIREMENTS.md)

## Current design slices

- [`CAREERSPEAK_DRIFT_ERD.md`](CAREERSPEAK_DRIFT_ERD.md) — **P0.12.4 Drift ERD**, working design v0.1
- [`CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md`](CAREERSPEAK_CONTENT_SYNC_COORDINATOR.md) — **P0.12.7 ContentSyncCoordinator state machine**, working design v0.1
- [`CAREERSPEAK_ADAPTIVE_UI.md`](CAREERSPEAK_ADAPTIVE_UI.md) — **Adaptive / Responsive UI contract**, working design v0.1

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

The last-known-good local snapshot remains learner-visible until commit succeeds.

## Adaptive UI rule

```text
available window size
        ↓
AdaptiveWindowInfo
        ↓
shared adaptive layout primitives
        ↓
feature presentation
        ↓
same Riverpod/domain/application state
```

CareerSpeak adapts presentation to the available window. Business logic is not forked by phone/tablet/orientation.

Baseline width classes:

```text
COMPACT   < 600
MEDIUM    600–839
EXPANDED  840–1199
LARGE     >= 1200
```

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
P0.12.A1 adaptive component primitives / design tokens
P0.12.A2 screen-by-screen adaptive qualification
P0.12.A3 accessibility / text-scale / RTL qualification
```
