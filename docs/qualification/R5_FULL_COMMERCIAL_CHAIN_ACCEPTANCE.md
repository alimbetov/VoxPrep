# R5 — Full Commercial Chain Qualification

Status: PROPOSED / NOT ACCEPTED
Baseline: `main` at `e68a9dcb3e736111ffee422fe8b1b425918fa4ae`
Prerequisites: R1 release defect remediation, R2 Content Studio + image Media Library completion, R3 real store acceptance.

## Objective

Prove one coherent production-code path, not a sequence of unrelated mocked unit tests:

```text
ADMIN creates content + selects READY image from Media Library by assetId
→ DRAFT validation / review / approval
→ immutable Backend publication (root N)
→ authenticated Flutter installation + HTTP sync
→ Drift CURRENT(root N), checked media, learner reading/audio/assessment/progress
→ FREE paywall / one-time purchase / server verified FULL entitlement
→ restore via trusted store proof on reinstall/new installation
→ publish immutable root N+1
→ Flutter atomic upgrade, retained learner state + old READY during transition
→ process kill/reopen, network disabled, verified offline material/audio/test/review
```

**Critical rule:** Do not report `R5 ACCEPTED` from mocked stores or from the existing A1 test alone. Store verification in CI can use a deterministic simulator only for contract/logic qualification; real store acceptance is separate and mandatory.

## Reuse existing production components

- Spring Boot modular monolith, PostgreSQL/Liquibase, private RustFS.
- `FileAssetEntity`, `ContentAssetBindingService`, `ContentAssetRole` and immutable publication.
- `A1RealBackendFlutterAcceptanceTest` and `a1_real_backend_flutter_test.dart` as the live HTTP/Drift/asset baseline.
- `PurchaseVerificationController`, `LifetimePurchaseService`, `PurchaseLedger`, official Google/Apple verifiers, signed Apple notifications and voided-purchase reconciliation.
- Installation token/secure storage, local learner state, revisions, assessment and verified offline assets.

Do not introduce a new storage service, second entitlement source, learner account or Flutter mock runtime switch.

## Test matrix: R5-01–R5-12

| ID | Step / positive acceptance | Required observable evidence |
| --- | --- | --- |
| R5-01 | ADMIN creates catalogue/content via authenticated Content Studio MVC, selects existing READY image by ID | HTTP form/request, DB draft and binding exact `revisionId + role + assetId` |
| R5-02 | Upload same image twice and bind it to distinct drafts | identical SHA-256 bytes resolve to one reusable physical blob; no duplicate storage; binding count >=2; never mutate published revision |
| R5-03 | Review/approve, publish root N | commit and immutable root, exact revision/asset references and checksums, ACTIVE + PUBLISHED only |
| R5-04 | Real Flutter installation registers and syncs using HTTP | real Postgres + RustFS + Spring Boot + production Flutter codecs + persistent Drift CURRENT=N |
| R5-05 | FREE learner reads/listens/tests; paid content denied | FREE media size and SHA verified, local markers/attempts persisted, FULL HTTP responds 403 with expected machine code |
| R5-06 | Purchase transitions entitlement FREE→FULL | backend verifies store proof, durable ledger grants once, premium API becomes accessible; no grant on client boolean |
| R5-07 | Reinstall/new installation restores non-consumable | device uses store-owned purchase history/proof, new installation obtains entitlement; cannot claim by guessing another installation UUID |
| R5-08 | Refund/revoke and replay safety | authorized store event downgrades premium, stale/duplicate/reordered events do not restore revoked access |
| R5-09 | ADMIN modifies published content by new draft and publishes root N+1 | prior root/content immutable, no in-place mutation; all references/checksums valid |
| R5-10 | Flutter synchronizes N→N+1 | atomic CURRENT switch; progress/markers/attempts retained by explicit identity rules |
| R5-11 | Network interruption/corruption during staged upgrade | retains CURRENT=N and old READY; restart/retry never mixes N and N+1 |
| R5-12 | Close app, disable network, reopen | verified downloaded image/audio and local content available; review and history intact; remote locked/unavailable bytes never fabricated |

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

## Environments and evidence

| Track | Runtime | Evidence | Can close |
| --- | --- | --- | --- |
| R5-CI | Ephemeral PostgreSQL + RustFS + live Spring Boot + Flutter subprocess + simulator for billing proofs only | exact SHA, workflow/job URLs, JUnit + Flutter results, assert IDs | integration-contract gate only |
| R5-GP | Google Play internal test track, real product registration and Android test purchaser | provider transaction and acknowledgement observed through sanitized logs/ledger, restore/refund checks | Google Play store gate |
| R5-AS | App Store Connect Sandbox/TestFlight, StoreKit transaction and notifications v2 | signed verification, restore and revoke evidence, sanitized traces | App Store store gate |
| R5-DEVICE | Android/iOS actual physical devices, app restart, storage and network toggles | manual acceptance checklist/screens/videos and test build identifiers | device release gate |

Never log raw tokens, store proof, server keys or personal purchaser identifiers. Use a dedicated test product and test users; do not perform real money purchases automatically.

## Required CI structure

1. Keep current A1, B1, B8, H2, Renderer, Flutter Main and Flutter Mock gates; do not disable failures.
2. Add `r5-commercial-chain-acceptance.yml` triggered on PR and optionally manual dispatch.
3. CI provisions isolated Postgres/RustFS; executes a live HTTP-backed content/publish/sync/learning/purchase-simulator/restore/update/offline scenario.
4. Run corruption/replay/rollback tests as distinct cases so their failures are visible independently.
5. Do not accept only smoke/simulator output as evidence for Google/Apple. Real store gate is manual or secured dedicated integration harness using connected store accounts.
6. Capture exact SHA, environment, build IDs, redacted evidence links, asserted contentVersion N/N+1, IDs and expiry behavior in a release report.

## Execution order and stop gates

- **R5.0**: Freeze candidate scope and obtain green CI on the merged `main`.
- **R5.1**: Finish media library pick/reuse and Content Studio publication UI; MVC HTTP acceptance.
- **R5.2**: Extend A1 with N→N+1, test/markers, image reuse, offline rollback.
- **R5.3**: Integrate simulated purchase/revoke/restore flows through the same billing controller and durable ledger. Simulator is test-only.
- **R5.4**: Qualify Google Play and Apple real store paths on devices.
- **R5.5**: Full exact-SHA CI + manual store/device results. Produce a release evidence report.

## Release decision

`R5 ACCEPTED` requires all R5-01..R5-12 green or explicitly split into scoped CI vs live-store evidence, both store tracks qualified, no unresolved critical/high severity security or data-loss defects, reproducible build SHA, and signed-off results. If any gate is missing, label `R5 PARTIAL / BLOCKED`, never `PRODUCTION READY`.

## Existing evidence is narrower

Existing A1 demonstrates live published mixed FREE/FULL data, HTTP, RustFS image delivery, checksums, Flutter Drift CURRENT and offline reopen. It does **not** demonstrate Content Studio initiated publication, new image picker, actual purchase/restore, refund with live stores, root N→N+1 upgrade, or complete application offline learning. These remain work, not presumed outcomes.
