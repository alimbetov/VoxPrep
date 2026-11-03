# VoxPrep — Technical Architecture & Consistency Review

**Review date:** 2026-11-03  
**Status:** BLOCKED / REVIEWED SOURCE, RUNTIME ACCEPTANCE STILL REQUIRED  
**Exact inspected SHA:** `f3ea3398ea31549893de7495a3bbbf727d3e14a0`  
**Branch / PR:** `feat/commercial-release` / #39  
**Method:** GitHub source inspection of security, installation, learner, publication, TTS, asset, MVC, Flutter configuration, requirements and exact-SHA CI; no local compiled test run or store-device run. The findings below distinguish actual code inconsistencies from still-unproven acceptance.

## Executive decision

**DO NOT MERGE OR RELEASE.** The dominant risk is not missing MVC polish: route-level authorization and commercial entitlement require closure first. A passing Maven suite does not prove every route is protected, and a published-content invariant does not imply a premium-access invariant.

## Confirmed / grounded findings

### ARCH-SEC-001 — P0: authentication route matcher mismatch

- `InstallationAuthenticationFilter.PROTECTED_PREFIXES` includes `/api/v1/catalogues/` and `/api/v1/assessment/`.
- Actual controllers are `LearnerCatalogueController @RequestMapping("/api/v1/catalogue")` and `LearnerAssessmentController @RequestMapping("/api/v1/assessments")`. These requests do not match those prefixes.
- `InstallationSecurityConfiguration.installationSecurityFilterChain` uses `anyRequest().permitAll()` and the installation filter only runs for its enumerated prefixes.
- **Consequence:** these two controller families can reach a controller without the expected installation-authentication filter; published data availability depends on downstream behavior. Missing authorization for endpoints is a verified routing defect, regardless of whether the data is free.
- **Fix:** centralize an exact request matcher / route registry for learner endpoints; protect `/api/v1/catalogue`, `/api/v1/catalogue/**`, `/api/v1/assessments/**`, `/api/v1/content/**` and other intended routes. Explicitly distinguish intentionally anonymous installation registration and public health endpoints; use deny-by-default for unclassified routes. Tests: unauthenticated/invalid/revoked token across EVERY learner controller including no-trailing-slash paths; verified permitted free access where intended.

### ARCH-SEC-002 — P0: no observed premium entitlement in content/media application read path

- `LearnerContentService.get`, `LearnerAssessmentService.getPracticeTest`, `LearnerLocalizationService.get`, `LearnerPublishedMediaService.requireMedia/listMedia` resolve exact CURRENT publication but the inspected method flows do not query entitlement or catalogue collection access level.
- Installation authentication confirms installation ACTIVE, **not** purchase authorization.
- Existing external filters or facade composition must be audited; this source inspection cannot prove full exploitability for every route. But the inspected read path lacks a visible verified PREMIUM gate.
- **Fix:** a common `LearnerAccessPolicy` keyed on canonical content -> collection FREE/PREMIUM -> verified entitlement, invoked before content, assessment, localization, media list and binary retrieval. Do not assume Flutter lock equals backend authorization. Return stable 403/entitlement error (or intentional obscure response) and test free/no purchase, premium/no purchase, premium/verified, refund/revoked, invalid token, direct asset URI, cache replay/304. Endpoints should not leak premium data in metadata or errors. **Must be implemented/verified before B8 release.**

### ARCH-PRIV-001 — P0: product privacy requirement vs persistent installation identifiers

- `InstallationEntity` persists `installationId UUID`, `tokenSha256`, token timestamp and status; `InstallationAuthenticationService` authenticates by persistent token hash and produces installation principal.
- This does **not** establish that names/emails are collected; it **does** refute the absolute requirement of no persistent installation identifiers.
- Product decision required: (A) no **personal profiles** but limited purpose-bound technical installation identity for access and purchases, with privacy/retention policy; or (B) truly no stable identifiers, which requires redesign of installation authentication and possibly entitlement reconciliation. Do not silently delete security state or claim zero personal data.
- Keep telemetry aggregate-only and separate from auth/billing records; do not use installation identifier as analytics user ID.

### ARCH-MOB-001 — P1: inconsistent definition of release mode

- `release_switch.dart` derives AppRunMode from `kReleaseMode || VOXPREP_RELEASE`.
- `app_configuration.dart` derives AppEnvironment and mock defaults from `kReleaseMode`, rather than the same resolved run mode.
- A debug build with VOXPREP_RELEASE=true may compose release billing safeguards while still allowing development HTTP/API policy. This is a configuration-policy inconsistency, **not proof that actual compiler release builds are insecure**.
- Fix a single resolved build-policy contract; test debug simulation, profile, compiler release and explicit staging/production override, invalid mock flags and insecure endpoints.

### ARCH-MEDIA-001 — P1: potential heap amplification in media delivery

- `LearnerMediaService.read` allocates full `byte[]`, `MediaContent` clones bytes on construction and on getter; `LearnerMediaController` returns `ResponseEntity<byte[]>`.
- This is bounded only by runtime/object sizes, not a streaming delivery contract, and may cause memory amplification under concurrent audio/media requests.
- Qualification: configurable max bytes, HTTP streaming/range as appropriate, controlled checksum verification, safe resource cleanup, load benchmark and caching semantics. Avoid modifying integrity guarantees.

