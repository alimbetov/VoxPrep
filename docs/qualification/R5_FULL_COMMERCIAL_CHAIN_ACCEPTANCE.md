# R5 — Full Commercial Chain Qualification

Status: SECOND-PASS REVIEW v1.2 / SPECIFICATION ONLY / IMPLEMENTATION NOT ACCEPTED
Baseline: `main` at `e68a9dcb3e736111ffee422fe8b1b425918fa4ae`
Dependencies: R1 release defect remediation, R2 Content Studio + image Media Library completion. Real store acceptance is an R5 sub-gate (not a prerequisite or circular dependency).

## Objective

Prove one coherent production-code path, not a sequence of unrelated mocked unit tests:

```text
ADMIN creates content using authenticated MVC HTTP; uploads/selects READY image from Media Library by assetId
→ DRAFT validation / review / approval
→ immutable Backend publication (root N)
→ authenticated Flutter installation + HTTP sync
→ Drift CURRENT(root N), checked media, learner reading/audio/assessment/progress
→ FREE paywall / one-time purchase / server verified FULL entitlement
→ restore same purchase in a separate clean installation via store-owned proof (separate branch of the test, not a reset of the primary learner device)
→ return to the original learner installation and publish immutable root N+1
→ Flutter atomic upgrade, retained learner state + old READY during transition
→ process kill/reopen, network disabled, verified offline material/audio/test/review under explicit offline entitlement policy
```

**Critical rule:** Do not report `R5 ACCEPTED` from mocked stores or from the existing A1 test alone. Store verification in CI can use a deterministic simulator only for contract/logic qualification; real store acceptance is separate and mandatory.

## Reuse existing production components

- Spring Boot modular monolith, PostgreSQL/Liquibase, private RustFS.
- `FileAssetEntity`, `ContentAssetBindingService`, `ContentAssetRole` and immutable publication.
- `A1RealBackendFlutterAcceptanceTest` and `a1_real_backend_flutter_test.dart` as the live HTTP/Drift/asset baseline.
- `PurchaseVerificationController`, `LifetimePurchaseService`, `PurchaseLedger`, official Google/Apple verifiers, signed Apple notifications and voided-purchase reconciliation.
- Installation token/secure storage, local learner state, revisions, assessment and verified offline assets.

Do not introduce a new storage service, second entitlement source, learner account or Flutter mock runtime switch.

## Test matrix: R5-01–R5-18

| ID | Step / positive acceptance | Required observable evidence |
| --- | --- | --- |
| R5-01 | ADMIN logs in, creates catalogue + draft with real HTTP MVC + CSRF, selects READY image via picker | Real form submissions, actor audit, DB draft, exact `revisionId + role + assetId`; no direct fixture insertion for authoring proof |
| R5-02 | Upload identical image twice (including concurrent requests), bind to distinct draft revisions | unique physical blob within defined dedup scope; stable returned assetId where compatible; two bindings; DB+RustFS integrity and reference-safe deletion |
| R5-03 | Review/approve, publish root N | commit and immutable root, exact revision/asset references and checksums, ACTIVE + PUBLISHED only |
| R5-04 | Real Flutter installation registers and syncs using HTTP | real Postgres + RustFS + Spring Boot + production Flutter codecs + persistent Drift CURRENT=N |
| R5-05 | FREE learner reads/listens/tests; paid content denied | FREE media size and SHA verified, local markers/attempts persisted, FULL HTTP responds 403 with expected machine code |
| R5-06 | Purchase transitions entitlement FREE→FULL | backend verifies store proof, durable ledger grants once, premium API becomes accessible; no grant on client boolean |
| R5-07 | Reinstall/new installation restores non-consumable independent of prior app token | fresh installation, store-origin proof independently reverified, ledger claim established; UUID-only claim blocked; local progress NOT restored |
| R5-08 | Refund/revoke and replay safety | authorized store event downgrades premium, stale/duplicate/reordered events do not restore revoked access |
| R5-09 | ADMIN modifies published content by new draft and publishes root N+1 | prior root/content immutable, no in-place mutation; all references/checksums valid |
| R5-10 | Flutter synchronizes N→N+1 | atomic CURRENT switch; progress/markers/attempts retained by explicit identity rules |
| R5-11 | Network interruption, crash, corrupt candidate or unsupported schema during staged upgrade | CURRENT=N and old READY preserved across process restart; journal replay safe; no mixed graph, locale, manifest or asset refs |
| R5-12 | Kill app, disable network, reopen and complete an offline learning operation | only verified downloaded image/audio, locally available tests and content accessible; review, attempts and history intact; offline premium access follows written policy | 
| R5-13 | Simulate crash at FileAsset REGISTERED/write/verify/READY boundaries | durable recoverable state or safely detected orphan; bounded recovery, no broken READY, no silent object deletion | 
| R5-14 | Installation token lost/rejected/revoked while local learner state exists | no UUID-only rotation or account takeover; preserve local data; explicit user recovery UX and separate store restore action | 
| R5-15 | Exhaustive purchase ledger transition/reordering/concurrency matrix | GRANTED/PENDING/REVOKED/REFUND_REVERSED consistent; older verify cannot defeat revoke tombstone; atomic concurrent same purchase claims | 
| R5-16 | R5 end-to-end observable reproducibility | per-stage correlated IDs, N/N+1, redacted ledger evidence, exact git SHA, application build and environment; independent assertion of each stage |
| R5-17 | Primary device A retains learner state while clean device B restores purchase | A progresses N→N+1→offline without reinstall; B restores entitlement by fresh store verification, starts with no inherited Drift progress/token |
| R5-18 | Real UI and store/device source-of-truth smoke checks | admin session and picker, Flutter tap flow, native store purchase/restore, app restart; evidence classified as CI vs device vs live store |

