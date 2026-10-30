# CareerSpeak — Material Design 3 Design System

**Document version:** 1.0  
**Status:** Normative UI design-system contract  
**Applies to:** CareerSpeak v0.9+  
**Target platforms:** Android, iOS  
**Branch:** `feat/p0-material-design-3`

---

## 1. Decision

CareerSpeak SHALL use **Material Design 3 as its single UI design system**.

```text
Material Design 3
        ↓
CareerSpeak Theme + Design Tokens
        ↓
CareerSpeak reusable components
        ↓
Feature presentation
```

CareerSpeak SHALL NOT maintain a second parallel custom design system for iOS, tablets, Study Ambience, Exam Mode or individual features.

Platform adaptation may affect interaction details where required by Android/iOS conventions, but visual semantics, components, tokens and accessibility rules remain governed by this contract.

---

## 2. Goals

The design system SHALL provide:

```text
professional visual identity
consistent Material 3 behavior
light/dark/system themes
adaptive phone/tablet/split-screen layouts
readable long-form English content
accessible large-text behavior
LTR/RTL mixed-direction support
stable reusable component vocabulary
low visual noise during focused learning/tests
predictable implementation for one development team
```

CareerSpeak should feel:

```text
PROFESSIONAL
ACADEMIC
CALM
MODERN
FOCUSED
```

It should not look like a highly gamified children's application.

---

## 3. Non-goals

Do not introduce in MVP:

```text
parallel Cupertino visual system
feature-specific button systems
feature-local typography scales
raw arbitrary colors in widgets
uncontrolled gradients
custom navigation framework
custom dialog framework
3D/physics-heavy transitions
large animation dependency
multiple unrelated icon families
wallpaper-based dynamic color as authoritative brand theme
```

Custom widgets are allowed only as CareerSpeak components built on top of Material 3 primitives or where no adequate Material primitive exists.

---

## 4. Theme ownership

Theme ownership is centralized under the application layer.

Recommended implementation:

```text
lib/app/theme/
├── career_speak_theme.dart
├── career_speak_color_tokens.dart
├── career_speak_semantic_colors.dart
├── career_speak_spacing.dart
├── career_speak_radius.dart
├── career_speak_typography.dart
├── career_speak_elevation.dart
└── career_speak_motion.dart
```

Feature widgets SHALL consume theme/tokens/components rather than define their own global visual language.

---

## 5. Flutter Material baseline

Application root SHALL use Material 3 through `ThemeData`/`ColorScheme`.

Conceptual application wiring:

```dart
MaterialApp.router(
  theme: CareerSpeakTheme.light(),
  darkTheme: CareerSpeakTheme.dark(),
  themeMode: themeMode,
  routerConfig: router,
)
```

Theme construction SHALL be centralized.

