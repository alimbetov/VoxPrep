# CareerSpeak — Adaptive / Responsive UI Contract

**Document version:** 0.1  
**Status:** Working design / P0.12 adaptive UI  
**Applies to:** CareerSpeak v0.9+  
**Target platforms:** Android, iOS  
**Branch:** `feat/p0-domain-contracts`

---

## 1. Goal

CareerSpeak SHALL use an adaptive learner UI that remains usable and visually coherent across:

```text
small phones
standard phones
large phones
foldable/split-screen windows
tablets
tablet landscape
large tablet windows
large system text
LTR and RTL UI
```

The implementation SHALL adapt to the **available application window size**, not to a hardcoded device class such as `phone/tablet` and not to orientation alone.

The same route/domain state SHALL be able to render through different layouts without changing the underlying business state.

---

## 2. Responsive vs adaptive

CareerSpeak distinguishes:

```text
RESPONSIVE
= dimensions, spacing, wrapping and grid density respond continuously to available space

ADAPTIVE
= navigation and information architecture may switch to a different layout pattern at defined width classes
```

Examples:

```text
Compact
→ bottom navigation
→ one-pane catalog/detail navigation

Expanded
→ navigation rail
→ master/detail where useful
```

The domain/application controller SHALL NOT contain screen-width branching.

Layout adaptation belongs to the presentation layer.

---

## 3. Window size classes

Width classes use logical pixels after application/window sizing.

```text
COMPACT   width < 600
MEDIUM    600 <= width < 840
EXPANDED  840 <= width < 1200
LARGE     width >= 1200
```

The application SHALL compute the current class from available window width using a centralized abstraction such as:

```text
AdaptiveWindowInfo
```

Conceptual API:

```dart
WindowSizeClass windowClassFor(double width)
```

Widgets SHALL NOT scatter raw breakpoint literals across feature code.

---

## 4. Height constraints

Width is the primary adaptation dimension, but short-height windows require special handling.

Conceptual height classes:

```text
SHORT   height < 600
NORMAL  height >= 600
```

`SHORT` commonly occurs on phones in landscape or split-screen.

Rules:

```text
avoid vertically fixed learning cards
allow controls to wrap/scroll
avoid forcing decorative hero content above learning content
keep primary action reachable
```

---

## 5. Adaptive tokens

Centralize layout tokens.

Recommended baseline:

```text
spacing:
4 / 8 / 12 / 16 / 24 / 32 / 48

content gutter:
COMPACT   16
MEDIUM    24
EXPANDED  32
LARGE     40

readable text max width:
~720

form / focused interaction max width:
~560

wide dashboard/catalog max width:
~1200
```

Exact design tokens may be adjusted during visual qualification, but feature code SHALL consume shared tokens rather than feature-local arbitrary constants.

---

## 6. Screen composition shell

Recommended application shell:

```text
AdaptiveScaffold
├── navigation
├── content body
├── optional secondary pane
└── global audio mini-player / transient UI where applicable
```

### COMPACT

```text
AppBar
Content
Bottom Navigation / destination bar
```

### MEDIUM

Preferred:

```text
NavigationRail (compact)
Content
```

or bottom navigation when the active flow benefits from maximum horizontal content width.

### EXPANDED

```text
NavigationRail
Primary content pane
Optional secondary/detail pane
```

### LARGE

```text
Extended navigation rail / navigation pane
Primary content
Secondary context/detail pane where useful
```

No screen SHALL require the LARGE class to expose functionality unavailable on COMPACT.

---

## 7. Top-level navigation

Primary destinations should remain small and stable.

Recommended top-level destinations:

```text
Home
Learn
Tests
Review
My / Settings
```

Feature-specific destinations such as Vocabulary, Interview and Topics are entered from Learn/Home rather than creating an overcrowded global navigation bar.

### Compact navigation

Use bottom navigation with labels.

### Medium/Expanded navigation

Use navigation rail.

### Large

Rail may be extended to show text labels persistently.

Navigation state SHALL be owned by router/application state and survive layout-class changes.

