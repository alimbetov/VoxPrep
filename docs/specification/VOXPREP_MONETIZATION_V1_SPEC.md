# VoxPrep Monetization v1 — FREE First Collection + Lifetime Full Unlock

**Status:** REVIEWED / implementation baseline  
**Target:** first commercial release  
**Updated:** 2026-11-02  
**Scope:** Flutter mobile + Backend + Google Play + Apple App Store + content cover images

---

## 1. Product decision

VoxPrep is distributed as a free application.

```text
FREE INSTALL
    ↓
First configured LearningCollection = FREE
    ↓
Remaining LearningCollections = FULL / locked
    ↓
Full Unlock ≈ USD 4.99
    ↓
ONE-TIME PURCHASE
    ↓
FULL access without expiration
```

V1 deliberately has:

```text
1 Store product
2 access levels: FREE / FULL
0 subscriptions
0 trials
0 advertisements
0 VoxPrep user accounts
0 email/password login
0 external checkout
```

Commercial product identifier:

```text
voxprep_full_unlock
```

Platform product types:

```text
Google Play  → one-time product, never consumed
Apple        → non-consumable In-App Purchase
```

The USD 4.99 value is a reference base price. Flutter MUST display the localized Store price returned by the platform Store and MUST NOT hardcode `$4.99` as authoritative UI pricing.

---

# PART I — Review decisions and architecture freeze

## 2. Product “block” maps to LearningCollection

The current production catalogue does not contain a separate `KnowledgeBlock` aggregate.

The product concept called “knowledge block” maps to the existing universal-catalogue entity:

```text
LearningCollectionProjection
```

Therefore Monetization v1 MUST NOT create a parallel `KnowledgeBlock` domain.

Canonical access classification belongs to:

```text
LearningCollection.accessLevel
```

This is the source of truth for whether all members of a collection are FREE or require FULL access.

---

## 3. Catalogue contract versioning

The already published/frozen catalogue v2 contract MUST remain immutable.

Monetization introduces:

```text
contracts/c2-content-catalog-v3.yaml
```

V3 adds explicit:

```text
AccessLevel = FREE | FULL
LearningCollection.accessLevel
```

Rules:

```text
v3 publication → accessLevel MUST be explicit
legacy v2 bytes without accessLevel → interpreted fail-closed as FULL
unknown accessLevel → rejected
access MUST NOT be inferred from sortOrder/title/position/locale
```

Changing a collection access classification changes publication bytes/checksum and therefore requires normal catalogue revision semantics.

The client application contract target for monetization-capable publications is:

```text
careerSpeakAppContractVersion = 3
```

The root manifest schema itself MAY remain schema v2 while declaring `minimumAppContractVersion: 3` for publications that require monetization-aware catalogue semantics.

---

## 4. Durable access persistence

`LearningCollection.accessLevel` MUST survive:

- sync;
- staged publication materialization;
- CURRENT switch;
- process restart;
- database reopen.

The current implementation uses additive schema v17:

```text
learning_collection_access_reads
--------------------------------
content_version
collection_code
access_level   FREE | FULL
```

This table extends the frozen universal-catalogue v9 read model without mutating its historical table definition.

Legacy materialized snapshots with no access row MUST read as:

```text
FULL
```

This is intentionally fail-closed.

---

# PART II — Access model and gating

## 5. Access domain

Flutter/application domain:

```dart
enum AccessLevel {
  free,
  full,
}
```

Semantics:

```text
learner FREE + collection FREE → ALLOW
learner FREE + collection FULL → DENY / show unlock
learner FULL + collection FREE → ALLOW
learner FULL + collection FULL → ALLOW
```

The same enum MAY describe learner entitlement and collection requirement because v1 has only two ordered access levels.

Do NOT add subscription-specific types in v1.

---

## 6. Initial commercial configuration

Initial production catalogue configuration:

```text
LearningCollection 1 → FREE
LearningCollection 2 → FULL
LearningCollection 3 → FULL
LearningCollection 4 → FULL
...
```

