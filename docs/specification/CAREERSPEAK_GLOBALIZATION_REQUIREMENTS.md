# CareerSpeak — Globalization & Localization Requirements

**Document version:** 1.1  
**Status:** Normative specification  
**Applies to:** CareerSpeak v0.9+

Related standards:

- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`../mobile/CAREERSPEAK_ADAPTIVE_UI.md`](../mobile/CAREERSPEAK_ADAPTIVE_UI.md)

This document is authoritative for locale support. Where an older system-level document lists only `en`, `ru`, and `kk`, this specification supersedes that restricted list.

---

## 1. Product language model

CareerSpeak teaches **English only**.

```text
learningLanguage = en
```

Other languages support presentation only:

```text
UI localization
vocabulary translation
hints
explanations
data-driven labels/guidance
```

Canonical English learning content/audio is stored once and reused across interface/translation locales.

---

## 2. Flutter locale dimensions

Flutter stores independently:

```text
uiLocale
translationLocale
preferredAccent
```

Example:

```text
uiLocale          = ru
translationLocale = kk
preferredAccent   = UK
learningLanguage  = en
```

Another valid example:

```text
uiLocale          = tr
translationLocale = uz
preferredAccent   = US
learningLanguage  = en
```

`uiLocale` and `translationLocale` may differ.

---

## 3. Multi-locale product policy

CareerSpeak SHALL be designed as a multi-locale platform, not as an `en + ru + kk` application.

Normative rule:

```text
locale = arbitrary supported BCP-47 identifier

NOT

locale ∈ {ru, kk}
```

No Backend, Flutter, Drift, manifest, localization, asset, assessment or admin contract may encode hidden assumptions that only `ru` and `kk` translation locales exist.

Adding a translation locale SHALL NOT require core database redesign.

Adding a UI locale may require a Flutter release because application chrome is compiled from ARB/gen-l10n resources.

---

## 4. Locale rollout tiers

### Tier 0 — baseline

```text
en
ru
kk
```

### Tier 1 — first expansion

Recommended first production expansion:

```text
uz
tr
ky
uk
```

The preferred minimum first expansion is:

```text
uz
tr
```

### Tier 2 — broader international rollout

```text
es
pt-BR
fr
de
```

Regional variants may be added independently, for example:

```text
pt-PT
es-MX
es-ES
```

### Tier 3 — RTL and additional high-scale markets

```text
ar
ur
hi
bn
id
vi
```

Tier membership is a rollout priority only. It MUST NOT be encoded as a protocol limitation.

---

## 5. Locale identifiers

Use BCP-47-compatible identifiers.

Examples:

```text
en
ru
kk
uz
tr
pt-BR
pt-PT
es-MX
ar
ur
```

Locale identifiers MUST be treated as data, not closed client enums, except where compile-time Flutter UI resources require an application release.

Locale metadata includes conceptually:

```text
code
bcp47Tag
nameEn
nativeName
direction
active
uiSupported
translationSupported
contentAvailability
fallbackLocaleCode
sortOrder
```

Direction:

```text
LTR
RTL
```

Recommended content availability values:

```text
NONE
PARTIAL
FULL
```

A boolean `contentPackAvailable` may be used in the first API version if necessary, but the domain model SHOULD allow future `PARTIAL` support without schema redesign.

---

## 6. Backend-owned SupportedLocale catalog

The set of product-supported locales is Backend-owned product capability data.

Minimum logical projection:

```text
SupportedLocale
├── code
├── bcp47Tag
├── nameEn
├── nativeName
├── direction
├── active
├── uiSupported
├── translationSupported
├── contentAvailability
├── fallbackLocaleCode
└── sortOrder
```

Responsibilities:

```text
Backend
→ defines which locale capabilities exist
→ defines activation/deactivation
→ defines fallback metadata
→ publishes locale capability revisions

Flutter
→ stores the user's selected stable locale codes
→ validates/falls back against the current supported catalog
→ renders UI resources only for compiled UI locales
```

Flutter MUST NOT own the mutable product locale catalog.

A locale may be translation-supported even when it is not yet UI-supported.

A locale may be UI-supported while content localization is still `PARTIAL`.

---

## 7. UI localization ownership

Flutter owns application/system UI strings through compile-time resources:

```text
ARB
Flutter gen-l10n
```

Examples:

```text
Home
Settings
Download
Retry
Free space
Correct
Incorrect
```

A fully supported new UI locale normally requires a mobile release.

Backend is not the primary source of application chrome/UI strings.

---

## 8. Content localization ownership

Backend owns learner-content localization such as:

```text
vocabulary translation
hint
explanation
profession/category localized label
topic localized support text
question localized guidance
```

