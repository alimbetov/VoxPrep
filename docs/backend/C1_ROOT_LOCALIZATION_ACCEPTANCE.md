# C1 Root + Localization — Acceptance Record

**Status:** ACCEPTED  
**Branch:** `feat/backend-contract-gap-audit`  
**Scope:** Flutter ↔ Backend learner-content contract and Flutter production lifecycle only.

## 1. What C1 closes

C1 contract-closes:

```text
BGA-001 root manifest locale identity
BGA-002 localized learner payload delivery
BGA-017 tombstone business-identity retirement semantics
```

C1 does not claim that a runnable backend learner-content implementation exists. Backend controllers, persistence, publication transactions and Admin authoring remain implementation work after the remaining P0 contracts are closed.

## 2. Accepted root contract

There is one locale-independent immutable learner root:

```text
contentVersion
checksum
publishedAt
exact pack revision refs
Backend-owned locale fallback rules
tombstones
```

`GET /api/v1/content/manifest` is not locale-scoped. A translation-locale change cannot create a second checksum identity for the same `contentVersion`.

Flutter materializes only the canonical packs and locale packs required by the requested locale plus the Backend-published fallback chain. Root identity itself never changes because of a device locale preference.

## 3. Accepted localization identity

Localized support copy is delivered by an exact immutable projection identified by:

```text
contentCode
contentType
contentRevision
locale
localizationRevision
checksum
```

Localized payloads may own locale-specific fields such as title, subtitle, description, translation, hint and explanation. They do not duplicate canonical English truth or shared media/audio ownership.

## 4. Backend-owned fallback policy

Fallback policy is publication data, not Flutter business logic.

Example:

```text
requested: ru-KZ
Backend rule: [ru, en]
resolved order: ru-KZ → ru → canonical English
```

Without a Backend rule Flutter does not infer `ru` from `ru-KZ`.

Policy rows are persisted in Drift with the CURRENT root `contentVersion`. Stale, non-contiguous or partially corrupted policy fails closed and causes same-root repair rather than silently changing learner behavior.

## 5. Drift v6 production model

C1 production persistence includes:

```text
PackLocalizationRefs
LocalizedContentReads
LocaleFallbackRules
ContentRetirements
```

Fallback policy is atomically committed with the root publication projection.

`ContentRetirements` is durable business-identity retirement state. `SyncTombstones` is execution evidence only and may be pruned without allowing resurrection.

## 6. No-resurrection invariant

Accepted lifecycle:

```text
revision 1
  ↓
revision 2
  ↓
tombstone stable business identity
  ↓
restart / journal pruning / migration
  ↓
revision 3+ publication attempt
  ↓
REJECT
```

The v5→v6 migration ranks surviving retirement evidence deterministically, preserves the highest retired revision and prefers journal metadata when evidence has equal revision.

## 7. Recovery and offline invariants

Accepted behavior includes:

- same immutable root repairs missing/corrupt localized payloads;
- same immutable root repairs incomplete Backend fallback policy;
- canonical + localized content survives file-backed database reopen;
- offline locale resolution uses persisted CURRENT Backend policy;
- missing locale data falls back without changing root checksum/contentVersion;
- tombstoned content remains invisible after restart;
- no localization replacement can mutate canonical content identity.

## 8. Production renderer acceptance

The production E2E uses the real Provider/Riverpod composition, real Drift repository, real production router and mock HTTP backend boundary.

Renderer acceptance uses synchronous `RenderRepaintBoundary.toImageSync()` snapshots in `flutter_test` so CI proves that the production subtree paints without relying on asynchronous PNG raster/encoding behavior. Adaptive navigation behavior remains covered by its dedicated P1.7 acceptance; this E2E validates the stable production router contract.

## 9. Qualification evidence

Qualified implementation commit:

```text
f7e24a3a2beda04ef39188a36788c613b7a15903
feat(c1): complete localization and retirement lifecycle
```

Qualification workflow:

```text
Backend Contract Gap C1 Backend Fallback Qualification
Run ID: 41183020530
result: SUCCESS
```

That qualification reproduced Drift v6, passed `flutter analyze`, passed the targeted C1 lifecycle suite and passed the complete Flutter regression suite before pushing the production implementation.

Clean production baseline:

```text
fa85f4240cdf96176098c64284fbd3a4629eb5ec
chore(c1): finalize production gate and remove staging tooling
```

Production workflow:

```text
Flutter Production Adapters
Run ID: 41183382458
result: SUCCESS
```

Exact-SHA production gates:

```text
format                         PASS
Drift v6 baseline reproducible PASS
flutter analyze                PASS
full flutter test              PASS
```

## 10. Exit decision

C1 is ACCEPTED.

The next contract stage is:

```text
C2 typed content + small product catalogues
```

Do not use C1 acceptance as permission to freeze the final learner-domain JPA schema. `Content` typed bodies, product catalogues, assessment and atomic publication still need C2–C4 contract closure before that schema is frozen.
