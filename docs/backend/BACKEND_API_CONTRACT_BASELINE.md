# Backend API Contract Baseline

Status: **Normative backend-readiness baseline for Backend B1**  
Applies to: Flutter production client, Spring Boot Backend, Backend-owned PostgreSQL/RustFS boundaries, Store verification, TTS integration boundary.  
Transport namespace: `/api/v1`  
Aggregate OpenAPI: `contracts/learner-api-v2.yaml`

## 1. Scope

This document is the single starting point for Spring Boot Backend design. It reconciles the production Flutter wire implementation with the versioned C1–C5 contracts and freezes the public learner-facing HTTP surface before Backend B1.

It does **not** define JPA entities, Backend tables, RustFS layout, Store SDK implementation, or TTS Worker implementation.

## 2. Source-of-truth contracts

Priority for new Backend work:

1. `contracts/learner-api-v2.yaml` — aggregate public HTTP/wire contract.
2. `docs/architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md` — cross-system invariants and security zones.
3. Component contracts:
   - `contracts/c2-content-catalog-v1.yaml` — typed content bodies;
   - `contracts/c2-content-catalog-v3.yaml` — collection access/member semantics;
   - `contracts/c2-content-audio-v1.yaml` — learner audio metadata;
   - `contracts/c3-assessment-v1.yaml` — immutable assessment payloads/scoring;
   - `contracts/c4-catalogue-publication-v2.yaml` — schema-v2 universal catalogue/publication rules;
   - `contracts/content-cover-v1.yaml` — cover asset role/media semantics;
   - `contracts/locale-configuration-v1.yaml` — locale configuration/fallback semantics.
4. Flutter production wire implementation under `mobile/careerspeak_app/lib/data/remote/**` and `lib/application/ports/**`.
5. Backend implementation notes and historical audit/roadmap documents.

`contracts/learner-api-v1.yaml` remains a compatibility snapshot of an earlier aggregate surface. It is superseded for new Backend B1 design by `learner-api-v2.yaml`; the HTTP path namespace intentionally remains `/api/v1` because the added endpoints/schema corrections align already-shipped additive Flutter behavior rather than introducing a transport breaking change.

If a future versioned contract and Flutter production behavior diverge, do not silently change Flutter. Determine intended semantics, update the contract deliberately and add a qualification test.

## 3. Security model

```text
/admin/**           -> ADMIN authenticated Backend surface
/api/v1/installations -> anonymous registration/re-registration
/api/v1/**          -> installation bearer token unless explicitly anonymous
/internal/v1/tts/** -> worker authentication; never exposed to Flutter
RustFS/PostgreSQL   -> Backend private security zone
```

Flutter sends `Authorization: Bearer <installationToken>` for authenticated learner endpoints. The token is Backend-issued and stored in platform secure storage. One credential-specific 401 may trigger bounded re-registration/retry through the existing Flutter auth-recovery client; repeated rejection fails closed.

Flutter also sends validated `Accept-Language` context. Root publication identity is locale-independent.

## 4. Endpoint matrix