The client MUST NOT implement this rule as `index == 0`.

The backend/catalogue explicitly publishes FREE/FULL, allowing the free set to change later without a Flutter release.

---

## 7. Access inheritance

A collection-level requirement applies to its exact members:

```text
LearningCollection
    ↓
ContentRevisionRef / PracticeTestRevisionRef
    ↓
Content body
Audio
PracticeTest
Protected downloads/assets
Continue Learning target
```

V1 does not duplicate FREE/FULL flags on every content record.

---

## 8. Catalogue UX

A FREE learner MUST see the complete catalogue, including FULL collections.

Example:

```text
English Basics             ✓ Free
Interview Preparation      🔒 Full
Java Interview             🔒 Full
System Design              🔒 Full
```

Locked collections remain visible for discovery/merchandising but cannot navigate into protected learning functionality.

Attempting to open a FULL collection while learner access is FREE opens the Full Unlock screen.

---

## 9. Full Unlock screen

Minimum content:

```text
Unlock Full VoxPrep

✓ Complete VoxPrep catalogue
✓ Included practice tests
✓ Included audio
✓ Offline access for entitled content

[ localized Store price ]
One-time purchase

[ Unlock Full VoxPrep ]

[ Restore Purchases ]
```

Do not promise “all future content forever” in v1 copy. The commercial promise is lifetime ownership of the Full Unlock entitlement for content covered by that entitlement.

---

## 10. Backend authorization

Flutter locking is UX, not the security boundary.

Backend MUST independently prevent FREE installations from accessing FULL collection members through:

- direct content IDs;
- deep links;
- Content Detail API;
- audio authorization;
- PracticeTest start/load;
- protected downloads;
- asset delivery/presigning;
- offline package acquisition;
- Continue Learning resolution.

Learner-safe business error:

```text
FULL_ACCESS_REQUIRED
```

No raw backend/store/storage details may reach learner UI.

---

# PART III — Content Visual Asset v1

## 11. Review correction: reuse existing content asset architecture

VoxPrep already has exact-revision media ownership:

```text
ContentAssetRef
├── contentIdentity
├── contentRevision
├── assetId
└── role
```

and canonical asset metadata:

```text
ManifestAssetDescriptor
├── assetId
├── checksumSha256
├── deliveryKey
├── sizeBytes
├── mediaType
└── requiredOffline
```

Therefore Content Visual Asset v1 MUST NOT duplicate `assetId/checksum/mediaType` inside a new `ContentPayload.coverImage` object.

The canonical cover image is expressed through the existing publication asset relation:

```text
ContentAssetRef.role = coverImage
```

This keeps one source of truth for checksum, MIME type, delivery key, retention and exact-revision ownership.

---

## 12. Visual role

Introduce a typed role:

```text
ContentVisualRole.coverImage
wire value: coverImage
```

V1 permits at most one cover image per exact content revision.

```text
0 coverImage refs → valid, use deterministic fallback
1 coverImage ref  → valid
2+ coverImage refs → invalid publication/content asset topology
```

Cover images are preview-safe catalogue media.

Preview-safe cover visibility does NOT authorize any other asset belonging to the content revision.

---

## 13. Supported image media

Content cover v1 accepts:

```text
image/webp
image/jpeg
image/png
```

SVG is OUT OF SCOPE for v1.

Preferred authoring profile:

```text
aspect ratio      16:9
recommended size  1200 × 675
preferred format  WebP
practical target  ~80–300 KB when quality permits
```

Dimensions are authoring guidance, not a requirement that every valid image be exactly 1200×675.

---

## 14. Exact revision semantics

Cover ownership is already exact because `ContentAssetRef` contains:

```text
contentIdentity + contentRevision
```

Changing a canonical cover MUST occur through normal publication/revision semantics.

Forbidden:

```text
same exact content revision/checksum
but silently replace its canonical cover with unrelated mutable media
```

