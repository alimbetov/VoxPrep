# Flutter ↔ Backend Contract Gap Remediation Plan

Status: **PLANNED / AUDIT FOLLOW-UP**

Primary audit:
- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_AUDIT.md`

Supplemental presentation/motion audit:
- `docs/audits/BACKEND_CONTRACT_GAP_AUDIT_MOTION_PLAN.md`

## Goal

Close the remaining backend-owned product contract gaps without contaminating the already established production/offline foundation, then introduce presentation motion only after the data/state boundary is stable.

The plan deliberately separates two workstreams:

```text
BACKEND CONTRACT COMPLETION
        ↓
backend implementation readiness

PRESENTATION MOTION
        ↓
learner UX polish
```

Motion is not allowed to become a workaround for missing backend contracts or ambiguous state ownership.

---

# Stream A — Backend contract completion

## A1 / B0.2 — PracticeTest contract

Priority: **P0**

Problem:
- Flutter has `PracticeTest`, `PracticeTestSummary`, `PracticeQuestion` and test-session UI;
- production wiring still cannot obtain tests from the backend contract;
- test definitions are therefore not yet part of the deterministic offline content lifecycle.

Deliverables:
- `PracticeTestSummaryDto`;
- `PracticeTestPayloadDto`;
- `PracticeQuestionDto`;
- stable test/question codes;
- immutable revision semantics;
- discovery/manifest relation;
- backend publication rules;
- Flutter decoder + mapper;
- Drift projection;
- production `PracticeTestRepository`.

Acceptance:
- no production unavailable/mock assessment repository;
- exact immutable test revision survives restart/offline;
- questions are not hardcoded in Flutter;
- scoring is deterministic for one revision;
- stale/partial test projections fail closed.

---

## A2 / B0.3 — Taxonomy contract

Priority: **P0/P1**

Problem:
- category/level codes and labels currently travel inside content payloads;
- Skill is also needed for assessment;
- backend Admin/catalog evolution requires first-class taxonomy ownership.

Deliverables:

```text
Category
Level
Skill
```

Each requires:
- stable code;
- active state;
- deterministic order;
- localized labels;
- version/revision/ETag strategy;
- optional hierarchy only where product requirements justify it.

Acceptance:
- Flutter does not invent mutable category/level/skill catalogs;
- codes are identity, labels are presentation;
- catalog additions do not require a Flutter release;
- local cache can reopen offline deterministically.

---

## A3 / B0.4 — Supported locale + learner-facing TTS voice catalog

Priority: **P1, P0 for TTS rollout**

Problem:
- supported UI/translation locales and accents are currently represented by concrete client-side values;
- device selection may remain local, but product availability must be backend-owned.

Deliverables:

```text
SupportedLocale
TtsVoice
```

Minimum locale semantics:
- code;
- displayName;
- active;
- uiSupported;
- translationSupported;
- contentPackAvailable;
- fallbackLocaleCode.

Minimum voice semantics:
- code;
- localeCode;
- accentCode;
- displayName;
- active;
- defaultForLocale;
- learner-visible capabilities.

Do not expose worker-only model/cache/storage internals to Flutter.

Acceptance:
- Flutter stores selected stable codes only;
- availability comes from backend projection;
- removed/deactivated choices fall back deterministically;
- catalog is revisionable/cacheable/offline-readable.

---

## A4 / B0.5 — Backend aggregate and persistence design

Priority: **P0 after A1–A3 contract freeze**

Do not map OpenAPI DTOs one-to-one into JPA entities.

Required separation:

```text
Persistence entities
      ↓
Backend domain aggregates
      ↓
Application projections
      ↓
REST DTO
      ↓
Flutter wire DTO
      ↓
