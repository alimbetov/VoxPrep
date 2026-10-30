# CareerSpeak / VoxPrep — Globalization & Localization Requirements

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.4  
**Status:** Normative specification  
**Applies to:** CareerSpeak v0.7+  
**Target platforms:** Android, iOS

---

## 1. Purpose

CareerSpeak is an **English-learning application**.

Canonical learning language:

```text
ENGLISH
```

Other languages are used for:

```text
UI localization
vocabulary translation
hints
explanations
localized catalog labels/guidance
```

Other languages are not alternative learning languages in MVP.

---

## 2. Core model

```text
CANONICAL ENGLISH CONTENT
        │
        ├── UI localization
        ├── translation
        ├── hint localization
        └── explanation localization
```

Canonical English learning content and English audio SHALL be stored once and reused across interface locales.

---

## 3. Locale dimensions

CareerSpeak distinguishes:

```text
ui_locale
translation_locale
preferred_accent
```

Learning language is fixed:

```text
learning_language = en
```

`ui_locale` and `translation_locale` may differ.

Preferences are local-first.

---

## 4. Initial locales

Release baseline:

```text
en  English
ru  Russian
kk  Kazakh
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

Architecture SHALL permit new locales without core-schema redesign.

---

## 5. Locale identifiers

Locale identifiers SHOULD follow BCP-47-compatible semantics.

Examples:

```text
en
ru
kk
pt-BR
pt-PT
ar
ur
```

Locale metadata should include:

```text
code
bcp47_tag
name_en
native_name
direction
enabled
sort_order
```

Text direction:

```text
LTR
RTL
```

Flutter SHALL be RTL-ready before Arabic/Urdu production rollout.

---

## 6. Typed localization model

Do not create fixed-language columns such as:

```text
title_ru
title_kk
translation_es
```

Do not use a generic untyped EAV localization store for all domain content.

Prefer typed localization tables owned by their domain, for example:

```text
profession_localization
vocabulary_localization
question_localization
topic_localization
```

This preserves foreign keys, validation and explicit field semantics.

---

## 7. Canonical vs localized fields

Canonical learner content remains English.

Examples:

```text
question_text           → English
model_answer             → English
vocabulary lemma         → English
example sentence         → English
topic section text       → English
```

Localized support may include:

```text
translation
hint
explanation
localized title/description
```

Localized text SHALL NOT duplicate canonical English merely to create a locale record.

---

## 8. Hint and explanation localization

`hint` and `explanation` are first-class localizable concepts.

Examples:

```text
canonical question
→ localized hint
→ localized explanation
```

A missing localized hint/explanation falls back according to locale fallback policy.

---

## 9. Locale publication/readiness

Localization readiness is separate from canonical English publication.

Example:

```text
Canonical English: PUBLISHED
RU: PUBLISHED
KK: READY
UZ: DRAFT
ES: MISSING
```

A missing optional locale SHALL NOT automatically block canonical English publication unless the pack/content policy explicitly requires that locale.

Suggested locale states:

```text
MISSING
DRAFT
READY
PUBLISHED
ARCHIVED
```

---

## 10. Locale fallback

Default fallback:

```text
requested regional locale
→ base language
→ English
```

Examples:

```text
pt-BR → pt → en
es-MX → es → en
ru-KZ → ru → en
kk-KZ → kk → en
```

Fallback rules SHALL be centralized and consistent between backend contracts and Flutter behavior.

---

## 11. Automatic locale selection

CareerSpeak SHALL NOT request GPS/precise location solely for language selection.

Selection precedence:

```text
1. explicit CareerSpeak selection
2. OS per-app locale
3. OS preferred language
4. OS region
5. English fallback
```

Learner may always override the automatic choice.

---

## 12. Installation identity

CareerSpeak has no personal learner account in MVP.

On first launch Flutter generates a cryptographically random app-specific:

```text
installationId
```

Recommended entropy:

```text
256-bit cryptographically secure random value
```

It SHALL NOT be derived from:

```text
IMEI
IMSI
MAC
hardware serial
advertising ID
phone number
email
Apple/Google account identity
```

---

## 13. Installation token

`installationId` is not itself the API credential.

Flow:

```text
Flutter generates installationId
→ registration request
→ backend issues installation token
→ token stored in Android Keystore/iOS Keychain-backed secure storage
→ token authenticates /api/v1/**
```

Do not use a client-computable credential such as:

```text
SHA256(installationId)
```

The backend-issued token may be opaque or signed according to the final security ADR.

---

## 14. Installation identity purpose

Installation identity/token may support:

```text
API abuse protection
rate limiting
entitlement/integrity extensions
token rotation
credential revocation
```

It SHALL NOT create a server-side learning profile.

The backend SHALL NOT join installation identity to:

```text
favorites
IELTS scores
mock-test history
learned vocabulary
profession interests
recent topics
learning progress
```

---

## 15. Learner data policy

CareerSpeak SHALL NOT require for MVP:

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

The following remain local-first:

```text
favorites
vocabulary progress
test attempts/answers/scores
completed topics
review schedule
recent content
downloaded packs
UI/localization settings
```

Uninstall may remove local history unless a future explicit backup/sync feature is introduced.

---

## 16. Privacy requirements

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
PRIV-010 Learner API credential is backend-issued, not client-derived from installationId.
```

---

## 17. Localized content delivery

The root/pack manifest model SHALL support locale-aware content delivery without requiring a learner profile.

Example:

```text
GET /api/v1/content/manifest?locale=kk
```

Manifest may expose:

```text
schemaVersion
contentVersion
locale
fallbackLocale
packs
assets
checksums
tombstones
```

---

## 18. Offline locale delta

Offline packs should reuse canonical English audio across locales.

Example:

```text
JAVA_SENIOR pack
├── English questions/answers
├── English audio
├── kk translations/hints/explanations
└── locale metadata
```

Changing from one translation locale to another SHOULD download the locale delta rather than redownloading unchanged English audio.

---

## 19. ADMIN localization workflow

There is one human ADMIN actor in MVP.

Localization is managed through the same Spring MVC Content Studio:

```text
/admin/localization
```

Required capabilities:

```text
locale catalog
translation editor
hint/explanation editor
missing-translation filter
readiness/status
preview by locale
publish/archive locale data
```

Do not create a separate Python/desktop moderator application.

---

## 20. Global delivery topology

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

Canonical media identity remains:

```text
bucket + object_key
```

Do not persist environment-specific CDN hostnames as domain identity.

---

## 21. Acceptance criteria

Globalization is accepted when:

1. canonical learning language is English and stored once;
2. UI/translation locale changes without duplicating English learning content;
3. a new locale can be added without core-schema redesign;
4. hints/explanations localize independently;
5. English audio is reused across locales;
6. RTL metadata is supported;
7. locale selection requires no GPS;
8. installationId exposes no hardware identity;
9. learner credential is backend-issued;
10. learning history remains local-first;
11. one ADMIN manages locale content through Spring MVC Content Studio;
12. offline locale deltas do not redownload unchanged English audio.

---

## 22. P0 deliverables

```text
locale domain model
typed localization ERD
fallback specification
Flutter locale-selection flow
installation registration/token contract
localized manifest contract
offline locale-delta design
ADMIN localization workflow
RTL qualification plan
```

This is the authoritative globalization/localization baseline for CareerSpeak v0.7.