Derived thumbnails/renditions MAY be generated later if they remain deterministic projections of the same canonical asset.

---

## 15. Cover use in UI

The same canonical cover is reused on:

```text
Catalogue card
Content Detail hero
Continue Learning thumbnail
```

Do NOT add separate canonical `thumbnailImage`, `cardImage`, and `heroImage` fields in v1.

Recommended Content Detail hierarchy:

```text
Back/context
Title
Subtitle
Hero cover
Category • level • duration
Audio controls
Description/body
```

The cover remains presentation-only and MUST NOT affect learner-state semantics.

---

## 16. FREE/FULL cover visibility

A cover image MAY be visible to FREE users for a locked FULL collection member.

Required distinction:

```text
FULL content title/metadata → visible
FULL cover image            → visible
FULL lock indicator         → visible
FULL body                   → denied to FREE
FULL audio                  → denied to FREE
FULL PracticeTest           → denied to FREE
protected assets            → denied to FREE
```

This makes locked catalogue cards useful commercial previews without weakening authorization.

---

## 17. Missing/corrupt image behavior

Image is optional.

If absent, missing offline, corrupt, unsupported or temporarily unavailable:

```text
render deterministic fallback
```

Fallback SHOULD depend on `ContentType`, for example:

```text
vocabulary → vocabulary visual/icon
interview  → conversation/interview visual/icon
topic      → document/topic visual/icon
phrase     → quote visual/icon
shadowing  → headphones/audio visual/icon
```

Image failure MUST NOT block otherwise valid content.

Checksum-invalid cache entries MUST be rejected and MAY be safely re-downloaded when network is available.

No raw checksum, filesystem, RustFS, presigned URL or object-storage error may reach learner UI.

---

## 18. Existing delivery pipeline is reused

Target image flow:

```text
Backend FileAsset / object storage
        ↓
ManifestAssetDescriptor
        ↓
ContentAssetRef(role=coverImage)
        ↓
publication/sync
        ↓
DownloadManager / AssetResolver
        ↓
local cache or authorized remote asset
        ↓
Catalogue / Content Detail / Continue Learning
```

Do NOT create:

```text
ImageSyncCoordinator
second image database
independent unbounded image cache
raw URL as durable image identity
```

Retention MUST reuse existing bounded asset-retention policy.

---

# PART IV — Store purchase architecture

## 19. Google Play requirements

Digital functionality unlocked inside the Google Play version MUST use Google Play Billing.

Release requirement:

```text
MUST   use a currently supported Play Billing Library
TARGET Play Billing 9.x
```

Product:

```text
voxprep_full_unlock
one-time product
never consumed
```

Required flow:

```text
ProductDetails
→ localized price
→ launchBillingFlow
→ PURCHASED/PENDING/CANCELLED handling
→ purchaseToken to backend
→ Google Play Developer API verification
→ persist verified purchase
→ grant FULL entitlement
→ acknowledge
```

PENDING MUST NOT grant FULL.

Verification and acknowledgement MUST be idempotent.

Restore/current ownership uses the supported current-purchases API (`queryPurchasesAsync` semantics for the target Billing generation).

---

## 20. Apple requirements

Use:

```text
StoreKit 2
Product ID: voxprep_full_unlock
Type: Non-Consumable
```

Do not build new code around legacy `/verifyReceipt` architecture.

Required flow:

```text
StoreKit Product
→ localized price
→ purchase()
→ verified Transaction / signed transaction data
→ backend verification
→ persist verified purchase
→ grant FULL entitlement
→ transaction.finish()
```

Transaction MUST be finished only after safe entitlement delivery/persistence.

Unlock screen MUST expose explicit:

```text
Restore Purchases
```

Do not trigger intrusive interactive restore on every startup.

---

## 21. Ownership and anonymous learner model

VoxPrep does not create a user account solely for monetization.

Ownership source:

```text
Android → Google Play account/store purchase
Apple   → App Store account/store purchase
```

