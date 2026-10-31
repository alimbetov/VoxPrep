# C4 — Atomic Publication Contract

**Status:** FROZEN MVP CONTRACT  
**Scope:** Backend publication transaction, immutable learner delivery identity, Flutter synchronization continuity, and C5 security-boundary alignment.  
**Related contracts:**

- `contracts/learner-api-v1.yaml`
- `docs/backend/C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`
- `docs/backend/FLUTTER_BACKEND_CONTRACT_GAP_REMEDIATION_PLAN.md`

## 1. Goal

C4 defines **what is published** and the exact immutable identity by which Flutter can synchronize it safely.

C5 defines **whether a particular installation may access that published data**.

These responsibilities MUST remain independent.

```text
C4 Publication identity
        !=
C5 Installation identity
        !=
C5 Installation token/session
```

Changing, reissuing, revoking, or replacing an installation token MUST NOT change publication identity.

---

## 2. Atomic publication boundary

Backend publication is one atomic transaction that makes one complete, internally consistent snapshot visible to learner clients.

Conceptually:

```text
Admin draft state
      ↓
validate complete publication graph
      ↓
atomic publish transaction
      ↓
PublicationSnapshot N
      ├── contentVersion
      ├── root checksum / ETag identity
      ├── exact pack revision refs
      ├── exact canonical payload revision refs
      ├── exact localization revision refs
      ├── exact assessment/catalogue revision refs where applicable
      ├── stable asset descriptors
      └── tombstones
```

A partially published graph MUST never become learner-visible.

The backend may use tables/aggregates different from this conceptual model, but externally visible publication semantics MUST be equivalent.

---

## 3. Publication identity

The publication snapshot has deterministic immutable identity.

At minimum the learner-visible identity includes:

```text
contentVersion
root checksum
root ETag semantics
exact pack revisions + checksums
exact content revisions + checksums
exact localization revisions + checksums
stable asset identity + checksums
```

For one published snapshot, these values MUST be stable for its lifetime.

### 3.1 Security-independent identity invariant

The following MUST NOT participate in publication checksum, ETag, revision identity, canonical serialization, or cache identity:

```text
installationId
installation token
Authorization header
token issuance time
token expiration time
token rotation generation
request session
request trace id
signed-media URL expiration
security decision metadata
```

Therefore two authorized installations reading the same exact publication resource receive the same immutable publication representation, subject only to transport metadata that is explicitly outside the hashed body.

---

## 4. Learner truth path

For MVP there is one learner content truth path:

```text
Backend
  root manifest
      ↓
  exact pack manifest revisions
      ↓
  exact immutable payload/localization/catalogue/assessment revisions
      ↓
Flutter validation
      ↓
atomic Drift projection
      ↓
local browsing/search/pagination
```

Remote collection/list APIs are not a second independently versioned learner truth source.

Flutter SHALL use local Drift for learner browsing, filtering, searching and pagination after synchronization.

---

## 5. Stable media identity

Publication snapshots MUST reference media through stable identity, not through session-bound or expiring access material.

Normative descriptor shape remains conceptually:

```text
assetId
checksumSha256
deliveryKey
sizeBytes
mediaType
requiredOffline
```

### 5.1 Forbidden in immutable publication bodies

The following MUST NOT be embedded as immutable publication identity:

```text
short-lived signed URL
session-bound download URL
Authorization token
installation-specific media path
credential-bearing query parameters
```

### 5.2 Delivery separation

If C5 selects protected media delivery, the flow is:

```text
C4 stable deliveryKey
        ↓
C5 authorized media-resolution request
        ↓
short-lived access grant / signed URL if required
        ↓
media download
        ↓
C4 checksum validation
```

The generated access grant is ephemeral and outside `PublicationSnapshot` identity.

C4 owns:

```text
asset identity
asset checksum
stable delivery key
publication membership
```

C5 owns:

```text
whether installation may resolve/download asset
authorization policy
access grant lifetime
signed URL policy if used
rate limiting / abuse controls
```

---

## 6. Security lifecycle during synchronization

C5 freezes the learner model as:

```text
installationId = stable installation identity
token          = temporary backend-issued credential
```

A token may therefore be replaced while Flutter is synchronizing one immutable publication snapshot.

That MUST NOT invalidate the selected publication.

Example:

```text
PublicationSnapshot v42
        ↓
GET root using token T1
        ↓
GET pack A using token T1
        ↓
GET exact payload X
        ↓
401 TOKEN_REJECTED
        ↓
C5 single-flight token reissue
T1 → T2
        ↓
retry GET exact payload X once
        ↓
validate same revision/checksum
        ↓
continue v42 synchronization
        ↓
commit local atomic projection
```

Credential replacement is a transport/security recovery event, not a publication transition.

---

## 7. Exact-resource retry invariant