| Method | Path | Auth | Request DTO | Response DTO | Identity/revision semantics | Contract |
|---|---|---|---|---|---|---|
| POST | `/api/v1/installations` | none | `InstallationRegistrationRequest` | `InstallationRegistrationResponse` | `installationId` is stable device installation identity; re-registration is idempotent | learner-api-v2 |
| GET | `/api/v1/content/manifest` | installation | none; optional `If-None-Match` | `RootContentManifest` or 304 | root is immutable by schemaVersion + contentVersion + checksum; ETag is transport validator | learner-api-v2, C4 |
| GET | `/api/v1/content/packs/{packCode}/manifest?variant={variant}&revision={revision}` | installation | path/query | `PackContentManifest` | exact root-owned pack target; response code/variant/revision/checksum must match root ref | learner-api-v2, C4 |
| GET | `/api/v1/content/{contentType}/{contentCode}/revisions/{revision}` | installation | path | `ContentPayload` | exact immutable canonical revision/checksum | learner-api-v2, C2 |
| GET | `/api/v1/content/{contentType}/{contentCode}/revisions/{contentRevision}/localizations/{locale}/revisions/{localizationRevision}` | installation | path | `LocalizedContentPayload` | exact locale projection owned by exact canonical revision | learner-api-v2, locale |
| GET | `/api/v1/catalogues/{kind}/revisions/{revision}` | installation | path | `CataloguePayload` | exact root-owned kind + revision + checksum; response contains only publication fields | learner-api-v2, C2/C4 |
| GET | `/api/v1/assessment/practice-tests/{practiceTestCode}/revisions/{revision}` | installation | path | `PracticeTestRevision` | exact immutable assessment revision/checksum | learner-api-v2, C3 |
| GET | `/api/v1/assessment/questions/{questionCode}/revisions/{revision}` | installation | path | `QuestionRevision` | exact immutable question revision | learner-api-v2, C3 |
| GET | `/api/v1/media/assets/{assetId}/content` | installation | path | binary stream | assetId must belong to learner-deliverable publication; Flutter verifies declared size/checksum | learner-api-v2, media |
| POST | `/api/v1/purchases/verify` | installation | `PurchaseVerificationRequest` | `PurchaseVerificationResponse` | `purchaseEventId` is replay/idempotency identity | learner-api-v2 |

No Flutter learner endpoint may expose PostgreSQL numeric IDs when a stable business code exists.

## 5. Request/response DTO matrix

| Flutter DTO/domain model | Backend API DTO | Required identity | Authoritative schema | Notes |
|---|---|---|---|---|
| installation registration mapper | `InstallationRegistrationRequest` | installationId | learner-api-v2 | non-blank; registration anonymous |
| installation registration decoder | `InstallationRegistrationResponse` | installationToken | learner-api-v2 | opaque token |
| `ApiErrorDto` | `ApiError` | code | learner-api-v2 | message safe; traceId nullable; details optional map |
| `RootContentManifestDto` | `RootContentManifest` | schemaVersion + contentVersion + checksum | learner-api-v2/C4 | immutable root |
| `PackRevisionDto` | `PackRevisionRef` | code + variant + revision + checksum | learner-api-v2 | exact pack target |
| `PracticeTestRevisionDto` | `PracticeTestRevisionRef` | practiceTestCode + revision + checksum | learner-api-v2/C3 | root membership |
| `CatalogueRevisionDto` | `CatalogueRevisionRef` | kind + revision + checksum | learner-api-v2/C4 | root membership |
| `LocaleFallbackRuleDto` | `LocaleFallbackRule` | locale | learner-api-v2/locale | fallback order is semantic |
| `ContentTombstoneDto` | `ContentTombstone` | contentCode + contentType | learner-api-v2/C4 | revision is audit/integrity metadata |
| `PackContentManifestDto` | `PackContentManifest` | code + variant + revision + checksum | learner-api-v2 | canonical checksum required |
| `PackContentRefDto` | `PackContentRef` | contentCode + type + revision + checksum | learner-api-v2 | immutable membership |
| `LocalizedContentRefDto` | `LocalizedContentRef` | canonical revision + locale + localizationRevision + checksum | learner-api-v2 | immutable locale projection |
| `ManifestAssetDescriptorDto` | `ManifestAssetDescriptor` | assetId + checksumSha256 | learner-api-v2 | deliveryKey Backend metadata only |
| `ContentAssetRefDto` | `ContentAssetRef` | content identity + exact revision + assetId + role | learner-api-v2 | `coverImage` optional/max one per exact content revision |
| `ContentPayloadDto` | `ContentPayload` | contentCode + contentType + revision + checksum | C2 v1 via learner-api-v2 | includes `skillCodes` and typed `body` |
| `VocabularyBodyDto` | `VocabularyBody` | body kind | C2 v1 | immutable typed body |
| `InterviewBodyDto` | `InterviewBody` | body kind | C2 v1 | immutable typed body |
| `TopicBodyDto` | `TopicBody` | body kind | C2 v1 | ordered sections |
| `PhraseBodyDto` | `PhraseBody` | body kind | C2 v1 | immutable typed body |
| `ShadowingBodyDto` | `ShadowingBody` | body kind | C2 v1 | segment order/time semantics |
| localized payload DTO | `LocalizedContentPayload` | canonical identity + locale revision + checksum | learner-api-v2 | nullable localized copy fields; at least one meaningful localized field by domain validation |
| `CataloguePayload` wire map | `CataloguePayload` | kind + revision + checksum | learner-api-v2/C2/C4 | only `kind/revision/checksum/items`; no lifecycle/admin fields |
| assessment decoder model | `PracticeTestRevision` | code + revision + checksum | C3 v1 | ordered question refs |
| assessment decoder model | `QuestionRevision` | code + revision + checksum | C3 v1 | `singleChoice` in MVP |
| purchase event | `PurchaseVerificationRequest` | provider + productId + purchaseEventId | learner-api-v2 | verificationData opaque/sensitive |
| `PurchaseVerification` | `PurchaseVerificationResponse` | verified + accepted entitlement fields | learner-api-v2 | rejected response is `{verified:false}` |

