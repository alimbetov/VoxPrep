# CareerSpeak Backend Contract Gap Remediation Plan

**Status:** PLANNED / AUDIT FOLLOW-UP  
**Normative product parent:** `docs/specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`

## 1. Goal

Close only the contract gaps required before backend aggregate/schema freeze.

Rule:

```text
smallest correct product contract
→ smallest correct backend domain
→ schema
→ implementation
→ cross-system acceptance
```

Do not add infrastructure or domain abstractions without a concrete MVP use case.

---

# C0P — Product contract freeze

Freeze:

```text
career/interview-first positioning
Goal → Track → Collection → Content/Test
CareerTrack != LearningTrack
3-step onboarding ownership
local learner state ownership
real Due semantics
learner-facing copy policy
```

No backend `LearningActivity`, workflow engine or recommendation service is needed.

---

# C1 — Root + localization

Close:

```text
BGA-001 root locale identity
BGA-002 localized payload transport
BGA-017 tombstone semantics
```

Decision:

```text
one locale-independent root
one contentVersion
one deterministic checksum/ETag identity
root references canonical + locale pack revisions
```

Define immutable localized payload delivery and deterministic fallback.

---

# C2 — Typed content + small product catalogues

Close:

```text
BGA-003 typed content body
BGA-007 taxonomy
BGA-008 locale/voice capability projection
BGA-016 checksum canonicalization
```

Freeze typed bodies:

```text
VocabularyBody
InterviewBody
TopicBody
PhraseBody
ShadowingBody
```

Freeze only these product catalogues:

```text
LearningGoal
LearningTrack
LearningCollection
Category
Level
Skill
SupportedLocale
TtsVoice learner-facing projection
```

`LearningCollection` references ordered `contentRefs[]` / `practiceTestRefs[]`; no separate activity aggregate.

---

# C3 — Assessment

Close `BGA-004`.

Minimum domain:

```text
PracticeTest
PracticeTestRevision
Question
QuestionRevision
TestQuestionRef
```

Wire contract includes deterministic answers/scoring inputs/explanations and stable skill codes where needed.

No recommendation engine is required.

---

# C4 — Atomic publication

**Atomic publication model is frozen in:** `docs/backend/C4_ATOMIC_PUBLICATION_CONTRACT.md`.

Close:

```text
BGA-005 atomic publication
BGA-009 delivery-path ambiguity
BGA-010 sync scalability limits
```

Freeze one immutable `PublicationSnapshot` / equivalent transaction boundary.

MVP truth path:

```text
Backend: manifest + exact immutable payloads/catalogues
Flutter: Drift browsing/search/pagination
```

Security alignment is normative:

```text
PublicationSnapshot identity
        !=
Installation identity
        !=
installation token/session
```

Therefore `contentVersion`, revision/checksum identity, ETag semantics and asset identity MUST NOT depend on:

```text
installationId
Authorization token
token issuance/expiry/rotation
request session
signed-media URL expiration
```

Stable media identity belongs to C4:

```text
assetId
checksumSha256
deliveryKey
```

Ephemeral media authorization belongs to C5:

```text
authorized delivery resolution
short-lived signed URL/access grant
rate limiting / abuse controls
```

A C5 token replacement during synchronization is a transport/security recovery event, not a publication transition:

```text
sync Publication v42 with T1
→ exact resource returns 401
→ C5 reissues T2
→ retry same exact idempotent resource once
→ revision/checksum unchanged
→ continue v42 atomic projection
```

Repeated `401`, missing exact revisions, checksum conflicts or failed projection MUST fail closed and MUST NOT partially replace the currently committed local projection.

A newer backend publication becoming `CURRENT` while a client synchronizes an older exact snapshot MUST NOT mutate the older exact resources or cause mixed-version local commit.

Add batch/bundle delivery only if measured pack size makes single-payload requests a real problem.

---

# C5 — Installation + external security

**Learner security model is frozen in:** `docs/backend/C5_INSTALLATION_EXTERNAL_SECURITY_CONTRACT.md`.  
**Media security model is frozen in:** `docs/backend/C5_MEDIA_SECURITY_CONTRACT.md`.  
**BGA-011 resolution:** `docs/backend/BGA_011_MEDIA_SECURITY_RESOLUTION.md`.

Close:

```text
BGA-006 installation token lifecycle
BGA-011 media policy
BGA-012 ADMIN security
BGA-018 rate limiting
BGA-022 entitlement risk decision
```

Frozen learner-token model:

```text
installationId = stable installation identity
token          = temporary backend-issued credential

cold bootstrap
→ preserve/get installationId
→ POST /api/v1/installations
→ issue fresh token
→ atomically replace TokenStore token
→ centralized HTTP client uses current Bearer token
```

Rules:

```text
fresh token on every application bootstrap
stored token never skips cold-start issuance
no learner login/password
no refresh token
no identity platform
business code never owns Authorization
one bounded 401 recovery
401 → single-flight re-issue → retry once
second 401 → fail closed
revoked installation → renewal fails closed
```

Frozen media policy:

```text
C4 stores stable assetId + checksumSha256 + deliveryKey
Flutter requests media access using authenticated learner API
Backend validates current installation token + asset eligibility
Backend issues short-lived signed/presigned URL
RustFS/edge serves media bytes directly to Flutter
Flutter verifies checksum before trusted local promotion
```

Media security rules:

```text
learner media is not public by default
no RustFS credentials in Flutter
client cannot request signing of arbitrary storage keys
signed URL is ephemeral and never durable publication state
default grant TTL = 5 minutes
maximum grant TTL = 15 minutes
expired grant → resolve same asset again, not publication resync
revoked installation → cannot mint new grants
normal media bytes do not proxy through Spring Boot
```

Also freeze:

```text
429/Retry-After
ADMIN cookie/CSRF/rate-limit/rotation basics
entitlement risk acceptance/rejection
```

Do not add user accounts, DRM or an identity platform for these MVP concerns.

---

# C6 — TTS hardening

May proceed in parallel.

Close:

```text
BGA-013 logical current-audio uniqueness
BGA-014 exact model-config byte contract
BGA-015 Worker-token risk documentation
```

Keep existing Worker architecture.

---

# C7 — Production operability

Before production acceptance define:

```text
basic observability
PostgreSQL/RustFS backup + restore
orphan/missing-object reconciliation
consumer contract CI
```

No distributed transaction or new platform component is required.

---

# Backend implementation order

```text
B1  project/security/Liquibase/RustFS foundation
B2  installation identity + bootstrap token issuance/rotation
B3  taxonomy + locale + voice catalogues
B4  Goal + Track + Collection
B5  typed content revisions
B6  localization
B7  assessment
B8  publication snapshot + manifests
B9  learner exact-payload/catalog APIs + media access grant
B10 TTS backend domain
B11 simple Admin Content Studio
B12 cross-system acceptance
```
