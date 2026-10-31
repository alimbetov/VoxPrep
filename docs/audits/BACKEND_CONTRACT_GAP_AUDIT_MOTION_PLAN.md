# Backend Contract Gap Audit — Motion & Interaction Findings

## Context

This document records UI motion/animation findings discovered while reviewing the Flutter learner application and adds a remediation roadmap. The findings are tracked in `feat/backend-contract-gap-audit` because they affect the product-quality boundary between backend-delivered state and learner-visible rendering, even though the motion implementation itself belongs to the Flutter UI layer rather than backend/domain/data layers.

## Scope boundary

Motion must remain a presentation concern:

```text
Backend / HTTP
      ↓
Sync / Drift
      ↓
Riverpod state
      ↓
──────────────────────────
Presentation motion boundary
──────────────────────────
      ↓
Flutter render transitions
```

No animation primitive may leak into backend contracts, domain models, application services, sync orchestration, persistence, or asset correctness semantics.

## Findings

### MOTION-GAP-001 — No centralized motion contract

Current UI code has no shared duration, curve, or reduced-motion policy. Introducing animation ad hoc would produce inconsistent timing and duplicated constants across screens.

Required remediation:
- add a shared `core/motion` layer;
- define duration tokens;
- define curve tokens;
- centralize reduced-motion behavior;
- prevent feature code from hard-coding arbitrary durations when a shared token exists.

Recommended baseline:

```text
instant      0 ms
fast       120 ms
standard   180 ms
navigation 220 ms
emphasized 300 ms
```

Recommended curves:

```text
standard   easeOutCubic
exit       easeInCubic
emphasized easeInOutCubic
```

Avoid bounce, elastic, and overshoot motion for the primary learner experience.

---

### MOTION-GAP-002 — Route transitions are not explicitly owned

Top-level routes currently rely on regular GoRouter builders, so the app has no product-level navigation motion semantics.

Required remediation:
- introduce a reusable `CustomTransitionPage` helper;
- keep top-level sibling navigation subtle;
- distinguish sibling navigation from hierarchical detail navigation.

Recommended semantics:

```text
Home / Learn / Tests / Review / Settings
→ fade + small vertical translation
→ 180–220 ms

Learn → Content detail
Tests → Test session
→ fade + small forward slide
→ 220 ms
```

Do not use large full-screen lateral slides for top-level destinations.

---

### MOTION-GAP-003 — Adaptive scaffold swaps destination content instantly

`CareerSpeakAdaptiveScaffold` preserves NavigationBar/NavigationRail chrome, but route child content changes without a product-defined transition.

Required remediation:
- keep the shell stable;
- animate only route child replacement;
- verify behavior on compact, medium, and large layouts;
- ensure NavigationBar/NavigationRail selected-state animation is not duplicated by a second competing animation.

---

### MOTION-GAP-004 — Learn detail-pane replacement is abrupt

On wide layouts, selecting an item replaces `ContentDetailPanel` immediately.

Required remediation:
- wrap detail replacement in `AnimatedSwitcher` or an equivalent shared motion primitive;
- key detail content by stable content identity;
- use fade + small translation;
- keep duration around the standard/navigation token.

This is a high-value, low-risk improvement.

---

### MOTION-GAP-005 — ContentCard selected state changes instantly

`ContentCard` changes its selected surface color immediately.

Required remediation:
- animate selected/unselected visual state via `AnimatedContainer` or equivalent;
- avoid scale changes that cause list-layout movement;
- optionally interpolate elevation conservatively.

Recommended duration: `standard`.

---

### MOTION-GAP-006 — Favorite state lacks feedback motion

Favorite icon state changes from outlined to filled immediately.

Required remediation:
- use `AnimatedSwitcher` for the icon;
- use a subtle scale/fade transition;
- do not block persistence or optimistic state semantics on animation completion.

Recommended duration: `fast`.

---

