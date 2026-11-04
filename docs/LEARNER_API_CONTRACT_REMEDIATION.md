# VoxPrep — Learner Backend ↔ Flutter API Contract Remediation

**2026-11-03 | feat/commercial-release | in progress — NOT release accepted**

This document describes the repository implementations and proof gaps, not a claim that production live integration already works. Canonical wire requirements are in `contracts/learner-api-v2.yaml`; Flutter DTO decoders and HTTP gateways are the compatibility reference. Existing `CURRENT` conveniences remain backward compatible; they are not aliases for exact version endpoints.

## Integration status

| Flutter HTTP operation | Backend implementation | Status |
|---|---|---|
| `POST /api/v1/installations` | `InstallationRegistrationController` + `HttpInstallationRegistrationGateway` | **Updated**: first claim anonymous, existing registration requires active Bearer proof; C5 token recovery must undergo fresh end-to-end qualification |
| `GET /api/v1/content/manifest` | No versioned root-manifest projection | **BLOCKED (P0)** |
| `GET /api/v1/content/packs/{code}/manifest?variant=...&revision=...` | No immutable pack snapshot | **BLOCKED (P0)** |
| `GET /api/v1/catalogues/{kind}/revisions/{revision}` | Existing `/api/v1/catalogue` only | **BLOCKED (P0)** |
| `GET /api/v1/content/{type}/{code}/revisions/{revision}` | `LearnerExactContentController`, `LearnerExactContentPayloadService` | **IMPLEMENTED FOR CURRENT**; five non-assessment types, strict Flutter payload keys |
| `GET /api/v1/content/{type}/{code}/revisions/{r}/localizations/{locale}/revisions/{lr}` | `LearnerExactLocalizationController`, `LearnerExactLocalizationService` | **IMPLEMENTED FOR CURRENT**; exact approved locale revision only |
| `GET /api/v1/media/assets/{assetId}/content` | `LearnerAssetDownloadController`, `LearnerAssetResolutionService` | **IMPLEMENTED FOR CURRENT**; all CURRENT bindings checked via FREE/FULL policy before ETag/download |
| `GET /api/v1/assessment/practice-tests/{code}/revisions/{r}` | Legacy `/api/v1/assessments/practice-tests/{code}` only | **BLOCKED (P0)** |
| `GET /api/v1/assessment/questions/{code}/revisions/{r}` | No exact assessment question projection | **BLOCKED (P0)** |
| `GET /api/v1/configuration/locales?countryCode=...` | No verified matching learner controller | **BLOCKED (P1)** |
| `POST /api/v1/purchases/verify` | No verified store entitlement implementation | **BLOCKED (P0)** |

## Exact content implementation constraints

- `LearnerContentService.get` validates exact identity/checksum against CURRENT, then `LearnerExactContentPayloadService` rejects a requested revision number different from CURRENT. This does **not** implement historical release reads.
- Response has the Flutter 15 required fields `contentCode, contentType, revision, checksum, title, subtitle, description, categoryCode, categoryLabel, levelCode, levelLabel, minutes, hasAudio, skillCodes, body`.
- `body.kind` and fields are mapped explicitly for vocabulary, interview, topic, phrase and shadowing; question/practice-test belong to assessment API.
- For now `categoryLabel/levelLabel` deliberately fall back to the immutable taxonomy codes. This satisfies nonblank decoder requirements but is **not** a final localized display-label system.
- `hasAudio` reflects a READY TTS_AUDIO binding on the exact CURRENT revision; publication validation still owns media integrity and fingerprint requirements.
- Root/pack checksum must be computed from the precise canonical JSON algorithm accepted by Flutter, *not* copied blindly from `publication_release.root_sha256`. Flutter recomputes the pack and root canonical digests.
- Publication must freeze `collection accessLevel`, membership/order, catalogue graph, locale refs, manifest asset descriptors and hash digests together; reading mutable catalogue rows after publication is not a valid substitute.

## Security requirements for remaining endpoints

1. Installation authentication (C5) and authoritative per-content FREE/FULL entitlement before body/metadata/media/ETag response.
2. All exact references must be members of the requested immutable published snapshot. Do not expose arbitrary draft, retired or unapproved content by guessing a revision.
3. Unknown asset IDs, stale bindings and malformed metadata fail closed. No RustFS URLs, pre-signed links or store proofs reach Flutter.
4. An asset shared by multiple CURRENT content bindings must be authorized conservatively; FREE aliasing cannot grant access to FULL content.
5. Store verification remains default deny until real receipts / purchase tokens are validated and persisted, and refund/restore are covered.
6. Backend binary delivery currently buffers whole files. Introduce bounded streaming and max concurrent-byte load qualification before production media scaling.
7. New C5 rotation proof is not a token-reset service: an invalid or revoked credential must not silently reclaim its old installation UUID.

## Required next implementation slices

**API-R2: publication projection** — Introduce a durable, release-versioned immutable projection of root, pack, catalogue and locale/asset refs. Freeze metadata atomically at publication, compute canonical checksums with test vectors derived from Flutter canonicalizer, and expose root+pack+catalogue routes with 200/304/401/403/404, exact checksum acceptance.

**API-R3: assessment** — Add persisted mode, points, skill code and exact published question refs where necessary; do not invent learn/exam mode or point values from unrelated fields. Implement exact test/question endpoints + Flutter decoder contract fixtures.

**API-R4: complete C5/B8** — Test Flutter cold start, Bearer token rotation, 401 recovery, revoked/blocked, purchase restore and server-verified lifetime entitlement. No anonymous fallback after a failed authenticated rotation.

**API-R5: live acceptance** — Boot real Spring backend + PostgreSQL + RustFS, publish a FREE and FULL collection via admin domain, sync Flutter using real network API, confirm exact DTO/ETag/checksum/media, offline reopen, permissions and refetch; confirm exact-SHA CI, including Renderer Acceptance.

**Do not merge to main** until all P0 slices above are accepted. The XML importer and new MVC production UI remain separate workstreams.
