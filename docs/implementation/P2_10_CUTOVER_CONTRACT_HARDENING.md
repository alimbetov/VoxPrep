# P2.10.0 — Production Repository Cutover Contract Hardening

**Branch:** `feat/p2-flutter-production-adapters`  
**Parent stage:** P2.9 Real Audio  
**Database schema impact:** none

## Goal

Freeze the seams required before switching learner-facing repositories from mock adapters to production Drift/API adapters.

P2.10.0 deliberately does not introduce `DriftContentRepository` or schema v4 yet. It removes contract ambiguities that would otherwise be baked into that adapter.

## 1. Content identity

Production learner content identity is:

```text
contentCode + contentType
```

Repository lookup therefore uses:

```text
getByIdentity(ContentIdentity)
```

and never `getByCode(String)` for generic learner content.

Generic detail routes carry the same identity:

```text
/content/:type/:code
```

A route with an unknown content type fails closed.

## 2. Exact content payload boundary

The manifest remains a synchronization envelope. It references exact content revisions but does not become a universal learner read model.

P2.10 introduces an explicit payload boundary:

```text
ContentPayloadRef
├── ContentIdentity
├── revision
└── checksum

ContentPayloadGateway
└── fetch(ContentPayloadRef)
```

`ContentPayload` contains the minimum learner-facing projection currently required by `ContentItem`:

```text
title
subtitle
description
category
level
minutes
hasAudio
```

The payload is always bound to one exact `(contentCode, contentType, revision, checksum)` target. Future HTTP adapters must reject a response whose identity, revision, or checksum does not match the requested target.

The expected backend learner endpoint shape is conceptually:

```text
GET /api/v1/content/{contentType}/{contentCode}/revisions/{revision}
```

with installation authentication. The concrete remote adapter is owned by the next implementation slice.

## 3. Installation bootstrap ownership

A fresh installation cannot call authenticated manifest/content endpoints until a backend-issued installation token exists.

The application boundary is now explicit:

```text
InstallationIdentityService
        ↓
InstallationBootstrapService
        ↓
InstallationRegistrationGateway
        ↓
Backend registration adapter (next slice)
```

Bootstrap semantics:

```text
existing id + token
    → reuse

existing/generated id + missing token
    → register once
    → persist returned token

concurrent bootstrap callers
    → one in-flight registration

corrupt token-only state
    → fail closed
```

Network registration is not allowed to delete or rotate an existing installation id merely because the network is unavailable.

## 4. Backend wire DTO boundary

Backend JSON transport types are now explicitly separated from application/domain models:

```text
JSON
  ↓
wire DTO
  ↓
remote mapper
  ↓
application/domain model
```

Current wire DTOs:

```text
ContentPayloadDto
RootContentManifestDto
PackContentManifestDto
ApiErrorDto
InstallationRegistrationRequestDto
InstallationRegistrationResponseDto
```

Rules:

1. `data/remote/dto/**` owns transport shape only;
2. `domain/**`, `application/**`, and `features/**` must not depend on remote DTOs;
3. backend DTO evolution must not force JPA/entity structure into Flutter;
4. shared JSON fixtures are the executable examples for both Flutter decoder tests and future Spring serialization tests;
5. canonical English learner payload remains owned by canonical packs; locale packs contain support/localization deltas and do not duplicate canonical payload rows.

Shared contract fixtures currently cover:

```text
content_payload_v1.json
root_manifest_v1.json
pack_manifest_v1.json
api_error_v1.json
installation_registration_request_v1.json
installation_registration_response_v1.json
```

## 5. Production mock policy

Mock repositories remain legal as explicit widget/acceptance-test overrides while P2.10 is under construction.

Final P2.10 production composition must satisfy:

```text
production dependency graph
    → no MockContentRepository
    → no MockTestRepository

test/preview composition
    → mocks allowed explicitly
```

Assessment production availability is not invented during content cutover. Until the assessment read model is implemented, production composition must use an explicit unavailable/empty assessment adapter rather than silently shipping mock learner data.

## 6. Next implementation order

```text
P2.10.1  schema v4 minimal content read model
P2.10.2  atomic payload staging + CURRENT projection
P2.10.3  DriftContentRepository
P2.10.4  production preferences + translationLocale wiring
P2.10.5  HTTP registration + startup bootstrap
P2.10.6  production composition cutover / remove runtime mocks
P2.10.7  end-to-end production acceptance
```

Before P2.10.5 runtime integration, backend-facing wire contracts should remain stable enough to mirror as Spring records/OpenAPI schemas without leaking backend persistence types into Flutter.

## Acceptance for P2.10.0

1. generic content lookup requires full `ContentIdentity`;
2. generic detail navigation carries both type and code;
3. wrong content type cannot resolve another type's item merely because the code matches;
4. exact content payload contract requires positive revision and SHA-256 checksum;
5. payload projection preserves identity and revision when converted to `ContentItem`;
6. installation bootstrap reuses existing credentials;
7. missing token invokes registration and persists the returned token;
8. concurrent bootstrap callers coalesce into one registration;
9. backend JSON is decoded through explicit remote wire DTO boundaries;
10. shared contract fixtures decode into the same application semantics as inline contract tests;
11. remote DTOs do not leak into domain/application/feature layers;
12. no Drift schema change occurs;
13. existing adaptive acceptance remains green;
14. format, analyze, codegen baseline, and full test suite are green on one exact SHA.