VoxPrep continues using anonymous installation identity for its own runtime.

`installationId` is NOT purchase proof.

Trust chain:

```text
Store transaction
→ backend verification
→ StorePurchase
→ InstallationEntitlement FULL
→ local AccessSnapshot
```

Cross-store portability is OUT OF SCOPE v1:

```text
Google purchase → Android restore
Apple purchase  → Apple restore
```

Automatic Android-purchase-to-iPhone access requires a future stable VoxPrep account/recovery identity.

---

## 22. Backend purchase model

Do not create `User` solely for payment.

Technical model:

```text
StorePurchase
-------------
id
provider                GOOGLE_PLAY | APP_STORE
productId
purchaseToken           // Google where applicable
transactionId           // Apple where applicable
originalTransactionId   // Apple where applicable
status                   PURCHASED | REFUNDED | REVOKED
purchasedAt
verifiedAt
revokedAt
createdAt
updatedAt
```

And:

```text
InstallationEntitlement
-----------------------
installationId
entitlement = FULL
sourcePurchaseId
verifiedAt
updatedAt
```

Database uniqueness MUST prevent duplicate processing of the same authoritative Store purchase.

---

## 23. Access API

Backend exposes an access endpoint compatible with existing installation identity, for example:

```http
GET /api/v1/access
```

FREE:

```json
{
  "accessLevel": "FREE"
}
```

FULL:

```json
{
  "accessLevel": "FULL",
  "verifiedAt": "2026-11-02T10:00:00Z"
}
```

Exact URI may follow backend versioning conventions.

---

## 24. Refund/revoke reconciliation

Google production design MUST support authoritative refund/revocation reconciliation using current Google Play mechanisms such as Play Developer API / RTDN / voided purchase reconciliation where applicable.

Apple production design MUST support current App Store Server Notifications V2 / authoritative transaction state.

After authoritative revoke/refund:

```text
PURCHASED → REFUNDED/REVOKED
FULL      → FREE
```

A restored/reversed authoritative entitlement may re-grant FULL.

All Store event processing MUST be idempotent.

---

# PART V — Local persistence and offline

## 25. AccessSnapshot

Flutter stores local access state for fast startup and offline continuity:

```text
AccessSnapshot
--------------
accessLevel
verifiedAt
source
```

Local snapshot is NOT authoritative purchase proof.

After a verified FULL purchase:

```text
FULL
↓
offline
↓
previously entitled/downloaded content remains usable
```

A temporary Store/backend outage MUST NOT immediately disable a previously verified paying learner.

Authoritative online refund/revoke state wins when synchronization resumes.

---

## 26. Existing learner state remains orthogonal

FREE → FULL, restart and image loading MUST NOT reset or rewrite:

```text
FAVORITE
LISTENED
COMPLETED
PracticeTest attempts
Continue Learning
last-opened content
audio resume position
```

Existing audio completion semantics remain unchanged.

Continue Learning MUST revalidate both CURRENT publication membership and access before opening a saved target.

---

# PART VI — Privacy and Store declarations

## 27. Privacy baseline

“No account” does NOT automatically mean “no data collected” under Store definitions.

Potentially reportable technical data may include:

- installation/device-related identifier;
- purchase history / transaction identifier;
- app interactions;
- diagnostics/crash data;
- backend request metadata;
- analytics if added.

Before release:

```text
Google Play → Data Safety completed truthfully
Apple       → App Privacy completed truthfully
```

Privacy Policy MUST describe:

- installation identity;
- purchase/transaction identifiers;
- learner-state/backend data actually transmitted;
- that Google/Apple process payment credentials;
- retention/deletion approach;
- contact method;
- third-party SDK behavior where applicable.

Do not claim broadly that VoxPrep stores “no user data” unless the final production audit supports that statement under the stores' definitions.

---

# PART VII — Error and security rules

## 28. Learner-safe errors

Possible learner-facing business errors:

```text
PURCHASE_CANCELLED
PURCHASE_PENDING
PURCHASE_UNAVAILABLE
PURCHASE_VERIFICATION_FAILED
RESTORE_NOT_FOUND
STORE_UNAVAILABLE
FULL_ACCESS_REQUIRED
```

Image technical failures normally degrade to fallback rather than interrupt learning.

Never expose:

```text
purchaseToken
Apple signed transaction payload
raw backend body
stacktrace
database error
filesystem path
RustFS/object-storage path
presigned URL internals
checksum internals
```

---

## 29. Production bypass prohibition

Production composition MUST NOT contain an accessible client-only path equivalent to:

```dart
accessLevel = AccessLevel.full;
```

Dev/test billing fakes must be dependency-injected and excluded or unreachable from production composition.

Likewise, the mere existence of a local FULL asset MUST NOT be treated as entitlement proof.

---

# PART VIII — Implementation roadmap

## 30. Monetization roadmap

```text
M1  Access contract foundation
    ├── AccessLevel
    ├── LearningCollection.accessLevel
    ├── C2 catalogue v3
    ├── legacy v2 → FULL fail-closed
    └── durable schema v17 persistence

M2  Deterministic gating
    ├── CollectionAccessPolicy
    ├── locked catalogue cards
    ├── navigation guard
    ├── deep-link protection
    └── member ownership resolution

M3  Learner entitlement state
    ├── AccessSnapshot
    ├── AccessController
    ├── backend access adapter
    └── restart/offline behavior

M4  Full Unlock UI
    ├── StoreProduct abstraction
    ├── localized price
    ├── purchase action
    └── Restore Purchases

M5  Google Play Billing

M6  Google backend verification / acknowledge / reconciliation

M7  Backend FULL authorization for Content/Audio/Test/Downloads/Continue Learning

M8  Android commercial qualification and release

M9  Apple StoreKit 2

M10 Apple backend verification / Server Notifications V2

M11 Apple commercial qualification and release
```

---

## 31. Content image roadmap

```text
IMG1  ContentVisualRole.coverImage
      ├── existing ContentAssetRef exact ownership
      ├── existing ManifestAssetDescriptor metadata
      ├── max one cover per exact revision
      └── WebP/JPEG/PNG validation

IMG2  Backend authoring/FileAsset binding

IMG3  Publication qualification
      ├── exact asset membership
      ├── image MIME validation
      └── preview-safe cover classification

IMG4  Flutter cover resolution/persistence

IMG5  AssetResolver image support / checksum-safe cache

IMG6  Catalogue card thumbnail + deterministic fallback

IMG7  Content Detail hero

IMG8  Continue Learning thumbnail

IMG9  Offline/restart/retention qualification

IMG10 Adversarial image qualification
```

IMG work is orthogonal to Store purchase ownership and can progress in parallel after contracts are frozen.

---

# PART IX — Acceptance criteria

## 32. Access qualification

```text
MON-A01 FREE can open FREE collection
MON-A02 FREE cannot open FULL collection
MON-A03 FULL can open FREE and FULL collections
MON-A04 access is never inferred from ordering/title
MON-A05 legacy v2 collection without access field resolves FULL
MON-A06 unknown access value is rejected
MON-A07 access survives materialization/restart/reopen
MON-A08 deep link cannot bypass collection access
MON-A09 direct content/test/audio/download path cannot bypass access
MON-A10 FREE→FULL preserves learner state
```

---

## 33. Purchase qualification

```text
MON-P01 localized price comes from Store
MON-P02 cancelled purchase does not grant FULL
MON-P03 pending purchase does not grant FULL
MON-P04 invalid proof does not grant FULL
MON-P05 valid Google purchase grants FULL
MON-P06 Google purchase is acknowledged and never consumed
MON-P07 repeated verification/acknowledge is idempotent
MON-P08 Google restore after reinstall grants FULL for valid ownership
MON-P09 valid Apple transaction grants FULL
MON-P10 Apple transaction finishes only after entitlement delivery
MON-P11 Apple restore after reinstall grants FULL for valid ownership
MON-P12 refund/revoke converges entitlement to FREE
MON-P13 verified FULL remains usable offline according to policy
MON-P14 production contains no client FULL bypass
```