Conceptually:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(...),
)
```

Feature code SHALL NOT instantiate unrelated `ThemeData` trees to create a different visual product.

---

## 6. Brand color policy

CareerSpeak uses a restrained professional brand palette.

Baseline direction:

```text
primary family     = deep indigo / blue
secondary family   = teal-compatible supporting tone
surfaces           = neutral
success            = semantic green
warning            = semantic amber/orange
error              = Material error role
```

Provisional brand seed for implementation qualification:

```text
CareerSpeak brand seed = #3F51B5
```

The exact seed may be refined once during visual qualification before release, but SHALL then be changed centrally rather than per feature.

Material `ColorScheme` roles are the primary color API:

```text
primary
onPrimary
primaryContainer
onPrimaryContainer
secondary
onSecondary
secondaryContainer
surface
onSurface
surfaceContainer*
outline
error
onError
```

Widgets SHALL NOT use raw `Colors.blue`, `Colors.green`, arbitrary hex values or unrelated palette constants for ordinary UI styling.

---

## 7. Semantic colors

Material `ColorScheme` does not need to carry every domain semantic role.

CareerSpeak MAY define one controlled theme extension:

```text
CareerSpeakSemanticColors
├── success
├── onSuccess
├── successContainer
├── onSuccessContainer
├── warning
├── onWarning
├── warningContainer
├── onWarningContainer
├── info
└── onInfo
```

Usage examples:

```text
correct answer       → success
incorrect/fatal      → error
storage warning      → warning
sync informational   → info
```

Do not encode semantic meaning only with color; use icon/text/state as well.

---

## 8. Theme modes

Supported theme modes:

```text
SYSTEM
LIGHT
DARK
```

`SYSTEM` is the default unless later product research changes it.

Light and dark themes SHALL share the same semantic design language and component geometry.

Dark mode is not implemented as `black background + inverted text`; it uses Material 3 surface roles and qualified contrast.

---

## 9. Dynamic color

System wallpaper/dynamic color SHALL NOT be the authoritative CareerSpeak brand theme in MVP.

Reason:

```text
consistent product identity
predictable screenshots/store assets
predictable learning-state semantics
predictable accessibility qualification
```

Dynamic color MAY be evaluated later as an opt-in enhancement, provided it does not break semantic color roles or brand recognition.

---

## 10. Spacing tokens

Baseline spacing scale:

```text
space4   = 4
space8   = 8
space12  = 12
space16  = 16
space24  = 24
space32  = 32
space48  = 48
space64  = 64
```

Primary screen gutters follow the adaptive UI contract:

```text
COMPACT   16
MEDIUM    24
EXPANDED  32
LARGE     40
```

Feature code should prefer shared spacing tokens over arbitrary values such as 13, 19 or 27 logical pixels.

---

## 11. Shape/radius tokens

Baseline shape scale:

```text
radiusSmall   = 8
radiusMedium  = 12
radiusLarge   = 16
radiusXLarge  = 24
```

Guidance:

```text
small controls / compact containers → Small/Medium
cards                            → Large
large sheets/prominent surfaces  → XLarge
```

Feature widgets SHALL NOT invent unrelated corner-radius systems.

---

## 12. Elevation and surfaces

CareerSpeak uses Material 3 surface/container roles rather than heavy shadows.

Rules:

```text
prefer tonal/surface hierarchy
use elevation only when it communicates hierarchy
avoid decorative floating cards everywhere
avoid stacking multiple elevated surfaces without semantic purpose
```

Learning text should typically live on stable readable surfaces.

---

## 13. Typography

Reading quality has priority over decorative typography.

Use Material `TextTheme` roles as the baseline:

```text
display*    → exceptional hero/marketing content only
headline*   → screen-level headings
title*      → sections/cards/question titles
bodyLarge   → primary English learning text
bodyMedium  → explanations/support text
label*      → controls/chips/metadata
```

CareerSpeak SHALL NOT define feature-specific font-size constants scattered through widgets.

English learning text should be visually distinct through role/weight/spacing, not by bypassing the global type scale.

Baseline readable line length:

```text
primary reading column max width ≈ 680–760 logical px
```

Current adaptive baseline:

```text
maxReadableWidth ≈ 720
```

---

## 14. Font policy

MVP may use the platform/default Material-compatible font stack to reduce packaging and rendering risk.

A custom brand font is optional and SHALL require:

```text
English readability qualification
Cyrillic support
Kazakh glyph support
future RTL-script strategy
large-text qualification
license review
```

No custom font is required for P1 implementation.

---

## 15. Iconography

Material Symbols/Material Icons are the baseline icon family.

Examples:

```text
Home
School
Work
Book
Headphones
Download
Favorite
Translate
Settings
Quiz
Volume
Replay
Search
```

Do not casually mix multiple unrelated icon families, emoji and custom SVGs for equivalent UI actions.

Custom icons are allowed for true product/domain concepts only when no suitable Material icon exists.

---

## 16. Primary Material 3 components

CareerSpeak should prefer Material 3 primitives:

```text
Scaffold
AppBar
NavigationBar
NavigationRail
SearchBar / SearchAnchor where suitable
Card
ListTile
FilledButton
FilledButton.tonal
OutlinedButton
TextButton
IconButton
FloatingActionButton only where semantically justified
FilterChip
ChoiceChip
InputChip
SegmentedButton
LinearProgressIndicator
CircularProgressIndicator
Badge
SnackBar
Dialog
BottomSheet
TextField / form fields
Divider
```

Each feature SHALL reuse these semantics before creating a bespoke alternative.

---

## 17. CareerSpeak component layer

Reusable product-level components MAY wrap Material 3 primitives.

Initial component vocabulary:

```text
CareerSpeakScaffold
CareerSpeakAdaptiveScaffold
CareerSpeakSectionHeader
CareerSpeakContentCard
CareerSpeakProgressCard
CareerSpeakLearningText
CareerSpeakMetadataChips
CareerSpeakAudioButton
CareerSpeakAudioMiniPlayer
CareerSpeakEmptyState
CareerSpeakErrorState
CareerSpeakOfflineBadge
CareerSpeakDownloadState
CareerSpeakAnswerOption
CareerSpeakStorageSummary
CareerSpeakStudySurface
```

Rules:

1. components expose semantic parameters rather than raw visual knobs where practical;
2. components obtain color/type/spacing from theme/tokens;
3. components do not own business state;
4. Riverpod/domain state remains outside reusable visual components;
5. component APIs remain usable across all width classes.

---

## 18. Adaptive integration

Material 3 works together with `CAREERSPEAK_ADAPTIVE_UI.md`.

Width classes remain:

```text
COMPACT   < 600
MEDIUM    600–839
EXPANDED  840–1199
LARGE     >= 1200
```

Baseline navigation mapping:

```text
COMPACT
→ NavigationBar

