# CareerSpeak — Cross-System Contract Standard

**Document version:** 1.0  
**Status:** Normative P0 integration standard  
**Applies to:** CareerSpeak v0.9+  
**Branch:** `feat/p0-domain-contracts`

---

## 1. Purpose

This document standardizes integration semantics between:

```text
Spring Boot Backend
Flutter App
TTS Worker
RustFS / CDN delivery
```

It defines shared terminology, identifiers, state ownership, version semantics, security boundaries, media identity, error semantics and recovery rules.

If a profile specification uses conflicting terminology, this standard takes precedence until the profile specification is corrected.

---

## 2. Technical actors

Exactly three actors exist in MVP:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

### ADMIN

One human account:

```text
fixed username
strong deployment-managed password hash
Spring Security server-side session
HttpOnly/Secure/SameSite cookie
CSRF
```

No moderator/editor/reviewer hierarchy, registration, password reset, OAuth, LDAP, Keycloak or user-role tables.

### FLUTTER INSTALLATION

No learner account.

```text
random installationId
→ backend registration
→ backend-issued installation token
→ platform Secure Storage
```

Learner progress is local-first and is not joined to installation identity on the backend.

### TTS WORKER

Machine actor with a dedicated rotatable token.

No ADMIN credential, learner token, direct PostgreSQL credential or permanent RustFS credential.

---

## 3. Security zones

```text
/admin/**
→ ADMIN session

/api/v1/**
→ installation token

/internal/v1/tts/**
→ worker machine token

RustFS private model/draft operations
→ presigned GET/PUT

Published learner media
→ CDN/edge → RustFS origin
```

Authentication mechanisms SHALL remain separate.

---

## 4. Identity standard

### Content

Cross-system learner content identity uses stable business codes.

```text
contentCode
+ revision when revision identity matters
```

Server numeric IDs are not mobile learner-domain identity.

### Pack

```text
packCode
variantKey
revision
```

Initial variant keys:

```text
canonical
locale:<bcp47/base-locale>
```

### Asset

```text
assetId
checksumSha256
deliveryKey
```

`deliveryKey` is a relative immutable delivery/object key, not a permanent CDN hostname.

### TTS job

A `jobId` does not prove worker ownership. Completion/heartbeat additionally require the current `leaseToken`.

---

## 5. Time standard

Persisted/exchanged timestamps use UTC semantics.

API representation:

```text
ISO-8601 UTC
```

Example:

```text
2026-10-30T09:30:00Z
```

Local timezone affects presentation/scheduling only.

---

## 6. Backend content lifecycle

Backend owns publication and learner-delivery availability.

Revision status:

```text
DRAFT
READY_FOR_AUDIO
READY_FOR_REVIEW
PUBLISHED
ARCHIVED
```

Availability:

```text
ACTIVE
INACTIVE
```

Normative delivery condition:

```text
PUBLISHED + ACTIVE
```

means:

```text
visible to learner API where applicable
included in applicable manifest/pack snapshot
deliverable to Flutter
published assets available for stream/download
```

`PUBLISHED + INACTIVE` remains auditable but SHALL NOT be offered to new learner delivery.

Backend `ACTIVE` is reserved for server availability and SHALL NOT name a Flutter local-revision state.

---

## 7. Flutter local lifecycle vocabulary

Local pack/content revision states:

```text
STAGING
VERIFIED
CURRENT
SUPERSEDED
FAILED
```

`CURRENT` = currently selected local metadata/read-model revision.

Offline pack states:

```text
NOT_DOWNLOADED
QUEUED
DOWNLOADING
VERIFYING
READY
UPDATING
FAILED
```

`READY` = all assets required by the offline contract are locally verified.

Local file states:

```text
DOWNLOADING
VERIFIED
CORRUPT
DELETE_PENDING
```

Critical distinction:

```text
Backend ACTIVE
= server permits delivery/download

Flutter CURRENT
= local metadata revision currently used

Flutter offline READY
= complete local offline asset set is verified
```

---

## 8. Metadata update vs offline download

Metadata synchronization and full offline-media download are separate processes.

Normal learner update:

```text
Backend PUBLISHED + ACTIVE
→ manifest/pack metadata
→ Flutter STAGING
→ verify metadata
→ Flutter CURRENT
→ media may stream/cache on demand
```

Explicit offline download:

```text
CURRENT metadata
→ DownloadManager downloads required_offline assets
→ checksum verification
→ offline READY
```

When a newer server revision appears, Flutter MAY have:

```text
metadata rev 8 = CURRENT
offline rev 7  = READY
offline rev 8  = UPDATING
```

The old READY offline bundle remains usable until the replacement is fully verified.

---

## 9. Manifest version model

The backend publishes one root learner snapshot version:

```text
contentVersion
```

The root snapshot references exact pack variants/revisions/checksums.

Locale data does not invent an unrelated root epoch. Locale variants are versioned pack members inside the root snapshot.

Conceptual root manifest:

```json
{
  "schemaVersion": 1,
  "contentVersion": 108,
  "minimumAppContractVersion": 1,
  "packs": [
    {
      "code": "JAVA_SENIOR",
      "variant": "canonical",
      "revision": 8,
      "checksum": "..."
    },
    {
      "code": "JAVA_SENIOR",
      "variant": "locale:kk",
      "revision": 4,
      "checksum": "..."
    }
  ],
  "tombstones": []
}
```

Flutter distinguishes:

```text
remoteContentVersionSeen
active/currentContentVersion
```

A seen remote version is not considered locally current until its metadata activation transaction succeeds.

---

## 10. Manifest atomicity

For MVP, root `contentVersion` represents a consistent backend delivery snapshot.

Flutter stages changed pack metadata and applies the root snapshot transition atomically in Drift.

A failed metadata pack SHALL NOT produce a half-old/half-new root metadata snapshot.

This root metadata barrier does **not** require downloading all optional learner media.

Explicit offline bundle replacement has its own atomic READY transition.

---

## 11. Tombstones

When previously delivered content becomes unavailable, Backend publishes a tombstone or equivalent explicit removal record.

Flutter SHALL:

```text
remove/retire disposable CURRENT content during atomic metadata commit
release disposable asset references
preserve durable learner state
```

Durable state includes:

```text
favorites
progress
review schedule
test attempt history
```

Absence from a paginated list is never sufficient evidence for destructive deletion.

---

## 12. Localization contract

Learning language:

```text
en
```

Flutter settings:

```text
uiLocale
translationLocale
preferredAccent
```

UI strings:

```text
Flutter ARB / gen-l10n
```

Content translations/hints/explanations:

```text
Backend pack locale variants
```

Canonical English/audio is shared across locales.

Locale identifiers are BCP-47 compatible.

---

## 13. Media delivery contract

Published learner bytes flow:

```text
Flutter
→ AssetResolver
→ verified local file if present
→ otherwise CDN/edge
→ RustFS published origin
```

Spring Boot does not proxy normal learner MP3/image payloads.

Backend/API provides stable asset metadata; environment-specific delivery host resolution belongs to delivery configuration.

---

## 14. TTS production contract

Backend owns:

```text
exact voice_model_id selection
TTS job lifecycle
lease state
fingerprint expectation
presigned RustFS authorization
final FileAsset association
ADMIN review/publication
```

Worker owns:

```text
claim
model cache/download
Piper synthesis
FFmpeg processing
technical QC
upload
complete/fail reporting
```

Worker never publishes learner content.

---

## 15. TTS queue standard

PostgreSQL is the durable queue.

Claim uses atomic transaction semantics based on:

```sql
FOR UPDATE SKIP LOCKED
```

Ownership fields:

```text
worker_id
lease_token
lease_until
attempt_count
```

Heartbeat extends the current lease.

Completion with an obsolete lease token is rejected.

A stale text/model fingerprint cannot overwrite a newer revision.

---

## 16. Error envelope standard

Backend JSON errors should follow one envelope:

```json
{
  "code": "CONTENT_NOT_FOUND",
  "message": "Content was not found",
  "traceId": "...",
  "details": {}
}
```

Rules:

```text
code = stable machine-readable contract
message = safe human/developer description
details = optional structured context
traceId = operational correlation
```

Flutter maps backend/transport errors to mobile domain failures and SHALL NOT display raw HTTP/SQL exceptions.

Worker uses stable machine error codes in fail callbacks.

---

## 17. Retry/idempotency standard

Safe GET/read operations MAY use bounded retry/backoff.

Mutating operations are retried only when idempotency semantics are explicit.

Mandatory idempotent/replay-safe areas:

```text
manifest reads
pack reads
sync staging of immutable revision
worker heartbeat
worker complete/fail handling of duplicate callback
asset upload identity by immutable object/fingerprint policy
```

---

## 18. Schema/application compatibility

Root manifest exposes `schemaVersion` and may expose a minimum compatible application/contract version.

Flutter SHALL:

```text
reject unsupported future schema
keep last compatible CURRENT snapshot
show update guidance when required
```

Backend SHALL NOT silently emit a schema that supported clients cannot interpret.

---

## 19. Flutter adaptive UI standard

Adaptive layout uses available window size, not device names or orientation alone.

Width classes:

```text
COMPACT   < 600
MEDIUM    600–839
EXPANDED  840–1199
LARGE     >= 1200
```

Adaptive presentation SHALL preserve the same route/domain/application state.

Canonical UI rules are defined in:

```text
docs/mobile/CAREERSPEAK_ADAPTIVE_UI.md
```

Layout changes SHALL NOT trigger content identity changes, duplicate domain controllers or unnecessary network requests.

---

## 20. Ownership boundaries

### Backend

Source of truth for:

```text
published content
availability
manifest/pack snapshot
localization content
asset metadata
TTS jobs/models
```

### Flutter

Source of truth for:

```text
local learner progress
favorites
review schedule
test attempts
local cache/offline state
local CURRENT metadata snapshot
UI settings
```

### Worker

No durable learner/content source of truth. Worker is an execution agent.

### RustFS

Binary object store; not source of business lifecycle state.

---

## 21. Failure boundaries

Backend unavailable:

```text
Flutter uses valid local CURRENT metadata and READY/local media
Worker cannot claim new work
```

CDN/RustFS learner delivery unavailable:

```text
local verified files still work
remote-only assets fail gracefully/retry
```

TTS Worker unavailable:

```text
content production jobs remain pending/recoverable
already published learner content remains unaffected
```

Flutter sync interrupted:

```text
last-known-good CURRENT metadata remains valid
```

Worker crash:

```text
lease expires
job can be reclaimed
```

---

## 22. Cross-system acceptance scenarios

Before P0 architecture freeze, prove contracts for at least:

```text
1. ADMIN publishes + activates content → appears in manifest
2. Flutter upgrades metadata N→N+1 atomically
3. Flutter streaming media works without explicit offline download
4. offline pack retains old READY revision while new revision updates
5. deactivation publishes tombstone and removes learner delivery
6. learner progress survives tombstone/cache eviction
7. locale change reuses canonical English/audio
8. unsupported schema preserves last CURRENT snapshot
9. worker claim/lease/reclaim is concurrency-safe
10. stale worker completion is rejected
11. published TTS asset becomes learner-deliverable only after backend review/publication
12. adaptive UI resize preserves route/test/audio state
```

---

## 23. Standard vocabulary

Use these terms consistently:

```text
Backend:
PUBLISHED / ARCHIVED
ACTIVE / INACTIVE
contentVersion
pack revision
assetId
fingerprint

Flutter metadata:
STAGING / VERIFIED / CURRENT / SUPERSEDED / FAILED

Flutter offline:
NOT_DOWNLOADED / QUEUED / DOWNLOADING / VERIFYING / READY / UPDATING / FAILED

Worker:
PENDING / RUNNING / READY / FAILED / CANCELLED / SUPERSEDED
leaseToken / leaseUntil
```

Do not use one term for two different ownership domains.

---

## 24. Final invariant

```text
Backend controls what may be delivered.
Flutter controls what is currently installed and locally retained.
Worker only produces backend-requested assets.
RustFS stores bytes; it does not decide business state.
```