### Required/nullable conventions

- Required means the JSON key must exist.
- Nullable means the key may exist with JSON null; it is not equivalent to omitted unless schema says so.
- `additionalProperties: false` is the default for immutable public DTOs unless an extension map is deliberately part of the contract.
- Checksums are lowercase 64-character SHA-256 hex strings.
- Revisions are positive integers and are never rewritten in place.

## 6. Error envelope

Normative JSON error:

```json
{
  "code": "CONTENT_NOT_FOUND",
  "message": "Content was not found",
  "traceId": "optional-trace-id",
  "details": {}
}
```

`code` and `message` are required. `traceId` is nullable/optional in transport handling. `details` contains safe structured metadata only. Raw SQL, RustFS paths/credentials, Store proofs, stack traces and internal worker secrets must never be returned.

Flutter normalizes 401 to `UNAUTHORIZED`, 403 to `FORBIDDEN`, and marks 408/429/500/502/503/504 retryable. Safe GETs may use bounded retry; mutations require explicit replay/idempotency semantics.

## 7. Publication model

Backend publishes one coherent immutable learner root. The consistency boundary includes hierarchy/catalogues, exact content revisions, exact practice-test/question dependencies, localization refs and asset metadata.

```text
validate candidate
-> freeze exact refs/revisions/checksums
-> allocate never-reused contentVersion
-> publish immutable root
-> atomically switch Backend CURRENT
```

Flutter stages the complete candidate and switches its local Drift CURRENT atomically only after validation succeeds. Failed/corrupt sync preserves last-known-good CURRENT.

Root schema v2 universal catalogue kinds:

- `vertical-sections`
- `verticals`
- `vertical-presentation`
- `learning-goals`
- `learning-tracks`
- `learning-collections`

Additional supported small catalogues may coexist in the same root.

## 8. Revision/checksum rules

- Stable business identity and exact revision are separate concepts.
- Published revision bytes are immutable.
- A changed payload, collection order, accessLevel, membership or other canonical publication field requires a new revision and checksum.
- Root checksum and pack checksum are canonical immutable-body SHA-256 digests; Flutter recalculates them and rejects mismatch.
- Root ETag is transport metadata. `304` is valid only when the request carried a validator.
- Exact payload responses must match the identity/revision/checksum referenced by their owner. Mismatch is fail-closed.
- `contentVersion`/publication identity is never reused.

## 9. Catalogue semantics

Hierarchy:

```text
Vertical -> LearningGoal -> LearningTrack -> LearningCollection
                                     -> exact ContentRevision / PracticeTestRevision members
```

