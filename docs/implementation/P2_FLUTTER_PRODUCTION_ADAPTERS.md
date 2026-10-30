# P2 — Flutter Production Adapters

**Branch:** `feat/p2-flutter-production-adapters`  
**Base:** P1 accepted mock UI merged to `main` at `6f2e06f51c33df979340e12859d1407a215dfd4e`.

## Goal

Replace in-memory adapters behind stable application ports without rewriting learner-facing Material 3 UI.

```text
Feature UI
    ↓
Riverpod composition providers
    ↓
application ports
    ↓
┌─────────────────────────────┐
│ mock adapters   (temporary) │
│ Drift adapters  (P2.1+)     │
│ API adapters    (P2.4+)     │
└─────────────────────────────┘
```

## P2 sequence

```text
P2.0  production adapter boundary
P2.1  Drift database foundation
P2.2  learner-state persistence
P2.3  installation identity + Secure Storage
P2.4  API client
P2.5  manifest DTOs / delivery contracts
P2.6  ContentSyncCoordinator
P2.7  DownloadManager
P2.8  AssetResolver
P2.9  real audio playback
P2.10 mock → production repository cutover
P2.11 offline / restart / recovery qualification
```

## P2.0 acceptance

P2.0 is accepted only when:

- feature screens do not import `data/mock/**` repositories;
- content and assessment access go through application repository ports;
- Riverpod composition providers own concrete adapter selection;
- mock adapters implement the same ports production adapters will implement;
- P1.7 adaptive/widget acceptance remains green;
- repository composition tests are green;
- `flutter analyze` and `flutter test` are green on the exact branch SHA.

## Current P2.0 boundary

Ports:

```text
ContentRepository
PracticeTestRepository
```

Composition providers:

```text
contentRepositoryProvider
practiceTestRepositoryProvider
```

Temporary concrete adapters:

```text
MockContentRepository
MockTestRepository
```

No Drift, HTTP, Secure Storage, manifest sync, binary downloads or real audio is introduced in P2.0.

## Architecture rule

Presentation code may depend on domain/application contracts and Riverpod composition providers. It must not choose a concrete persistence or transport implementation.

The adapter selected by the composition root may change without changing feature widgets.
