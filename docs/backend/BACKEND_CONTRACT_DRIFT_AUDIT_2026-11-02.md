# Backend Contract Drift Audit — 2026-11-02

Status: closed for Backend B1 baseline, except explicit open questions in `BACKEND_API_CONTRACT_BASELINE.md`.

## Scope

Audited against the production Flutter wire implementation on `feat/learner-product-ui-v1`:

- `mobile/careerspeak_app/lib/data/remote/**`
- `mobile/careerspeak_app/lib/data/remote/dto/**`
- `mobile/careerspeak_app/lib/application/ports/**`
- `mobile/careerspeak_app/lib/app/api_client_providers.dart`
- `mobile/careerspeak_app/lib/app/billing_providers.dart`
- `mobile/careerspeak_app/lib/app/purchase_providers.dart`
- `contracts/*.yaml`
- active architecture/backend/mobile/specification documentation.

Historical audit/roadmap snapshots were not rewritten. Where their aggregate view is stale, the new Backend B1 baseline supersedes them for implementation decisions.

## Drift ledger

| Area | Stale state before audit | Production evidence | Resolution | Authoritative result |
|---|---|---|---|---|
| Aggregate learner API | `learner-api-v1.yaml` omitted catalogue, assessment and purchase-verification endpoints already used by Flutter | production HTTP gateways call `/catalogues/*`, `/assessment/*`, `/purchases/verify` | added `learner-api-v2.yaml` aggregate | `contracts/learner-api-v2.yaml` |
| Pack manifest | aggregate path did not make the full exact-target semantics prominent | Flutter sends mandatory `variant` + `revision` query and verifies code/variant/revision/checksum | documented mandatory query + identity/checksum invariant | learner-api-v2 + C4 |
| Content payload | old aggregate schema omitted `skillCodes` and typed `body` | `ContentPayloadDto` decodes `skillCodes` and vocabulary/interview/topic/phrase/shadowing bodies | aggregate v2 references typed C2 schema | C2 v1 via learner-api-v2 |
| Catalogue kinds | old aggregate enum lacked schema-v2 universal catalogue kinds | Flutter `CatalogueKind` supports vertical sections/presentation/verticals/goals/tracks/collections plus small catalogues | aggregate enum reconciled | learner-api-v2 + C4 v2 |
| Catalogue wire shape | documentation could be read as lifecycle-rich catalogue records | production gateway accepts only `kind`, `revision`, `checksum`, `items` and rejects extra publication/admin keys | exact learner wire shape documented | learner-api-v2 |
| Assessment | component contract existed but aggregate learner API omitted endpoints | production assessment gateway fetches exact practice-test/question revisions | aggregate endpoints added and externally reference C3 schemas | learner-api-v2 + C3 v1 |
| Purchase verification | real HTTP adapter existed but aggregate OpenAPI had no endpoint | production adapter posts provider/productId/purchaseEventId/verificationData and decodes strict verified true/false result | endpoint, provider enum, replay semantics and errors added | learner-api-v2 |
| Media delivery | some older project history discussed object-storage delivery options | current production `HttpAssetByteSource` uses Backend `/media/assets/{assetId}/content`, disables redirects, verifies bytes locally | Backend-stream-only v1 rule reaffirmed | learner-api-v2 + cross-system contract |
| Environment | API URL and mock flags were parsed independently in multiple providers | `api_client_providers`, billing and purchase providers each read build variables separately | centralized typed `AppConfiguration` + `AppEnvironment` + host policy | H3.1 Flutter configuration |
| Release mocks | prior hardening was fail-closed but not environment-aware | release mock billing became unavailable; release purchase verification used HTTP | preserved and integrated with environment policy | H3.1 composition tests |
| Source hierarchy | component contracts were newer than aggregate v1 in several domains | production behavior matched newer component contracts | explicit source-of-truth hierarchy documented | Backend baseline section 2 |
| Backend DTO boundary | older implementation notes could tempt entity-shaped controllers | cross-system architecture requires stable business identities and private DB/storage | explicit `API DTO != JPA Entity` boundary added | Backend baseline section 17 |

## Endpoints reconciled

The production Flutter learner surface is now represented in the aggregate contract:

```text
POST /api/v1/installations
GET  /api/v1/content/manifest
GET  /api/v1/content/packs/{packCode}/manifest?variant=...&revision=...
GET  /api/v1/content/{contentType}/{contentCode}/revisions/{revision}
GET  /api/v1/content/{contentType}/{contentCode}/revisions/{contentRevision}/localizations/{locale}/revisions/{localizationRevision}
GET  /api/v1/catalogues/{kind}/revisions/{revision}
GET  /api/v1/assessment/practice-tests/{practiceTestCode}/revisions/{revision}
GET  /api/v1/assessment/questions/{questionCode}/revisions/{revision}
GET  /api/v1/media/assets/{assetId}/content
POST /api/v1/purchases/verify
```

## Intentionally preserved compatibility

- The transport namespace stays `/api/v1`. `learner-api-v2.yaml` is an aggregate contract-document revision, not a new HTTP major path.
- Root/pack schema v1 remains readable for backward compatibility; schema v2 adds stricter universal-catalogue publication invariants.
- Legacy learning-collection bytes without explicit `accessLevel` remain fail-closed as FULL.
- Existing Flutter installation-auth recovery, publication immutability and media checksum behavior are not weakened.

## Documentation consistency result

Active normative documentation now agrees on these rules:

```text
Flutter -> Backend HTTPS learner API
Backend -> private PostgreSQL/RustFS/Store/TTS integrations
no direct Flutter RustFS/S3 credentials or presigned RustFS URL in learner v1
contentType is the learner content discriminator
catalogue endpoint is /api/v1/catalogues/{kind}/revisions/{revision}
purchase verification is a real Backend boundary outside development mocks
publication identity is exact revision/checksum based and immutable
```

Historical snapshot documents may still contain decisions that were correct at the time they were written. They are not authoritative for Backend B1 when they conflict with `BACKEND_API_CONTRACT_BASELINE.md` or the versioned contracts referenced there.

## Fixed files

- `contracts/learner-api-v2.yaml`
- `docs/backend/BACKEND_API_CONTRACT_BASELINE.md`
- `docs/backend/BACKEND_CONTRACT_DRIFT_AUDIT_2026-11-02.md`
- `docs/mobile/FLUTTER_ENVIRONMENTS.md`
- H3.1 Flutter configuration/composition and tests

## Remaining open questions

Only deployment/product/security values remain open, not DTO or endpoint shape:

1. approved staging and production API DNS names;
2. Backend-managed Store product allowlist lifecycle (current Flutter product: `voxprep_full_unlock`);
3. exact installation-token TTL/rotation duration.

See `BACKEND_API_CONTRACT_BASELINE.md#19-open-backend-contract-questions` for recommendations.