## Architecture review findings and design decisions (2026-11-04)

### AR-01 — The existing A1 starts below the Content Studio boundary (P0)

The existing `A1RealBackendFlutterAcceptanceTest` seeds `FileAssetIngestService`, `ContentAssetBindingService`, JPA repositories and publisher directly inside a test transaction. This is a valid backend-to-Flutter integration test, but **not** evidence that authenticated admin UI can create, validate, select media, approve and publish a draft. R5 must exercise authenticated MVC HTTP requests, CSRF, real session, validation, role access and state transitions before invoking publication. Internal DB inspection is allowed only as an assertion, not as a shortcut for creating the object under test.

### AR-02 — Reinstall restore is not installation 401 recovery (P0)

`InstallationRegistrationService` requires proof of the *current* bearer token to rotate an existing installation. Never bypass this with a known UUID. Reinstall/new installation has a newly registered identity and verifies store-owned original transaction/purchase token to recover **entitlement only**. A rejected or lost token for an existing installation cannot be transparently renewed with rejected proof: present explicit bounded recovery UX, preserve Drift progress, and do not make a second anonymous installation under the original UUID. Define backup/migration separately; restore does not imply learner history portability.

### AR-03 — Offline premium policy is a release decision (P0)

Proposed v1 policy, **not yet adopted**: server controls fresh entitlement; device may use previously authorized and downloaded FULL assets offline for a bounded configurable freshness period. The currently inspected `GET /api/v1/purchases/entitlement` returns unsigned JSON with `verified`, `accessLevel`, `verifiedAt` and `Cache-Control: no-store`; **there is no signed offline entitlement certificate in the verified API contract**. Any offline claim must be bound to a validated installation and securely persisted local decision, or introduce an explicitly versioned backend-signed proof verified by Flutter. Neither variant is accepted until implemented and tested. No server call is required for already verified FREE content. Once freshness expires while offline, the product must show a clear revalidation-required state and must not grant new premium downloads; do not erase local files/progress. On reconnection force authoritative entitlement refresh before premium network requests; revoke/refund removes premium access even if bytes remain cached. Client-side clock rollback must not extend freshness; use monotonic/last-server-time rules and qualify process restart. Set a versioned policy before coding: offline premium TTL, grace (if any), initial acquisition, clock rollback/reinstall behavior, cached premium payload visibility after revoke, and UX after expiry. Example 30 days is a candidate only, not an agreed product requirement. Until these are decided and tested, offline-premium sub-gate is BLOCKED. Do not claim instantaneous refund enforcement for a disconnected device.

### AR-04 — Media dedup must respect existing asset kinds (P1)

`FileAssetEntity` currently has unique `(bucket, object_key)` but no content-hash unique constraint, and `ContentAssetBindingService.bind` checks exact `FileAssetKind` against `COVER_IMAGE` / `CONTENT_IMAGE`. R5 must NOT assume that identical bytes across differing kinds can share the same `FileAsset` ID. Implement either dedup within compatible kind+mediaType+sha256+size, or design an independently versioned physical blob identity with separate logical roles. Prefer the smaller compatible-kind solution for v1; use DB-level concurrency arbitration, deterministic re-read and explicit behavior for non-READY matches. Revalidate actual image signatures/dimensions; do not trust MIME label or filename; do not dedup audio against images. No automatic deletion of referenced or unknown RustFS objects.