Switching from bottom navigation to rail SHALL NOT reset the route stack.

---

## 8. Route preservation across resize

Window resizing, rotation, split-screen change or text scaling SHALL NOT reset:

```text
current route
selected content code
scroll position where practical
active test attempt
audio playback state
shadowing segment
form/input state where relevant
```

Adaptive layout is a view change, not a new navigation event.

---

## 9. One-pane vs two-pane rule

Two-pane layout is allowed only where there is a natural master/detail relationship.

Good candidates:

```text
Vocabulary list + word detail
Interview question list + detail
Topic list + topic detail
Downloads list + pack details
Settings category + detail
```

Do not force two-pane layouts onto focused learning activities such as:

```text
exam question
shadowing practice
focused reading
onboarding
```

unless the secondary pane materially improves the task.

---

## 10. Master/detail navigation semantics

### COMPACT

```text
List route
   ↓ tap item
Detail route
```

### EXPANDED/LARGE

```text
List pane | Detail pane
```

The same stable business code identifies the selected item.

Back behavior:

```text
Compact detail
→ back returns to list

Expanded split view
→ back follows router history, not merely clearing visual selection unless route semantics require it
```

Deep links SHALL resolve correctly in both modes.

---

## 11. Home screen

### COMPACT

```text
Continue Learning
Daily Review
Primary learning areas
Quick Test
Downloads/status
```

Use one-column stacked sections/cards.

### MEDIUM

Use a two-column adaptive grid for secondary cards while keeping Continue Learning prominent.

### EXPANDED

Recommended:

```text
Main column
├── Continue Learning
├── Daily Review
└── Learning areas

Secondary column
├── Quick Test
├── Download status
└── recent/favorites summary
```

### LARGE

May use a 3-column dashboard, but readable learning previews remain width-constrained.

The Home screen SHALL render from local data immediately and SHALL NOT change its entire geometry when background sync begins/ends.

---

## 12. Catalog/list screens

Applies to:

```text
Vocabulary
Interview
Topics
Phrases
Tests
Downloads
```

### COMPACT

```text
filters/search
single-column list/cards
```

### MEDIUM

```text
filters
1–2 columns depending on content density
```

### EXPANDED/LARGE

For card-oriented catalogs:

```text
2–4 responsive columns
```

For list/detail domains:

```text
master list + detail pane
```

Grid column count SHALL be derived from a minimum usable card width, not a fixed device name.

Conceptually:

```text
columnCount = floor(availableContentWidth / minCardExtent)
```

with bounded minimum/maximum values per feature.

---

## 13. Search and filters

### COMPACT

Filters may open as:

```text
bottom sheet
full-screen filter route
collapsible filter section
```

### EXPANDED/LARGE

Persistent side filter pane MAY be shown when it improves catalog browsing.

Filter state SHALL be independent of how controls are rendered.

Changing layout class SHALL preserve:

```text
query
selected filters
sort
cursor/list position where practical
```

---

## 14. Vocabulary detail

### COMPACT

Single scrollable column:

```text
word
phonetic / POS / CEFR
audio action
translation
meaning/hint
examples
collocations
review/favorite actions
```

### MEDIUM

Same semantic order with increased whitespace and constrained readable width.

### EXPANDED/LARGE

Possible structure:

```text
Primary learning column
| Secondary support column
```

Primary:

```text
word + audio
definition/examples/collocations
```

Secondary:

```text
translation/hints
progress/review status
related metadata
```

Do not stretch paragraph text across the full tablet width.

---

## 15. Interview detail

### COMPACT

```text
question
question audio
model answer
answer audio
useful phrases/vocabulary
favorite/review
```

### EXPANDED

Use either:

```text
question/context | model answer/support
```

or a centered readable column plus side metadata.

Question and answer MUST preserve a clear hierarchy; do not render them as two equal dense newspaper columns when that harms reading order.

---

## 16. Topic / reading screen

Reading content uses a constrained centered reading column.

Recommended:

```text
max readable width ≈ 720 logical px
```