### MOTION-GAP-007 — Learner marker changes are visually abrupt

Learner states such as FAVORITE, LISTENED, and COMPLETED are represented by marker chips but appear/disappear without transition.

Required remediation:
- use `AnimatedSize` / `AnimatedSwitcher` for marker insertion/removal;
- preserve semantic labels and accessibility tree correctness;
- motion must reflect already-committed learner state, never replace state confirmation.

---

### MOTION-GAP-008 — Home learner statistics and progress jump between values

Home statistics (`Completed`, `Listened`, `Favorites`, `Due`) and progress bars update immediately.

Required remediation:
- animate numeric/stat value replacement with `AnimatedSwitcher` or equivalent;
- interpolate progress changes with a bounded tween;
- avoid decorative looping animation.

Recommended durations:
- statistic change: `standard`;
- progress interpolation: `navigation` or ~240 ms.

---

### MOTION-GAP-009 — Audio player state machine has no transition policy

The audio UI exposes meaningful phases (`idle`, `resolving`, `playing`, `paused`, `completed`, `failure`), but controls switch abruptly.

Required remediation:
- animate `Preparing → Play/Pause` and `Play ↔ Pause ↔ Replay` using `AnimatedSwitcher`;
- keep progress driven by real playback state;
- no decorative waveform/spectrum/pulsing loop in the first motion iteration.

Motion must never affect playback state, persisted resume position, LISTENED semantics, or failure delivery.

---

### MOTION-GAP-010 — Practice-test state transitions are abrupt

The test flow currently switches immediately between intro, question session, next/previous question, and result.

Required remediation:
- animate `Intro → Questions → Result` with a bounded switch transition;
- use directional small-offset transition for question navigation;
- Next and Previous must use opposite visual direction;
- keep translation small (roughly 20–24 logical pixels), not full-screen.

Result presentation may use the `emphasized` token.

---

### MOTION-GAP-011 — No reduced-motion contract

Custom motion must respect platform accessibility preferences.

Required remediation:
- centralize `MediaQuery.disableAnimations` handling;
- map all non-essential durations to zero when reduced motion is requested;
- keep state changes immediate and correct when animation is disabled;
- add acceptance tests for reduced-motion mode.

This is a prerequisite for production motion rollout, not a follow-up nice-to-have.

---

### MOTION-GAP-012 — Motion must not alter production/recovery semantics

The application now has production sync, local CURRENT projection, offline/restart recovery, and real audio. Motion must not become coupled to correctness behavior.

Hard rule: do not animate or delay correctness for:
- installation bootstrap;
- backend registration;
- sync planning/execution;
- CURRENT snapshot switching;
- Drift persistence;
- offline recovery;
- download verification;
- corrupt asset repair;
- error propagation.

Animation may only render the resulting state.

---

### MOTION-GAP-013 — Avoid unnecessary third-party animation dependencies

The current app can implement the proposed first motion system with Flutter built-ins.

Do not add Rive/Lottie/animation packages unless a later product requirement demonstrates a concrete benefit not reasonably achievable with native Flutter primitives.

Preferred primitives:

```text
AnimatedSwitcher
AnimatedContainer
AnimatedSize
AnimatedOpacity
AnimatedScale
TweenAnimationBuilder
FadeTransition
SlideTransition
CustomTransitionPage
Hero (later, only with a valid shared visual element)
```

---

### MOTION-GAP-014 — Hero transitions are premature

Current content cards and detail screens do not yet expose a strong shared visual element that justifies a Hero transition.

Remediation decision:
- do not add Hero in the first motion slice;
- revisit only after card/detail visual composition is intentionally aligned.

---

### MOTION-GAP-015 — Settings should remain restrained

Material controls in Settings already provide built-in state feedback.

Required policy:
- do not add redundant animation around ChoiceChip, SwitchListTile, or DropdownMenu state;
- do not animate the whole page during RTL/text-scale preview changes;
- accessibility preview must remain direct and deterministic.