### ARCH-MVC-001 — P0: incomplete authoring/publication product flow

- `ContentMvcController` implements editing and revision lifecycle but not create-new-logical-content. `ContentStudioController` publication remains placeholder.
- `admin/content/form.html` lacks image upload and TTS controls; `/admin/imports` intentionally reserved for later XML.
- `/admin/localization` menu is placeholder although per-content localized editor exists.
- Verify all seven types from creation through CURRENT and learner Flutter display. Do not conflate JPA service tests with product acceptance.

### ARCH-CONTENT-001 — P1: catalogue semantics not represented in learner catalogue read model

- `LearnerCatalogueService` maps publication manifest refs into `LearnerCatalogueEntry(contentCode,contentType,revisionNumber,checksum)`.
- No collection, access level, order or FREE-first-block metadata appears in that returned DTO.
- This does not show whether some other catalogue/access API exists; **integration review must locate the authoritative mapping**. Absence here is an architectural contract gap for the selected free-first-block product if this DTO is treated as the canonical learner catalogue.

### ARCH-MEDIA-002 — P1: single media slot per role

- `ContentAssetBindingRepository.findByContentRevision_IdAndRole` implies unique active `COVER_IMAGE` and `CONTENT_IMAGE` per revision. Confirmed v1 scope; do not promise multi-image gallery before a versioned schema and Flutter contract.
- Validate upload byte/pixel constraints, safe decode, crop/resize, status transitions and immutable published media.

### ARCH-OPS-001 — P0: CI is not green on inspected SHA

Exact SHA `f3ea3398ea31549893de7495a3bbbf727d3e14a0`: backend foundation, infrastructure, real backend worker, H2 restart succeeded at observation. Renderer Acceptance failed at `renderer-e2e`: its `Renderer snapshot acceptance` step ran `timeout 3m flutter test test/acceptance/p2_10_7_production_e2e_test.dart --plain-name 'production app syncs from mock backend across renderer snapshots'` and exited **124 (timeout)**. At observation Flutter Main and Flutter Mock UI were still in progress. The root cause of the timeout is **not** identified. Investigate test deadlock, environment, fixture/setup, and timeout budget; do not mark it as an assertion failure or increase timeout without diagnosis.

### ARCH-XML-001 — P2: future importer is a documented deliberate omission

`XML-R1` must remain deferred, not treated as an active release blocker; its contract requires versioned XSD, dry-run, XXE protection, bounded import, explicit duplicate policy, no publication side effects. Current `/admin/imports` must clearly say PLANNED.

## Consistency matrix / contract owners

| Boundary | One owner | Rule / proof required |
|---|---|---|
| Route authentication | Spring Security + InstallationAuthenticationFilter | All actual learner routes match a single tested policy |
| Monetization entitlement | Learner access policy + store-verified billing | FREE/PREMIUM checked server-side on every content/media path |
| Publication snapshot | PublicationPublisher / CurrentPublicationResolver | Immutable refs, checksums and CURRENT consistency |
| Media | FileAsset + ContentAssetBinding | READY, role, size/SHA, immutable after publish; RustFS behind adapter |
| TTS | ContentAudioPolicy / planner / Worker | One source of roles, deterministic fingerprints and stale behavior |
| UI localization | Flutter ARB | 12 locales; content translation is independent; Arabic RTL |
| Analytics | aggregate ingestion | Never link telemetry to installation IDs; never claim DAU/MAU |
| XML import | future authoring adapter | Reuse domain services and fail closed, deferred |

## Recommended implementation / review order

1. **SEC-FIX-1:** route matching and negative HTTP acceptance.
2. **SEC-FIX-2:** canonical content collection access level plus verified entitlement protection (text, assessment, localization, media, 304), cross-platform restore tests.
3. **PRIV-DEC-1:** document 'no personal account' vs limited technical installation records; adjust spec, retention, and app privacy declarations.
4. **CI-FIX-1:** investigate and qualify Renderer exact-SHA timeout; fix cause and rerun.
5. **MVC-R7/MVC-R9:** product creation and publication console.
6. **MVC-R5/R8/R6:** image upload/bounds, TTS controls and server search/pagination.
7. **MVC-R12/R11:** 12-language UI, RTL, aggregate-only analytics.
8. **B8/B9:** store sandbox + live backend, then exact-SHA green qualification.
9. **XML-R1** later. Do not start XML implementation in this slice.

## Review exit criteria

- Linked regression test and exact SHA for each P0; publish a route permission matrix and free/premium response matrix.
- Full exact-SHA CI including Renderer SUCCESS; no 'accepted' label based on only backend checks.
- Verified user flow: admin creates/edits/attaches image/audio -> validates/publishes CURRENT -> anonymous/free learner sees first block -> premium blocked without entitlement -> real store purchase -> server verify -> premium available -> restore/refund transitions correct, with 12 UI locales.
- Independent privacy review resolves persistent installation identifiers and transaction evidence requirements.
- This document contains **source-based findings**, not proof of production exploitation or a completed pentest.