On Expanded/Large layouts additional horizontal room may contain:

```text
section outline
progress
playback controls
related vocabulary
```

but the article body itself remains constrained.

Long paragraphs SHALL reflow naturally under text scaling.

---

## 17. Audio mini-player

A shared mini-player may be shown while audio is active.

### COMPACT

```text
bottom mini-player above bottom navigation
```

### MEDIUM/EXPANDED

```text
bottom bar or rail-adjacent compact panel
```

Mini-player SHALL NOT obscure:

```text
primary action
bottom navigation
system gesture area
exam answer controls
```

Insets must account for the active mini-player.

---

## 18. Shadowing screen

Shadowing is a focused learning activity.

### COMPACT portrait

```text
segment text
highlight/current sentence
primary playback controls
speed/repeat controls
progress
```

Secondary controls may use expandable sheets/menus.

### COMPACT short/landscape

Use horizontal grouping and scrollable content; reduce decorative content before reducing control accessibility.

### EXPANDED/LARGE

Recommended:

```text
Text/segments pane
| Playback/practice control pane
```

or:

```text
centered text
+ persistent right control panel
```

The current segment must remain visually dominant.

Do not put essential playback actions far apart merely because more width is available.

---

## 19. Assessment / test screen

Test UI prioritizes focus and deterministic interaction.

### COMPACT

```text
progress
question
answers
primary navigation/action
```

Single primary column.

### MEDIUM

Question column remains constrained; progress/navigation may become more spacious.

### EXPANDED/LARGE

Optional secondary pane:

```text
question navigator
answered/unanswered status
skill/category metadata if relevant
```

The answer area remains one coherent reading/interaction region.

Exam mode SHALL NOT place distracting Home/navigation content next to the question.

Focus/Exam mode may hide or minimize global navigation.

---

## 20. Test answer layouts

Answer options SHALL adapt by content type.

Text-heavy options:

```text
one column at all sizes unless usability testing proves otherwise
```

Short binary/compact options MAY use multiple columns on wider windows.

The UI SHALL NOT reorder semantic answer options purely due to grid wrapping in a way that changes intended reading order.

---

## 21. Review screen

### COMPACT

One-card-at-a-time review is preferred for focus.

### EXPANDED

May show:

```text
current review item
| review queue/progress summary
```

Do not show future answer content in a side pane if it compromises the exercise.

---

## 22. Downloads / storage screen

### COMPACT

```text
storage summary
pack list
per-pack state/progress
cleanup actions
```

### EXPANDED

Recommended:

```text
pack list
| selected pack detail + storage breakdown
```

States such as `DOWNLOADING`, `VERIFYING`, `READY`, `FAILED` SHALL remain visually distinguishable without relying only on color.

---

## 23. Settings

### COMPACT

Conventional nested settings routes.

### EXPANDED/LARGE

Use list/detail settings layout where appropriate:

```text
Settings categories | selected category settings
```

Changing:

```text
uiLocale
translationLocale
theme
storage policy
```

must not require application restart unless a platform-specific limitation demands it.

---

## 24. Onboarding

Onboarding uses a centered constrained layout.

Recommended maximum content width:

```text
~560 logical px
```

On large tablets, do not stretch onboarding copy full width.

Illustration/decorative areas may expand, but primary text/actions remain constrained and reachable.

Offline first-launch behavior and registration errors SHALL fit the same layout without overflow.

---

## 25. Text scaling / Dynamic Type

CareerSpeak SHALL respect the platform text scale/accessibility font settings.

Qualification target:

```text
core learning/navigation flows usable at text scale 2.0
```

Rules:

1. Do not disable system text scaling globally.
2. Avoid fixed-height containers around localized or educational text.
3. Buttons may grow vertically.
4. Labels may wrap where semantics allow.
5. Critical action labels SHALL NOT become icon-only solely to avoid overflow.
6. Important English learning text must remain fully readable.
7. Large text may cause a layout to switch to a simpler one-column structure even on a wide device.

Responsive decisions SHOULD consider both width and content pressure.

---

