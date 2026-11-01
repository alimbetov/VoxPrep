# CareerSpeak — Cross-System Contract Standard

**Document version:** 1.2  
**Status:** Normative CareerSpeak v1 integration standard  
**Applies to:** Flutter App, Spring Boot Backend, TTS Worker, Backend-internal RustFS

Normative parents:

- [`../specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md`](../specification/CAREERSPEAK_PRODUCT_REQUIREMENTS.md)
- [`../specification/CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](../specification/CAREERSPEAK_MVP_DELIVERY_SCOPE.md)
- [`../specification/CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md`](../specification/CAREERSPEAK_MVP_FUNCTIONAL_BUSINESS_AUDIT_2026-11-01.md)

---

## 1. Purpose

This standard defines shared integration semantics for:

```text
Spring Boot Backend
Flutter App
TTS Worker
Backend-owned object storage (RustFS)
```

It standardizes identity, ownership, publication/CURRENT semantics, security, media delivery, errors, retry/idempotency and recovery.

---

## 2. Actors and security zones

Exactly three actors:

```text
ADMIN
FLUTTER INSTALLATION
TTS WORKER
```

Security zones:

```text
/admin/**           → ADMIN session
/api/v1/**          → installation token
/internal/v1/tts/** → worker token
Backend storage     → private RustFS credentials
```

Flutter and Worker network I/O terminates at Spring Boot. RustFS is never a client-facing security zone.

No mandatory learner account exists in v1.

---

## 3. Product ownership

Backend owns mutable product truth:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
published Content / PracticeTest revisions
localization catalogues/payloads
asset/audio metadata
TTS production state
```

Flutter owns device-local learner state:

```text
selected Goal/Track
onboarding progress
FAVORITE/LISTENED/COMPLETED
Review state
PracticeTest attempts/completion/history
playback/local cache state
UI/locale preferences
```

Worker owns no durable learner/product truth; it is an execution agent.

---

## 4. Learner hierarchy and selection

Only normative hierarchy:

```text
Vertical
 ↓
LearningGoal
 ↓
LearningTrack
 ↓
LearningCollection
 ↓
exact ContentRevision / PracticeTestRevision members
```

Current Vertical is derived from selected CURRENT Goal.

Invalid selection is fail-closed:

```text
invalid Track → clear Track; preserve active Goal
invalid Goal/Vertical → clear Goal + Track
```

No sibling auto-fallback and no cross-Vertical guessing.

---

## 5. Identity standard

### Learner content

```text
stable business code
+ exact revision where revision identity matters
```

Server numeric IDs are not Flutter learner-domain identity.

### Publication

```text
contentVersion / publicationVersion
```

The identity is never reused and represents one coherent learner snapshot.

### Asset

```text
assetId
size
checksumSha256
deliveryKey (Backend-internal storage metadata)
```

Flutter/Worker MUST NOT use `deliveryKey` as a URL/path/authorization input.

### TTS job

`jobId` alone does not prove ownership; heartbeat/completion require the current lease token.

---

## 6. Time standard

Persisted/exchanged timestamps use UTC semantics and ISO-8601 UTC API representation.

Local timezone affects display only. Review scheduling decisions are persisted as UTC instants.

---

## 7. Backend lifecycle

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

Learner-deliverable = `PUBLISHED + ACTIVE` within the current Backend publication.

Published revisions are immutable.

---

## 8. Flutter lifecycle vocabulary

```text
Backend ACTIVE
= Backend permits learner delivery

Flutter CURRENT
= one atomically active local publication/read model

Flutter verified local asset / READY
= exact local bytes passed integrity verification
```

These concepts must not be conflated.

---

## 9. C4 atomic publication contract

The Backend publishes one immutable learner publication identity/root.

Its consistency boundary includes:

```text
Vertical
LearningGoal
LearningTrack
LearningCollection
exact Content revisions
exact PracticeTest revisions
Localization
Assets/audio references
```

Conceptual publication process:

```text
validate complete candidate
→ persist exact refs/revisions/checksums
→ allocate never-reused publication/contentVersion
→ expose immutable root
→ switch Backend current root atomically
```

Flutter synchronization:

```text
observe remote publication
→ stage complete candidate locally
→ validate ownership/refs/schema/checksums
→ one Drift CURRENT activation transaction
```

Required invariants:

- Backend never exposes a half-published root;
- Flutter repositories never observe mixed CURRENT publication versions;
- a seen remote version is not CURRENT until local activation succeeds;
- incomplete/corrupt sync leaves last-known-good CURRENT active;
- restart preserves/deterministically recovers the previous valid CURRENT;
- publication/tombstone behavior is reproducible by exact revision identity.

Atomic metadata activation does not require eagerly downloading all optional media.

---

## 10. Tombstones / removals

Backend publication explicitly represents removal/deactivation of previously delivered learner objects.

Flutter applies removal during atomic activation:

```text
retire disposable CURRENT projection
release disposable asset references where safe
preserve durable learner state
```

Durable state includes markers, Review and PracticeTest history.

Absence from a browse/paginated response is never deletion evidence.

---

## 11. Localization

```text
learningLanguage = en
uiLocale
translationLocale
preferredAccent / preferredVoiceCode where applicable
```

Flutter UI strings use local ARB/gen-l10n. Backend owns supported locale catalogue and localized content payloads.

Publication/root identity is locale-independent. Locale changes reuse canonical English/audio where identities are unchanged.

---

## 12. Learner media contract

CareerSpeak v1 has one Flutter-facing media path:

```text
Flutter
→ AssetResolver
→ verified local file if present
→ otherwise authenticated Backend media API
→ Backend validates installation + current publication/asset eligibility
→ Backend resolves private FileAsset/storage metadata
→ Backend storage adapter reads RustFS
→ Backend streams bytes
→ Flutter verifies size + SHA-256
→ atomic verified local file
```

Flutter SHALL NOT receive or construct:

```text
RustFS/S3 endpoint
bucket/object key URL
storage credentials
signed/presigned object-storage URL
CDN/media-origin URL
```

Backend SHALL NOT redirect v1 learner media requests to object storage.

A future direct/signed grant model requires a new versioned contract; it is not an alternative implementation of this v1 contract.

A standalone Downloads dashboard is not required for this media/offline contract.

---

## 13. Installation identity and bounded 401 recovery

Normative flow:

```text
random installationId
→ idempotent Backend registration/re-registration
→ installationToken
→ Secure Storage
→ authorized learner API
```

Credential-specific recovery:

```text
401
→ invalidate rejected token only
→ preserve installationId + learner state
→ re-register once
→ retry safe request once where policy permits
→ fail closed if rejected again
```

No account/profile state is fabricated or deleted during token recovery.

---

## 14. TTS production contract

Backend owns:

```text
voice/model catalogue
TTS job lifecycle
lease state
fingerprint expectation
model artifact delivery
RustFS persistence
final FileAsset association
ADMIN review/publication
```

Worker owns:

```text
claim
model cache/download through Backend
Piper synthesis
FFmpeg processing
technical QC
Backend output upload
complete/fail reporting
```

Queue uses PostgreSQL `FOR UPDATE SKIP LOCKED` with lease token, expiry, heartbeat, bounded retry and stale-result rejection.

Worker never publishes learner content and never accesses PostgreSQL/RustFS directly.

---

## 15. Error envelope

Backend JSON errors use stable machine-readable codes and safe messages, conceptually:

```json
{
  "code": "CONTENT_NOT_FOUND",
  "message": "Content was not found",
  "traceId": "...",
  "details": {}
}
```

Flutter maps transport/backend failures to learner-safe application failures and never displays raw HTTP/SQL/storage exceptions.

---

## 16. Retry / idempotency

Safe reads may use bounded retry/backoff.

Mutations are retried only with explicit idempotency/replay semantics.

Mandatory replay-safe areas include:

```text
publication/manifest reads
immutable payload reads/staging
learner media reads
installation registration/re-registration
worker heartbeat
worker duplicate complete/fail handling
immutable asset/fingerprint finalization
```

---

## 17. Schema/application compatibility

Publication/root exposes schema/application compatibility metadata sufficient for Flutter to:

```text
reject unsupported future schema
preserve last compatible CURRENT
show safe update/recovery guidance
```

Backend SHALL NOT silently activate a schema unsupported by contracted clients.

---

## 18. Failure boundaries

```text
Backend unavailable
→ valid local CURRENT + verified assets continue

Backend media/storage unavailable
→ verified local files continue; missing remote asset fails safely

TTS Worker unavailable
→ production jobs wait; already published learner content unaffected

Flutter sync interrupted/corrupt
→ previous CURRENT remains active

401 recovery repeatedly rejected
→ fail closed; preserve learner state

Worker crash
→ lease expires; job reclaimable
```

---

## 19. Cross-system acceptance — A1

Before v1 release, prove at least:

```text
1. Backend publication appears as one coherent learner root
2. Flutter upgrades publication N→N+1 atomically
3. mixed old/new hierarchy/payload CURRENT is impossible
4. failed/corrupt candidate preserves prior CURRENT across restart
5. learner media works through Backend without storage credentials/redirects
6. valid local media works offline
7. missing local media reacquires through current installation credential
8. deactivation/removal retires learner projection without deleting learner history
9. locale change reuses canonical content/audio where valid
10. unsupported schema preserves last compatible CURRENT
11. 401 performs one bounded re-registration/retry path
12. active PracticeTest/review state survives offline/restart
13. exact revision completion/history remains reproducible
14. TTS claim/lease/reclaim and stale completion are concurrency-safe
```

---

## 20. Final invariant

```text
Backend controls what is published/deliverable and owns all RustFS access.
Flutter controls device-local learner state and one atomically active CURRENT projection.
Worker only executes Backend-requested TTS work through Backend APIs.
RustFS stores private bytes behind Backend and is never addressed by Flutter or Worker.
```
