# C1 Localization Fallback Contract

**Status:** C1 CONTRACT / IMPLEMENTATION BASELINE  
**Scope:** Flutter learner projection + backend publication semantics

## 1. Purpose

C1 keeps the root manifest locale-independent while allowing immutable localized support copy to be synchronized and resolved locally.

Fallback order is **Backend-owned**, deterministic and offline-safe. Flutter validates and applies the published order; it does not invent language relationships from BCP-47 tags.

## 2. Canonical source

Canonical English remains the authoritative learner payload for:

- content identity;
- canonical title/subtitle/description;
- taxonomy references;
- shared media/audio;
- content revision identity.

Localized payloads are overlays. They never duplicate or replace canonical content identity.

## 3. Backend-owned fallback policy

The locale-independent root may publish ordered fallback rules:

```text
requested locale -> ordered fallback locales
```

Example:

```text
ru-KZ -> [ru, en]
```

The runtime resolution order becomes:

```text
ru-KZ exact locale pack
  ↓
ru configured fallback pack
  ↓
en canonical payload
```

A different Backend rule is equally valid:

```text
ru-KZ -> [kk, en]
```

which resolves as:

```text
ru-KZ
  ↓
kk
  ↓
en canonical payload
```

Flutter must **not** derive `ru` merely because the requested locale is `ru-KZ`.

When no rule exists for a requested locale, the chain is:

```text
exact requested locale
  ↓
en canonical payload
```

Canonical English is always the final product fallback. It does not require a locale pack.

All locale codes are canonicalized as BCP-47 values before comparison.

## 4. Root identity and fallback policy

`localeFallbacks` belongs to the locale-independent publication root.

Changing fallback policy therefore requires a new immutable root publication:

```text
new contentVersion
new root checksum / ETag
```

A locale preference change on the device does **not** change root identity.

The client materializes only:

```text
canonical packs
+ exact requested locale packs
+ locale packs explicitly named by the Backend fallback rule
```

## 5. Field-level merge

Fallback is evaluated per localized field, not only per payload object.

Example with Backend rule `ru-KZ -> [ru, en]`:

```text
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
title        <- ru-KZ
subtitle     <- en canonical
description  <- en canonical
translation  <- ru
hint         <- ru
explanation  <- ru-KZ
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

## 6. CURRENT-only rule

A localized payload is learner-visible only when all of the following are true:

1. its exact `LocalizedContentRef` belongs to a locale pack revision;
2. that pack revision is `CURRENT`;
3. `contentCode`, `contentType`, `contentRevision`, `locale`, and `localizationRevision` match exactly;
4. the localized payload checksum equals the pack reference checksum;
5. the canonical content revision is itself `CURRENT`.

`STAGING` and `SUPERSEDED` locale packs never participate in fallback.

An unreferenced localized payload stored in Drift is not learner-visible.

## 7. Persisted policy and restart semantics

The Backend fallback policy is persisted in Drift as part of the CURRENT publication state.

Publication commit is atomic for:

```text
CURRENT packs
CURRENT canonical content
CURRENT locale refs/payloads
locale fallback policy
contentVersion + root checksum
```

Each persisted fallback row records the `sourceContentVersion` that owns it. A resolver must fail closed if the policy does not belong to the CURRENT root version.

After process death or device restart, fallback resolution uses only this persisted policy. It does not need the network and does not reconstruct fallback order heuristically.

## 8. Ambiguity handling

The resolver is fail-closed.

If two distinct CURRENT localization revisions are visible for the same:

```text
content identity
+ canonical revision
+ locale
```

the local read model is invalid. The client must not choose one arbitrarily.

Invalid or duplicate Backend fallback metadata also fails closed during root decoding/domain validation.

## 9. Offline behavior

Fallback resolution is local-only:

```text
Flutter preferences
      ↓
requested translation locale
      ↓
persisted Backend fallback rule for CURRENT contentVersion
      ↓
CURRENT locale packs in Drift
      ↓
exact locale
      ↓
configured fallback locales in Backend order
      ↓
canonical English
```

No network request is performed during read-time fallback.

If the requested/fallback locale packs are unavailable locally, the learner still receives canonical English content.

Changing the local translation preference must not mutate the stored root `contentVersion`, checksum or ETag identity.

## 10. Tombstone interaction

A tombstone retires the entire stable content business identity. Once an identity has been tombstoned, a later pack must not resurrect it by publishing a higher canonical revision.

Locale payloads cannot make tombstoned content visible because localized projection requires a CURRENT canonical revision.

## 11. Backend publication implications

Backend publication must guarantee:

- immutable localized payload revisions;
- deterministic checksum identity;
- locale pack variant `locale:<BCP-47>`;
- Backend-owned ordered fallback metadata in the root;
- at most one logical CURRENT localization revision per content revision and locale in one publication snapshot;
- exact reference graph between locale pack and localized payload;
- canonical content remains independently publishable and reusable;
- tombstoned content identities are not republished.

Backend does not pre-resolve fallback chains into duplicated payloads. It publishes the fallback policy and immutable locale packs; Flutter applies them locally.

## 12. Acceptance cases

C1 fallback/recovery acceptance proves:

```text
Backend rule controls fallback order
Flutter does not derive base language implicitly
exact + configured fallback merge field-by-field
missing configured packs -> canonical en
SUPERSEDED locale pack is ignored
orphan localized payload is ignored
checksum drift fails closed
ambiguous CURRENT localization revisions fail closed
invalid Backend fallback metadata fails closed
fallback policy survives Drift reopen
locale switch offline does not change root identity
rev1 -> rev2 -> tombstone -> restart remains retired
post-tombstone higher revision resurrection is rejected
production composition uses Drift localized resolver
```

This contract closes the runtime fallback/restart portion of BGA-002 and supplies the C1.5-C1.7 acceptance baseline.