## 26. Touch targets

Interactive controls SHALL provide a practical minimum hit target approximately equivalent to:

```text
48 × 48 logical px
```

Small visual icons may exist inside a larger semantic hit area.

Dense tablet layouts SHALL NOT reduce touch targets below mobile usability requirements.

---

## 27. Safe areas and system UI

All top-level screens SHALL respect:

```text
status bar/notch
navigation gesture area
home indicator
cutouts
fold/hinge information where exposed
software keyboard
```

Do not solve safe areas with arbitrary static padding.

Use platform/window inset information.

---

## 28. Keyboard handling

For search/settings/forms:

```text
focused field remains visible
primary action remains reachable where practical
content can scroll above keyboard
keyboard opening does not permanently lose route/layout state
```

On tablets with hardware keyboard, the UI shall not assume an on-screen keyboard is present.

---

## 29. Landscape

Landscape is not a separate device class.

Rules:

```text
recompute layout from current available width/height
preserve route/state
avoid forcing landscape-specific business logic
```

A phone landscape window may become MEDIUM by width but SHORT by height; layouts must satisfy both constraints.

---

## 30. Split-screen / multitasking

Window size may change while the app is running.

Required behavior:

```text
no restart required
no route reset
no loss of test/audio state
navigation shell adapts in place
lists/grids recompute safely
```

The UI SHALL NOT cache one initial screen width for the lifetime of the app.

---

## 31. Foldables

MVP does not require advanced hinge-aware dual-screen UX, but architecture SHALL avoid blocking it.

Baseline:

```text
use current window metrics
respect display features when available
avoid placing primary control directly across an obstructing hinge
```

Two-pane layouts should be compatible with future hinge-aware pane placement.

---

## 32. Localization pressure

Adaptive qualification SHALL include long localized strings.

Required locales:

```text
en
ru
kk
```

Future-readiness cases:

```text
German-style long labels
Arabic/Urdu RTL
mixed RTL guidance + LTR English learning content
```

Do not size controls based on English string length.

A pseudo-localization test mode SHOULD be added during implementation to reveal truncation and hardcoded width assumptions.

---

## 33. RTL

For RTL `uiLocale`:

```text
navigation direction follows platform semantics
start/end padding mirrors
directional icons mirror where appropriate
English learning text may remain LTR
localized guidance follows RTL
```

Mixed-direction blocks SHALL declare/derive direction at the correct content boundary rather than forcing the entire screen to one text direction.

---

## 34. Visual themes and ambience

Adaptive layout structure SHALL be independent of visual theme.

Themes may change:

```text
background imagery
surface treatment
decorative accents
```

but SHALL NOT alter:

```text
breakpoints
navigation semantics
content order
hit target size
readability constraints
```

Focus/Exam mode reduces decorative imagery.

Background images use appropriate fit/crop behavior and never drive fixed screen dimensions.

---

## 35. Empty/loading/error states

Every major adaptive screen SHALL define:

```text
loading
empty
offline-with-cache
offline-without-cache
recoverable error
fatal/update-required
```

State components SHALL adapt to width without changing their meaning.

For example, an empty state may be centered in wide layouts but must not occupy an excessively wide text line.

---

## 36. Skeleton/loading behavior

Skeletons, where used, should resemble the current width-class layout.

Do not use a phone-shaped one-column skeleton on a three-column tablet screen if it causes a large visual reflow after data appears.

However, Home/local-first screens should prefer immediate local content over unnecessary loading skeletons.

---

## 37. Scroll ownership

Every route SHALL have explicit scroll ownership.

Avoid:

```text
nested unconstrained vertical scroll views
multiple competing primary scrollables
fixed-height lists inside long scrolling pages
```

Use sliver/custom-scroll patterns when screens combine headers, grids and long lists.

Preserve list scroll position across detail navigation where practical.

---

## 38. Adaptive images

Images SHALL:

```text
preserve aspect ratio unless intentional crop is specified
use bounded decode/display sizes
not determine text-column width
avoid layout shift after loading
```