MEDIUM
→ NavigationRail or NavigationBar where flow requires more width

EXPANDED
→ NavigationRail + optional second pane

LARGE
→ extended NavigationRail/navigation pane + multi-pane layout when useful
```

Material component choice adapts presentation; it SHALL NOT fork domain/application logic.

---

## 19. Top-level navigation

Recommended top-level destinations remain:

```text
Home
Learn
Tests
Review
My / Settings
```

Do not place Vocabulary, Interview, Topics, Downloads, Settings and every feature simultaneously into a crowded bottom bar.

`NavigationBar` and `NavigationRail` represent the same logical destinations and preserve the same route state during resize.

---

## 20. Home pattern

Home uses a calm dashboard composition.

Suggested structure:

```text
Home
├── Continue Learning
├── Daily Review
├── IELTS
├── Job Interview
├── Professional English
├── Quick Test
└── Downloads status
```

Material mapping:

```text
Continue Learning → prominent Card + progress + FilledButton/Tonal action
Daily Review      → Card/ListTile + Badge/progress
Learning areas    → Card grid/list according to width class
Downloads         → compact status surface
```

Avoid banners/hero graphics that push learning actions below the fold on short windows.

---

## 21. Catalog/search pattern

Vocabulary, Interview, Topics and similar catalogs use:

```text
SearchBar
FilterChip / ChoiceChip
ListTile / Card results
optional sort/filter sheet
```

Compact:

```text
list → navigate to detail
```

Expanded/Large when natural:

```text
list pane | detail pane
```

Search/filter state survives adaptive layout change.

---

## 22. Vocabulary detail pattern

Recommended semantic hierarchy:

```text
word + favorite action
phonetics + audio
part-of-speech / CEFR metadata
English definition
localized translation
examples
collocations
word-family where available
review action
```

Use Material cards/surfaces only where grouping improves comprehension. Do not wrap every line in a separate card.

Primary English learning text uses the readable content column.

---

## 23. Interview pattern

Recommended hierarchy:

```text
question
question audio
profession/seniority/skill chips
useful phrases
model answer disclosure
model-answer audio
review/progress action
```

`FilledButton.tonal`, `OutlinedButton`, chips and Cards should communicate hierarchy without making every action equally prominent.

---

## 24. Shadowing / focused listening pattern

Shadowing uses a reduced-noise Material surface.

Core composition:

```text
current segment
highlighted English text
progress/position
play/pause
seek/skip
speed segmented control
repeat segmented control
```

On larger windows, text and playback controls may use two panes.

Do not introduce a separate visual framework for Shadowing.

---

## 25. Assessment / Exam mode

Exam Mode uses the same Material 3 design system with stricter focus rules.

Required characteristics:

```text
minimal decoration
clear question hierarchy
large answer hit targets
single obvious primary progression action
persistent but non-distracting progress/time where applicable
no Study Ambience imagery behind answer content
no unrelated recommendations/gamification surfaces
```

Suggested Material components:

```text
AppBar
LinearProgressIndicator
Card/surface question container where useful
CareerSpeakAnswerOption built from Material semantics
FilledButton for Next/Submit
Dialog for destructive exit/finish confirmation
```

---

## 26. Answer states

Assessment states SHALL use more than color.

Examples:

```text
selected
correct
incorrect
unanswered
reviewed
```

Represent with a combination of:

```text
container role
outline
icon
text label/semantics
```

Correct/incorrect SHALL remain distinguishable under color-vision deficiencies.

---

## 27. Downloads and storage pattern

Downloads use clear Material state presentation:

```text
QUEUED
DOWNLOADING
VERIFYING
READY
FAILED
```

Suggested components:

```text
ListTile/Card
LinearProgressIndicator
Badge/status text
IconButton for pause/resume/remove
Dialog for destructive removal where data impact needs confirmation
```

`READY` means offline asset completeness, not Backend availability.

---

## 28. Settings pattern

Settings use grouped Material list sections.

Initial groups:

```text
Language
Appearance
Audio / learning preferences
Downloads
Storage
About
```

Appearance exposes:

```text
System
Light
Dark
```

Theme selection changes Material theme only; Study Ambience is a separate learning-surface preference.

---

## 29. Study Ambience integration

Study Ambience is **not a second design system**.

Architecture:

```text
Material 3 theme
      +
