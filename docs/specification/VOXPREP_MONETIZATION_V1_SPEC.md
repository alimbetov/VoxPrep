# VoxPrep Monetization v1 — FREE First Block + Lifetime Full Unlock

**Status:** Proposed / implementation-ready  
**Target:** first commercial release  
**Updated:** 2026-11-02  
**Scope:** Flutter mobile + Backend + Google Play + Apple App Store + Content visual assets

## 1. Product decision

VoxPrep is distributed as a free application.

Commercial model:

```text
FREE INSTALL
    ↓
First Knowledge Block = FREE
    ↓
All remaining Knowledge Blocks = LOCKED
    ↓
Full Unlock ≈ USD 4.99
    ↓
ONE-TIME PURCHASE
    ↓
FULL access without expiration
```

There are no subscriptions, trials, advertisements, VoxPrep user accounts, email/password login, coins, consumables, or external payment flows in v1.

Commercial product identifier:

```text
voxprep_full_unlock
```

Platform product types:

```text
Google Play  → one-time product, non-consumed
Apple        → non-consumable In-App Purchase
```

The USD 4.99 value is a reference base price only. Flutter MUST display the localized Store price returned by Google Play / App Store and MUST NOT hardcode `$4.99` as authoritative pricing.

---

## 2. Store compliance baseline

### 2.1 Google Play

Digital content/functionality unlocked inside the Google Play distributed application MUST use Google Play Billing.

For a new production release:

```text
MUST   use a currently supported Play Billing Library version
TARGET Play Billing 9.x
MIN    Play Billing 8.x while supported by Google Play
```

Do not build new monetization code on Billing Library 7 or removed/deprecated SKU/history APIs.

The Full Unlock product MUST NOT be consumed. A successful completed purchase MUST be acknowledged after authoritative verification and entitlement delivery.

The implementation MUST support:

- ProductDetails and localized pricing;
- purchase launch;
- PURCHASED state;
- PENDING state;
- cancellation/failure;
- current purchase query / restore;
- server-side verification;
- acknowledgement;
- refund/revocation reconciliation;
- idempotent repeated processing.

### 2.2 Apple App Store

Unlocking the full version / premium digital content MUST use Apple In-App Purchase.

The product MUST be configured as:

```text
Product ID: voxprep_full_unlock
Type: Non-Consumable
```

New implementation MUST target StoreKit 2 semantics and signed transaction data rather than building a new solution around the legacy `/verifyReceipt` endpoint.

The implementation MUST support:

- StoreKit Product and localized pricing;
- purchase;
- verified transaction handling;
- current entitlements;
- Restore Purchases;
- backend verification of signed transaction information;
- transaction finishing only after successful entitlement delivery;
- refund/revocation handling;
- App Store Server Notifications V2 where server notifications are used.

### 2.3 No alternative checkout in v1

The mobile app MUST NOT use the following to unlock FULL access:

```text
Kaspi transfer
bank card entered into VoxPrep
Stripe checkout
QR payment
crypto
external license code
manual FULL grant from an unverified client request
```

Regional alternative-billing programs are outside Monetization v1 scope.

---

## 3. Access domain

Introduce only two access levels:

```dart
enum AccessLevel {
  free,
  full,
}
```

Semantics:

```text
FREE → access only to FREE Knowledge Blocks
FULL → access to all commercially available Knowledge Blocks
```

Do NOT introduce subscription-specific domain types in v1:

```text
Subscription
MonthlyPlan
AnnualPlan
Trial
AutoRenewal
```

---

## 4. Catalogue contract

Each top-level Knowledge Block MUST explicitly contain an access classification:

```text
FREE
FULL
```

Initial commercial configuration:

```text
Knowledge Block 1 → FREE
Knowledge Block 2 → FULL
Knowledge Block 3 → FULL
Knowledge Block 4 → FULL
...
```

The client MUST NOT determine free access through `index == 0`, `position == 1`, localized title, or another presentation-only property.

`KnowledgeBlock.accessLevel` is the catalogue source of truth.

This allows the backend/catalogue to change the free set later without publishing a new Flutter version.

---

## 5. Access inheritance

In Monetization v1, access is inherited from the owning Knowledge Block.

```text
KnowledgeBlock
    ↓
Topic / Collection membership
    ↓
Content
    ↓
Audio
    ↓
PracticeTest
    ↓
Downloadable assets
```

A child of a FULL Knowledge Block requires FULL access unless a future specification explicitly introduces a more granular override.

Do not duplicate FREE/FULL flags across every content record in v1 unless required by an existing canonical contract.

---

## 6. Catalogue UX

