# VoxPrep — Admin ↔ Flutter User Story Acceptance Register

Feature branch: `feat/user-stories-acceptance-hardening`.
Primary PR: #50. This document distinguishes **implementation**,
**automated qualification** and **real browser/mobile acceptance**.

## Blocking acceptance (ordered)

| ID | User Story | Exact acceptance invariant | Current evidence / state |
|---|---|---|---|
| US-P0-01 | As developer, I want merge-safe CI | One exact HEAD with B1, Flutter Main, A1, Mock UI, Worker, RustFS, Renderer and generator checks all successful | Fixed lifecycle transition tests and generated Dart formatter; final SHA CI pending |
| US-P0-02 | As developer, I want repeatable PostgreSQL seed | Explicit DEV flag creates real revision 1 drafts via ContentAuthoringService; rerun never overwrites author edits; not available in prod | `DemoCatalogueSeedRunner`, tests; integration DB/Content Studio acceptance pending |
| US-P1-01 | As author, I want one catalogue source | Same codes, types, revisions, access levels and membership in generated fixture, Backend published CURRENT and Flutter Drift after sync | NOT ACCEPTED: generated backend JSON and Flutter mock catalogue are not the publication source of truth |
| US-P1-02 | As admin, I want working Localization navigation | Admin Localization entry opens real revisions and editing forms, not placeholder | Redirect to `/admin/content` committed; reviewer still navigates via per-revision localization |
| US-P1-03 | As admin, I want typed XML/JSON import | Preview validates schema and typed bodies, import is transactional/idempotent, documents remain DRAFT, bad payload rolls back | Implemented in `/admin/imports` with same-session file SHA-256 preview and test coverage; exact-SHA CI and manual browser acceptance pending |
| US-P1-04 | As developer, I want Chrome demo without infrastructure | `flutter run -d chrome` with explicit demo flag opens working Home/Learn/Tests/Settings without creating Drift/HTTP clients | NOT ACCEPTED: production bootstrap still composes SQLite/HTTP; test-only mock adapters do not solve Web |
| US-P1-05 | As admin, I want browser end-to-end acceptance | Browser create → image → translation → TTS → review → approve → publish CURRENT → real Flutter HTTP → Drift → offline | NOT ACCEPTED: partial A1 automatic tests exist; full real browser path unverified |

## Runtime profiles

- DEV/TEST may use simulator fixtures and generated demo content.
- `prod` without real Store credentials must set
  `VOXPREP_BILLING_MODE=disabled`; never `simulated`.
- Real staging sandbox requires Google Play / App Store credentials and native
  device acceptance; never infer it from mock tests.
- All backend imports/seeders must use application services and must not
  update immutable approved/published revisions directly.

## How to seed local PostgreSQL safely

1. `python tools/generate_demo_catalogue.py` from repository root (Python 3.12+).
2. Initialize DEV secrets and start PostgreSQL / RustFS.
3. Start Backend with Spring `dev` profile and
   `VOXPREP_DEV_DEMO_SEED_ENABLED=true`.
4. Open `/admin/content` and inspect 32 generated **DRAFT** content revisions.
5. Restart with the flag and confirm no duplicates or overwritten edits.

This operation does **not** publish catalogue hierarchy, media, TTS or
entitlements, and does not bypass review. Document and qualify each later
transition separately.

## Definition of DONE

A User Story is **Accepted** only when its actual production adapter executes
with the corresponding DB/storage/system dependencies and the exact SHA
checks are green. A method name, static mock fixture, unconnected screen, or
synthetic test alone cannot justify DONE.

## Typed Content Studio Import

The previous `/admin/imports` landing placeholder has been replaced by a
real JSON/XML validator and Draft creator. See
[`ADMIN_CONTENT_IMPORT_V1.md`](ADMIN_CONTENT_IMPORT_V1.md) for schema,
constraints and user workflow. This is not interchangeable with the DEV
seed generator and does not perform publication on behalf of an admin.