optional decorative ambience layer
      +
Material readable learning surface
```

Allowed ambience examples:

```text
MINIMAL
NATURE
COSMOS
LIBRARY
COFFEE_STUDY
PROFESSIONAL
```

Rules:

1. English/support text remains on a contrast-qualified surface/scrim;
2. ambience never changes control semantics;
3. Exam/Mock Test defaults to MINIMAL;
4. Focus mode may suppress decorative backgrounds;
5. ambience assets obey normal asset/cache rules;
6. accessibility can disable/reduce visual decoration.

---

## 30. Motion

Motion is restrained and communicates state/navigation.

Centralize motion tokens, conceptually:

```text
motionFast
motionStandard
motionEmphasized
```

Use Material transitions where adequate.

Avoid animation that delays reading, answering or audio controls.

Respect platform accessibility/reduced-motion signals where available.

---

## 31. Touch targets

Interactive controls SHALL target at least approximately:

```text
48 × 48 logical px
```

unless a qualified Material component safely provides equivalent accessibility behavior.

Dense desktop-style controls are not the mobile baseline.

---

## 32. Large text

Core flows SHALL be qualified at text scale:

```text
1.0
1.3
1.6
2.0
```

At 2.0:

```text
primary actions remain reachable
answers are not clipped
navigation remains usable
cards grow/scroll rather than crop
critical labels are not hidden solely to preserve aesthetics
```

Avoid fixed-height text containers for learner-facing copy.

---

## 33. Accessibility semantics

Interactive/important content SHALL expose meaningful semantics for assistive technologies.

Examples:

```text
audio play/pause state
download progress
selected answer
correct/incorrect result
favorite state
sync/offline status where user-relevant
```

Decorative ambience/images should not create noisy accessibility trees.

---

## 34. Contrast and state qualification

Light and dark themes SHALL be visually qualified for:

```text
primary text
secondary/support text
buttons
chips
answer states
error states
success/warning states
surface overlays on ambience
```

Do not approve a color combination only because it looks acceptable on one display.

Automated contrast checks should be supplemented by device/screenshots/manual review.

---

## 35. Localization and RTL

Material layout follows directional `start/end` semantics.

In RTL UI:

```text
navigation/chrome may mirror
localized support text follows RTL
canonical English learning text remains LTR
```

English content and audio controls SHALL remain pedagogically clear inside RTL layouts.

Do not hardcode left/right padding/alignment when direction-aware alternatives are appropriate.

---

## 36. Empty/loading/error states

Every primary feature SHALL use consistent Material-based states.

### Loading

Use skeleton/progress only where it clarifies waiting. Local cached content should render immediately rather than showing network spinners unnecessarily.

### Empty

Use:

```text
short explanation
optional simple icon/illustration
one clear next action when meaningful
```

### Error

Use domain language such as:

```text
You're offline. Downloaded lessons are still available.
```

not raw transport/database exceptions.

---

## 37. Snackbars/dialogs/bottom sheets

Use semantics consistently:

```text
SnackBar
→ transient confirmation/non-blocking feedback