Use typed localization tables by domain.

Examples:

```text
profession_localization
vocabulary_localization
question_localization
topic_localization
```

Do not use fixed columns such as:

```text
title_ru
title_kk
title_uz
```

Do not use one generic untyped EAV store for all localization domains.

---

## 9. Canonical vs localized content

Canonical fields remain English:

```text
question text
model answer
vocabulary lemma
example sentence
topic text
phrase English text
shadowing transcript
```

Localized support may contain:

```text
translation
hint
explanation
localized title/description
localized taxonomy labels
localized assessment guidance
```

English audio does not duplicate per translation locale.

Canonical assets and canonical content identity SHALL remain reusable across all translation locales.

---

## 10. Localization readiness

Localization readiness is separate from canonical English publication.

Suggested locale payload states:

```text
MISSING
DRAFT
READY
PUBLISHED
ARCHIVED
```

A missing optional locale does not block canonical English publication unless an explicit pack policy requires that locale.

Only locale data allowed by publication policy is included in learner delivery.

Locale readiness must be tracked per locale and per revisionable localization unit; a global boolean on the canonical content object is insufficient for long-term multi-locale operation.

---

## 11. Locale fallback

Fallback metadata is Backend-owned and MUST be deterministic.

Content fallback:

```text
requested regional locale
→ configured/base locale
→ English support content where defined
```

Examples:

```text
pt-BR → pt → en
es-MX → es → en
ru-KZ → ru → en
kk-KZ → kk → en
uz-UZ → uz → en
ar-SA → ar → en
```

Flutter MUST NOT invent product fallback chains independently from the Backend catalog.

Canonical English learning content remains available regardless of translation availability.

UI fallback:

```text
supported requested UI locale
→ en
```

A missing content translation SHALL NOT make canonical English content unavailable.

---

## 12. Automatic locale selection

CareerSpeak SHALL NOT request GPS solely for language selection.

Initial selection order:

```text
1. explicit saved CareerSpeak choice
2. OS per-app locale
3. OS preferred languages
4. OS region as weak hint
5. English fallback
```

User can override `uiLocale` and `translationLocale` independently.

---

## 13. Installation identity/privacy

No personal learner account is required.

First launch:

```text
cryptographically random app-specific installationId
→ backend registration
→ backend-issued installation token
→ Secure Storage
```

Do not derive installation identity/credential from:

```text
IMEI
IMSI
MAC
hardware serial
advertising ID
phone
email
Apple/Google identity
```

Do not use `SHA256(installationId)` or another client-computable credential as API authentication.

Backend SHALL NOT join installation identity to learner progress/favorites/test history in MVP.

---

## 14. Root manifest + locale variants

CareerSpeak uses one root learner snapshot:

```text
contentVersion
```

The root snapshot identity MUST be locale-independent.

A single immutable root snapshot may contain arbitrary locale pack variants:

```text
JAVA_SENIOR / canonical / rev 8
JAVA_SENIOR / locale:ru / rev 5
JAVA_SENIOR / locale:kk / rev 4
JAVA_SENIOR / locale:uz / rev 2
JAVA_SENIOR / locale:tr / rev 3
JAVA_SENIOR / locale:ar / rev 1
```

There are not independent unrelated canonical and locale root epochs.

The Backend MUST NOT return a different root checksum for the same `contentVersion` merely because the requester's translation locale differs.

Normative invariant:

```text
same contentVersion
→ same immutable root manifest identity
→ same root checksum
```

Flutter selects the locale variants it needs from that root snapshot.

Locale filtering, if introduced as an optimization, MUST NOT alter root identity semantics.

---

## 15. Locale payload delivery

Locale pack metadata alone is insufficient. Backend contracts SHALL provide immutable localized payload delivery for locale variants.

Conceptual flow:

```text
root manifest
  ↓
locale:<bcp47> pack revision
  ↓
localized payload refs
  ↓
localized payload endpoint/bundle
  ↓
Drift locale projection
  ↓
Flutter UI/read model
```

Localized payloads MUST have:

```text
stable target identity
locale code
revision/version identity
checksum/integrity semantics
publication state
```

The exact endpoint shape may be finalized during backend contract freeze, but a locale pack MUST NOT be considered complete if the client can discover locale metadata but cannot retrieve the corresponding localized content.

---

## 16. Locale-aware offline delivery

Changing translation locale reuses canonical English/audio.

Example:

```text
current: locale:ru
new:     locale:uz

canonical rev 8 already CURRENT
English audio already cached/READY as applicable
→ download/stage locale:uz delta only
```

The following MUST NOT happen solely because translation locale changes:

