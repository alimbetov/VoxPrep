# VoxPrep commercial release gates — R1 to R6

**Source of truth:** exact branch SHA, GitHub Actions runs, real PostgreSQL,
HTTP, Flutter SQLite/Drift, native store sandbox evidence and physical devices.
A green mocked test never substitutes for a required real adapter.

| Gate | Goal | Evidence | Blocking condition |
| --- | --- | --- | --- |
| R1 | Content Studio → CURRENT → HTTP → Drift → offline reopen | #51; authenticated editorial workflow; real PostgreSQL; A1 live backend; N → injected error → retry N+1; closed/reopened SQLite typed body and saved progress | CURRENT differs from Flutter revision/body; missing data; failed retry |
| R2 | Store Verification for `voxprep_full_unlock` | Google Play license sandbox and App Store sandbox TestFlight; signed purchase tokens; backend verification; install/reinstall restore; replay; refund/revoke | Entitlement granted from local-only or unverified purchase; paid reinstall cannot restore |
| R3 | One production-quality learning route | Actual author/reviewer-approved content with text, images where appropriate, TTS, localization, questions, tests; editorial and visual QA on real client | Placeholder/incomplete body, broken references, inaccessible media |
| R4 | Android and iOS real device | Fresh install, offline, reinstall, app upgrade, slow network, credential expiry, store restore | Persistent content lost/corrupted; entitlement or progress not restored as designed |
| R5 | Release qualification | One immutable SHA; mandatory CI green, privacy policy/data safety, least-privilege secrets, monitoring, rollback, store compliance | Security/privacy issue or missing release evidence |
| R6 | Launch | Release candidates and signed builds, Google Play Console/App Store Connect listing, staged rollout, production observability | No verified production transaction path or rollback plan |

## Strict sequence

1. R1 code changes live on `feat/r1-current-drift-offline-acceptance`; PR #52 adds exact typed-body assertions to existing A1. Issue #51 stays open until *all* acceptance evidence exists.
2. R2 must include real provider verifications. DEV/TEST mock payments and a generated installation UUID are not substitutes for App Store / Google Play purchase ownership.
3. R3 should first accept one complete FREE/FULL path, not a large unreviewed generated catalogue.
4. R4 requires actual Android and iOS devices; emulator/UI mocks are supplemental.
5. R5/R6 release decision must record package IDs, signing, review status, store compliance, rollback and evidence URLs.

## Evidence table to update, not infer

| Gate | Exact SHA | CI links | External/manual evidence | State |
| --- | --- | --- | --- | --- |
| R1 | pending | PR #52 | #51; browser/editor and full publication contract still pending | IN PROGRESS |
| R2 | — | — | Play/App Store sandbox transactions missing | BLOCKED |
| R3 | — | — | Editorial QA not yet accepted | BLOCKED |
| R4 | — | — | Physical device acceptance not yet accepted | BLOCKED |
| R5 | — | — | Production release review not yet accepted | BLOCKED |
| R6 | — | — | Store rollout not performed | BLOCKED |

Do not mark a gate CLOSED without capturing each required artifact and actual
run identifier. In particular, do not merge #52 or close #51 merely because a
previous A1 version was green.
