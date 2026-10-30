# CareerSpeak / VoxPrep — Globalization & Localization Requirements

**Repository:** `alimbetov/VoxPrep`  
**Product name:** CareerSpeak  
**Codename:** VoxPrep  
**Document version:** 0.3  
**Status:** Normative extension to the System Requirements baseline  
**Target platforms:** Android, iOS  
**Production target:** DigitalOcean  

---

## 1. Purpose

This document defines the globalization, localization, installation-identity and privacy requirements for CareerSpeak.

It is a normative extension of `CAREERSPEAK_SYSTEM_REQUIREMENTS.md` and supersedes any earlier assumption that CareerSpeak is intended to support multiple learning languages in the MVP architecture.

CareerSpeak is an **English-learning application**.

The canonical learning language is fixed as:

```text
ENGLISH
```

Other languages are required for:

- mobile UI localization;
- vocabulary translation;
- translation of `hint` content;
- translation of explanations and supporting guidance;
- localized category/profession/test names where useful;
- locale-aware onboarding and navigation.

Other languages are **not** separate learning languages in the current product scope.

---

## 2. Core globalization principle

CareerSpeak separates:

```text
CANONICAL ENGLISH CONTENT
            │
            ├── UI localization
            ├── translation
            ├── hint localization
            └── explanation localization
```

The application SHALL NOT duplicate canonical English learning content per locale.

Examples:

```text
Canonical word:
significant

Localized translation:
ru → значительный
kk → елеулі
uz → sezilarli
es → significativo
```

```text
Canonical hint:
Think about a word that describes a large or important change.

Localized hints:
ru → Подумайте о слове, описывающем крупное или важное изменение.
kk → Үлкен немесе маңызды өзгерісті сипаттайтын сөзді ойлаңыз.
```

English audio remains the same for all interface locales.

---

## 3. Locale dimensions

CareerSpeak SHALL distinguish the following settings:

```text
ui_locale
translation_locale
preferred_accent
```

The learning language is not a user-selectable dimension in MVP:

```text
learning_language = en
```

Example:

```text
ui_locale          = ru
translation_locale = kk
preferred_accent   = UK
```

Another valid configuration:

```text
ui_locale          = es
translation_locale = es
preferred_accent   = US
```

`ui_locale` and `translation_locale` MAY be the same or different.

These preferences SHALL be stored locally by default.

---

## 4. Initial supported locales

### Release 1

```text
en  English
ru  Russian
kk  Kazakh
```

The first production release SHALL support English UI plus Russian and Kazakh localization where the relevant content translations are available.

---

## 5. Planned globalization rollout

The rollout is a product/content plan, not a database limitation.

### Phase G1 — Central Asia

```text
uz  Uzbek
ky  Kyrgyz
```

### Phase G2 — Adjacent markets

```text
uk  Ukrainian
tr  Turkish
```

### Phase G3 — Major global IELTS / career-English markets

```text
es  Spanish
pt  Portuguese
hi  Hindi
ur  Urdu
ar  Arabic
```

### Phase G4 — Further global expansion

```text
bn  Bengali
id  Indonesian
vi  Vietnamese
fr  French
de  German
```

The architecture SHALL permit additional locales without redesigning core content entities.

---

## 6. Language/locale master data

Locale support SHALL be data-driven.

Suggested entity:

```text
locale
────────────────────────
code
bcp47_tag
name_en
native_name
direction
enabled
sort_order
created_at
updated_at
```

Example data:

```text
en | en    | English    | English     | LTR
ru | ru    | Russian    | Русский     | LTR
kk | kk    | Kazakh     | Қазақша     | LTR
uz | uz    | Uzbek      | O‘zbekcha   | LTR
es | es    | Spanish    | Español     | LTR
pt | pt-BR | Portuguese | Português   | LTR
ar | ar    | Arabic     | العربية     | RTL
ur | ur    | Urdu       | اردو        | RTL
```

Supported text direction values:

```text
LTR
RTL
```

The Flutter UI SHALL be RTL-ready before Arabic or Urdu production rollout.

---

## 7. Canonical content model

Canonical educational content SHALL remain English-first.

Examples:

```text
vocabulary_word
────────────────────────
id
lemma
phonetic
part_of_speech
cefr_level
status
created_at
updated_at
```

```text
vocabulary_translation
────────────────────────
id
word_id
locale
translation
localized_definition
status
```

The schema SHALL NOT use fixed-language columns such as:

```text
translation_ru
translation_kk
translation_uz
translation_es
```

---

## 8. Hint localization

`hint` is a first-class localizable content type.

Canonical hint content SHALL be stored independently from its localized variants.

Suggested conceptual model:

```text
hint
────────────────────────
id
content_type
content_id
hint_text_en
status
revision
```

```text
hint_translation
────────────────────────
hint_id
locale
text
status
```

A hint may be associated with:

- vocabulary;
- mock-test question;
- interview question;
- IELTS cue card;
- topic section;
- phrase;
- collocation;
- answer explanation.

The mobile application SHALL display the localized hint when available and SHALL fall back to English if no translation exists.

---

## 9. Explanation localization

Supporting explanations MAY be translated without changing canonical English questions or answers.

Example:

```text
Canonical question:
Which collection is designed for concurrent access?

Canonical answer:
ConcurrentHashMap

Localized explanation (ru):
ConcurrentHashMap предназначен для безопасной конкурентной работы нескольких потоков.
```

The same question, answer and English audio SHALL be reusable across every UI locale.

---

## 10. Localizable entities

At minimum, the following content SHALL support localization where applicable:

```text
UI strings
vocabulary translations
hints
explanations
profession names
career-track names
category names
skill names
mock-test titles/descriptions
topic titles/descriptions
phrase translations
administrative labels visible to learners
```

Canonical learning content remains English unless the business explicitly defines an auxiliary translated field.

---

## 11. Publication by locale

Localization SHALL have its own publication state.

Example:

```text
Canonical content: PUBLISHED

EN: PUBLISHED
RU: PUBLISHED
KK: PUBLISHED
UZ: DRAFT
ES: MISSING
AR: MISSING
```

Publishing the canonical English content SHALL NOT automatically publish every locale.

Locale status values:

```text
MISSING
DRAFT
READY
PUBLISHED
ARCHIVED
```

The mobile application SHALL receive only localized content with `PUBLISHED` status, plus configured fallback English content.

---

## 12. Locale fallback

Default fallback policy:

```text
requested locale
      ↓
base language where applicable
      ↓
English
```

Examples:

```text
pt-BR → pt → en
es-MX → es → en
ru-KZ → ru → en
kk-KZ → kk → en
```

Fallback rules SHALL be centralized and consistent across mobile and backend contracts.

---

## 13. Automatic locale selection

CareerSpeak SHALL NOT require GPS or precise/approximate location permission solely to choose UI language.

Automatic locale selection SHALL use:

```text
1. Explicit CareerSpeak locale selection
2. OS per-app locale
3. OS preferred language list
4. OS region
5. English fallback
```

Example:

```text
kk-KZ → kk
ru-KZ → ru
uz-UZ → uz
es-MX → es
pt-BR → pt-BR/pt according to configured availability
```

The learner SHALL always be able to override the automatically selected locale.

---

## 14. Installation identity

CareerSpeak SHALL NOT require a personal learner account.

The application MAY generate a cryptographically random technical installation identifier at first launch.

Normative term:

```text
installationId
```

The system SHALL NOT use `userId` or hardware `deviceId` for this concept.

Recommended generation:

```text
256-bit cryptographically secure random value
```

The installation identifier SHALL NOT be derived from:

- IMEI;
- IMSI;
- MAC address;
- hardware serial number;
- advertising ID;
- phone number;
- email address;
- Apple/Google account identity.

---

## 15. Installation identity purpose

`installationId` MAY be used only for technical purposes such as:

- API abuse protection;
- rate limiting;
- application entitlement/integrity extensions;
- token rotation;
- blocking compromised installation credentials.

It SHALL NOT be used to create a server-side learning profile.

The backend SHALL NOT associate the installation identifier with:

```text
favorites
IELTS score
mock-test history
learned vocabulary
profession interests
recent topics
learning progress
```

---

## 16. Installation credential protection

Sensitive installation material SHALL be stored with platform secure storage:

```text
Android → Keystore-backed secure storage
iOS     → Keychain
```

If the server needs to compare an installation secret but does not need the original value, it SHOULD store a one-way keyed derivation such as HMAC rather than reversible encryption.

A server-signed installation token SHOULD be evaluated as the preferred stateless design.

---

## 17. Learner data policy

CareerSpeak SHALL NOT require the following learner data for MVP:

```text
name
email
phone number
birth date
precise location
social account
employer
resume/CV
voice recording
contacts
advertising identifier
```

The following learning state SHALL be local-first:

```text
favorites
vocabulary progress
mock-test attempts
mock-test answers
scores
completed topics
review schedule
recently opened content
downloaded packs
UI settings
```

Deleting the application may delete this local learning history unless a future explicit backup/sync capability is introduced.

---

## 18. Privacy requirement IDs

```text
PRIV-001 CareerSpeak SHALL NOT require a personal learner account.
PRIV-002 Learning history, favorites, test results and preferences SHALL be local-first.
PRIV-003 CareerSpeak SHALL NOT request GPS location solely for localization.
PRIV-004 A random installationId MAY be used only for technical security/entitlement purposes.
PRIV-005 installationId SHALL NOT be derived from persistent hardware or advertising identifiers.
PRIV-006 Learner voice SHALL NOT be uploaded in MVP.
PRIV-007 Application logs SHALL avoid learner-identifying payloads where not operationally required.
PRIV-008 Advertising SDKs are outside MVP scope.
PRIV-009 installationId SHALL NOT be joined with local learning history to form a server-side learner profile.
```

