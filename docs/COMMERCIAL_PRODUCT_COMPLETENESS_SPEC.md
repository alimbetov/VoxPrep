# VoxPrep — Commercial Product Completeness Specification

**Version:** 1.0-review  
**Date:** 2026-11-03  
**Status:** REVIEW BASELINE, not release-accepted  
**Repository:** alimbetov/VoxPrep  
**Working branch:** feat/commercial-release  
**PR:** #39  
**Baseline observed before specification:** 10a8e34058748701fd6bcd2a792570d406d70c70

## A. Objectives and non-negotiable contracts

Commercial v1: first knowledge block free; remaining content available after a single lifetime unlock (target USD 4.99, actual localized store display price authoritative). No subscription, no user accounts, no registration requirement. Android and iOS purchase, verified backend entitlement, restore, refunds/revocations and offline revalidation must be accepted in store sandbox and release builds. Never trust a local purchase Boolean alone.

**Privacy-first:** no personal profiles, names, emails, phone numbers, advertising IDs, persistent device/install identifiers, device fingerprinting or precise location for analytics. Aggregate event counters only; no user-level analytics. Store verification may necessarily retain transaction identifiers/tokens for entitlement and replay protection: treat as purpose-bound, access-controlled, redacted and retention-limited, and avoid the claim that the whole platform processes no personal information. Exact DAU/MAU, unique users, deduplicated conversion and user retention are **not measurable** in this design; label metrics as counts of events/transactions, not people. Apply minimum cell thresholds and avoid sparse group breakdowns.

The pre-existing B6/B7/B8/B9 and H1/H2/H3 publication, integrity, TTS, RustFS, security and payment contracts remain authoritative. No new parallel media or authoring stack. Maintain one working branch and PR unless ownership changes explicitly.

## B. Mandatory backlog and acceptance

| ID | Priority | Capability | Done means |
|---|---|---|---|
| MVC-R5 | P1 | Image management and upload | Admin upload -> validated/optimized RustFS asset -> READY -> bound -> published -> Flutter display |
| MVC-R6 | P1 | Server search, filtering, sorting, pagination | Search across seven content types, stable filtered pages, valid URL navigation |
| MVC-R7 | P0 | Create and preview materials | Admin creates each of seven types, edits, previews and makes next immutable revision |
| MVC-R8 | P1 | TTS authoring controls | UI generates and monitors TTS, plays audio, shows stale/ready/failure |
| MVC-R9 | P0 | Publication Console | Admin validates candidate, sees blockers, confirms atomic CURRENT publish, verifies learner delivery |
| MVC-R10 | P0 | Complete authoring E2E acceptance | Admin can complete content -> locale/media/audio -> publication -> mobile consumption without hidden scripts |
| MVC-R11 | P1 | Privacy-safe analytics dashboard | Simple aggregate activity, purchases, locales and errors with no personal profiles |
| MVC-R12 | P1 | 12-language internationalization | App strings, purchase UX, errors, fallback, RTL and localization completeness dashboard |
| XML-R1 | P2 DEFERRED | XML content importer | Contract and review now; implementation **after** release-critical MVC/B8/B9 work |
| B8-C | P0 | Commercial purchase contract | Actual Play/App Store purchase, verify, restore, refunds, duplicate/replay protection |
| B9-C | P0 | Production qualification | Full exact-SHA CI, smoke/E2E, real infrastructure, stores, privacy policy and release checklist |

P0 means product flow blocked. P1 remains release scope unless explicitly waived by reviewed risk decision. P2 must not delay first commercial release. A working backend service or clickable menu link is not accepted as a complete feature.

## C. MVC-R7 — Authoring completeness

