# CareerSpeak / VoxPrep — Globalization & Localization Requirements

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.5  
**Status:** Normative specification  
**Applies to:** CareerSpeak v0.8+  
**Target platforms:** Android, iOS

---

## 1. Core principle

CareerSpeak is an **English-learning application**.

Canonical learning language:

```text
ENGLISH
```

Other languages are presentation/localization languages for:

```text
application UI
vocabulary translation
hints
explanations
localized catalog labels/guidance
```

They are not alternative learning languages in MVP.

Canonical English text/audio SHALL be stored once and reused across locales.

---

## 2. Two localization channels

CareerSpeak deliberately separates Flutter UI localization from backend-driven educational content localization.

### 2.1 Flutter UI localization

Application-owned/system strings use:

```text
ARB resources
Flutter gen-l10n
compile-time mobile resources
```

Examples:

```text
Home
Settings
Download
Retry
Free space
Correct / Incorrect
```

A fully supported new `uiLocale` normally requires an application release.

### 2.2 Backend content localization

Backend-driven content includes:

```text
translation
hint
explanation
localized profession/category/test/topic labels
```

It is delivered through:

```text
root manifest
pack manifest
locale delta
```

Compatible content localization may be published without a new Flutter release.

---

## 3. Locale dimensions

Flutter SHALL distinguish:

```text
uiLocale
translationLocale
preferredAccent
```

Learning language is fixed:

```text
learningLanguage = en
```

Example:

```text
uiLocale          = ru
translationLocale = kk
preferredAccent   = UK
```

`uiLocale` and `translationLocale` may differ.

Preferences are local-first.

---

## 4. UI locales vs translation locales

Initial application UI locales:

```text
en
ru
kk
```

Backend translation locale catalog may grow independently, for example:

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

A locale MAY exist as a content translation locale before it becomes a complete application UI locale, provided the application can safely render its script/direction.

---

## 5. Locale identifiers

Locale identifiers use BCP-47-compatible semantics.

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

Locale metadata concept:

```text
code
bcp47_tag
name_en
native_name
direction
enabled
sort_order
```

Directions:

```text
LTR
RTL
```

---

## 6. Canonical vs localized fields

Canonical learner content remains English:

```text
question_text
model_answer
vocabulary lemma
example sentence
topic section text
phrase text
English audio
```

Localized support may include:

```text
translation
hint
explanation
localized title/description
```

Do not duplicate canonical English into every locale record merely to satisfy schema structure.

---

## 7. Typed localization tables

Do not create fixed-language columns such as:

```text
title_ru
title_kk
translation_es
```

Do not use one generic untyped EAV localization store for all domains.

Prefer typed tables owned by their domain, for example:

```text
profession_localization
vocabulary_localization
question_localization
topic_localization
```

This preserves foreign keys, validation and explicit semantics.

---

## 8. Hint and explanation

`hint` and `explanation` are first-class localizable concepts.

Example:

```text
canonical English question
→ localized hint
→ localized explanation
```

Missing localized support content falls back according to the locale fallback contract.

---

## 9. Locale readiness/publication

Localization readiness is separate from canonical English publication.

Example:

```text
Canonical English: PUBLISHED
RU: PUBLISHED
KK: READY
UZ: DRAFT
ES: MISSING
```

Suggested states:

```text
MISSING
DRAFT
READY
PUBLISHED
ARCHIVED
```

A missing non-required locale SHALL NOT block canonical English publication.

Pack/content policy may explicitly require selected locales before that pack is advertised for those locales.

---

## 10. UI locale selection

Initial selection precedence:

```text
1. saved explicit CareerSpeak uiLocale
2. OS per-app locale
3. OS preferred language list
4. OS region as a weak hint
5. English
```

CareerSpeak SHALL NOT request GPS solely to choose locale.

The learner can override the selected UI language.

---

## 11. Translation locale selection

`translationLocale` is an independent learner preference.

It may default from `uiLocale`, but the learner can choose another supported translation language.

Example:

```text
UI = English
Translation = Kazakh
```

or:

```text
UI = Russian
Translation = Russian
```

Changing translation locale SHALL NOT change canonical English learning text/audio.

---

## 12. Fallback rules

### UI fallback

```text
requested supported UI locale
→ English
```

### Backend content fallback