`LearningCollection.accessLevel` is explicit and only `FREE|FULL` is valid. Legacy collection bytes missing `accessLevel` are interpreted fail-closed as FULL. Access is never inferred from sort order, title, locale, position or another presentation field.

Collection members are ordered by contiguous `position` from zero and reference exactly one content or practice-test target. Reordering changes publication bytes and therefore revision/checksum.

Catalogue HTTP payload contains only `kind`, `revision`, `checksum`, `items`. Backend lifecycle fields do not leak into learner catalogue DTOs.

## 10. Content semantics

Supported content types:

- `vocabulary`
- `interview`
- `topic`
- `phrase`
- `shadowing`

Canonical content uses the typed C2 body discriminator `kind`. `ContentPayload` includes `skillCodes` and `body`; the older aggregate v1 schema that omitted them is superseded.

Canonical English content and shared media are not duplicated into localized projections.

## 11. Assessment semantics

MVP question kind is `singleChoice`. Practice tests are immutable exact revisions containing ordered exact question refs and deterministic scoring inputs. Flutter may score locally from immutable contracted bytes; no answer-upload endpoint is introduced in this slice.

PracticeTest does not directly own Content in MVP. Publication membership and cross-vertical ownership are validated before CURRENT publication.

## 12. Media semantics

Only learner media delivery path:

```text
Flutter -> GET /api/v1/media/assets/{assetId}/content
        -> Backend validates installation/publication eligibility
        -> Backend resolves FileAsset + deliveryKey
        -> Backend storage adapter reads private RustFS
        -> Backend streams bytes
        -> Flutter verifies size + SHA-256
        -> atomic verified local file
```

Flutter never receives RustFS/S3 endpoint, bucket credentials, storage credentials, internal object key as URL, or presigned RustFS URL in v1. `deliveryKey` may appear in immutable publication metadata but is never a Flutter locator or authorization input. Backend v1 does not redirect media to object storage.

## 13. Installation identity

No mandatory learner account exists in v1. Flutter generates/persists an installationId and obtains an opaque installationToken. Registration/re-registration is idempotent for the same installation identity.

Credential recovery on 401 clears/replaces the rejected token only; installationId and learner state remain intact.

## 14. Purchase verification

Endpoint: `POST /api/v1/purchases/verify` with installation bearer authentication.

Request:

```json
{
  "provider": "GOOGLE_PLAY",
  "productId": "voxprep_full_unlock",
  "purchaseEventId": "store-event-id",
  "verificationData": "opaque-store-proof"
}
```

Providers: `GOOGLE_PLAY`, `APP_STORE`.

`productId` is Store product identity. Current Flutter full-unlock product id is `voxprep_full_unlock`; Backend configuration must treat allowed Store product IDs as deployment/product configuration rather than accepting arbitrary entitlement mapping.

`purchaseEventId` is the replay/idempotency identity. Same event + same semantic request is replay-safe and returns the previously processed result. Reuse with a different provider/product/proof fingerprint is a 409 conflict. The Backend may store a proof fingerprint, but must not unnecessarily persist or log plaintext `verificationData`.

Verified:

```json
{
  "verified": true,
  "accessLevel": "FULL",
  "verifiedAt": "2026-11-02T10:00:00Z"
}
```

Rejected:

```json
{
  "verified": false
}
```

`verified=false` is a successfully processed negative verification and therefore HTTP 200, not an exception. `verifiedAt` is canonical UTC. 429 and 503 are retryable. 400 is malformed request; 401 invalid installation token; 403 installation not permitted; 409 only semantic replay conflict; 500 server failure.

No Google Play Developer API or Apple Store Server API implementation is part of this slice.

## 15. Localization

Root identity is locale-independent. `Accept-Language` supplies learner request context but must not change root contentVersion/checksum/ETag membership.

Fallback order is Backend-owned and explicitly delivered; Flutter does not invent fallback chains from BCP-47 tags. Canonical English/audio may be reused when exact identities are unchanged.

## 16. Environment/deployment contract

