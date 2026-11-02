# Learner Product UI v1 Roadmap

Branch: `feat/learner-product-ui-v1`

Goal: bring VoxPrep learner UX and Flutter production qualification to a Google Play / App Store-ready baseline without weakening current domain, publication, access, asset, or installation-auth contracts.

## Delivery model

The branch has two coordinated lanes:

- **Product UX lane (L-series)** — presentation quality and learner journey.
- **Production hardening lane (H-series)** — CI, release safety, schema/test qualification, and GitHub governance.

No stage is considered closed until its exact branch SHA is qualified by canonical Flutter CI.

## Product UX lane

### L0 — Product foundation — IN PROGRESS

- VoxPrep learner-facing branding.
- Material 3 commercial theme baseline.
- Production-safe loading/empty/error copy.
- Remove backend/repository/revision jargon from learner-facing surfaces unless it is genuinely useful to the learner.

### L1 — Home — IMPLEMENTED, awaiting qualification

- Continue Learning is the primary action.
- Learning direction remains visible but secondary.
- Today/progress stats and quick actions have explicit hierarchy.
- Cover remains fail-soft.

### L2 — Catalogue and access discovery — IMPLEMENTED, awaiting qualification

- Vertical → goal → track → collection hierarchy uses learner-friendly cards.
- FULL collections stay discoverable and route through the existing access policy.
- Collection member cards resolve learner-facing content/test metadata where available.
- Exact-revision/access ownership checks remain fail-closed.

### L3 — Content experience — NEXT after hardening baseline

- Dedicated layouts for `vocabulary`, `interview`, `topic`, `phrase`, `shadowing`.
- Cover hero hierarchy.
- Audio controls expressed as learner actions, not pipeline diagnostics.
- Favorite/completed/review actions consolidated into a clear action model.

### L4 — Practice tests and review — NEXT

- Practice test cards and session hierarchy.
- One-item-at-a-time review session UX.
- Preserve deterministic scoring and review scheduling semantics.

### L5 — Monetization and onboarding — PARTIAL

- Commercial paywall wording and visual hierarchy.
- Explicit one-time purchase / no subscription positioning.
- Onboarding and settings copy cleanup.
- No real backend purchase verification is added in this branch.

### L6 — Store presentation acceptance — FINAL UX GATE

- Compact phone, large phone, tablet, desktop/web adaptive checks.
- Text scaling and RTL boundary checks.
- No raw exceptions visible to learners.
- No broken cover placeholders.
- Golden/widget acceptance for the primary funnel:
  `Onboarding → Home → Catalogue → Collection → Content → Unlock`.

## Production hardening lane

### H1 — Canonical main Flutter CI — IMPLEMENTED

One workflow is the source of truth for PRs and pushes to `main`:

`format → generated Drift check → analyze → targeted hardening tests → full flutter test`.

### H2 — Main branch protection/ruleset — PENDING GOVERNANCE

Target rules:

- require `flutter-main` before merge;
- require pull requests for `main`;
- block direct push and force push;
- keep merge blocked while required checks are red.

This is repository governance, not application code.

### H3 — Release-mode mocks fail closed — IMPLEMENTED, awaiting qualification

- DEV/TEST may use mock billing and mock purchase verification.
- RELEASE defaults to real adapters.
- RELEASE explicitly compiled with mock flags fails closed and cannot manufacture FULL access.

### H4 — Drift v18 qualification — IMPLEMENTED, targeted GREEN

- Production schema stays v18.
- No v19 tables or migrations.
- Database assertions and generated-schema reproducibility match v18.
- Historical migration fixtures validate migration into v18, including raw auxiliary structures.
- Final closure still requires the exact-SHA canonical full-suite gate.

### H5 — API composition tests — IMPLEMENTED, awaiting qualification

Current production composition is authoritative:

- `rawApiClientProvider → HttpApiClient`
- `apiClientProvider → InstallationAuthRecoveryApiClient`

Tests follow production composition; production is not rolled back for stale assertions.

### H6 — Riverpod timeout tests — IMPLEMENTED, targeted GREEN

Test subscription/container lifecycle is qualified without introducing new Riverpod abstractions or weakening production provider semantics.

### H7 — Publication identity fixtures — IMPLEMENTED, strict targeted GREEN

Publication fixtures satisfy current immutable identity invariants. `PUBLICATION_SNAPSHOT_IDENTITY_CONFLICT` remains fail-closed, and V12 adversarial qualification is a blocking gate rather than a diagnostic-only check.

### H8 — Adaptive UI tests — IMPLEMENTED, targeted GREEN

Tests follow the current Material 3 adaptive shell and realistic viewports while preserving the production `NavigationBar` / `NavigationRail` design and text-scale boundaries.

### H9 — Audio E2E lifecycle — IMPLEMENTED, targeted GREEN

The redownload path and adversarial audio scenarios use deterministic bounded waits. Real filesystem operations, including temporary-directory creation, execute in `WidgetTester.runAsync`, and widget teardown ownership is explicit. Production audio behavior was not weakened to satisfy the test harness.

### H10 — Full suite GREEN — IN PROGRESS

Current blocker is isolated to `test/acceptance/p2_10_7_production_e2e_test.dart`: canonical manifest fixture checksums are stale and the renderer-snapshot case must override the production asset root so `path_provider` is not awaited through a plugin-less widget-test host. The repair is guarded by an isolated P2.10.7 qualification before commit.

Target:

- `flutter analyze` ✅
- `flutter test` ✅
- no timeout
- no hidden asynchronous exceptions

### H11 — exact-SHA qualification and main requalification — REQUIRED

Before merge, one exact feature SHA must have all canonical checks green. After merge, canonical CI must be green again on the exact merge SHA in `main`.

## Execution order

1. Normalize branch formatting so H1 can inspect deeper stages.
2. Qualify H3/H4/H5 through canonical CI.
3. Repair H6 → H9 from actual CI evidence.
4. Reach H10 full-suite green.
5. Continue L3 → L6 on that stable baseline.
6. Configure H2 repository rules with `flutter-main` as the required check.
7. Freeze one exact SHA and complete H11.
8. Merge only that qualified SHA and re-run canonical CI on `main`.

## Non-goals

- No backend purchase-verification implementation.
- No schema v19.
- No weakening publication/access/security invariants.
- No replacement of Riverpod/GoRouter/adaptive shell purely for UI preference.
- No direct object-storage URLs in Flutter.
