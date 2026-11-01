# CareerSpeak — Content Delivery, Availability & Local Retention Requirements

**Document version:** 2.2  
**Status:** Normative specification  
**Applies to:** CareerSpeak v1

Related standards:

- [`../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md`](../architecture/CAREERSPEAK_CROSS_SYSTEM_CONTRACT.md)
- [`CAREERSPEAK_MVP_DELIVERY_SCOPE.md`](CAREERSPEAK_MVP_DELIVERY_SCOPE.md)

---

## 1. Purpose

This specification defines how Backend delivers published content to Flutter and how Flutter retains/reclaims local metadata and media.

It covers:

```text
backend availability
atomic publication/root identity
tombstones
metadata CURRENT state
offline verified assets
Backend media delivery
bounded download/cache infrastructure
TTL/LRU/quota retention
shared asset references
safe eviction
```

A standalone user-managed Downloads screen/library is explicitly outside the CareerSpeak v1 release gate.

---

## 2. Backend learner-delivery rule

Backend owns revision/publication and availability status.

Learner-deliverable content is exactly:

```text
PUBLISHED + ACTIVE
```

Meaning:

```text
included in the applicable atomic learner publication
visible in learner contracts where applicable
associated published assets deliverable through Backend
```

`PUBLISHED + INACTIVE` remains auditable but is not offered for new learner delivery.

---

## 3. Publication root

Flutter synchronizes one coherent learner publication identity/version.

The publication consistency boundary includes:

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

The root references exact immutable payload/catalogue revisions and integrity metadata.

Locale variants remain members of the same publication and do not create unrelated publication epochs.

---

## 4. Flutter metadata lifecycle

Flutter local metadata states may include:

```text
STAGING
VERIFIED
CURRENT
SUPERSEDED
FAILED
```

`CURRENT` means the one coherent local publication/read model used by learner repositories.

Activation is atomic at publication identity/version level:

```text
complete candidate staged
→ ownership/refs/revisions/checksums verified
→ one CURRENT activation transaction
```

A failed/corrupt/incomplete candidate does not replace the last-known-good CURRENT publication.

---

## 5. Metadata synchronization vs media availability

Metadata publication activation and optional/on-demand media acquisition are separate.

Normal learner behavior:

```text
CURRENT metadata
→ asset requested
→ verified local copy if present
→ otherwise authenticated Backend media endpoint
→ bounded download
→ size/checksum verification
→ atomic local placement
→ verified local asset
```

Metadata synchronization SHALL NOT download every optional audio/image asset by default.

A product flow may prefetch/pin a bounded set of assets, but CareerSpeak v1 does not require a dedicated Downloads dashboard or user-managed download library.

---

## 6. Offline readiness

Offline behavior is defined by verified local availability, not by the existence of a Downloads screen.

A local asset/bundle is usable offline only after its required bytes pass integrity verification.

A newer CURRENT publication may coexist temporarily with older verified local bytes only where the exact content/asset identity remains valid for the requested historical/current use. The application must never substitute a mismatched revision silently.

---

## 7. Tombstones/removals

Backend publication exposes explicit removal/tombstone semantics for previously delivered objects that are no longer learner-deliverable.

Flutter applies removals during atomic publication activation:

```text
retire/remove disposable CURRENT projection
release disposable references where safe
preserve durable learner history
```

Absence from a paginated/browse result is never sufficient evidence for destructive deletion.

---

## 8. Durable vs disposable local state

Durable learner state:

```text
onboarding/selection preferences
FAVORITE/LISTENED/COMPLETED markers
review schedule
PracticeTest attempts/completion/history
playback progress where persisted
settings/locale/theme preferences
```

Disposable/re-downloadable state:

```text
superseded metadata projections
audio/images
cached asset bytes
temporary download files
```

Cache/media eviction never deletes durable learner state.

---

## 9. Retention policy

Disposable storage may use:

```text
TTL
+
LRU
+
managed-storage quota
+
reference-safe deletion
```

Baseline cleanup priority:

```text
1. corrupt/invalid/temp data
2. tombstoned/obsolete disposable references
3. expired auto-cache
4. least-recently-used auto-cache under quota pressure
5. preserve currently referenced/explicitly retained verified assets where policy requires
```

Exact TTL/quota values are configuration policy, not immutable business-domain constants.

Favorites do not automatically pin media.

---

## 10. Shared asset references

One immutable asset may be referenced by multiple current/historical contexts.

Physical deletion is permitted only when no retained/current/required reference needs the file.

Quota accounting counts unique physical files rather than duplicated logical references.

---

## 11. Learner media delivery

CareerSpeak v1 uses one Flutter-facing path:

```text
Flutter
→ AssetResolver
→ verified local file if present
→ otherwise authenticated Backend media API
→ Backend validates installation + publication/asset eligibility
→ Backend resolves private RustFS metadata internally
→ Backend streams bytes
→ Flutter verifies size + SHA-256
→ atomic verified local file
```

Flutter never:

```text
addresses RustFS/S3/CDN directly
receives object-storage credentials
receives/constructs a presigned object-storage URL
uses deliveryKey as a remote locator
```

Backend learner media responses do not redirect Flutter to object storage in v1.

---

## 12. Locale reuse

Canonical English content/audio is shared across supported translation locales where asset identity is unchanged.

Changing translation locale downloads/synchronizes only the required locale delta and does not duplicate canonical audio unnecessarily.

---

## 13. Cleanup triggers

Correctness does not depend solely on OS background scheduling.

Cleanup may be evaluated at:

```text
startup
publication sync/activation
asset replacement
large download completion
quota pressure
explicit Free space action if UI exposes one
```

---

## 14. HTTP/cache behavior

May use:

```text
ETag / If-None-Match on Backend APIs
Backend-controlled HTTP caching
local Drift/filesystem cache
```

Do not add Redis solely for learner catalogue/media caching in MVP.

---

## 15. Acceptance scenarios

Must prove:

```text
PUBLISHED + INACTIVE absent from new learner delivery
publication N→N+1 produces one atomic CURRENT transition
incomplete/corrupt candidate keeps previous CURRENT
media download works through Backend without direct storage access
checksum mismatch never becomes verified local data
valid local asset remains usable offline
learner progress/review/test state survives tombstone/cache/media eviction
favorites do not force permanent media retention
quota cleanup removes safe disposable auto-cache
shared file survives while another retained reference exists
locale change reuses canonical English/audio
missing local media is reacquired only through authenticated Backend path
Backend redirect/direct storage bypass is rejected
restart preserves last-known-good CURRENT and durable learner state
```

---

## 16. Standard terminology

```text
Backend ACTIVE
= learner-deliverable under an active publication

Flutter CURRENT
= one atomically selected local publication

Flutter verified local asset / READY
= exact required bytes have passed integrity verification
```

This terminology is mandatory.