A FREE learner MUST see the full catalogue, including locked blocks.

Example:

```text
English Basics             ✓ Free
Interview Preparation      🔒 Full
Java Interview             🔒 Full
System Design              🔒 Full
```

Locked blocks are visible but not navigable into protected content.

When a FREE learner attempts to open a FULL block, the client MUST open the Full Unlock screen instead of the protected content.

---

## 7. Full Unlock screen

The screen MUST contain at least:

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

The displayed price MUST come from Store product metadata.

Do not promise `all future content forever` in product copy in v1. The commercial promise is lifetime ownership of the Full Unlock entitlement for commercially available VoxPrep content covered by that entitlement.

---

# PART II — Content Visual Asset v1

## 8. Product goal for content images

VoxPrep content currently has rich textual metadata and audio capability but no canonical visual asset. Content Visual Asset v1 adds one optional cover/hero image to an exact Content revision.

The image exists to improve:

- catalogue scanning;
- perceived product quality;
- content recognition;
- locked FULL-content merchandising;
- Content Detail presentation;
- Continue Learning recognition.

The image capability MUST remain independent from monetization state.

```text
Content.coverImage → presentation
AccessLevel         → authorization
```

A cover image MUST NOT itself grant access to protected content.

---

## 9. Visual scope

V1 supports exactly one optional visual asset per exact Content revision:

```text
ContentRevision
└── coverImage? : ContentImageRef
```

V1 explicitly does NOT introduce:

```text
image per TopicSection
image per vocabulary example
image per interview question
image per PracticeTest question
image galleries
inline rich-media blocks
multiple hero images
video thumbnails generated by VoxPrep
```

Those require a future InlineMedia / QuestionMedia specification.

---

## 10. Canonical content contract

`TypedContentPayload` (or its current canonical equivalent) MUST gain an optional `coverImage` field.

Recommended logical contract:

```yaml
coverImage:
  oneOf:
    - $ref: '#/components/schemas/ContentImageRef'
    - type: 'null'
```

Recommended schema:

```yaml
ContentImageRef:
  type: object
  additionalProperties: false
  required:
    - assetId
    - checksum
    - mimeType
  properties:
    assetId:
      type: string
      minLength: 1
    checksum:
      type: string
      pattern: '^[0-9a-f]{64}$'
    mimeType:
      type: string
      enum:
        - image/webp
        - image/jpeg
        - image/png
    width:
      type:
        - integer
        - 'null'
      minimum: 1
    height:
      type:
        - integer
        - 'null'
      minimum: 1
    altText:
      type:
        - string
        - 'null'
```

The exact names MAY be aligned with the existing FileAsset/AssetResolver contracts, but the semantics MUST remain equivalent.

The API MUST NOT expose a raw storage path as the canonical identity of the image.

---

## 11. Asset identity, not URL identity

The canonical content contract MUST NOT model the image as an authoritative mutable URL:

```text
DO NOT:
imageUrl = https://...
```

Instead:

```text
Content revision
      ↓
ContentImageRef
      ↓
assetId + checksum
      ↓
manifest / asset metadata
      ↓
AssetResolver
      ↓
local cached asset OR authorized remote asset
```

A transport URL may be generated/resolved at runtime, but it is not the durable identity of the image.

---

## 12. Exact-revision ownership

The cover image belongs to the exact Content revision.

Example:

```text
Content revision 4
├── title
├── body
├── audio refs
└── coverImage = image-A
```

Changing the canonical cover image MUST create a new exact content revision or otherwise participate in the existing revision/checksum semantics so that the published revision is reproducible.

The following is forbidden:

```text
same exact revision/checksum
but mutable cover image silently changes later
```

This requirement protects:

- deterministic manifests;
- offline correctness;
- exact-revision resume semantics;
- cache consistency;
- publication reproducibility.

---

## 13. Image formats and dimensions

Preferred v1 authoring profile:

```text
Aspect ratio:     16:9
Recommended size: 1200 × 675
Preferred format: WebP
Fallback formats: JPEG, PNG
```

Guidelines:

```text
WebP/JPEG target payload: approximately 80–300 KB where quality permits
PNG: only when transparency or lossless diagram quality is materially useful
```

Very large original images MUST NOT be delivered unchanged to mobile when a production-sized rendition can be stored/generated.

The app MUST tolerate valid dimensions other than exactly 1200×675, but authoring/administration SHOULD validate that content covers are suitable for 16:9 presentation.

---

## 14. One image, multiple presentations

V1 MUST use one canonical cover image for multiple UI surfaces.

