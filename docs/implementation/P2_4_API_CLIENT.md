# P2.4 — Typed API Client Foundation

**Branch:** `feat/p2-flutter-production-adapters`  
**Parent stage:** P2.3 Installation identity + Secure Storage  
**Database schema impact:** none (`CareerSpeakDatabase.schemaVersion = 1`)

## Goal

Introduce one production HTTP transport boundary for Flutter without coupling feature presentation, domain models, or future manifest DTOs to `package:http`.

```text
feature / application adapter
          ↓
       ApiClient
          ↓
      HttpApiClient
          ↓
     package:http
          ↓
 CareerSpeak Backend
```

P2.4 owns transport mechanics only. P2.5 owns manifest DTOs and learner-delivery endpoint contracts.

## Application contract

Framework-independent application types:

```text
ApiRequest
├── method
├── origin-relative path
├── query parameters
├── headers
├── optional JSON body
└── authentication mode

ApiResponse
├── status code
├── normalized immutable headers
├── decoded JSON body
└── traceId

ApiClient
└── Future<Result<ApiResponse>> send(ApiRequest)
```

`package:http` types SHALL NOT leak into `domain/`, `application/`, or `features/`.

## Authentication

Default learner requests use:

```text
ApiAuthentication.installation
        ↓
InstallationCredentialStore
        ↓
InstallationToken
        ↓
Authorization: Bearer <token>
```

Rules:

1. caller-provided `Authorization` is ignored and cannot override managed installation authentication;
2. missing installation token fails locally as `UNAUTHORIZED` before any network request is sent;
3. Secure Storage read failure maps to `CREDENTIAL_STORE_ERROR` and does not leak the platform exception;
4. `ApiAuthentication.none` is available only for explicit unauthenticated bootstrap operations such as future installation registration;
5. P2.4 does not invent the registration endpoint or its request/response DTOs.

## URL and environment boundary

Production composition reads the API origin from:

```text
--dart-define=CAREERSPEAK_API_BASE_URL=https://...
```

The source default is deliberately non-routable:

```text
https://api.careerspeak.invalid
```

`ApiRequest.path` is origin-relative and rejects:

```text
absolute/authority URLs
query embedded in path
fragment embedded in path
. / .. dot segments
```

Query parameters are supplied separately through the typed request contract.

## JSON and errors

The transport decodes successful JSON and maps backend failures into `ApplicationFailure`.

Normative backend envelope:

```json
{
  "code": "CONTENT_NOT_FOUND",
  "message": "Content was not found",
  "traceId": "...",
  "details": {}
}
```

`ApplicationFailure` carries:

```text
code
message
retryable
traceId
details
```

Rules:

1. raw HTTP/platform exceptions do not escape to feature presentation;
2. successful non-empty invalid JSON becomes `API_RESPONSE_INVALID`;
3. `X-Trace-Id` response header takes precedence over body `traceId` when both exist;
4. HTTP `401` always maps to stable mobile code `UNAUTHORIZED`;
5. HTTP `403` always maps to stable mobile code `FORBIDDEN`;
6. a more specific backend 401/403 code is retained in `details.backendCode` for diagnostics/recovery policy;
7. backend-provided safe message/details are preserved when structurally valid.

## Timeout and retry

Default request timeout:

```text
10 seconds
```

Generic automatic retry is intentionally conservative:

```text
GET only
maximum attempts = 3
bounded delays = 200 ms, 400 ms
```

Retryable transport/status failures include:

```text
OFFLINE
TIMEOUT
HTTP 408
HTTP 429
HTTP 500
HTTP 502
HTTP 503
HTTP 504
```

`POST`, `PUT`, `PATCH`, and `DELETE` are never automatically replayed by the generic transport. Future endpoint-specific mutation retries require an explicit idempotency contract.

## Production composition

```text
apiBaseUriProvider
    → CAREERSPEAK_API_BASE_URL

httpClientProvider
    → package:http Client

apiClientProvider
    → HttpApiClient
       + InstallationCredentialStore
```

The HTTP client is owned and closed by the Riverpod provider lifecycle.

## Dependency

```text
http 1.6.0
```

The dependency is pinned in `pubspec.yaml`/`pubspec.lock` for reproducible qualification.

## Explicit non-goals

P2.4 does not add:

```text
installation registration endpoint DTOs
installation token refresh endpoint DTOs
root manifest DTOs
pack manifest DTOs
content DTOs
ContentSyncCoordinator
DownloadManager
AssetResolver
repository production cutover
```

Those belong to subsequent contract/application slices.

## Acceptance

P2.4 is accepted only when one exact clean branch SHA proves all of the following under the normal read-only CI workflow:

1. `ApiClient` is framework-independent and `package:http` is isolated to data/composition;
2. production Riverpod composition selects `HttpApiClient`;
3. managed installation token becomes the Bearer authorization header;
4. caller headers cannot override managed authorization;
5. missing token and Secure Storage failures stop before network transport;
6. explicit unauthenticated requests do not inherit caller-supplied authorization;
7. request path validation prevents leaving the configured API origin;
8. base path, query parameters, headers, and JSON body are encoded deterministically;
9. backend error envelope maps to typed failure with traceId/details preservation;
10. 401/403 are canonicalized to `UNAUTHORIZED`/`FORBIDDEN`;
11. invalid successful JSON becomes a controlled protocol failure;
12. GET retry is bounded and mutations are not automatically replayed;
13. timeout and `ClientException` map to typed failures;
14. feature presentation cannot import the concrete remote adapter;
15. `pubspec.lock`, Dart formatting, Drift generated baseline, `flutter analyze`, and full `flutter test` are green;
16. Drift schema remains version `1` and unchanged;
17. temporary dependency/formatter normalization commits are absent from the accepted branch history.