---

## 34. Image qualification

```text
IMG-A01 no cover is valid and renders fallback
IMG-A02 one valid WebP/JPEG/PNG cover resolves through existing manifest metadata
IMG-A03 duplicate cover refs are rejected
IMG-A04 missing asset metadata is rejected
IMG-A05 unsupported MIME is rejected
IMG-A06 cover belongs to exact content revision
IMG-A07 same cover can render card/detail/continue surfaces
IMG-A08 FULL locked cover may be preview-visible to FREE
IMG-A09 cover visibility cannot authorize protected body/audio/test/assets
IMG-A10 valid cached cover survives restart/offline
IMG-A11 corrupt/checksum-invalid cache is rejected
IMG-A12 image failure never exposes storage internals
IMG-A13 image cache remains bounded by existing retention
IMG-A14 image state does not alter learner state
```

---

## 35. Store/privacy release checklist

```text
GOOGLE
✅ current supported Play Billing dependency
✅ one-time non-consumed product configured
✅ Product ID exact match
✅ localized pricing
✅ pending/cancel handling
✅ server verification
✅ acknowledgement
✅ restore/current purchase reconciliation
✅ refund/revoke reconciliation
✅ Data Safety
✅ Privacy Policy

APPLE
✅ non-consumable IAP configured
✅ StoreKit 2
✅ signed transaction verification
✅ Restore Purchases visible
✅ transaction finish semantics
✅ refund/revoke handling
✅ Server Notifications V2 where used
✅ App Privacy
✅ Privacy Policy URL/in-app access
✅ Sandbox/TestFlight qualification
✅ App Review Notes explain unlock path
```

Suggested App Review note:

```text
VoxPrep is free to download.
One configured Learning Collection is available without purchase.
Opening locked learning content presents the non-consumable Full Unlock purchase.
Restore Purchases is available on the unlock screen.
Catalogue preview cover images may be visible before purchase; protected learning content remains locked.
```

---

## 36. Definition of Done

Commercial v1 is accepted only when all of the following are true:

```text
✅ free installation works
✅ configured FREE collection is fully usable
✅ FULL collections are visible but locked
✅ access classification is explicit and durable
✅ old catalogue data fails closed
✅ backend protects FULL functionality
✅ one lifetime Store product exists
✅ Store price is localized
✅ purchase/restore lifecycle is reliable
✅ no VoxPrep account is required
✅ refund/revoke lifecycle is supported
✅ cover images reuse existing exact-revision asset architecture
✅ cover images remain optional and safe
✅ offline/restart behavior is qualified
✅ learner state is preserved
✅ privacy declarations match production behavior
✅ adversarial qualification passes
✅ production CI is green on exact SHA
```

---

## 37. Final target architecture

```text
                         VOXPREP
                            │
                      FREE INSTALL
                            │
                  Universal Catalogue
                            │
              LearningCollection.accessLevel
                    ┌───────┴───────┐
                    │               │
                  FREE            FULL 🔒
                    │               │
                    │       Unlock Full VoxPrep
                    │          localized price
                    │               │
                    │      Google Play / StoreKit 2
                    │               │
                    │       backend verification
                    │               │
                    └───────┬───────┘
                            │
                    effective access
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
       Content            Audio          PracticeTest
          │                 │                 │
          └─────────────────┴─────────────────┘
                            │
                         Offline
```

Visual path:

```text
Exact Content revision
        ↓
ContentAssetRef(role=coverImage)
        ↓
ManifestAssetDescriptor
        ↓
existing sync / DownloadManager / AssetResolver
        ↓
Catalogue card / Detail hero / Continue Learning
```

This reviewed specification is the implementation baseline for VoxPrep first commercial release.