```text
coverImage
├── Catalogue card thumbnail
├── Content Detail hero
└── Continue Learning thumbnail
```

Do NOT introduce separate canonical `thumbnailImage`, `cardImage`, and `heroImage` fields in v1.

Flutter MAY resize/crop the same image for each surface.

A future CDN/backend optimization MAY derive renditions such as:

```text
320×180
640×360
1200×675
```

without changing the canonical Content revision semantics, provided derived renditions are deterministic projections of the same source asset.

---

## 15. Catalogue card behavior

If `coverImage != null`, a Content card SHOULD render the image in a 16:9 or equivalent stable card region using a deterministic crop policy such as `BoxFit.cover`.

Example:

```text
┌──────────────────────────────┐
│          COVER IMAGE         │
├──────────────────────────────┤
│ Tell Me About Yourself       │
│ Interview • B1 • 5 min       │
│                          🔒   │
└──────────────────────────────┘
```

Image rendering MUST NOT move important text metadata into the image itself. Title, level, type, duration and lock state remain semantic UI elements.

---

## 16. Content Detail behavior

If `coverImage != null`, Content Detail SHOULD render the image as a hero visual after title/subtitle and before the main content body.

Recommended hierarchy:

```text
Back / context
Title
Subtitle
Hero cover image
Category • Level • duration
Audio controls where applicable
Description / typed body
```

The image MUST NOT interfere with audio playback, LISTENED semantics, Continue Learning, or exact-revision resume logic.

---

## 17. Continue Learning behavior

Continue Learning MAY render the same cover image as a compact thumbnail.

The thumbnail is presentation-only.

Continue Learning target selection MUST remain deterministic and MUST continue to revalidate publication/access independently from whether an image exists.

Missing or failed image loading MUST NOT make Continue Learning unavailable.

---

## 18. FREE/FULL visibility rule for images

The canonical cover image is catalogue merchandising metadata and MAY be visible to FREE users even when the owning Content belongs to a FULL Knowledge Block.

Required v1 behavior:

```text
FULL content card metadata   → visible
FULL content cover image     → visible
FULL lock indicator          → visible
FULL protected body          → denied to FREE
FULL audio                   → denied to FREE
FULL PracticeTest            → denied to FREE
FULL downloadable body asset → denied to FREE
```

This is intentional: locked content should communicate value before purchase.

The backend/manifest design MUST therefore distinguish a cover image that is safe as preview/catalogue metadata from protected content assets.

---

## 19. Preview asset classification

To prevent access logic from becoming implicit, image assets SHOULD have explicit delivery semantics, for example:

```text
CATALOGUE_PREVIEW
PROTECTED_CONTENT
```

or an equivalent existing asset role.

`coverImage` for v1 is classified as preview-safe catalogue media unless a future specification says otherwise.

A FREE user receiving the cover image MUST NOT imply permission to fetch other assets from the same Content revision.

---

## 20. Missing-image fallback

`coverImage` MUST remain optional.

If absent, unresolved, corrupt, or temporarily unavailable, Flutter MUST render a deterministic fallback rather than a broken-image control.

Fallback SHOULD depend on `ContentType`, for example:

```text
vocabulary → vocabulary/icon fallback
interview  → conversation/interview fallback
topic      → document/topic fallback
phrase     → quote fallback
shadowing  → headphones/audio fallback
```

The fallback MAY use an icon, gradient, type label, or deterministic combination, but MUST NOT require a network request.

Image failure MUST NOT block access to otherwise valid FREE/FULL content.

---

## 21. Accessibility

Where an image conveys meaningful information, `altText` SHOULD be provided by backend authoring and exposed through Flutter accessibility semantics.

For purely decorative images, Flutter MAY mark the image as decorative according to platform accessibility behavior.

`altText` MUST NOT be used as a business key or authorization input.

Text embedded inside an image MUST NOT be the only way essential learning information is presented.

---

## 22. Storage and backend binding

The image SHOULD use the existing FileAsset / object-storage architecture rather than creating a second media storage mechanism.

Target logical flow:

```text
Author/Admin
    ↓
upload image
    ↓
Backend FileAsset metadata
    ↓
RustFS / configured object storage
    ↓
Content revision references assetId/checksum
    ↓
publication manifest
    ↓
Flutter AssetResolver
```

The content domain stores stable references/metadata, not filesystem paths or object-storage credentials.

---

## 23. Publication semantics

A CURRENT publication containing Content with `coverImage` MUST include enough deterministic asset metadata for the client to resolve/download/cache the exact expected image.

Publication validation SHOULD fail closed for an invalid non-null image reference, for example:

```text
unknown assetId
checksum mismatch
unsupported MIME type
asset not publishable
asset belongs to incompatible revision/context
```

However `coverImage = null` is valid.

---

## 24. Sync and manifest integration

Content Visual Asset v1 MUST reuse the existing production sync pipeline.

Expected flow:

```text
publication metadata
    ↓
manifest includes cover asset metadata
    ↓
ContentSyncCoordinator
    ↓
DownloadManager where required
    ↓
AssetResolver
    ↓
Flutter image rendering
```

Do NOT introduce a parallel `ImageSyncCoordinator` unless existing architecture demonstrably requires it.

Metadata and image asset state MUST remain restart-safe.

---

## 25. Download policy

Catalogue preview covers SHOULD be cheap to obtain and cache.

V1 MAY choose one of these implementation strategies:

```text
A. eager small preview download with catalogue metadata
B. lazy first-view download with cache
```

The chosen strategy MUST be deterministic, bounded, and compatible with offline behavior.

Recommended initial approach:

```text
small cover asset
→ lazy download
→ persistent cache
→ reuse across card/detail/continue surfaces
```

Do not download all full-resolution protected assets merely because catalogue covers are visible.

---

## 26. Offline behavior for images

If a cover image has already been downloaded and its checksum is valid, it SHOULD remain renderable offline.

If not available offline:

```text
render deterministic fallback
```

The app MUST NOT block Content Detail solely because a cover image is missing offline.

Image cache eviction MUST follow existing content retention/storage policies rather than creating an unbounded independent cache.

---

## 27. Corruption and checksum behavior

If a cached image fails checksum validation:

```text
cached image → reject
fallback     → render
network available → safe re-download permitted
```

The learner MUST NOT see raw checksum, filesystem, RustFS, URL-signing, or storage exception text.

Repeated corruption/retry MUST remain bounded and must not create a retry loop on app startup.

---

## 28. Image loading safety

Flutter MUST treat image decoding as untrusted media input.

The implementation SHOULD enforce practical bounds on:

- supported MIME types;
- expected byte size;
- decoded dimensions where platform APIs permit;
- network timeouts;
- retry count.

Unsupported media MUST fail to the deterministic fallback.

SVG is OUT OF SCOPE for Content Visual Asset v1 unless a later security/rendering review explicitly adds it.

---

## 29. Authoring requirements

Backend/admin authoring SHOULD support:

```text
upload cover image
replace cover image by creating/updating draft revision
preview image
remove optional image
validate MIME type
validate basic dimensions
calculate checksum
associate asset with draft Content revision
```

Publication is the boundary at which the exact image reference becomes immutable for that exact revision.

---

## 30. Content visual acceptance scenarios

Mandatory visual qualification:

```text
IMG-A01 Content without image renders deterministic fallback
IMG-A02 Content with valid WebP renders card image
IMG-A03 Same cover renders Content Detail hero
IMG-A04 Same cover can render Continue Learning thumbnail
IMG-A05 Cover image survives restart after cache/download
IMG-A06 Cached cover renders offline
IMG-A07 Missing offline cover falls back without blocking content
IMG-A08 Corrupt cached cover is rejected and falls back
IMG-A09 Checksum mismatch cannot silently display stale/wrong image
IMG-A10 Unsupported MIME fails safely
IMG-A11 Image load failure exposes no raw backend/storage error
IMG-A12 Changing canonical cover changes exact revision/checksum semantics
IMG-A13 Old exact revision continues to resolve its old exact cover
IMG-A14 FULL locked card may display cover to FREE learner
IMG-A15 FREE learner still cannot open protected body through image route
IMG-A16 FREE learner cannot derive protected asset authorization from preview asset
IMG-A17 Cover image is optional in publication
IMG-A18 Invalid non-null cover reference fails publication qualification
IMG-A19 Image cache remains bounded by existing retention policy
IMG-A20 Image state does not alter FAVORITE/LISTENED/COMPLETED
```

---

# PART III — Purchase and entitlement architecture

## 31. Flutter access architecture

Add an isolated feature boundary:

```text
lib/features/access/
├── domain/
│   ├── access_level.dart
│   ├── access_snapshot.dart
│   ├── store_product.dart
│   └── purchase_result.dart
├── application/
│   ├── access_controller.dart
│   └── purchase_controller.dart
├── infrastructure/
│   ├── access_repository.dart
│   ├── billing_repository.dart
│   ├── google_play_billing_adapter.dart
│   └── apple_storekit_adapter.dart
└── presentation/
    ├── full_unlock_page.dart
    ├── locked_block.dart
    └── restore_purchases_action.dart
```