---

## 19. DigitalOcean global deployment strategy

The production platform SHALL be designed for DigitalOcean.

Initial deployment MAY use one primary application/database region.

Recommended logical topology:

```text
                    GLOBAL USERS
                         │
                         ▼
                    CDN / EDGE
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
          Audio/Media            Content API
              │                     │
              ▼                     ▼
            RustFS          CareerSpeak Backend
                                  │
                                  ▼
                              PostgreSQL
                                  ▲
                                  │
                         Moderator Desktop
```

The initial API/database region may be located in Europe, with Frankfurt as a strong candidate for the first deployment serving Kazakhstan, Europe and broader international traffic.

The exact region SHALL be confirmed during production infrastructure qualification.

---

## 20. CDN-first media strategy

CareerSpeak is audio-heavy and predominantly read-oriented.

Audio files SHALL NOT require every global learner to read directly from a single RustFS origin over long geographic distances.

Production architecture SHALL support:

```text
RustFS origin
     ↓
CDN/cache layer
     ↓
Global learners
```

The content/database API remains the source of metadata while media delivery is optimized independently.

CDN integration SHALL NOT require changes to canonical `file_asset` identity.

---

## 21. File identity

Canonical media identity remains:

```text
bucket + object_key
```

The database SHALL NOT use a CDN hostname or public URL as durable media identity.

This allows later migration between:

- RustFS endpoints;
- CDN providers;
- DigitalOcean object-storage options;
- additional delivery regions.

without rewriting educational entities.

---

## 22. Localized content manifest

The content manifest SHOULD support locale selection.

Example:

```http
GET /api/v1/content/manifest?locale=kk
```

Conceptual response metadata:

```text
manifestVersion
contentVersion
locale
fallbackLocale
publishedAt
packs
assets
checksums
```

The manifest SHALL NOT require a learner profile.

---

## 23. Mobile offline localization

Offline packs SHALL contain the selected locale resources required for the learner experience.

Example pack:

```text
Java Interview Pack
├── canonical English questions
├── canonical English answers
├── English audio
├── kk translations
├── kk hints
└── kk explanations
```

Switching locale MAY require downloading the new locale delta rather than redownloading the English audio assets.

This is a core optimization goal for global expansion.

---

## 24. Moderator localization workflow

The Python Moderator application SHALL include localization management.

Required capabilities:

```text
locale catalog
translation editor
hint translation editor
explanation translation editor
missing-translation filter
translation status
preview by locale
publish locale
archive locale
```

Example dashboard:

```text
Content                EN      RU       KK       UZ       ES
----------------------------------------------------------------
Java question #101     ✓       ✓        ✓        Draft    Missing
IELTS word #202        ✓       ✓        ✓        ✓        Missing
Topic #17              ✓       ✓        Draft    Missing  Missing
```

---

## 25. Globalization acceptance criteria

Globalization architecture is accepted when all of the following are true:

1. Canonical learning content is English and is stored once.
2. UI language can be changed independently from English learning content.
3. Vocabulary translation can be added for a new locale without changing the core schema.
4. `hint` can be translated independently per locale.
5. Explanations can be translated independently per locale.
6. English audio is reused across locales.
7. RTL locale metadata is supported.
8. Locale selection does not require GPS permission.
9. `installationId` does not expose hardware identity.
10. Learning history remains local by default.
11. A new locale can be published through Moderator + backend data without a new Flutter feature implementation.
12. CDN/media delivery can change without changing canonical media IDs.
13. Offline locale deltas do not require redownloading unchanged English audio.

---

## 26. Architecture decisions to record

The following ADRs SHALL be created during P0:

```text
ADR-G01 English as the fixed learning language for CareerSpeak MVP
ADR-G02 UI locale and translation locale are independent
ADR-G03 Typed localization tables; no fixed-language columns
ADR-G04 Hint and explanation localization model
ADR-G05 No GPS solely for locale detection
ADR-G06 Random installationId, not hardware device identity
ADR-G07 Local-first learner progress
ADR-G08 DigitalOcean primary-region deployment
ADR-G09 CDN-first global audio delivery
ADR-G10 Locale-specific offline delta packs
```

---

## 27. P0 globalization deliverables

Before implementation of the content domain, P0 SHALL produce:

```text
G0.1 Locale domain model
G0.2 Translation ERD
G0.3 Hint localization ERD
G0.4 Locale fallback specification
G0.5 Flutter locale-selection flow
G0.6 installationId security design
G0.7 localized manifest contract
G0.8 offline locale-delta design
G0.9 moderator localization workflow
G0.10 DigitalOcean/CDN deployment decision
```

These deliverables are prerequisites for freezing the content schema.