After bounded C5 `401` recovery, Flutter MUST retry the **same exact idempotent resource**.

For example:

```text
/api/v1/content/{type}/{code}/revisions/{revision}
```

The retry MUST NOT silently switch to a newer `CURRENT` resource or a different publication snapshot.

For the retried resource, all publication identity values MUST remain unchanged:

```text
contentVersion unchanged
revision unchanged
checksum unchanged
ETag meaning unchanged
asset checksum unchanged
```

If the exact resource is no longer retrievable, checksum identity changes unexpectedly, or the second request is again unauthorized, synchronization fails closed and the current local committed projection remains intact.

---

## 8. Concurrent publication while client is syncing

A newer publication may become current while Flutter is still synchronizing an older snapshot.

Example:

```text
Flutter selected v42
        ↓
Backend publishes v43
        ↓
Flutter continues exact v42 resource retrieval
```

The backend MUST preserve exact immutable revision retrieval for the retention window required by the mobile synchronization/recovery contract.

A change in the backend's `CURRENT` publication MUST NOT mutate exact v42 resources.

Flutter may discover v43 on its next root refresh, but MUST NOT mix v42 and v43 inside one atomic local projection transaction.

---

## 9. Failure semantics

C4 synchronization remains fail-closed.

The current committed local projection MUST remain usable if any of the following occurs before final commit:

```text
authentication recovery fails
second 401 occurs
required exact resource is missing
revision/checksum mismatch occurs
asset checksum mismatch occurs
network fails beyond retry policy
publication graph is incomplete
projection transaction fails
```

Partial next-publication state may exist only in explicitly staged/recoverable synchronization structures; it MUST NOT become learner-visible as the committed `CURRENT` projection.

---

## 10. C4/C5 ownership boundary

### C4 owns

```text
PublicationSnapshot transaction boundary
contentVersion issuance
immutable revision identities
checksums / canonical publication identity
root + pack manifest consistency
stable asset descriptors
exact-resource retention semantics
atomic Flutter projection compatibility
publication fail-closed behavior
```

### C5 owns

```text
installation identity
token issuance and reissuance
token replacement storage
Authorization header injection
bounded 401 recovery
revocation
ADMIN security
rate limiting / Retry-After security policy
media access authorization / signed access grants
```

Neither contract may duplicate the other's state machine.

---

## 11. Acceptance scenarios

### C4-A01 — Publication identity is independent of installation

Given two valid installations `I1` and `I2` reading the same exact root/pack/payload revision:

```text
body identity       = equal
revision            = equal
checksum            = equal
ETag semantics      = equal
contentVersion      = equal
```

Installation identity and bearer token do not alter publication representation.

### C4-A02 — Cold-start token reissue does not create a new publication

Given local committed publication v42 and a cold application bootstrap:

```text
old token T1
→ C5 issues T2
→ root still reports v42 when no new publication exists
→ checksum/ETag identity remains unchanged
```

### C4-A03 — 401 mid-sync recovers same exact resource

Given Flutter synchronizing v42 and exact payload revision 7:

```text
GET revision 7 using T1
→ 401
→ C5 issues T2
→ retry revision 7 once
→ same checksum/revision returned
→ sync continues
```

No restart as a different publication is required solely because credential changed.

### C4-A04 — repeated 401 fails closed

```text
T1 request → 401
T2 reissue → retry → 401
```

Result:

```text
no auth loop
no partial publication commit
previous committed local projection remains usable
```

### C4-A05 — signed URL is outside snapshot identity

If protected media uses signed URLs:

```text
same assetId
same checksumSha256
same deliveryKey
```

may resolve to different ephemeral URLs over time without changing `PublicationSnapshot` checksum or revision identity.

### C4-A06 — new publication during old sync does not mix versions

```text
client syncing v42
backend publishes v43
```

Client either completes exact v42 atomically or fails it; it MUST NOT combine v42 and v43 resources in one committed projection.

### C4-A07 — auth recovery never changes exact-revision target

A retry after token reissue MUST preserve the exact path/revision/query identity of the original idempotent request, except for transport/security headers.

---

## 12. Non-goals

C4 does not define:

```text
how tokens are generated
JWT vs opaque token implementation
token persistence format
refresh tokens
OAuth/OIDC
ADMIN login mechanics
signed-URL cryptography
CDN vendor
user accounts
```

Those are C5/infrastructure concerns.

C4 also does not introduce batching by default. Batch/bundle delivery is justified only if measured pack size or request volume proves single exact-payload delivery inadequate.

---

## 13. Frozen architectural rule

The cross-system rule is:

> C4 determines what immutable product state exists. C5 determines whether an installation is authorized to retrieve it. Security-session changes never redefine publication identity.

This rule is normative for Backend schema/API implementation and Flutter synchronization/recovery behavior.