The exact physical paths may follow repository conventions, but architectural separation MUST remain.

Content, learner-state, audio, test and sync domains MUST NOT directly depend on Google/Apple SDK types.

Billing abstraction:

```dart
abstract interface class BillingRepository {
  Future<StoreProduct> loadFullUnlockProduct();
  Future<PurchaseResult> purchaseFullUnlock();
  Future<PurchaseResult> restoreFullUnlock();
}
```

---

## 32. Client access state

Recommended state machine:

```text
IDLE
  ↓
PURCHASING
  ↓
PENDING / VERIFYING
  ↓
FULL
```

Alternative paths:

```text
CANCELLED → keep current access
FAILED    → keep current access
INVALID   → keep current authoritative access
```

A purchase error MUST NOT erase a previously verified FULL snapshot.

Flutter MUST NOT grant trusted FULL access merely because a local SDK callback says `success`.

---

## 33. Backend purchase model

Do NOT create a VoxPrep `User` entity solely for monetization.

Persist a technical Store purchase record, for example:

```text
StorePurchase
-----------------------------
id
provider
productId
storePurchaseId
purchaseToken           // Google where applicable
transactionId           // Apple where applicable
originalTransactionId   // Apple where applicable
status
purchasedAt
verifiedAt
revokedAt
createdAt
updatedAt
```

Provider:

```text
GOOGLE_PLAY
APP_STORE
```

Status:

```text
PURCHASED
REFUNDED
REVOKED
```

Database uniqueness MUST prevent duplicate processing of the same authoritative Store purchase.

---

## 34. Installation entitlement

VoxPrep continues using anonymous installation identity.

Add a technical entitlement binding, for example:

```text
InstallationEntitlement
-----------------------
installationId
entitlement       // FULL
sourcePurchaseId
verifiedAt
updatedAt
```

`installationId` is NOT a user account and MUST NOT be treated as proof that a purchase exists.

Trust chain:

```text
Google Play / App Store transaction
             ↓
backend verification
             ↓
verified StorePurchase
             ↓
InstallationEntitlement
             ↓
Flutter AccessSnapshot
```

---

## 35. Access API

Backend MUST expose an access endpoint compatible with the existing installation-identity mechanism.

Example:

```http
GET /api/v1/access
```

FREE response:

```json
{
  "accessLevel": "FREE"
}
```

FULL response:

```json
{
  "accessLevel": "FULL",
  "verifiedAt": "2026-11-02T10:00:00Z"
}
```

The exact URI may align with the backend's established versioning convention.

---

## 36. Google purchase flow

Target flow:

```text
query ProductDetails
        ↓
show localized price
        ↓
launchBillingFlow
        ↓
PurchasesUpdatedListener
        ↓
PENDING ?
  yes → do not grant FULL
        ↓ no
PURCHASED
        ↓
send productId + purchaseToken to backend
        ↓
backend verifies with Google Play Developer API
        ↓
VALID
        ↓
persist StorePurchase
        ↓
grant InstallationEntitlement FULL
        ↓
acknowledge purchase
        ↓
return FULL
```

The product MUST NOT be consumed.

Repeated verification / acknowledgement MUST be idempotent.

---

## 37. Google restore

Restore/reconciliation MUST use current purchases from the supported Play Billing API (`queryPurchasesAsync` semantics for the current Billing generation).

Do not build new code around removed purchase-history APIs.

A purchase can complete while the application is not running, therefore Android MUST reconcile purchases when appropriate after billing connection/resume, without blocking every startup on a Store network round-trip.

Restore flow:

```text
fresh installation
    ↓
new installationId
    ↓
query current Store purchases
    ↓
voxprep_full_unlock found
    ↓
backend verification
    ↓
FULL attached to new installation
```

---

## 38. Apple purchase flow

Target StoreKit 2 flow:

```text
Product.products(...)
        ↓
localized Product
        ↓
purchase()
        ↓
VerificationResult
        ↓
verified Transaction
        ↓
signed transaction data / transaction identifiers
        ↓
VoxPrep backend verification
        ↓
VALID
        ↓
persist StorePurchase
        ↓
grant InstallationEntitlement FULL
        ↓
transaction.finish()
        ↓
return FULL
```

Transaction MUST NOT be finished before entitlement delivery/persistence is safely completed.

New implementation MUST NOT use legacy receipt verification as its architectural foundation.

---

## 39. Apple restore

The Full Unlock screen MUST provide an explicit `Restore Purchases` action.

Restore MUST recover an existing non-consumable entitlement for the current App Store account and then pass the recovered transaction through normal backend verification.

Do not trigger intrusive interactive restore automatically on every application startup.

