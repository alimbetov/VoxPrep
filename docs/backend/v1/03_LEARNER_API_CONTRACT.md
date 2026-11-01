# 03 — Learner API Contract

**Status:** FROZEN FLUTTER CONSUMER CONTRACT

This document reflects the API surface already used by production Flutter gateways.

## 1. Anonymous locale configuration

```http
GET /api/v1/configuration/locales?countryCode=KZ
```

Authentication: none.

Response:

```json
{
  "countryCode": "KZ",
  "defaultLocale": "ru",
  "locales": [
    {"code": "ru", "label": "Русский"}
  ]
}
```

Rules:

- `countryCode` is ISO-3166 alpha-2;
- payload fields are explicit and versioned by contract;
- unsupported/malformed payload fails closed in Flutter.

## 2. Installation registration / token issuance

```http
POST /api/v1/installations
```

Authentication: none.

Request:

```json
{
  "installationId": "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
}
```

Response HTTP 200:

```json
{
  "installationToken": "opaque-token"
}
```

Semantics:

- same installationId may register repeatedly;
- each cold bootstrap receives a fresh token;
- backend may reject REVOKED installation;
- operation must be replay-safe and rate-limited.

## 3. Root publication manifest

```http
GET /api/v1/content/manifest
Authorization: Bearer <installationToken>
If-None-Match: <etag>   # optional
```

Allowed success responses:

```text
200 → immutable root manifest
304 → only when request contained a valid If-None-Match
```

Root publication identity is locale-independent.

Root must provide exact revision/checksum membership for all data required to build one coherent learner CURRENT.

## 4. Pack manifest

```http
GET /api/v1/content/packs/{packCode}/manifest?variant={variant}&revision={revision}
```

Authenticated.

Returned identity must exactly match the root target:

```text
packCode
variant
revision
checksum
```

## 5. Universal catalogue payload

```http
GET /api/v1/catalogues/{kind}/revisions/{revision}
```

Authenticated.

Envelope:

```json
{
  "kind": "learning-goals",
  "revision": 14,
  "checksum": "<64 lowercase hex chars>",
  "items": []
}
```

Recognized publication catalogue kinds include the universal hierarchy projections such as:

```text
vertical-sections
verticals
vertical-presentation
learning-goals
learning-tracks
learning-collections
```

No request-specific fields may be injected into this immutable envelope.

## 6. Exact canonical content

```http
GET /api/v1/content/{contentType}/{contentCode}/revisions/{revision}
```

Authenticated.

Returned payload must match the requested exact `contentType + contentCode + revision` and the checksum referenced by the pack manifest.

## 7. Exact localized content

```http
GET /api/v1/content/{contentType}/{contentCode}/revisions/{contentRevision}/localizations/{locale}/revisions/{localizationRevision}
```

Authenticated.

Exact identity:

```text
contentType
contentCode
contentRevision
locale
localizationRevision
checksum
```

Localization does not redefine canonical English/audio identity.

## 8. Assessment

```http
GET /api/v1/assessment/practice-tests/{practiceTestCode}/revisions/{revision}
GET /api/v1/assessment/questions/{questionCode}/revisions/{revision}
```

Authenticated.

PracticeTestRevision must contain deterministic exact QuestionRevision membership/order.

Flutter verifies returned identity/revision/checksum and fails closed on mismatch.

## 9. Learner media bytes

```http
GET /api/v1/media/assets/{assetId}/content
Authorization: Bearer <installationToken>
```

Backend streams bytes directly.

Do not return redirect to object storage.

Relevant statuses:

```text
2xx → stream bytes
401 → installation credential rejected
403 → authenticated but media forbidden
404 → asset unavailable/not published
409 → asset not ready
408 → transient
429 → transient/rate limited
500/502/503/504 → transient backend/storage failure
```

Flutter verifies content size and SHA-256 before publishing a local file as verified.

## 10. Error envelope

JSON error body:

```json
{
  "code": "STABLE_MACHINE_CODE",
  "message": "Safe external message",
  "traceId": "optional",
  "details": {}
}
```

Forbidden in API errors:

```text
raw SQL exceptions
stack traces
RustFS credentials
installation token
filesystem paths
internal secrets
```

## 11. Retry semantics

Safe immutable reads may be retried with bounded backoff.

Mutations require explicit replay safety.

Flutter performs bounded credential recovery on 401. Backend must not depend on infinite client retry.

Use `Retry-After` for 429 where practical.

## 12. Contract evolution

Any incompatible change requires a versioned contract change.

Do not silently:

- add semantic fields into checksum identity;
- change locale/root identity scope;
- replace backend media streaming with redirects;
- reinterpret stable business codes;
- make current endpoints return mutable/latest data instead of exact revisions.