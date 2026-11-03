# VoxPrep — Full Flutter ↔ Backend API Technical Work Plan

**Baseline:** `feat/commercial-release`, November 3, 2026  
**Status:** IMPLEMENTATION IN PROGRESS — **NOT** FULL API ACCEPTANCE  
**Ownership:** Backend learner/publication/security, Flutter integration, Content Studio acceptance  
**Related specs:** `contracts/learner-api-v2.yaml`, `contracts/locale-configuration-v1.yaml`, `docs/COMMERCIAL_PRODUCT_COMPLETENESS_SPEC.md`, `docs/LEARNER_API_CONTRACT_REMEDIATION.md`

## Definition of done

**"Supported" is three gates, not a controller name:** (1) implemented route and authorization; (2) response satisfies the exact Flutter strict decoder and immutable store contract with real published PostgreSQL/RustFS records; (3) exact-SHA green backend, Flutter and real Backend↔Flutter acceptance (positive, negative and offline/reopen paths).

No hardcoded/test-only release manifests, fake transaction verification, mutable-publication rewrites, or weakening FREE/FULL checks in production. Until every P0 gate is green, the branch stays **NO MERGE / NO RELEASE**.

## API coverage / target traceability

| ID | Flutter API | Current repository status at baseline | Required implementation and acceptance |
|---|---|---|---|
| API-01 | `POST /api/v1/installations` | Registration + proof-of-possession rotation implemented | Cold start / repeated start / concurrent 401 / stale / blocked / revoked / lost credential, both Java and Flutter tests |
| API-02 | `GET /api/v1/content/manifest` | **Writer + reader implemented**, exact-SHA E2E qualification pending | Frozen canonical root written atomically before CURRENT switch; Flutter digest and 200/304/missing/rollback |
| API-03 | `GET /api/v1/content/packs/{code}/manifest?variant=&revision=` | **Canonical/locale pack writer implemented**, exact-SHA E2E qualification pending | Frozen pack, exact content/localizations/assets/access and order, canonical digest; no mutable source lookup |
| API-04 | `GET /api/v1/catalogues/{kind}/revisions/{rev}` (6 kinds) | **Six catalogue projections implemented**, completeness and Flutter graph E2E pending | Materialize six deterministic catalogue projections; exact Flutter decoder schemas + digest proof and freeze |
| API-05 | `GET /api/v1/content/{type}/{code}/revisions/{rev}` | Exact CURRENT endpoint exists for five learning types | Verify all 15 fields, each typed body, immutable checksum, reference membership, PREM authorization before ETag |
| API-06 | `GET /api/v1/content/{type}/{code}/revisions/{rev}/localizations/{locale}/revisions/{lr}` | CURRENT exact approved revision exists | Freeze exact locale ref with publication; no retroactive approval or fallback substitution; 12-locale tests |
| API-07 | `GET /api/v1/media/assets/{assetId}/content` | Direct asset route exists with CURRENT membership+PREM checks | Frozen media descriptor, RustFS bytes/hash, size, range/streaming, wrong asset ID, 304 authorization and load tests |
| API-08 | `GET /api/v1/assessment/practice-tests/{code}/revisions/{rev}` | Missing; legacy unversioned controller only | Exact DTO: mode, passingScoreBasisPoints, ordered question refs and points; checksum, publication and PREM |
| API-09 | `GET /api/v1/assessment/questions/{code}/revisions/{rev}` | Exact CURRENT singleChoice endpoint implemented, backend CI passed on ebc7623 | Exact singleChoice DTO incl. options/index/skillCode/explanation, checksum, release membership, PREM |
| API-10 | `GET /api/v1/configuration/locales?countryCode=XX` | Public twelve-language API implemented; backend CI passed on 670b15d; Flutter UI localization not qualified | Public strict `countryCode,defaultLocale,locales[{code,label}]` from 12-language registry, KZ preference, deterministic fallback and invalid ISO handling |
| API-11 | `POST /api/v1/purchases/verify` | Missing; default `UnverifiedLifetimeEntitlementAdapter` denies FULL | Real Google Play / App Store server verification, transaction replay + token protection, persistence, refund/revoke, restore cross-device without app account |
| API-12 | Existing learner CURRENT convenience endpoints | Existing, partly authorized | Preserve explicit legacy compatibility without letting them bypass the exact immutable publication or PREM |

Each entry must receive an evidence link to a test job and exact commit SHA before being marked ACCEPTED. HTTP 200 from mocked services **alone does not qualify** any entry.

## Slice sequence (must be dependency-safe)