Decorative backgrounds may crop using cover-style fitting.

Educational diagrams/images should use contain-style fitting and allow full viewing.

---

## 39. Performance requirements

Adaptive UI SHALL NOT introduce excessive rebuild cost.

Rules:

```text
window-class state is centralized
large lists use lazy builders/slivers
expensive image/audio widgets are not recreated solely due to unrelated layout state
Riverpod providers separate domain state from local presentation geometry
```

Resize/orientation changes may rebuild layout widgets but SHALL NOT refetch content unnecessarily.

---

## 40. Accessibility semantics

Interactive controls SHALL have meaningful semantics/labels.

Audio actions must expose understandable labels such as:

```text
Play pronunciation
Pause topic audio
Repeat current sentence
```

Do not expose only visual icon names.

Logical reading/focus order must follow semantic content order in both one-pane and split-view layouts.

---

## 41. Color and contrast

Status and correctness SHALL NOT rely on color alone.

Examples:

```text
correct → icon + text + color
failed download → icon + status label + color
current selection → shape/state + color
```

Study ambience backgrounds must have an overlay/surface treatment sufficient to preserve text readability.

---

## 42. Animation and motion

Adaptive layout transitions SHOULD be restrained.

Avoid large animated rearrangements when crossing a breakpoint during rotation/split-screen resizing.

Respect reduced-motion platform preferences where practical.

Learning correctness/status feedback should be clear without requiring animation to understand the result.

---

## 43. Component strategy

Shared adaptive components should live under a presentation/design-system layer, for example:

```text
core/ui/
├── adaptive/
│   ├── adaptive_scaffold.dart
│   ├── adaptive_navigation.dart
│   ├── adaptive_pane.dart
│   ├── adaptive_grid.dart
│   ├── adaptive_window_info.dart
│   └── content_width_constraint.dart
├── components/
└── tokens/
```

Feature code may compose these primitives but SHALL NOT invent incompatible breakpoint systems.

---

## 44. Suggested Flutter contract

Conceptual model:

```dart
enum WindowSizeClass {
  compact,
  medium,
  expanded,
  large,
}

class AdaptiveWindowInfo {
  final WindowSizeClass widthClass;
  final bool isShort;
  final Size size;
}
```

Feature layouts consume `AdaptiveWindowInfo` through the presentation layer.

Do not put `MediaQuery` width checks throughout business/application controllers.

---

## 45. Responsive grid contract

Recommended utility accepts:

```text
available width
minimum item extent
maximum column count
gap
```

It returns a deterministic column count.

Examples, subject to feature-specific minimum extents:

```text
COMPACT   → 1 column
MEDIUM    → 1–2 columns
EXPANDED  → 2–3 columns
LARGE     → 3–4 columns
```

The actual card width remains bounded; cards should not stretch into extremely wide tiles.

---

## 46. Content-width hierarchy

Use three conceptual width constraints:

```text
FOCUSED
≈ 560
forms/onboarding/test interactions

READABLE
≈ 720
articles/answers/explanations

WIDE
≈ 1200
catalog dashboards/grids/split layouts
```

This prevents tablet interfaces from simply stretching phone content across the screen.

---

## 47. Primary action placement

Primary actions remain predictable across layouts.

### Compact

May use bottom-aligned action area when appropriate.

### Wide

Action may move into the focused content pane/header, but must remain visually associated with the task.

Do not place primary actions at an extreme right edge merely because the window is wide.

---

## 48. Adaptive screen matrix

| Screen | Compact | Medium | Expanded/Large |
|---|---|---|---|
| Home | 1 column | 2-column sections | dashboard 2–3 columns |
| Vocabulary | list → detail | list/cards | master/detail |
| Interview | list → detail | list/detail as space allows | master/detail |
| Topics | list → reader | wider list/reader | outline + reader |
| Shadowing | focused single pane | focused/wrapped controls | text + control pane |
| Tests | single focused column | focused column | question + navigator |
| Review | one-card focus | one-card focus | item + queue summary |
| Downloads | stacked list | richer list | list + pack detail |
| Settings | nested routes | nested/rail | category + detail |
| Onboarding | centered | centered | centered constrained |