- `/admin/content` needs **New content** action. Create logical content and initial draft for VOCABULARY, PHRASE, INTERVIEW, TOPIC, SHADOWING, QUESTION and PRACTICE_TEST through existing application service, Form DTO and mapper.
- Validate stable code uniqueness, category/level/catalogue references, required structured fields and allowed lifecycle. Preserve form data on errors; HTTP 404/409 for missing/conflict, auth and CSRF enforce.
- Add private admin learner-style preview of exact draft text, selected localization, images and audio without public access to draft endpoints.
- Frozen/published revisions are read-only. Editing published content requires **create next draft**; old CURRENT release unchanged. Optimistic version check on editable forms.
- Replace freehand question UUID entry in practice tests with searchable question selector (P1). Structured repeatable section/option controls preferred (P2 refinement); maintain safe validation until then.
- Content list back-navigation preserves search and pagination query state.

## D. MVC-R5 — Images

- In content editor add role slots `coverImage` and `contentImage`; show current preview, dimensions, bytes, status; upload, replace and unbind permitted only for mutable revisions.
- Accept JPEG, PNG, WebP after signature and bounded decode validation, not filename or MIME alone. Reject SVG/active media, invalid images, unsafe animations, and decompression bombs. Enforce server-side bytes + pixel limits before expensive operations. Upload byte targets: cover max 2 MiB; content max 3 MiB. Decode dimensions max 4096x4096 and total pixels max 16 million; subject to resource qualification.
- Cover preferred display 16:9, 1200x675, with manual crop/preview; content preferred <=1024x1024 without stretching. Respect EXIF orientation, strip unneeded metadata and optimize to WebP where supported; preserve transparency when needed, no silent upscaling. Generate thumbnail, bound processing CPU/time/memory.
- Use existing FileAsset / RustFS / ContentAssetBindingService. Never embed binary in content JSON; never bind until asset READY and metadata/integrity verified. Handle storage unavailable, repeated upload, corrupt, concurrent bind, and failed conversion without dangling READY. Published media immutable.
- V1: exactly one active binding per role. Multiple gallery images are explicitly out of scope until schema and learner contract are revised.

## E. MVC-R8 — TTS controls

- Show type-dependent role policy: VOCABULARY pronunciation OPTIONAL; PHRASE pronunciation RECOMMENDED; INTERVIEW question + sampleAnswer RECOMMENDED; TOPIC narration OPTIONAL; SHADOWING shadowing REQUIRED; QUESTION/PRACTICE_TEST no TTS v1.
- Per role: source/voice/language, prepare/generate, queued/processing/ready/failed/stale status, play, retry, warning when required audio missing.
- Reuse ContentTtsPlanner, TtsJobPreparationService, Worker/Piper, RustFS and role-aware FileAsset bindings. No direct tts_job SQL to manufacture user-visible output.
- Repeated requests idempotent; changed text yields stale fingerprint and regeneration; no destructive removal of old assets.
- Real generated media must be delivered and played by Flutter through publication-scoped endpoints.

## F. MVC-R6 — Search and pagination

- Search by code/title/description with filters: content type (all 7), category, level, lifecycle, catalogue scope, CURRENT publication status and locale translation completeness.
- `latestOnly=true` by default; optional all revisions. Distinguish publication version and draft revision.
- Server-side pageable query, default size 25, allowed 10/25/50/100, max 100, nonnegative index. Whitelist order by title/code/type/updatedAt with deterministic unique ID tiebreaker.
- Persist q/filter/sort/page in URL; restore when returning from editor. Empty state, total count, previous/next and clear filters. Avoid full table loading.
- Integration tests >100 fixtures, every content type, same timestamps, duplicate revisions, invalid sort/pages, and concurrent updates. Index frequent filters; inspect query plans under representative data volume.

## G. MVC-R9 — Publication console

- Replace `/admin/publication` placeholder with app-service-backed candidate selection, exact revision/locale/media manifest, validator severity (ERROR/WARNING), preview, confirm and atomic publish to CURRENT.
- Never bypass existing B6 publication services; do not resolve mutable latest after freeze. Block required SHADOWING audio and invalid image/audio bindings.
- Make publish idempotent; test concurrency, replay, old manifest invariance and recovery; support safe return to prior immutable manifest only if service semantics make this possible.
- Acceptance: author via admin UI, publish, fetch exact learner publication, open on Flutter.

## H. MVC-R11 — Aggregate analytics, no user profiles