### Q0 — Repair exact-SHA CI baseline (P0)
- [x] Diagnose `LearnerWirePublicationServiceTest` stale `sha(root)` call; repaired in `ccafbdc`.
- [ ] B1 Backend Foundation successfully compiles and all JUnit tests pass on a *new* exact SHA.
- [ ] B1 Infrastructure, B8 Real Backend Worker and H2 RustFS Restart success on that SHA.
- [ ] Flutter Main, Flutter Mock UI and Renderer Acceptance success. Renderer previously timed out; instrumentation is not proof of resolution.
- [ ] Add explicit test fixtures shared (or independently computed) for Dart↔Java C4.4 digests; reject magic constants not validated against Dart.

### R1 — Complete publication writer/freeze and signed access snapshot (P0)
- [x] `publication_wire_document` storage table, immutability trigger and read endpoints exist.
- [ ] Analyze `PublicationPublisher` transaction, `JpaPublicationContentFreezer`, catalogue/locale/media data lifecycles and release current pointer.
- [x] Initial `JpaPublicationWireSnapshotWriter` constructs v2 root, canonical/available locale packs, ordered memberships, six catalogue kinds and READY media descriptors in the publisher transaction (4c3839e + follow-ups). **Not accepted until full Flutter contract/e2e proves it**.
- [ ] Replace section-code label fallback and default presentation policy with editor-managed persisted publication metadata; qualify locale fallback and tombstones; verify complete frozen semantics for every assessment type.
- [x] Writer snapshots FREE/FULL and collection membership/order; `LearnerFrozenAccessResolver` now authorizes using immutable CURRENT catalogue (0c3cd14, 38f8ac7). Tests cover FULL alias, malformed/missing snapshots; post-publish edit acceptance added in 53ac62e.
- [ ] Exact-SHA completion and validation of concurrent changes across catalogue/publish operations.
- [ ] Validate semantic and digest completeness of all root/pack/catalogue documents; compare with Dart canonicalizer on fixture vectors, with actual valid catalogue schema.
- [x] Wire writer invoked after `PublicationReleaseEntity.saveAndFlush` and before `publication_current.switchTo` inside `PublicationPublisher.publish` (4c3839e). A missing active member/pack or corrupted revision fails the transaction.
- [ ] Add concurrent publisher, reload, content deletion and schema-tampering adversarial integration tests; prove complete Dart canonical compatibility.
- [ ] No changes to `CURRENT` during corrupted RustFS, missing TTS/translation or concurrent edit. Test 2 competing publishers; repeated publish idempotency; saved old immutable manifests.
- [ ] Existing releases without snapshots must be handled by an explicitly reviewed migration/rollback policy; continue fail-closed 503 until formally qualified.

### R2 — Complete exact material / localization / media contract (P0)
- [ ] Back-to-back real JSON tests for five content bodies, nullable optional fields, safe MIME, checksum/revision, ETag and 304, old vs CURRENT, 12 languages and fallback.
- [ ] Ensure taxonomy category/level labels are actual published immutable labels, not code placeholders, once label data is frozen.
- [ ] Ensure `hasAudio` and each `contentAssets` role match real READY media and Flutter role vocabulary. Writer currently emits `requiredOffline=false` and uses the asset's frozen object key; qualify offline and media asset descriptors.
- [ ] Ensure requested asset IDs are UUIDs (or formally update both API and Flutter contract), never raw RustFS URLs; verify byte/hash consistency and cache isolation.
- [ ] Move download from `ResponseEntity<byte[]>` / repeated byte copies to bounded response streaming; cover concurrency/abort/range as applicable.

### R3 — Exact practice-test and question APIs (P0)
- [ ] Trace current seven content types / question body / practice test member tables / publication refs.
- [ ] Persist missing required fields explicitly where needed: mode `learn|exam|quick`, passingScoreBasisPoints, question points, skillCode. No invented defaults that misrepresent content.
- [ ] Freeze ordered question ref/checksum in publication.
- [x] Exact question `singleChoice` API-09 implemented with parent-test entitlement and negative tests (ebc7623).
- [ ] Implement API-08 exact practice-test DTO; mode and per-question points are missing and must be persisted explicitly, not inferred.
- [ ] Verify Flutter `AssessmentPayloadDecoder` strict keys with real HTTP fixtures for learn/exam/quick and empty/invalid question sets.

### R4 — Public locale configuration and 12-language support (P1)
- [x] API-10 public endpoint, ISO alpha-2 validation, cache and exact JSON keys implemented (670b15d).
- [ ] Single registry: en, ru, kk, es, fr, de, pt-BR, zh-Hans, ar, hi, tr, ja; country preference `KZ -> kk`, other markets localized default with `en` fallback.
- [ ] Decide if Flutter accepts `kk` vs `kk-KZ` and `ru` vs `ru-KZ`; do not silently change locale codes and invalidate stored preferences.
- [ ] Tests for 12 locales, Arabic RTL on Flutter, unknown ISO country, malformed code, empty list, duplicates and exact schema.