Expected flow:

```text
fresh install
    ↓
FREE
    ↓
Restore Purchases
    ↓
StoreKit current entitlement / sync
    ↓
verified Full Unlock transaction
    ↓
backend verification
    ↓
FULL
```

---

## 40. Cross-platform limitation

Monetization v1 does NOT promise cross-store ownership portability.

```text
Google Play purchase → Android restore
Apple purchase       → Apple restore
```

The following is OUT OF SCOPE:

```text
buy on Android → automatically FULL on iPhone
buy on iPhone  → automatically FULL on Android
```

Supporting that later requires a stable VoxPrep account/recovery identity or another approved cross-platform entitlement strategy.

---

## 41. Backend authorization

Flutter locking is UX, not the security boundary.

Backend MUST independently authorize protected resources.

Decision table:

```text
Resource  Installation access  Result
FREE      FREE                 ALLOW
FREE      FULL                 ALLOW
FULL      FREE                 DENY
FULL      FULL                 ALLOW
```

Use a learner-safe business error such as:

```text
FULL_ACCESS_REQUIRED
```

Protected paths include at minimum:

- content detail;
- audio authorization/delivery;
- PracticeTest start/load;
- protected downloads;
- protected asset delivery/presigning;
- offline package acquisition;
- deep-link/direct-ID access;
- Continue Learning resolution.

Catalogue-preview cover images follow the explicit preview rule from Content Visual Asset v1 and are not protected-body authorization.

---

## 42. Existing VoxPrep subsystems

Monetization MUST remain orthogonal to learner state.

FREE → FULL MUST NOT reset or rewrite:

```text
FAVORITE
LISTENED
COMPLETED
PracticeTest attempts
Continue Learning
last-opened content
audio resume positions
```

### Audio

Existing Play/Pause/Resume/Seek/LISTENED semantics remain unchanged. Add an access gate before protected audio/asset authorization.

### PracticeTest

A test owned by a FULL Knowledge Block is unavailable to FREE access. Existing durable attempt semantics remain unchanged.

### DownloadManager

Before downloading a protected FULL asset, access MUST be authorized. A FREE installation cannot use the download path as a paywall bypass.

Catalogue-preview cover images are allowed according to their preview-safe role.

### AssetResolver

`file exists locally` MUST NOT be treated as proof that the installation owns FULL.

### Continue Learning

A saved resume target MUST be revalidated. FREE access cannot use a stale Continue Learning pointer or deep link to bypass FULL gating.

---

## 43. Local persistence and offline behavior

Flutter stores a local snapshot:

```text
AccessSnapshot
--------------
accessLevel
verifiedAt
source
```

The snapshot exists for:

- fast startup;
- restart durability;
- offline operation.

It is NOT authoritative proof of purchase.

After a successfully verified FULL purchase:

```text
FULL
 ↓
offline
 ↓
previously entitled/downloaded content remains usable
```

A temporary Store/backend outage MUST NOT immediately make a previously verified paying user unusable offline.

When authoritative online state later confirms refund/revocation, local entitlement MUST converge back to FREE according to synchronization policy.

---

## 44. Refunds and revocations

### Google

Production design MUST support reconciliation using current Google Play mechanisms, including Real-time Developer Notifications / Play Developer API and voided purchase reconciliation where applicable.

After authoritative refund/revocation:

```text
PURCHASED → REFUNDED / REVOKED
FULL      → FREE
```

### Apple

Production design MUST support App Store Server Notifications V2 where server notifications are used, including refund/revocation-related state.

A refund reversal or restored authoritative entitlement may re-grant FULL.

All Store event processing MUST be idempotent.

---

## 45. Privacy and Store declarations

VoxPrep v1 does not create user accounts, but that does NOT automatically mean `no data collected` for Store declarations.

Potentially relevant technical data includes, depending on actual implementation:

```text
installation/device-related identifier
purchase history / purchase identifier
transaction identifier
app interactions
backend request metadata
diagnostics / crash data
analytics data
```

Before release:

### Google Play

Complete Data Safety truthfully based on production behavior and all included SDKs.

### Apple

Complete App Privacy truthfully based on production behavior and all included SDKs.

### Privacy Policy

Publish a Privacy Policy explaining at minimum:

- what VoxPrep sends/stores;
- installation identity;
- purchase/transaction identifiers;
- that payment credentials are handled by Google/Apple rather than VoxPrep;
- learner-state data sent to backend, if any;
- image/content asset delivery telemetry if retained;
- retention/deletion approach;
- contact method.

Do not state broadly that VoxPrep stores `no user data` unless a final production audit supports that exact statement under Store definitions.