```text
redownload unchanged canonical English content
redownload unchanged English audio
redownload unchanged shared images/assets
```

If locale delta is unavailable offline, canonical English remains usable according to fallback policy.

---

## 17. Adaptive/RTL UI

UI adaptation follows:

```text
docs/mobile/CAREERSPEAK_ADAPTIVE_UI.md
```

RTL languages such as `ar` and `ur` are first-class architecture targets.

RTL requirements include:

```text
start/end layout semantics
mirrored directional controls where appropriate
mixed RTL guidance + LTR English learning text
no hardcoded English-width assumptions
large text qualification
navigation qualification
assessment qualification
audio-control qualification
```

Adaptive width classes are based on current window width, not locale or device model.

Adding RTL locales SHALL NOT require a separate UI architecture or second design system.

---

## 18. TTS voice/accent relationship

`preferredAccent` is a learner preference; available voice/accent capabilities are Backend-owned product catalog data.

Flutter stores stable selected codes only.

Conceptually:

```text
SupportedLocale
      ↓
learner-facing TtsVoice catalog
      ↓
voiceCode / accentCode selection
```

The learner-facing catalog MUST NOT expose worker-only storage/cache internals.

Locale expansion and TTS voice expansion are related but independent: adding a translation locale does not require a new English TTS voice.

---

## 19. ADMIN localization workflow

One ADMIN manages localization in Spring MVC Content Studio:

```text
/admin/localization
```

Capabilities:

```text
locale catalog
locale activation/deactivation
translation/hint/explanation editing
missing translation filters
readiness/status per locale
preview by locale
publish/archive locale payload
fallback configuration
```

No separate moderator application or role hierarchy is required.

---

## 20. Privacy requirements

```text
PRIV-001 no mandatory learner account
PRIV-002 progress/favorites/test history local-first
PRIV-003 no GPS solely for locale selection
PRIV-004 installationId random/app-specific
PRIV-005 no hardware/advertising identity derivation
PRIV-006 no learner voice upload in MVP
PRIV-007 backend-issued learner API token
PRIV-008 installation identity not joined to learner learning profile
PRIV-009 advertising SDKs outside MVP scope
```

---

## 21. Architecture constraints

The following are forbidden:

```text
hardcoded runtime assumption locale ∈ {ru, kk}
fixed DB columns per language
locale-specific root contentVersion epochs
client-invented mutable locale catalog
client-invented product fallback chains
duplicating canonical English/audio per translation locale
using display locale names as business identity
```

Stable BCP-47-compatible codes are the cross-system identity.

---

## 22. Acceptance criteria

Must prove:

```text
English canonical content stored once
UI locale independent from translation locale
new translation locale added without core-schema redesign
new locale added without changing manifest protocol shape
SupportedLocale catalog is backend-owned
arbitrary BCP-47 locale code accepted where contract allows
no hardcoded ru|kk runtime branch in backend/mobile domain logic
hint/explanation independent localization
English audio reused across locales
configured BCP-47 fallback behavior
root manifest identity remains locale-independent
same contentVersion cannot have different checksum per locale
locale variant delivered inside one root contentVersion snapshot
localized payload is actually retrievable, not metadata-only
ru→uz delta does not redownload unchanged English audio
ru→tr delta does not redownload unchanged canonical assets
no GPS locale permission
installation token backend-issued
RTL/mixed direction UI qualification
adaptive layout survives long localized strings
locale deactivation falls back deterministically
PARTIAL translation availability does not hide canonical English content
```

### Required qualification locales

Before declaring the localization architecture production-ready, automated/manual qualification SHALL include at least:

```text
en  — canonical/fallback
ru  — Cyrillic baseline
kk  — Cyrillic regional baseline
uz  — first expansion locale
tr  — Latin expansion locale
ar  — RTL structural qualification
```

`ar` may remain product-disabled until translation content is ready, but RTL architecture qualification must exist before the system claims general multi-locale readiness.

---

## 23. Initial rollout recommendation

Recommended staged rollout:

```text
Release A:
en + ru + kk + uz + tr

Release B:
ky + uk + es + pt-BR + fr + de

Release C:
ar + ur + hi + bn + id + vi
```

This is a product rollout plan, not a protocol constraint.

The implementation must remain capable of adding further valid BCP-47 locales without architectural redesign.

---

## 24. Final invariant

```text
English learning content is canonical and stored once.
Backend defines which locale capabilities exist.
Flutter stores the learner's locale selections.
Locale packs are versioned members of one immutable root snapshot.
Changing translation locale downloads only the required locale delta.
No system layer assumes that ru and kk are the only translation languages.
```

This is the authoritative globalization/localization baseline for CareerSpeak v1.1.