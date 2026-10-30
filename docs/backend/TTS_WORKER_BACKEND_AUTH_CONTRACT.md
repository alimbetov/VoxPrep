# CareerSpeak — Backend Contract for TTS Worker Authentication

**Status:** Normative W2 backend contract  
**Applies to:** CareerSpeak v0.9+  
**Branch:** `feat/tts-worker-backend-http`

## Decision

For MVP the TTS Worker uses one deployment-managed static `WORKER_TOKEN`.

Worker startup configuration:

```text
BASE_URL
WORKER_TOKEN
WORKER_ID=${HOSTNAME}
```

Every protected Worker request sends the token in the HTTP header:

```http
Authorization: Bearer <WORKER_TOKEN>
```

Backend reads the Bearer value and compares it with the configured backend secret.

No token issuance endpoint is required.

No JWT, TTL, refresh token, bootstrap token, worker session table, OAuth server, Keycloak, logout or revocation API is required for MVP.

## Backend configuration

Recommended configuration:

```text
TTS_WORKER_TOKEN=<deployment secret>
```

The Worker receives the corresponding value as:

```text
WORKER_TOKEN=<deployment secret>
```

The token MUST be a strong random deployment secret and MUST differ between environments.

## Protected API boundary

The static Worker token protects only the Worker API namespace:

```text
/internal/v1/tts/**
```

Examples:

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{jobId}/heartbeat
POST /internal/v1/tts/jobs/{jobId}/output
POST /internal/v1/tts/jobs/{jobId}/fail
GET  /internal/v1/tts/models/{voiceModelId}/model
GET  /internal/v1/tts/models/{voiceModelId}/config
```

A valid Worker token authenticates the Worker process only. It does not replace job ownership validation.

For job-specific mutation Backend still validates:

```text
jobId
workerId
leaseToken
leaseUntil
job status
```

## Backend validation

The backend security check is intentionally simple:

```text
read Authorization header
→ require Bearer scheme
→ extract token
→ constant-time compare with TTS_WORKER_TOKEN
→ allow request when equal
→ otherwise return 401
```

Recommended responses:

```text
missing token  → 401 Unauthorized
wrong token    → 401 Unauthorized
valid token    → continue to endpoint/domain validation
```

The comparison should be constant-time when practical.

## Secret handling

Backend and Worker MUST NOT log:

```text
WORKER_TOKEN
Authorization header
```

The token MUST NOT be committed to Git or baked into the Docker image.

Production communication uses HTTPS.

The Worker does not receive:

```text
ADMIN credentials
learner installation credentials
PostgreSQL credentials
RustFS credentials
```

## Rotation

Token rotation is deployment-driven and intentionally simple:

```text
1. generate a new strong token
2. update TTS_WORKER_TOKEN on Backend
3. update WORKER_TOKEN in Worker deployment configuration
4. restart/redeploy Worker
```

If zero-downtime rotation becomes necessary later, dual-token grace support may be added then. It is not part of MVP.

## Spring Boot implementation boundary

A minimal implementation can use one small request filter/interceptor for `/internal/v1/tts/**`.

Conceptually:

```text
TtsWorkerAuthenticationFilter
    ↓
read Authorization: Bearer ...
    ↓
compare with configured TTS_WORKER_TOKEN
    ↓
allow / reject 401
```

No authentication repository or token database is required.

## Acceptance criteria

W2 authentication is accepted when automated tests prove:

```text
valid WORKER_TOKEN allows Worker API request
missing token returns 401
wrong token returns 401
token is checked only for /internal/v1/tts/**
valid token does not bypass lease validation
WORKER_TOKEN never appears in logs
no DB/token-service dependency is required
```

## Final invariant

```text
WORKER_TOKEN authenticates the Worker.
leaseToken proves ownership of one claimed TTS job.
Backend remains authoritative for job state and persistence.
```
