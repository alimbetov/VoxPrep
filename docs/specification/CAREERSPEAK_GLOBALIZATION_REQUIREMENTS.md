# CareerSpeak — Globalization & Localization Requirements

**Document version:** 1.0  
**Status:** Normative specification  
**Applies to:** CareerSpeak v0.9+

Related standards:

- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`../mobile/CAREERSPEAK_ADAPTIVE_UI.md`](../mobile/CAREERSPEAK_ADAPTIVE_UI.md)

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

`uiLocale` and `translationLocale` may differ.

---

## 3. Initial locales

Initial UI/content-localization target:

```text
en
ru
kk
```

Planned expansion may include:

```text
uz
ky
uk
tr
es
pt
hi
ur
ar
bn
id
vi
fr
de
```

Adding a content translation locale SHALL NOT require core database redesign.

---

## 4. Locale identifiers

Use BCP-47-compatible identifiers.

Examples:

```text
en
ru
kk
pt-BR
pt-PT
es-MX
ar
ur
```

Locale metadata includes conceptually:

```text
code
bcp47Tag
nameEn
nativeName
direction
enabled
sortOrder
```

Direction:

```text
LTR
RTL
```

---

## 5. UI localization ownership

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

## 6. Content localization ownership

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

Do not use fixed columns like `title_ru` / `title_kk` and do not use one generic untyped EAV store for all domains.

---

## 7. Canonical vs localized content

Canonical fields remain English:

```text
question text
model answer
vocabulary lemma
example sentence
topic text
phrase English text
```

Localized support may contain:

```text
translation
hint
explanation
localized title/description
```

English audio does not duplicate per translation locale.

---

## 8. Localization readiness

Localization readiness is separate from canonical English publication.

Suggested locale states:

```text
MISSING
DRAFT
READY
PUBLISHED
ARCHIVED
```

A missing optional locale does not block canonical English publication unless an explicit pack policy requires that locale.

Only locale data allowed by publication policy is included in learner delivery.

---

## 9. Locale fallback

Content fallback:

```text
requested regional locale
→ base language
→ English support content where defined
```

Examples:

```text
pt-BR → pt → en
es-MX → es → en
ru-KZ → ru → en
kk-KZ → kk → en
```

Canonical English learning content remains available regardless of translation availability.

UI fallback:

```text
supported requested UI locale
→ en
```

---

## 10. Automatic locale selection

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

## 11. Installation identity/privacy

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

## 12. Root manifest + locale variants

CareerSpeak uses one root learner snapshot:

```text
contentVersion
```

Locale deltas are pack variants inside that root snapshot.

Example:

```text
JAVA_SENIOR / canonical / rev 8
JAVA_SENIOR / locale:ru / rev 5
JAVA_SENIOR / locale:kk / rev 4
```

There are not independent unrelated `canonical contentVersion` and `locale contentVersion` epochs.

This keeps Backend/Flutter agreement deterministic.

---

## 13. Locale-aware offline delivery

Changing translation locale should reuse canonical English/audio.

Example:

```text
current: locale:ru
new:     locale:kk

canonical rev 8 already CURRENT
English audio already cached/READY as applicable
→ download/stage locale:kk delta only
```

If locale delta is unavailable offline, canonical English remains usable according to fallback policy.

---

## 14. Adaptive/RTL UI

UI adaptation follows:

```text
docs/mobile/CAREERSPEAK_ADAPTIVE_UI.md
```

RTL requirements include:

```text
start/end layout semantics
mirrored directional controls where appropriate
mixed RTL guidance + LTR English learning text
no hardcoded English-width assumptions
large text qualification
```

Adaptive width classes are based on current window width, not locale or device model.

---

## 15. ADMIN localization workflow

One ADMIN manages localization in Spring MVC Content Studio:

```text
/admin/localization
```

Capabilities:

```text
locale catalog
translation/hint/explanation editing
missing translation filters
readiness/status
preview by locale
publish/archive locale payload
```

No separate moderator application or role hierarchy is required.

---

## 16. Privacy requirements

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

## 17. Acceptance criteria

Must prove:

```text
English stored once
UI locale independent from translation locale
new content locale added without core-schema redesign
hint/explanation independent localization
English audio reused across locales
BCP-47 fallback behavior
locale variant delivered inside root contentVersion snapshot
ru→kk delta does not redownload unchanged English audio
no GPS locale permission
installation token backend-issued
RTL/mixed direction UI qualification
adaptive layout survives long localized strings
```

This is the authoritative globalization/localization baseline for CareerSpeak v0.9.