```text
requested regional translation locale
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

Fallback policy SHALL be deterministic and shared between backend contracts and Flutter behavior.

---

## 13. RTL readiness

Before Arabic/Urdu rollout, Flutter SHALL qualify:

```text
Directional start/end layout APIs
RTL navigation/icon mirroring where semantically required
text direction per localized block
mixed English-learning text inside RTL UI
long translated strings/text scaling
```

Canonical English learning text may remain LTR inside an RTL application shell.

---

## 14. Locale-aware content manifests

The learner manifest contract SHALL support locale-aware delivery.

Example:

```text
GET /api/v1/content/manifest?locale=kk
```

Manifest metadata may include:

```text
schemaVersion
contentVersion
locale
fallbackLocale
packs
localeDeltas
assets
checksums
tombstones
```

No learner profile is required.

---

## 15. Locale delta packs

Canonical English/audio assets are shared.

Example:

```text
JAVA_SENIOR
├── canonical English questions/answers
├── English audio
├── common assets
└── locale deltas
    ├── ru translations/hints/explanations
    ├── kk translations/hints/explanations
    └── ...
```

Changing `translationLocale` SHOULD download only missing/changed locale resources where canonical content/audio is unchanged.

---

## 16. Flutter local storage

Locale preferences remain local-first:

```text
uiLocale
translationLocale
preferredAccent
```

Downloaded locale deltas are versioned disposable content and may be reclaimed by local retention policy when no longer required.

User language preferences themselves are durable local settings and are not deleted by media/cache cleanup.

---

## 17. Installation identity

CareerSpeak has no personal learner account.

First launch:

```text
Flutter generates random app-specific installationId
→ backend registration
→ backend-issued installation token
→ platform secure storage
```

`installationId` SHALL NOT be derived from:

```text
IMEI
IMSI
MAC
hardware serial
advertising ID
phone number
email
Apple/Google identity
```

It SHALL NOT be joined to learner progress/favorites/test history.

---

## 18. Installation token

`installationId` is not the API credential.

The learner credential is backend-issued.

Do not use:

```text
SHA256(installationId)
```

or another credential that the client can deterministically manufacture without server authority.

Token material is stored using platform secure storage and is not logged.

---

## 19. Learner data policy

MVP SHALL NOT require:

```text
name
email
phone
birth date
precise location
social account
employer
resume/CV
learner voice recording
contacts
advertising identifier
```

Local-first learner state includes:

```text
favorites
progress
test attempts/answers/scores
review schedule
completed topics
recent content
downloads
language/theme/settings
```

---

## 20. ADMIN localization workflow

There is one human ADMIN actor.

Localization is managed through the Spring MVC Content Studio:

```text
/admin/localization
```

Capabilities:

```text
locale catalog
translation editor
hint/explanation editor
missing-translation filter
readiness/status
preview by locale
publish/archive locale data
```

No separate desktop/Python moderator application exists.

---

## 21. Global delivery topology

```text
Flutter
├── REST API → Spring Boot Backend → PostgreSQL
└── CDN/edge → RustFS published media

ADMIN Browser
→ Spring MVC Content Studio

TTS Worker
→ Backend Job API
→ RustFS models/media
```

Canonical binary identity remains:

```text
bucket + object_key + checksum
```

CDN hostname is not durable domain identity.

---

## 22. Privacy requirements

```text
PRIV-001 No mandatory personal learner account.
PRIV-002 Learning history/favorites/test results/preferences are local-first.
PRIV-003 No GPS solely for locale selection.
PRIV-004 installationId is random and app-specific.
PRIV-005 installationId is not derived from hardware/advertising identifiers.
PRIV-006 Learner voice is not uploaded in MVP.
PRIV-007 Logs avoid unnecessary learner-identifying payloads.
PRIV-008 Advertising SDKs are outside MVP scope.
PRIV-009 installationId is not joined to learning history as a learner profile.
PRIV-010 Learner API credential is backend-issued.
PRIV-011 Full installation token SHALL NOT be written to application logs.
```

---

## 23. Acceptance criteria

Globalization/localization is accepted when:

1. canonical English content/audio is stored once;
2. UI locale and translation locale can differ;
3. UI strings are Flutter-owned ARB/gen-l10n resources;
4. content translations/hints/explanations are backend-driven;
5. new compatible content translations can be published without a mobile release;
6. a new locale can be added without core content-schema redesign;
7. English audio is reused across locales;
8. locale delta download avoids redownloading unchanged English audio;
9. fallback works for regional/base/English cases;
10. RTL mixed-language UI is qualified before RTL rollout;
11. no GPS is required for locale selection;
12. learner credential is backend-issued;
13. learning history remains local-first;
14. one ADMIN manages localization through Content Studio.

---

## 24. P0 deliverables

```text
locale domain model
typed localization ERD
UI locale resource contract
translation-locale catalog contract
fallback specification
RTL qualification plan
Flutter locale-selection state flow
installation registration/token contract
localized manifest/locale-delta contract
ADMIN localization workflow
```

This is the authoritative globalization/localization baseline for CareerSpeak v0.8.
