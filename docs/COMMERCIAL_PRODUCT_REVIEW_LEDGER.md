# VoxPrep — Commercial Product Review Ledger

**Status:** REVIEW IN PROGRESS  
**Date:** 2026-11-03  
**Working branch:** `feat/commercial-release`; **PR:** #39  
**Requirements:** [COMMERCIAL_PRODUCT_COMPLETENESS_SPEC.md](COMMERCIAL_PRODUCT_COMPLETENESS_SPEC.md)

Classification: `CONFIRMED GAP` = verified missing UI/route in inspected source; `PARTIAL` = component exists but full product scenario unproven; `REVIEW REQUIRED` = needs implementation/runtime inspection; `DEFERRED` = intentionally postponed. Priority P0 blocks critical authoring or purchase experience, P1 required for planned v1 unless waived; P2 future phase.

| ID | Priority | Classification | Initial evidence / finding | Next qualification |
|---|---|---|---|---|
| GAP-001 / MVC-R7 | P0 | CONFIRMED GAP | `ContentMvcController` has edit/update/next revision but no create-logical-content endpoint; content list lacks New action | Trace `ContentAuthoringService` create contract and add admin creation E2E for 7 types |
| GAP-002 / MVC-R9 | P0 | CONFIRMED GAP | `ContentStudioController` maps `/admin/publication` to placeholder `admin/section` | Wire exact B6/B7 candidate validation and CURRENT publish through secured MVC; E2E |
| GAP-003 / MVC-R5 | P1 | CONFIRMED GAP | `admin/content/form.html` no multipart image upload/preview; backend `ContentAssetBindingService` supports COVER_IMAGE/CONTENT_IMAGE | Actual image -> RustFS READY -> binding -> published Flutter read |
| GAP-004 / MVC-R8 | P1 | CONFIRMED GAP | Content editor has no TTS prepare/status/play controls, though planner/jobs exist | Real Worker/Piper and role policy UI acceptance |
| GAP-005 / MVC-R6 | P1 | PARTIAL | `ContentMvcController.index` has fixed PAGE_SIZE=25 and paginated list, but no q/type/lifecycle/filter/sort parameters | Query API + deterministic paging, >100 mixed rows |
| GAP-006 / MVC-R12 | P1 | PARTIAL | Per-content localization forms exist; `/admin/localization` navigation currently placeholder | Replace navigation, coverage list, test 12 locales |
| GAP-007 / XML-R1 | P2 | DEFERRED | `/admin/imports` placeholder; XML contract specified, not required for current critical-path implementation | Later versioned XSD, XXE-safe dry-run, duplicate policy, batch qualification |
| GAP-008 / MVC-R7 | P1 | CONFIRMED UX GAP | Practice-test editor requires raw question UUIDs; topic/options require pipe-delimited fields | Searchable question picker, structured field usability tests |
| GAP-009 / MVC-R11 | P1 | REVIEW REQUIRED | Analytics admin page and aggregate ingestion not yet audited end to end | Inspect all source paths, prove no personal/user/install identifiers |
| GAP-010 / B8-C | P0 | PARTIAL | Flutter billing and purchase verification providers present; test only proves adapter selection under release mode | Android/iOS real store sandbox purchase/restore/refund and backend entitlement |
| GAP-011 / B8-C | P1 | REVIEW REQUIRED | `release_switch.dart` uses `VOXPREP_RELEASE`, while `app_configuration.dart` selects environment from `kReleaseMode`; may diverge during debug release simulation | Unify contract and negative tests; avoid treating simulation as production build |
| GAP-012 / OPS-01 | P1 | REVIEW REQUIRED | `LearnerMediaController` returns `ResponseEntity<byte[]>`; large media concurrency memory impact unqualified | Streaming, bounds, load and cache qualifications |
| GAP-013 / MVC-R5 | P1 | PARTIAL | One active binding per `(contentRevision,role)` supports a single cover and content image slot; no gallery contract | Document v1 limitation and Flutter display acceptance |
| GAP-014 / MVC-R10 | P0 | REVIEW REQUIRED | No unified admin->publication->Flutter->purchase exact-SHA acceptance evidenced in reviewed files | Scenario acceptance gate and links to CI |
| GAP-015 / OPS-01 | P0 | REVIEW REQUIRED | H1/H2/H3 hardening in progress in same branch; final exact-SHA acceptance must be observed | Run all required checks on exact SHA, fix regressions before release |
| GAP-016 / MVC-R12 | P1 | REVIEW REQUIRED | No proof yet all 12 UI locale resources and RTL/screens are complete | ARB inventory + fallback + screenshot tests |
| GAP-017 / B8-C | P0 | REVIEW REQUIRED | FREE first block, premium gate and store restore behavior not verified from actual mobile navigation in this audit | Exercise all routes and entitlement transitions with real backend |
| GAP-018 / MVC-R11 | P1 | REVIEW REQUIRED | Aggregate counters design accepted in spec; unique-user/DAU claims incompatible with no identifiers | Define event schema, retention, privacy, thresholds and verify ingestion |

## Review priorities

**Review batch A (P0):** GAP-001, GAP-002, GAP-010, GAP-014, GAP-017.  
**Review batch B (P1 core):** GAP-003, GAP-004, GAP-005, GAP-006, GAP-011, GAP-016.  
**Review batch C (P1 support):** GAP-008, GAP-009, GAP-012, GAP-013, GAP-015, GAP-018.  
**Future XML batch:** GAP-007.

## Exit rules

A ledger item is CLOSED only with code change, unit/integration test, negative/edge acceptance where relevant, exact new SHA, and successful required CI. A static code observation alone is not runtime acceptance. The ledger itself does not assert that the listed items are all existing defects; REVIEW REQUIRED items are hypotheses to resolve. Never classify XML as done simply because its future contract is written.

## XML decision

`XML-R1` is **specified now, implementation deferred**. Do not implement an XML parser, XSD, upload endpoint or import pipeline in the current release-critical implementation slice. Review its future scope without blocking the immediate release path.