- Admin page `/admin/analytics`, read-only for authorized admins. Filter date range (7/30/90 days), Android/iOS and interface locale.
- Aggregate counters: app opens, lesson opens/completions, purchase screen views, successful verified purchases, refunds/revocations, TTS/media errors; chart by day and conversion funnel using **events** with explicit denominator. Country only if aggregated from a separately legitimate non-identifying source, otherwise omit.
- Do NOT store persistent device/installation ID, individual session traces, IP/user agent telemetry or per-person activity history. Event emission must minimize payloads and avoid arbitrary free text.
- Store bounded daily aggregate rows by date/platform/locale/event/version; use ingestion validation, rate control, idempotent payment event handling, limited raw buffer only if justified, threshold suppression for small cells, and retention policy.
- No DAU/MAU, unique users or retention claims. Revenue displayed as qualified approximate transaction sum excluding or identifying commission/tax/refunds, never invented finance amounts.
- Minimal privacy disclosures and audit log without secrets.

## I. MVC-R12 — 12 languages

UI locale list: `en` English, `ru` Russian, `kk` Kazakh, `es` Spanish, `fr` French, `de` German, `pt-BR` Brazilian Portuguese, `zh-Hans` Simplified Chinese, `ar` Arabic, `hi` Hindi, `tr` Turkish, `ja` Japanese.
- Separate UI locale from learning content language and TTS voice language. Flutter ARB/resources for all 12 including paywall, restore, validation and offline/errors; locale fallback deterministic, never show blank screen for missing translation.
- Real RTL layout test for Arabic; long German strings, Asian fonts, Hindi shaping, accessibility and screenshots.
- Backend ContentLocalization BCP-47 support and content coverage by locale. Admin can filter Missing/Draft/Approved and create/approve localized revisions. Do not make complete translated learning content in all 12 a v1 prerequisite; interface strings must be complete.
- External store product text/pricing and store-listing translations depend on store configuration; never assume store provides all translations automatically.
- Regression on all 12 locale bundles, RTL, language switch without changing paid entitlement.

## J. XML-R1 — DEFERRED CONTENT IMPORT CONTRACT (review now, build later)

**Explicit decision: XML ingestion must be included in the product roadmap but implementation is deferred.** No XML upload endpoint or importer is required for release-critical implementation unless this priority is changed in review. The existing `/admin/imports` placeholder must be labeled as planned/unavailable instead of suggesting it is functional.

Later XML ingestion design:
1. Canonical versioned `voxprep-content-v1.xsd` with root/schemaVersion; explicit catalogue references, logical code, contentType, metadata, seven body types, localization texts, revision intent and optional media references (not binary-in-XML).
2. Strict schema + semantic validation, UTF-8, explicit namespace, supported version gate, no external entities/DTD/XInclude, bounded nesting, byte limits and element count; reject XML bombs and remote entity resolution (XXE).
3. UI upload -> dry-run parse -> preview creates/updates -> row-level diagnostics (line, content code, validation code) -> explicit commit; default dry-run always.
4. Deterministic duplicate policy (skip/conflict/update only mutable draft), optimistic locking, per-batch idempotency keys/content hash, never overwrite immutable published versions.
5. Transaction/batch-size strategy and rollback semantics documented; large imports paged with bounded server memory; no hidden partial success.
6. Binary media imported separately through verified FileAsset/RustFS pipeline, referenced by safe logical identifiers and bound only after validation.
7. Automated fixtures for all seven types, 12-locale metadata, wrong schema version, invalid category, duplicate code, conflicting revision, malicious XXE, oversized input, retry and partial failure.
8. Reuse authoring services and publication invariants. Do not create a second XML-specific domain model or publish automatically.

**Review gate for XML-R1 now:** agree on XSD outline, version, duplicate policy and dry-run acceptance; leave development status PLANNED/DEFERRED.

## K. B8 commercial acceptance and application integration