### R5 — C5 installation + B8 verified lifetime entitlement (P0)
- [x] Server rotates existing installation only on existing valid Bearer token.
- [x] Flutter registration gateway selects Bearer when stored token exists.
- [ ] E2E prove old-token rotation/restore/concurrent 401/race behavior; no silent re-registration of existing UUID after 401.
- [ ] Implement provider adapters verifying Android Play purchase tokens / iOS App Store transactions against official server authorities with configured credentials/IDs.
- [ ] Persist minimal purpose-limited verified transaction evidence, entitlement lifecycle and revocations without user profiles; never use installation ID for analytics. Do not conflate privacy claim with "no technical IDs."
- [ ] Idempotent verify, store account restore without app registration, replay protection across installations, refund/chargeback/revocation, pending payment, fraud guards, test and production separation.
- [ ] Authoritative entitlement adapter replaces default deny only after server and store acceptance. Refuse local Flutter Boolean as source of truth.
- [ ] FREE first knowledge block and all FULL routes gated consistently, including catalogues, exact media, localization, tests, 304 and offline access decisions.

### R6 — Cross-system acceptance and release (P0)
- [ ] Boot real PostgreSQL, Spring backend, RustFS and Worker; publish two structured collections (FREE and FULL) through production authoring path.
- [ ] Flutter production HTTP gateways (not mocks): first install, manifest sync, six catalogues, five content types, two assessment types, locale, images/audio; persist Drift and offline reopen.
- [ ] Store sandbox purchase and restore verified by backend; paid/revoked transitions for content/media/ETag.
- [ ] Negative tests: tampered checksum, dangling refs, wrong revision, invalid locale, missing asset, storage outage, concurrent CURRENT switch, revoked token, stale cache, duplicate purchase and 12 locale layouts.
- [ ] Exact-SHA green quality/verification/renderer + backend and integration workflows, all source-linked; reviewed privacy disclosures, store metadata and rollback/DB backup.
- [ ] Only then request merge PR #39 and tag commercial v1.

## Separate UI producer workstream (not falsely counted as API completion)

MVC-R7 new material + seven typed authoring forms; MVC-R9 publication UI; MVC-R5 image upload/validation/resizing; MVC-R8 TTS authoring controls; MVC-R6 search/filter/pagination; MVC-R12 translations coverage; MVC-R11 aggregate-only analytics. XML-R1 upload/dry-run/XSD remains explicitly **DEFERRED after commercial-critical API acceptance**.

## Required CI and evidence ledger

| Gate | Evidence needed | Current disposition |
|---|---|---|
| Java compilation and JUnit | Exact SHA, backend job result + real DB tests | **PENDING** |
| Database schema | Liquibase migration executed in integration container; immutable trigger, JPA schema validation | **PENDING** |
| Flutter analyzer/test | Exact SHA, all HTTP decoder and interaction tests | **PENDING** |
| Real integration | Published fixture → immutable manifest → Flutter strict decode → Drift/cache | **NOT YET DEMONSTRATED** |
| Security | FREE/FULL on every read route, direct media, 304, token rotation, verified store | **PARTIAL** |
| Renderer screenshots | End-to-end test completes without timeout | **PENDING** |

When any test is red, identify the exact error and repair the actual failing slice. Never declare "API full support" based on mocks or green B1 alone.

## 2026-11-03 implementation update: API-R2 publication and SEC-FIX-4

Implementation refs: `4c3839e` (atomic wire writer), `bffa4be` (B7 real catalogue fixture), `0c3cd14` (immutable FREE/FULL), `38f8ac7` (frozen policy and canonical catalogue tests), `cfc2713` (question ownership), `53ac62e` (post-publication authoring mutation acceptance).

**Confirmed:** B1 Backend Foundation, Infrastructure, B8 Worker and H2 RustFS Restart successfully completed for `38f8ac7f0c0283edab6882583a0e4812dddd58d5`. This is NOT a release gate for later commits; exact-SHA CI must repeat.

**Known incompleteness:** UI-authored section metadata and presentation mode are not in the backend catalogue model: current writer uses section codes as explicit title fallbacks and a deterministic GRID presentation. It does NOT yet implement editor-configurable section titles/icons and presentation policy. Locale pack variants are generated only where approved localizations exist, and fallback rules/tombstones require completion. Store receipt verification and practice-test mode/points remain P0 blockers. Flutter renderer qualification remains unresolved.

**Release decision:** NO MERGE and NO FULL-API ACCEPTANCE until all P0 gates pass.