---

## 46. Learner-safe error model

Learner-visible errors MAY include:

```text
PURCHASE_CANCELLED
PURCHASE_PENDING
PURCHASE_UNAVAILABLE
PURCHASE_VERIFICATION_FAILED
RESTORE_NOT_FOUND
STORE_UNAVAILABLE
FULL_ACCESS_REQUIRED
CONTENT_IMAGE_UNAVAILABLE
```

The UI MUST NOT expose:

```text
raw backend body
stacktrace
Google exception text
Apple signed transaction data
purchaseToken
filesystem path
RustFS/object-storage path
presigned URL internals
database errors
checksum internals
```

Image-specific technical failures SHOULD normally degrade silently to fallback rather than interrupt learning.

---

## 47. Production bypass prohibition

Production composition MUST NOT contain an accessible path equivalent to:

```dart
accessLevel = AccessLevel.full;
```

based only on debug/client configuration.

Dev/test billing fakes MUST be dependency-injected and excluded or unreachable from production composition.

The same rule applies to protected asset authorization.

---

## 48. Store review readiness

### Google

Before production:

```text
supported Billing version
one-time product configured
Product ID exact match
localized price loading
pending purchase support
server verification
acknowledgement
restore/current purchase reconciliation
refund/revoke reconciliation
Data Safety
Privacy Policy
internal/closed purchase qualification
```

### Apple

Before App Review:

```text
non-consumable IAP configured
StoreKit 2 purchase path
signed transaction verification
Restore Purchases visible
transaction finish semantics
refund/revocation handling
App Privacy
Privacy Policy URL
Privacy Policy accessible from app
Sandbox/TestFlight qualification
App Review Notes explaining unlock flow
```

Suggested review note:

```text
VoxPrep is free to download.
The first Knowledge Block is available without purchase.
Opening locked learning content presents the non-consumable Full Unlock purchase.
Restore Purchases is available on the unlock screen.
Catalogue preview images may be visible before purchase; protected learning content remains locked.
```

---

# PART IV — Implementation roadmap

## 49. Monetization roadmap

```text
M1  Access contracts
    ├── AccessLevel
    ├── KnowledgeBlock.accessLevel
    └── FULL_ACCESS_REQUIRED

M2  Catalogue gating
    ├── locked blocks
    ├── navigation guard
    └── deep-link protection

M3  Access persistence
    ├── AccessController
    ├── AccessSnapshot
    └── restart/offline behavior

M4  Full Unlock UI
    ├── StoreProduct abstraction
    ├── localized price
    ├── purchase action
    └── Restore Purchases

M5  Google Play Billing
    ├── supported Billing generation
    ├── ProductDetails
    ├── purchase/pending/cancel
    └── queryPurchases restore

M6  Google backend
    ├── purchase verification
    ├── StorePurchase
    ├── idempotency
    ├── acknowledge
    └── refund/revoke reconciliation

M7  Backend authorization
    ├── Content
    ├── Audio
    ├── PracticeTest
    ├── protected Downloads
    └── Continue Learning

M8  Android commercial qualification

M9  Apple StoreKit 2

M10 Apple backend verification / notifications

M11 Apple commercial qualification
```

---

## 50. Content image roadmap

```text
IMG1  Canonical ContentImageRef contract
      └── optional coverImage on exact Content revision

IMG2  Backend asset binding
      ├── FileAsset/object storage
      ├── checksum
      ├── MIME/dimension validation
      └── preview-safe role

IMG3  Publication/manifest integration
      ├── exact revision binding
      └── fail-closed invalid non-null refs

IMG4  Flutter repository/model cutover
      └── cover image metadata persisted locally

IMG5  AssetResolver image support
      ├── local cache
      ├── safe remote resolution
      └── checksum validation

IMG6  Catalogue UI
      ├── card thumbnail
      ├── lock overlay independent from image
      └── deterministic fallback

IMG7  Content Detail hero

IMG8  Continue Learning thumbnail

IMG9  Offline/restart/retention qualification

IMG10 Adversarial image qualification
```

IMG work MAY proceed in parallel with billing infrastructure after contracts are frozen, because visual assets and purchase ownership are orthogonal domains.

Recommended dependency order:

```text
M1–M2
  ↓
IMG1–IMG3
  ↓
IMG4–IMG7
  ↓
M3–M8 Android commercial path
  ↓
IMG8–IMG10 hardening
  ↓
M9–M11 iOS commercial path
```

The exact sequencing MAY be adjusted to current branch readiness, but contract/revision semantics MUST precede production image delivery.

---