### AR-05 — FileAsset ingest crash consistency (P1)

`FileAssetIngestService.ingest` writes REGISTERED via `saveAndFlush`, then performs RustFS I/O; `saveAndFlush` alone does **not** commit an enclosing transaction. R5 must test caller-owned transaction rollback, interruption after object write, storage timeout, checksum mismatch, failed verification and repeated recovery. Specify transaction boundaries before claiming durable REGISTERED; assess the current H2 reconciler instead of adding a duplicate cleanup service. Ensure object keys remain immutable, non-user-controlled and scoped.

### AR-06 — Ledger state-machine needs temporal proof (P0)

`PurchaseLedger.record` currently upserts GRANTED/PENDING/REVOKED using a `REVOKED` guard; `applyStoreEvent` uses provider event time for monotonic ordering, and `updateState` directly changes state. Tests must prove the combined paths cannot resurrect a refunded purchase through stale `verify`, delayed notifications, concurrent restore, scheduler reconciliation or clock skew. The system must distinguish explicit verified refund reversal from replaying an older GRANTED assertion. A purchase may be legitimately claimable by another installation after independent store verification; never grant via an unverified UUID or local client flag. Document whether installs are bounded and detect cross-account purchase abuse without retaining raw transaction tokens.

### AR-07 — Exact-root and learner identity semantics (P0)

Prove publication candidate validation + atomic activation for both N and N+1; retain immutable exact revisions, content/localization/assets and assessment membership. Assert that progress and attempt history keying follows explicit stable business identity + exact revision where applicable; no silent migration of incompatible assessment questions. Verify old READY persists while N+1 downloads, and local candidate staging recovery is deterministic. Direct FULL media and assessment endpoints must enforce the same entitlement as the catalogue.

### AR-08 — One uninterrupted learner journey plus a separate reinstall branch (P0)

Do not test reinstall in the middle of the *same* Drift history continuity proof: a clean reinstall destroys local progress by design. Use **primary installation A** for publication N, learner progress, purchase, update N→N+1 and offline replay. After purchase, use independent **clean installation B** for provider-backed restore; ensure B cannot inherit A's bearer or local SQLite by fixture leakage. Verify both entitlements refer to the same authenticated store identity while progress in B remains new/empty. For offline entitlements on A, assert the active installation-specific durable access policy explicitly.

### AR-09 — Purchase state and provider binding must be source-authoritative (P0)

`PurchaseVerificationController` accepts a client-reported `provider`, `productId`, `purchaseEventId` and `verificationData`. The service validates provider/product and verifies the supplied store proof, but **the client event ID is not a store authenticity proof**. Acceptance must prove the returned provider, product, environment, verified transaction identity and store application identity match configured expectations. Verify production cannot accept sandbox/test purchases, product token from another app, provider spoofing or unverified notification. Test restore to installation B only after fresh verification against the corresponding store, and ensure no orphaned claims when provider verification fails.

### AR-10 — Real user interaction vs internal integration tests (P1)

A backend HTTP/Flutter repository test is not equivalent to a UI journey. Require both: a deterministic API/domain integration suite with real Postgres/RustFS, and a device-level UI smoke path covering Content Studio form/picker/publish and Flutter onboarding/catalogue/open item/audio/practice-test/paywall/purchase/restore/update/offline. Mocked/store simulators are permitted only in isolated CI. Classify evidence by layer (MVC HTTP, Flutter widget, backend-to-Flutter live HTTP, actual device/store); no layer substitutes for another.

### AR-11 — Release pipeline and provenance (P1)

The current A1 GitHub workflow is triggered on PR, manual dispatch, and a specific feature-branch push, not every `main` push. A green feature-branch SHA does **not** prove merged `main`. R5 workflow must run on PR and relevant `main` pushes, or a mandatory manually dispatched immutable release SHA; never publish from an unqualified merge commit. Record migrations, environment config fingerprints, Android package/iOS bundle ID, release signing, deployed backend image digest and Flutter build SHA. CI secrets and store test identities must never be embedded in artifacts.

### AR-12 — Media Library and editor boundary are preconditions, not proven features (P1)