Dialog
→ destructive/important confirmation

BottomSheet
→ temporary contextual selection/actions on compact layouts
```

Do not use modal dialogs for routine informational messages.

---

## 38. Implementation boundaries

Presentation code may depend on:

```text
Flutter Material
CareerSpeak theme/tokens
CareerSpeak UI components
Riverpod view/application state
```

Domain/application code SHALL NOT depend on:

```text
Material widgets
BuildContext
ThemeData
Color
TextStyle
screen width
```

Adaptive/UI concerns remain presentation-only.

---

## 39. Recommended implementation structure

```text
lib/
├── app/
│   └── theme/
│       ├── career_speak_theme.dart
│       ├── color_tokens.dart
│       ├── semantic_colors.dart
│       ├── spacing.dart
│       ├── radius.dart
│       ├── typography.dart
│       └── motion.dart
│
├── core/
│   └── ui/
│       ├── adaptive/
│       ├── components/
│       └── states/
│
└── features/
    └── .../presentation/
```

`core/ui` is the reusable product UI layer; it must not become a home for domain/business logic.

---

## 40. Testing strategy

At minimum qualify:

```text
light theme
dark theme
COMPACT/MEDIUM/EXPANDED/LARGE
portrait/landscape/split-screen representative sizes
text scale 1.0 and 2.0
English/Russian/Kazakh UI
RTL representative layout
offline/loading/error states
selected/correct/incorrect assessment states
Study Ambience readability
route/audio/test-state preservation across resize
```

Use widget/golden/screenshot testing where it provides stable value, but do not make pixel-perfect goldens so brittle that ordinary Material patch changes block all development.

---

## 41. Material 3 acceptance criteria

Material Design 3 integration is accepted when:

1. `ThemeData`/`ColorScheme` is the single application theme source;
2. light/dark/system modes work across core flows;
3. raw feature-local colors are eliminated except justified domain/media rendering;
4. spacing/radius/type/motion tokens are centralized;
5. top-level navigation maps to Material `NavigationBar`/`NavigationRail` by width class;
6. reusable CareerSpeak components wrap Material primitives rather than replace the entire component system;
7. Home, Vocabulary, Interview, Shadowing, Assessment, Downloads and Settings follow documented Material patterns;
8. Study Ambience remains decorative and cannot override readability/control semantics;
9. text scale 2.0 remains usable;
10. RTL/mixed-direction behavior remains correct;
11. answer/status semantics do not depend only on color;
12. domain/application code has no Material/BuildContext dependency;
13. adaptive resize does not reset route/audio/test state;
14. accessibility semantics exist for critical interactive states;
15. no competing second UI design system exists in the codebase.

---

## 42. Final rule

```text
ONE PRODUCT
ONE MATERIAL 3 DESIGN SYSTEM
ONE TOKEN LAYER
ONE REUSABLE COMPONENT LAYER
MANY ADAPTIVE PRESENTATIONS
```

Material Design 3 is the authoritative and exclusive CareerSpeak UI design-system baseline.