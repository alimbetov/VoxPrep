# C5 — Installation + External Security Contract

**Status:** FROZEN TARGET MODEL  
**Scope:** Flutter installation identity, backend-issued learner credential, centralized HTTP authentication and bounded authentication recovery.  
**Non-goals:** user accounts, email/password login, OAuth/OIDC identity platform, refresh-token flow.

## 1. Core decision

CareerSpeak authenticates a Flutter installation, not a human account.

```text
installationId = stable installation identity
token          = temporary backend-issued session credential
```

The token is **not** a permanent application secret. A fresh token is issued during every application bootstrap and becomes the only learner Bearer credential used by the centralized HTTP client for that runtime session.

## 2. Bootstrap lifecycle

Every cold application bootstrap MUST execute this flow even when Secure Storage already contains a previous token:

```text
APP START
   ↓
InstallationIdentity.getOrCreate()
   ↓
POST /api/v1/installations
   ↓
Backend registers/recognizes installationId
   ↓
Backend issues a fresh installationToken
   ↓
TokenStore.replace(newToken)
   ↓
Authenticated ApiClient becomes READY
   ↓
repositories / sync / content / progress
```

Rules:

1. `installationId` is generated once per installation and preserved in platform Secure Storage.
2. Bootstrap MUST NOT treat a previously stored token as sufficient to skip token issuance.
3. `POST /api/v1/installations` is the bootstrap/session-issuance boundary and is safe to retry according to its endpoint-specific idempotency policy.
4. Every successful bootstrap response returns a fresh token for the same stable installation identity.
5. The newly issued token atomically replaces the previous token in `TokenStore`.
6. Business repositories and features never read, persist or pass the token directly.

## 3. Centralized HTTP authentication

All authenticated learner API calls use one managed HTTP boundary:

```text
feature / repository
       ↓
     ApiClient
       ↓
AuthenticatedHttpClient
       ↓
TokenStore.current
       ↓
Authorization: Bearer <current-token>
       ↓
CareerSpeak Backend
```

Invariants:

- callers cannot provide or override `Authorization`;
- the centralized HTTP client reads the current token;
- no feature-specific client may own its own learner token;
- token values must never be logged;
- a missing current token fails locally as unauthorized rather than sending an unauthenticated learner request.

## 4. Token rotation semantics

A successful bootstrap issuance rotates the learner credential for that installation.

```text
installationId remains stable
old token      -> superseded/revoked
new token      -> current
```

Backend SHOULD store a verifier/hash rather than a recoverable plaintext token where practical.

The token may have a bounded server-defined lifetime, but Flutter does not use a refresh token. Normal renewal is always performed by repeating the installation bootstrap/session issuance with the stable `installationId`.

## 5. Bounded 401 recovery

A legitimate installation credential rejection is recoverable exactly once for a logical request/startup operation:

```text
authenticated request
       ↓
      401
       ↓
issue fresh token using installationId
       ↓
TokenStore.replace(newToken)
       ↓
retry original request ONCE
       ↓
second 401
       ↓
FAIL CLOSED
```

Rules:

1. only an installation-authentication `401` may trigger this recovery;
2. renewal is attempted at most once per logical request/recovery cycle;
3. parallel 401s MUST be single-flight/coalesced so they do not create a token-rotation storm;
4. the original request is retried at most once after successful renewal;
5. a second authentication failure is returned to the application and MUST NOT loop;
6. `installationId` is preserved across token recovery;
7. a revoked/disabled installation may fail renewal and remains fail-closed.

## 6. Secure Storage ownership

Platform Secure Storage owns installation security material:

```text
installationId
current installationToken
```

`installationId` is long-lived for the installation. `installationToken` is replaceable and disposable.

A token left from an earlier process may be read for diagnostics/recovery state, but normal cold bootstrap still obtains a fresh token before authenticated backend work starts.

## 7. Backend installation state

The minimum backend installation record is conceptually:

```text
Installation
- installationId
- status: ACTIVE | REVOKED
- currentTokenVerifier / equivalent credential state
- createdAt
- lastSeenAt
- tokenIssuedAt
```

Persistence shape is not part of the wire contract.

Backend requirements:

- registration/session issuance is rate-limited;
- revoked installations cannot obtain a valid learner token until backend policy explicitly allows it;
- issuance/rotation is auditable without logging token plaintext;
- token comparison is constant-time where applicable;
- token rotation and installation status changes are transactionally consistent.

## 8. API contract

Bootstrap endpoint:

```http
POST /api/v1/installations
Content-Type: application/json
```

Request:

```json
{
  "installationId": "stable-installation-id"
}
```

Response:

```json
{
  "installationToken": "opaque-backend-issued-token"
}
```

The wire shape stays intentionally small. Platform/app metadata may be added later only for a concrete product or compatibility requirement.

## 9. Explicitly rejected model

C5 does not use:

```text
email/password learner login
user account registration
OAuth authorization code flow
OIDC provider
refresh token
static token compiled into Flutter
per-feature Bearer token handling
"reuse stored token forever" bootstrap
unbounded 401 retry
```

## 10. Acceptance criteria

C5 is accepted only when cross-system tests prove:

1. first launch creates one `installationId` and obtains a token;
2. next cold launch preserves the same `installationId` but obtains a different/current token;
3. successful bootstrap replaces the token used by all subsequent authenticated requests;
4. caller code cannot override managed `Authorization`;
5. a valid token authorizes learner endpoints;
6. a superseded/revoked token is rejected according to backend policy;
7. one `401` causes one single-flight token re-issuance and one request retry;
8. a repeated `401` fails closed without an authentication loop;
9. concurrent `401` responses do not cause multiple competing token rotations;
10. no token value appears in logs, traces or application failures;
11. revoked installation renewal fails closed;
12. no learner account/password/refresh-token infrastructure is introduced.

## 11. Architectural consequence

The security boundary is therefore:

```text
stable installation identity
          +
fresh bootstrap-issued token
          +
centralized managed HTTP authentication
          +
one bounded 401 recovery
```

This is the normative C5 learner-security model for Backend and Flutter implementation.