## Proposed implementation roadmap

Motion work should start only after the production foundation is accepted and merged. Do not mix it into P2 adapter/recovery qualification.

Recommended branch:

```text
feat/p3-motion-system
```

Use one feature branch for the whole stream unless a real isolation need appears.

### P3.0 — Motion contract

Deliverables:
- `core/motion` package/folder;
- shared duration tokens;
- shared curves;
- reduced-motion policy;
- reusable transition builders;
- motion architecture tests/policy tests.

Acceptance:
- feature code can consume motion without importing backend/data/application layers;
- reduced motion maps non-essential transitions to instant behavior;
- no third-party animation dependency introduced.

### P3.1 — Navigation motion

Deliverables:
- explicit page transitions in GoRouter;
- sibling navigation transition for top-level destinations;
- hierarchical transition for content detail and test session;
- stable adaptive shell during route changes.

Acceptance:
- compact/medium/large behavior consistent;
- no duplicated transition from shell + route;
- navigation remains deterministic with reduced motion.

### P3.2 — Shared component motion

Deliverables:
- ContentCard selected-state transition;
- favorite icon transition;
- marker chip insert/remove transition.

Acceptance:
- no list-layout jumping caused by scale transforms;
- learner state persistence remains independent of animation;
- widget tests cover favorite/selected/marker states.

### P3.3 — Learn + content detail motion

Deliverables:
- detail-pane AnimatedSwitcher keyed by stable content identity;
- completion/favorite state feedback;
- audio-control phase transitions.

Acceptance:
- selection change does not lose state;
- audio controller semantics unchanged;
- reduced-motion path renders immediately.

### P3.4 — Home motion

Deliverables:
- animated learner-stat value changes;
- animated progress interpolation;
- bounded transition for continue-learning changes if needed.

Acceptance:
- no looping decorative animation;
- values always reflect the real state source;
- updates remain deterministic in tests.

### P3.5 — Tests + review motion

Deliverables:
- Intro → Questions → Result transition;
- directional question navigation;
- restrained result emphasis;
- no redundant animation on existing ExpansionTile review behavior.

Acceptance:
- Next/Previous directionality correct;
- fast repeated navigation cannot corrupt session state;
- result rendering remains deterministic.

### P3.6 — Motion qualification

Qualification matrix:

```text
compact / medium / large
light / dark
normal motion / reduced motion
text scale 1.0 / large preview
LTR / RTL structural preview
rapid repeated taps
back navigation
offline content state
real audio states
renderer/golden screenshot evidence
```

Required gates:
- `dart format`;
- `flutter analyze`;
- full `flutter test`;
- motion-specific widget tests;
- no regression in production E2E/recovery suite;
- screenshot qualification for representative screens.

## Recommended priority

| Area | UX value | Risk | Priority |
|---|---:|---:|---:|
| Learn detail switch | Very high | Low | P0 |
| Route/navigation motion | Very high | Low | P0 |
| Favorite + marker feedback | High | Low | P0 |
| Audio state transitions | High | Low | P0 |
| Test question transitions | High | Medium | P1 |
| Home statistics/progress | Medium | Low | P1 |
| Hero transitions | Medium | Medium | P2 / later |
| Decorative continuous loops | Low | High | Do not implement |
| Rive/Lottie | Low for current scope | Medium | Do not implement yet |

## Definition of Done

The motion stream is complete only when:

```text
state correctness remains owned by existing production layers
        ↓
motion is presentation-only
        ↓
all durations/curves use shared policy
        ↓
reduced-motion is supported
        ↓
all adaptive layouts are qualified
        ↓
full existing production/recovery tests remain green
        ↓
representative renderer evidence is produced
        ↓
exact-SHA CI is green
```

No stage should be declared accepted without an exact HEAD SHA whose full CI is green.