Flutter mapper/read model
```

Suggested bounded areas:

```text
ContentCatalog
Taxonomy
PracticeTesting
AssetDelivery
InstallationIdentity
TtsCatalog
```

Acceptance:
- published revisions are immutable;
- stable codes are not display labels;
- API projection can evolve independently from persistence shape;
- publication/version semantics are explicit before table design is frozen.

---

# Stream B — Presentation motion after production foundation

Motion work starts only after the P2 production foundation/recovery qualification is accepted and merged.

Recommended implementation stream:

```text
feat/p3-motion-system
```

Use one branch unless there is a real isolation need.

## B1 / P3.0 — Motion contract

Priority: **P0**

Deliverables:
- shared duration tokens;
- shared curves;
- reduced-motion policy;
- reusable route/widget transition builders;
- architecture tests preventing motion dependency leakage into data/application/domain.

Baseline durations:

```text
instant      0 ms
fast       120 ms
standard   180 ms
navigation 220 ms
emphasized 300 ms
```

Acceptance:
- all custom motion goes through central policy;
- reduced motion maps non-essential animation to instant state rendering;
- no Rive/Lottie/third-party animation dependency required.

---

## B2 / P3.1 — Navigation motion

Priority: **P0**

Deliverables:
- GoRouter `CustomTransitionPage` helper;
- subtle sibling destination transition;
- hierarchical content-detail/test-session transition;
- stable adaptive shell.

Acceptance:
- compact/medium/large layouts qualified;
- route transition is not duplicated by scaffold transition;
- reduced-motion path is deterministic.

---

## B3 / P3.2 — Shared component motion

Priority: **P0**

Deliverables:
- `ContentCard` selected-state interpolation;
- favorite icon transition;
- learner marker chip insert/remove transition.

Acceptance:
- no layout jump from scaling cards;
- persistence completes independently of visual transition;
- rapid repeated taps cannot desynchronize UI and learner state.

---

## B4 / P3.3 — Learn + content detail + audio

Priority: **P0**

Deliverables:
- stable-identity keyed detail-pane switch;
- favorite/completed visual feedback;
- audio phase transitions for resolving/playing/paused/completed/failure.

Do not add decorative waveform/spectrum loops in this slice.

Acceptance:
- audio playback/resume/LISTENED semantics unchanged;
- detail selection never loses state;
- reduced-motion rendering remains immediate.

---

## B5 / P3.4 — Home state motion

Priority: **P1**

Deliverables:
- learner-stat value transitions;
- progress interpolation;
- bounded continue-learning replacement if it materially improves orientation.

Acceptance:
- values always come from real learner state;
- no looping decorative animation;
- tests remain deterministic.

---

## B6 / P3.5 — Tests + review motion

Priority: **P1**

Deliverables:
- Intro → Question → Result transitions;
- small directional question transitions;
- restrained result emphasis;
- no redundant animation around existing Material `ExpansionTile` behavior.

Acceptance:
- Next/Previous directions are inverse and stable;
- fast navigation does not corrupt session state;
- result state remains deterministic.

---

## B7 / P3.6 — Motion qualification

Priority: **REQUIRED**

Qualification matrix:

```text
compact / medium / large
light / dark
normal / reduced motion
normal / large text scale
LTR / RTL structural preview
rapid repeated taps
back navigation
offline local content
real audio phases
renderer screenshots
```

Required gates:
- strict `dart format`;
- `flutter analyze`;
- full `flutter test`;
- motion-specific widget tests;
- all existing production E2E/recovery tests remain green;
- representative screenshot evidence;
- exact-SHA green CI.

---

# Global priority order

```text
1. PracticeTest contract                      P0
2. Taxonomy contract                          P0/P1
3. Locale / TTS voice availability            P1 / P0 for TTS
4. Backend aggregate/entity design            P0 after contract freeze
5. P2 production foundation final acceptance  prerequisite for motion
6. Motion contract                            P0
7. Navigation + shared feedback                P0
8. Learn/content/audio motion                  P0
9. Home + test polish                          P1
10. Full motion qualification                  required
```

# Dependency map

```text
B0.1 Content/Manifest baseline ✅
        │
        ├──► B0.2 PracticeTest
        │
        ├──► B0.3 Taxonomy
        │
        └──► B0.4 Locale / Voice
                 │
                 ▼
        B0.5 backend aggregate design
                 │
                 ▼
        backend implementation

P2 production/recovery accepted
                 │
                 ▼
             P3.0 Motion
                 ↓
             P3.1 Navigation
                 ↓
             P3.2 Shared
                 ↓
             P3.3 Learn/Audio
                 ↓
             P3.4 Home
                 ↓
             P3.5 Tests
                 ↓
             P3.6 Qualification
```

# Definition of Done

The audit remediation program is complete when:
- all mutable product catalogs are backend-owned and revisionable;
- practice tests are production-backed and offline-reopen safe;
- taxonomy/locale/voice availability does not require hardcoded Flutter product truth;
- backend persistence is not a mirror of Flutter DTOs;
- motion stays presentation-only;
- reduced motion is implemented before broad animation rollout;
- no animation delays or masks sync/recovery/error correctness;
- existing P2 production/recovery gates remain green;
- each accepted slice has exact-SHA green CI evidence.
