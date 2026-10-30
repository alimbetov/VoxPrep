# P1 — Flutter Mock UI Implementation

**Branch:** `feat/p1-flutter-mock-ui`  
**Base:** CareerSpeak architecture v0.10  
**Purpose:** qualify the learner UX and Material 3 component architecture before production adapters.

## Strategy

```text
P1.0 app scaffold / theme / router
P1.1 Home + Learn + content detail
P1.2 mock Tests / Review flows
P1.3 learner marker interactions
P1.4 adaptive phone/tablet/split-screen qualification
P1.5 localization visual qualification
P1.6 accessibility / text scale / dark mode
P1.7 mock UI acceptance
      ↓
production adapter work starts only after acceptance
```

## Mock boundary

Allowed:

```text
in-memory mock content
Riverpod in-memory learner state
mock SnackBar audio/test actions
static locale labels
```

Forbidden in P1 foundation:

```text
real Backend calls
Drift schema implementation
Secure Storage identity
real TTS/audio downloads
manifest synchronization
fake production APIs hidden behind UI widgets
```

## Acceptance targets

- Material Design 3 only;
- same domain state across adaptive layout changes;
- Home/Learn/Detail/Tests/Review/Settings navigable;
- FAVORITE, LISTENED and COMPLETED independent and immediately reflected;
- filters expose Favorites, Not listened and Not completed;
- compact uses NavigationBar;
- medium/expanded/large use NavigationRail;
- system/light/dark theme works;
- no raw transport/storage dependencies in feature presentation;
- `flutter analyze` and `flutter test` green after local platform bootstrap.