At reviewed baseline, the Content Studio main controller still has placeholder `/admin/imports` and `/admin/publication` pages; existing backend services do not prove the complete admin UI. R5.1 must implement or explicitly link production routes for authenticated media search/preview/upload/select, image provenance/license, file asset reference-safety, and publication. Prove that read-only search/preview never modifies domain state; `bind` only to mutable drafts with a matching `FileAssetKind`. Define acceptable dedup scope per image kind before adding DB constraints. R5-01/02 are BLOCKED until real endpoints and UI exist.

### AR-13 — Test fixture realism and no false release closure (P1)

A1's image is a synthetic 1×1 PNG and publication is service-seeded. R5 must include a representative nontrivial image with image dimensions/byte integrity, actual content text/localization, usable assessment questions and audio asset from the real TTS pipeline or a separately attributed pre-reviewed real asset. Verify media dimensions, codec decode, cache quota, resumed downloads and actual audio playback; do not pretend a 1×1 image or mocked player proves user experience. Each optional capability explicitly outside the v1 MVP remains excluded rather than quietly expanding scope.

## Adversarial gates (non-negotiable)

- Concurrent upload of identical bytes; hash collision handling (size+digest and safe duplicate handling).
- Same file attached to many drafts; prevent deleting a referenced file. A new image byte revision gets a new file identity.
- Unsupported MIME, oversized image, invalid pixel header and missing/corrupt RustFS bytes fail closed.
- Unpublished draft never appears in Flutter.
- Unauthorized media and premium assessment content cannot be retrieved through direct asset endpoints.
- Mixed-root, checksum mismatch, unsupported schema, interrupted transfer, tombstone and asset revoke leave a consistent last-known-good local state.
- Installation 401 must not permit UUID-only token takeover; genuinely lost proof requires a specified secure recovery UX.
- Purchase replay across installations, cross-provider mismatch, refunded transactions, pending transactions and provider outage never fabricate FULL.
- Store restore does **not** restore device-local learner progress: no cloud user profile exists. Verify entitlement recovery separately from learner-data backup/migration.
- Local offline availability and server-side revocation have an unavoidable disconnected-device boundary: verify that a device revalidates revoked entitlement upon reconnection; document the offline paid-cache policy.

## Non-functional and operational acceptance

- Performance budgets must be **measured and recorded**, not invented: define tested device tiers, content catalogue size, first sync, delta sync, offline reopen, image thumbnail latency, peak backend heap and network byte totals. R5 is blocked if target budgets are not agreed and reported.
- Security: ADMIN login/session/CSRF, XML parsing XXE, image decompression bombs/polyglots, bounded uploads, rate limits for install/register and purchases, no cross-installation entitlement leaks, secret-free logs, and replay-safe store notifications.
- Resilience: database restart, RustFS restart, TTS outage, store API timeout, HTTP retry, process kill during CURRENT commit and idempotent replay. Distinguish fail-closed (no entitlement) from temporary offline usability.
- Accessibility and devices: narrow/large Flutter layouts, locale/RTL, screen reader, font scaling, Android and iOS real devices; validate essential purchase/restore error copy.
- Data and legal: image provenance/licensing and author audit, retained local progress, privacy-minimal purchase records, explicit offline policy; backup/restore drill for PostgreSQL and RustFS with coordinated recoverability.
- Observability: correlation of HTTP request ID, publication version, file asset ID (not secret object path), installation pseudonymous ID, purchase ledger event ID, test build and git SHA. No PII/raw proof tokens in reports.

## Environments and evidence

| Track | Runtime | Evidence | Can close |
| --- | --- | --- | --- |
| R5-CI | Ephemeral PostgreSQL + RustFS + live Spring Boot + Flutter subprocess + simulator for billing proofs only | exact SHA, workflow/job URLs, JUnit + Flutter results, assert IDs | integration-contract gate only |
| R5-GP | Google Play internal test track, real product registration and Android test purchaser | provider transaction and acknowledgement observed through sanitized logs/ledger, restore/refund checks | Google Play store gate |
| R5-AS | App Store Connect Sandbox/TestFlight, StoreKit transaction and notifications v2 | signed verification, restore and revoke evidence, sanitized traces | App Store store gate |
| R5-DEVICE | Android/iOS actual physical devices, app restart, storage and network toggles | manual acceptance checklist/screens/videos and test build identifiers | device release gate |

Never log raw tokens, store proof, server keys or personal purchaser identifiers. Use a dedicated test product and test users; do not perform real money purchases automatically.

## Acceptance evidence ledger (mandatory per gate)