# PART V — Acceptance / Definition of Done

## 51. Monetization acceptance

```text
MON-A01 VoxPrep installs for free
MON-A02 first configured Knowledge Block works as FREE
MON-A03 remaining configured blocks are visible and locked
MON-A04 FREE cannot open protected content via UI
MON-A05 FREE cannot bypass lock via deep link/direct ID
MON-A06 Store price comes from platform Store
MON-A07 cancelled purchase does not grant FULL
MON-A08 pending purchase does not grant FULL
MON-A09 invalid purchase proof does not grant FULL
MON-A10 valid Google purchase grants FULL
MON-A11 Google purchase is acknowledged and not consumed
MON-A12 valid Apple transaction grants FULL
MON-A13 Apple transaction is finished only after entitlement delivery
MON-A14 repeated verification is idempotent
MON-A15 repeated restore is idempotent
MON-A16 restart preserves verified FULL
MON-A17 verified FULL remains usable offline
MON-A18 reinstall + same Google Store ownership can restore FULL
MON-A19 reinstall + same Apple Store ownership can restore FULL
MON-A20 refund/revoke converges FULL back to FREE
MON-A21 FREE→FULL preserves learner state
MON-A22 production contains no FULL bypass
MON-A23 raw Store/token/backend errors never reach learner UI
```

---

## 52. Content image acceptance

```text
IMG-A01 optional null cover is valid
IMG-A02 valid cover renders on catalogue card
IMG-A03 same cover renders on Content Detail
IMG-A04 same cover may render on Continue Learning
IMG-A05 FULL locked content cover remains preview-visible to FREE
IMG-A06 cover visibility does not authorize protected body/audio/test
IMG-A07 image identity uses asset reference/checksum, not mutable raw URL
IMG-A08 canonical image is bound to exact content revision
IMG-A09 image change cannot silently mutate an existing exact revision
IMG-A10 cached valid cover survives restart
IMG-A11 cached valid cover renders offline
IMG-A12 absent offline cover renders fallback
IMG-A13 corrupt/checksum-invalid cover is rejected
IMG-A14 invalid image reference fails safely/fail-closed at publication boundary
IMG-A15 unsupported MIME fails safely
IMG-A16 image failures expose no storage/filesystem internals
IMG-A17 image cache obeys bounded retention policy
IMG-A18 image rendering does not affect learner-state semantics
IMG-A19 old exact revision can still resolve its own exact image semantics
IMG-A20 no duplicate image-specific sync architecture is introduced without need
```

---

## 53. Store/privacy acceptance

```text
STORE-A01 Google product configured as one-time/non-consumed
STORE-A02 Apple product configured as non-consumable
STORE-A03 Restore Purchases available
STORE-A04 Google Billing dependency is currently supported at release time
STORE-A05 Apple flow uses StoreKit 2 architecture
STORE-A06 Google Data Safety matches production behavior
STORE-A07 Apple App Privacy matches production behavior
STORE-A08 Privacy Policy published and reachable
STORE-A09 no external payment bypass in v1
STORE-A10 no account is introduced solely for purchase ownership
```

---

## 54. Final target architecture

```text
                         VOXPREP
                            │
                      FREE INSTALL
                            │
                ┌───────────┴───────────┐
                │                       │
        catalogue metadata       preview cover images
                │                       │
                └───────────┬───────────┘
                            │
                    first block FREE
                            │
                    remaining FULL 🔒
                            │
                   Unlock Full VoxPrep
                      localized price
                            │
                ┌───────────┴───────────┐
                │                       │
         Google Play Billing       Apple StoreKit 2
                │                       │
                └───────────┬───────────┘
                            │
                    backend verification
                            │
                    verified entitlement
                            │
                           FULL
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
       Content            Audio          Practice Tests
          │                 │                 │
          └─────────────────┴─────────────────┘
                            │
                         Offline
```

Visual delivery remains a separate concern:

```text
Exact Content revision
        ↓
optional coverImage
        ↓
FileAsset / object storage
        ↓
publication manifest
        ↓
AssetResolver
        ↓
card / hero / Continue Learning
```

---

## 55. Final v1 constraints

Commercial and visual v1 deliberately stay small:

```text
1 Store product
2 access levels
0 subscriptions
0 VoxPrep accounts
0 passwords
0 external checkout
1 optional canonical cover image per Content revision
1 existing asset/sync pipeline reused
```

The implementation MUST prefer extension of existing content publication, FileAsset, sync, DownloadManager and AssetResolver boundaries over creating parallel monetization/media infrastructure.

This specification is the implementation baseline for VoxPrep first commercial release.