Flutter uses typed `AppEnvironment` with `development|staging|production` and centralized `AppConfiguration`.

Build/runtime inputs:

- `CAREERSPEAK_APP_ENV`
- `CAREERSPEAK_API_BASE_URL`
- `CAREERSPEAK_MOCK_BILLING`
- `CAREERSPEAK_MOCK_PURCHASE_VERIFICATION`
- `CAREERSPEAK_STAGING_API_HOSTS` — comma-separated host allowlist, no URLs
- `CAREERSPEAK_PRODUCTION_API_HOSTS` — comma-separated host allowlist, no URLs

Default environment: debug/profile -> development; release -> production. Missing API URL creates a network-disabled configuration; any network composition then fails before an HTTP call.

Staging and production require HTTPS and a host classified for that environment. Production rejects localhost, loopback/private/link-local addresses, `.local`, `.invalid`, `.test` and `.example` placeholders. Staging/prod host sets must not overlap.

Production/release mock flags never grant FULL. Purchase verification outside non-release development always uses the real HTTP verification boundary.

API base URL and hostnames are configuration, not secrets. Store verification credentials, Backend credentials and RustFS credentials must never be embedded in Flutter.

## 17. Backend implementation boundaries

Target conceptual architecture:

```text
Flutter
  -> HTTPS
Spring Boot modular monolith
  -> PostgreSQL
  -> private RustFS/object storage
  -> Google/Apple Store verification adapters
  -> TTS Worker internal APIs
```

Suggested Backend modules derived from contracts:

- installation
- catalogue
- content
- publication
- assessment
- media
- access/monetization
- localization
- tts
- admin

Backend API DTO != JPA Entity. Public business codes/revisions are mapped explicitly to persistence entities. Flutter must not receive DB entity shapes, internal TTS model paths, Worker lease secrets, RustFS credentials or Backend storage credentials.

## 18. Explicit non-goals

This baseline does not implement:

- Spring Boot Backend or Backend database schema;
- real Google Play verification;
- Apple Store Server API integration;
- new learner UI/domain/navigation features;
- Flutter schema v19;
- microservice decomposition;
- direct RustFS integration or presigned RustFS delivery in Flutter.

## 19. OPEN BACKEND CONTRACT QUESTIONS

### Q1 — Production/staging DNS names

Real DNS hosts are not yet frozen. Deployment must provide `CAREERSPEAK_STAGING_API_HOSTS` and `CAREERSPEAK_PRODUCTION_API_HOSTS` together with `CAREERSPEAK_API_BASE_URL`. Recommendation: freeze one canonical API hostname per environment before first staging release and enforce it in CI/release configuration.

### Q2 — Store product configuration lifecycle

Flutter currently uses `voxprep_full_unlock`. Recommendation: keep that as the current public Store product identifier, but configure Backend provider/product allowlists outside code so Store listing changes do not require changing public verification DTO shape.

### Q3 — Installation token lifetime/rotation values

Behavior is contracted (opaque token, re-registration, bounded 401 recovery), but exact TTL/rotation duration is not frozen here. Recommendation: define TTL as Backend security configuration and expose no TTL-derived authorization assumptions to Flutter.

No other open question blocks Backend B1 domain/module design.

## 20. Backend implementation readiness checklist

- [x] Learner endpoint paths/methods fixed.
- [x] Installation authentication boundary fixed.
- [x] Error envelope fixed.
- [x] Root/pack publication identity fixed.
- [x] Universal catalogue kind set fixed for schema v2.
- [x] Typed content payload fixed.
- [x] Assessment payload endpoints fixed.
- [x] Media delivery is Backend-stream only.
- [x] Purchase verification request/response and replay semantics fixed.
- [x] Environment parsing/HTTPS/host policy fixed in Flutter.
- [x] Release mocks fail closed by composition.
- [x] Backend DTO/JPA separation fixed as architecture rule.
- [ ] Real staging/production DNS values supplied by deployment.
- [ ] Backend B1 implementation created — deliberately outside this slice.
