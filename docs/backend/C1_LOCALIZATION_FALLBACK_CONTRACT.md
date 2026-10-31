# C1 Localization Fallback Contract

**Status:** C1 CONTRACT / IMPLEMENTATION BASELINE  
**Scope:** Flutter learner projection + backend publication semantics

## 1. Purpose

C1 keeps the root manifest locale-independent while allowing immutable localized support copy to be downloaded and resolved locally.

The fallback contract is deliberately deterministic and offline-safe.

## 2. Canonical source

Canonical English remains the authoritative learner payload for:

- content identity;
- canonical title/subtitle/description;
- taxonomy references;
- shared media/audio;
- content revision identity.

Localized payloads are overlays. They never duplicate or replace canonical content identity.

## 3. Fallback chain

For requested locale `ru-KZ`:

```text
ru-KZ
  ↓
ru
  ↓
en canonical payload
```

For requested locale `ru`:

```text
ru
  ↓
en canonical payload
```

For requested locale `en`:

```text
en canonical payload
```

A regional English overlay such as `en-US` may be published and used before canonical `en`:

```text
en-US
  ↓
en canonical payload
```

All locale codes use canonical BCP-47 casing before lookup.

## 4. Field-level merge

Fallback is evaluated per localized field, not only per payload object.

Example:

```text
requested: ru-KZ

ru-KZ payload:
  title        = value
  explanation  = value

ru payload:
  translation  = value
  hint         = value

canonical en:
  subtitle     = value
  description  = value
```

Resolved projection:

```text
title        ← ru-KZ
subtitle     ← en canonical
description  ← en canonical
translation  ← ru
hint         ← ru
explanation  ← ru-KZ
```

Localized fields are:

```text
title
subtitle
description
translation
hint
explanation
```

Canonical `title/subtitle/description` are always the final fallback for those fields. `translation/hint/explanation` may remain absent when no localized layer provides them.

## 5. CURRENT-only rule

A localized payload is learner-visible only when all of the following are true:

1. its exact `LocalizedContentRef` belongs to a locale pack revision;
2. that pack revision is `CURRENT`;
3. `contentCode`, `contentType`, `contentRevision`, `locale`, and `localizationRevision` match exactly;
4. the localized payload checksum equals the pack reference checksum;
5. the canonical content revision is itself `CURRENT`.

`STAGING` and `SUPERSEDED` locale packs never participate in fallback.

An unreferenced localized payload stored in Drift is not learner-visible.

## 6. Ambiguity handling

The resolver is fail-closed.

If two distinct CURRENT localization revisions are visible for the same:

```text
content identity
+ canonical revision
+ locale
```

the local read model is invalid. The client must not choose one arbitrarily.

## 7. Offline behavior

Fallback resolution is local-only:

```text
Flutter preferences
      ↓
requested translation locale
      ↓
CURRENT locale packs in Drift
      ↓
exact locale
      ↓
language locale
      ↓
canonical English
```

No network request is performed during read-time fallback.

If a requested locale has not been synchronized, the learner still receives canonical English content.

## 8. Backend publication implications

Backend publication must therefore guarantee:

- immutable localized payload revisions;
- deterministic checksum identity;
- locale pack variant `locale:<BCP-47>`;
- at most one logical current localization revision per content revision and locale in one publication snapshot;
- exact reference graph between locale pack and localized payload;
- canonical content remains independently publishable and reusable.

Backend does not need to pre-resolve Flutter fallback chains into duplicated payloads.

## 9. Acceptance cases

C1.5 is accepted when tests prove:

```text
ru-KZ exact + ru base merge deterministically
ru-KZ missing exact → ru
ru-KZ missing exact/base → canonical en
SUPERSEDED exact locale is ignored
orphan localized payload is ignored
checksum drift fails closed
ambiguous CURRENT localization revisions fail closed
invalid BCP-47 locale fails before storage lookup
production composition uses Drift localized resolver
```

This contract closes the runtime fallback part of BGA-002. C1 remains open until tombstone and restart/offline qualification are also complete.