---

## 49. Acceptance breakpoints

Every major route SHALL be qualified at representative logical sizes, including at least:

```text
360 × 800   compact phone portrait
412 × 915   large phone portrait
800 × 600   medium / landscape-window case
834 × 1194  expanded tablet portrait
1194 × 834  expanded tablet landscape
1366 × 1024 large tablet/window
```

These are test viewports, not device-model checks.

---

## 50. Text-scale qualification matrix

At minimum test:

```text
1.0
1.3
1.6
2.0
```

for:

```text
en
ru
kk
```

High-risk routes:

```text
Home
Vocabulary detail
Interview detail
Shadowing
Test question
Settings
Downloads
```

No clipped critical text or unreachable primary control is acceptable.

---

## 51. RTL qualification matrix

Before Arabic/Urdu release, qualify at least:

```text
Compact portrait
Compact landscape
Expanded portrait
Expanded landscape
text scale 1.0 and 1.6+
```

with mixed-direction English learning text.

---

## 52. Adaptive UI test strategy

Required test layers:

```text
unit tests
→ breakpoint/window-class selection

widget tests
→ navigation mode
→ column counts
→ one-pane/two-pane switching
→ text scaling
→ RTL direction

Golden/snapshot tests where useful
→ representative critical screens by width class

integration tests
→ rotate/resize without state loss
→ active audio preserved
→ test attempt preserved
→ split-screen style width transitions
```

Do not create a golden test for every possible screen permutation; focus on shared layout primitives and high-risk screens.

---

## 53. State-preservation acceptance

The following scenario SHALL pass:

```text
open Interview detail
start answer audio
resize Compact → Expanded
```

Expected:

```text
same question selected
same route identity
audio continues or restores seamlessly according to audio contract
no duplicate API request caused solely by layout change
```

Similarly:

```text
start test
answer question 3
rotate/resize
```

must preserve attempt/question/answers.

---

## 54. Offline/adaptive acceptance

Adaptive layouts SHALL behave identically from an offline/data perspective.

A wide layout MUST NOT make additional network requests merely because it exposes a second pane if the required detail is already locally available.

If detail data is not locally present, the same repository policy applies as on Compact.

Layout is not a data-consistency boundary.

---

## 55. Error/adaptive acceptance

Error presentation adapts but error semantics stay constant.

Example:

```text
STORAGE_FULL
```

Compact:

```text
inline/banner/dialog + Manage Storage action
```

Expanded:

```text
may show persistent contextual error panel
```

Both route to the same storage-management use case.

---

## 56. Anti-patterns

The implementation SHALL avoid:

```text
isTablet = width > ... copied across screens
orientation == landscape as the main layout rule
fixed pixel heights around localized text
full-width 1200px reading paragraphs
phone UI stretched to tablet
separate business controllers for phone/tablet
layout changes that reset Riverpod/domain state
hardcoded left/right instead of start/end
UI text fetched from backend as the primary app localization mechanism
bottom navigation plus navigation rail simultaneously for the same destinations
```

---

## 57. Definition of Ready for implementation

Adaptive UI design is ready when:

```text
[ ] centralized width classes
[ ] shared adaptive layout primitives defined
[ ] top-level navigation behavior defined per class
[ ] screen matrix accepted
[ ] readable/focused/wide width constraints accepted
[ ] text-scale qualification target accepted
[ ] RTL/mixed-direction policy accepted
[ ] safe-area/keyboard behavior accepted
[ ] resize state-preservation rules accepted
[ ] accessibility/touch-target rules accepted
[ ] widget/integration test matrix accepted
```

---

## 58. Final baseline

```text
Available window size
        ↓
AdaptiveWindowInfo
        ↓
AdaptiveScaffold / shared layout primitives
        ↓
feature presentation
        ↓
same Riverpod/domain/application state
```

The key invariant is:

> **CareerSpeak adapts presentation to the window; it does not fork business logic by device type.**
