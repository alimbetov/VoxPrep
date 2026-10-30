# P2.10.4 — Production Preferences + Locale Wiring

**Branch:** `feat/p2-flutter-production-adapters`  
**Parent stage:** P2.10.3 DriftContentRepository  
**Database schema impact:** none (`schemaVersion = 4`)

## Goal

Replace runtime-only learner preferences with the existing Drift `app_preferences` singleton and make persisted `translationLocale` the source of truth for content synchronization.

P2.10.4 does not perform startup bootstrap and does not switch content/test repositories. Those remain P2.10.5 and P2.10.6.

## Durable preferences

```text
ApplicationPreferences
├── uiLocale
├── translationLocale
├── preferredAccent
├── theme
├── focusMode
└── storageQuotaBytes
```

Stable values are typed in the domain layer:

```text
uiLocale          en | ru | kk
translationLocale en | ru | kk
preferredAccent   en-US | en-GB | en-AU | null
theme              system | light | dark
```

Defaults are deterministic:

```text
uiLocale          en
translationLocale ru
preferredAccent   en-US
theme             system
focusMode         false
storageQuotaBytes null
```

The repository lazily materializes exactly one row with `id = 1`. Updates mutate only that singleton and preserve the existing schema.

## Architecture

```text
Settings / Theme / Sync
          ↓
Riverpod composition
          ↓
AppPreferencesRepository
          ↓
DriftAppPreferencesRepository
          ↓
app_preferences (id = 1)
```

Presentation does not import the Drift adapter directly.

## Translation locale ownership

English remains the learning language. `translationLocale` only selects learner-support/localization content.

Sync entrypoint:

```text
PreferenceAwareContentSync
        ↓
AppPreferencesRepository.getPreferences()
        ↓
translationLocale.code
        ↓
ContentSyncCoordinator.synchronize(...)
        ↓
GET /api/v1/content/manifest?locale=<translationLocale>
```

A preferences read failure prevents the remote sync request. Locale is never guessed from UI labels or device locale during this slice.

## UI semantics

The Settings screen reads/writes durable preferences for:

```text
UI language
translation language
preferred English accent
theme
```

Actual ARB/localized shell rendering is not introduced here. Persisting `uiLocale` establishes the production source of truth for that later presentation work.

`textScale` and `RTL` remain P1 structural preview controls only and are explicitly not persisted product preferences.

## Failure semantics

```text
PREFERENCES_INVALID
PREFERENCES_READ_FAILED
PREFERENCES_WRITE_FAILED
```

Unsupported stored codes and negative storage quota fail closed.

## Explicit non-goals

P2.10.4 does not:

```text
change Drift schema
add ARB localization
infer device locale
run installation registration
run startup sync
switch ContentRepository composition
remove MockContentRepository / MockTestRepository
persist locale support overlays in a new read model
```

## Acceptance matrix

```text
PR01 deterministic singleton defaults materialize once
PR02 typed preference updates round-trip through Drift
PR03 preferences survive database close/reopen
PR04 unsupported stored codes fail closed
PR05 negative storage quota fails without mutation
PR06 Riverpod composition selects DriftAppPreferencesRepository
PR07 theme derives from persisted preference state
PR08 Settings uses durable UI/translation/accent/theme preferences
PR09 persisted translationLocale is passed to root manifest sync
PR10 preference read failure prevents remote sync
PR11 textScale/RTL remain preview-only state
PR12 schemaVersion remains 4 with zero generated baseline drift
PR13 format/analyze/full-test exact-SHA qualification passes
```

P2.10.4 is accepted only on one exact branch SHA with the normal read-only `Flutter Production Adapters` workflow green. After acceptance the next stage is **P2.10.5 — HTTP registration + startup bootstrap**.