- FREE: first canonical knowledge block is accessible without purchase/account. PREMIUM: all remaining blocks require verified lifetime entitlement at application and protected backend boundary; do not rely on visual padlock alone.
- Test Play Billing and StoreKit product discovery, localized price, pending purchase, declined/cancelled, repeat, interrupted verification, backend unavailable, restore after reinstall, different device on same supported store account, refunds/revocation and replay/fraud attempts.
- Refuse accepting mock billing/verification in any distribution build. Review interaction of `VOXPREP_RELEASE`, compiler `kReleaseMode`, and `VOXPREP_ENV`; all release safeguards must derive from one authoritative production policy. Debug release-simulation and actual store builds require explicit test matrices.
- Store transaction evidence may be necessary without a profile; entitlement reconciliation must be documented against store account/receipt on backend. No fabricated 'same user' matching using device fingerprint.
- Confirm Flutter consumes published text, localized text, image, and audio, applies FREE/PREMIUM, handles missing/failed media and offline state.
- Respect platform payment rules, privacy declarations, restore UI and store review metadata at time of submission.

## L. Security, storage, operational and test gates

- Permissions, CSRF, validation, boundary errors, no published edit, transactional locks for binding/publish, author/reviewer approval policy review.
- RustFS stale REGISTERED recovery, byte budgets, orphan inventory advisory-only, no automatic destructive orphan cleanup; test restart, outages and storage consistency with real integration jobs.
- Learner media should be assessed for `ResponseEntity<byte[]>` memory amplification, streaming/range/cache needs, especially audio and simultaneous downloads.
- P0 release gate: exact-head green Backend Foundation, Infrastructure, Flutter, Renderer, real Backend↔Worker and RustFS qualification; successful MVC Selenium/Playwright-equivalent user-path tests (framework chosen per repo), representative Android/iOS store flows, production configuration, rollback/backup verification.
- Do not merge or tag `v1.0.0` until a signed-off acceptance matrix links requirements to tests and exact SHA.

## M. Review and remediation process

**Review stage first; implementation second.** Create a defect ledger with columns `ID | requirement | observed code/UI evidence | severity | owner | implementation slice | test | status | SHA`. For each feature classify: IMPLEMENTED+ACCEPTED, CODE EXISTS/UI MISSING, PARTIAL, NOT IMPLEMENTED, or DEFERRED. Avoid claiming functionality purely from service names.

Suggested order:
1. Review actual working tree/PR vs this specification, catalog gaps and negative test cases.
2. Stabilize active H1/H2/H3 integrity work and exact-head CI.
3. MVC-R7 create/preview and MVC-R9 publication (critical path).
4. MVC-R5 images and MVC-R8 TTS controls; MVC-R6 search/pagination; MVC-R12 internationalization.
5. MVC-R11 aggregate analytics and B8 monetization/Flutter E2E.
6. MVC-R10 + B9 full product acceptance and release.
7. XML-R1 implementation in **later phase**, after release-critical work, with its own schema review.

**Success scenario:** ADMIN creates a type-specific item, finds it through paginated search, adds localized text and optimized image, prepares required TTS, verifies learner preview, validates and publishes CURRENT; anonymous learner opens first block freely, pays once to unlock remaining content, restores supported purchase without an app account, consumes published media in one of 12 UI locales; admins see only aggregate analytics. Failed security, validation, upload, storage, concurrent edit, publication and payment scenarios are verified fail-closed.

## N. Known evidence and review questions

Observed at baseline: `ContentMvcController` edits revisions but does not create logical items; `/admin/publication` and `/admin/imports` are placeholder views; `/admin/localization` is a placeholder while per-content localization forms exist; admin content form has no image upload or TTS panel; server paging exists but search/multi-filter navigation is missing. Backend has image roles, publication media and RustFS recovery; none alone demonstrates end-to-end admin upload. Flutter has billing/verification providers but exact store device acceptance is not established by these sources.

**Review decisions required:** absolute media processing budgets, accepted WebP encoder/library, source retention, schema for XML future phase, actual store product IDs, platform support matrix, privacy analytics retention/suppression thresholds, any explicit P1 release waiver. These remain pending review, not hidden implementation assumptions.