Record one row per R5 test with: test ID; commit SHA; PR; environment; app build/platform; publication root N/N+1; assetId and hash (test-only); sanitized purchase provider/state; automated job URL; device evidence; PASS/FAIL/BLOCKED; timestamp; responsible reviewer; defect link and re-test SHA. No checkbox may be marked PASS without direct evidence. For all store sub-gates include separate purchase, restore, refund/revoke and pending/outage evidence on each supported platform.

## Required CI structure

1. Keep current A1, B1, B8, H2, Renderer, Flutter Main and Flutter Mock gates; do not disable failures.
2. Add `r5-commercial-chain-acceptance.yml` triggered on PR, relevant `main` pushes and manual dispatch of an exact release SHA; protect mandatory gate names and reject stale SHA evidence.
3. CI provisions isolated Postgres/RustFS; executes a live HTTP-backed content/publish/sync/learning/purchase-simulator/update/offline flow on primary installation A and separately verifies store-simulated restore on clean installation B. Never copy A's local files or token into B.
4. Run corruption/replay/rollback tests as distinct cases so their failures are visible independently.
5. Do not accept only smoke/simulator output as evidence for Google/Apple. Real store gate is manual or secured dedicated integration harness using connected store accounts.
6. Capture exact SHA, environment, build IDs, redacted evidence links, asserted contentVersion N/N+1, IDs and expiry behavior in a release report.

## Execution order and stop gates

- **R5.0**: Freeze candidate scope and obtain green CI on the merged `main`; decide and version the offline-entitlement policy, acceptance budgets and reproducible evidence format.
- **R5.1**: Finish media library pick/reuse and Content Studio publication UI; MVC HTTP acceptance.
- **R5.2**: Extend A1 with N→N+1, test/markers, image reuse, offline rollback.
- **R5.3**: Integrate simulated purchase/revoke/restore flows through the same billing controller and durable ledger. Simulator is test-only.
- **R5.4**: Qualify Google Play and Apple real store paths on devices.
- **R5.5**: Full exact-SHA CI + manual store/device results. Produce a release evidence report.

## Pre-implementation decision register (must resolve explicitly)

| ID | Decision owner | Default recommendation | Gate |
| --- | --- | --- | --- |
| DEC-01 | Product + security | Confirm an installation-bound, securely stored entitlement snapshot or versioned signed backend receipt; never describe unsigned JSON as signed proof | R5-06/12 |
| DEC-02 | Product + security | Agree bounded premium-offline TTL, grace, revoke/expiry UX and clock manipulation defense; do not treat example 30 days as approved | R5-12 |
| DEC-03 | Backend + data | Compatible-kind SHA-256+size dedup scope, physical blob lifecycle and atomic concurrency strategy | R5-02/13 |
| DEC-04 | Backend + billing | Specify authoritative store-event ordering, reversal handling, platform/environment binding, and maximum reasonable claims policy | R5-07/08/15 |
| DEC-05 | Product + QA | Choose measurable budgets/devices/content sizes and classify API vs UI vs real-store evidence | R5-16/18 |

## Release decision

`R5 ACCEPTED` requires all R5-01..R5-18 green or explicitly split into scoped CI vs live-store evidence, both store tracks qualified with actual store credentials/test-account transactions, no unresolved critical/high severity security or data-loss defects, reproducible build SHA, and signed-off results, agreed nonfunctional budgets, executable recovery playbooks and no unverified in-scope P0/P1 defects. If any gate is missing, label `R5 PARTIAL / BLOCKED`, never `PRODUCTION READY`.

## Out of scope / avoid premature expansion

No user accounts/cloud progress, face recognition, visual similarity ML, new object-storage service, full CMS workflow engine, public media CDN, subscriptions, server-side review history, or multi-user authoring roles. These are not preconditions for release. This document defines acceptance; production changes and tests must be delivered incrementally in subsequent exact-SHA commits, never claimed complete from documentation alone.

## Second-pass review outcome

**Specification completeness is improved, implementation is not claimed.** Existing PR is documentation-only. The reviewed code confirms particular failure modes and unimplemented contracts that acceptance must address, but this review has not executed a complete runtime test of media, stores or devices. Prioritise DEC-01 and DEC-02 before writing an offline premium implementation, then R5.1/R5.2. Keep PR draft and preserve existing CI gates.

## Existing evidence is narrower

Existing A1 demonstrates live published mixed FREE/FULL data, HTTP, RustFS image delivery, checksums, Flutter Drift CURRENT and offline reopen. It does **not** demonstrate Content Studio initiated publication, new image picker, actual purchase/restore, refund with live stores, root N→N+1 upgrade, or complete application offline learning. These remain work, not presumed outcomes.
