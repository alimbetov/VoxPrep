# VoxPrep Monetization v1 — FREE First Block + Lifetime Full Unlock

**Status:** Proposed / implementation-ready  
**Target:** first commercial release  
**Updated:** 2026-11-02  
**Scope:** Flutter mobile + Backend + Google Play + Apple App Store

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

The commercial product identifier is:

```text
voxprep_full_unlock
```

Platform product types:

```text
Google Play  → one-time product, non-consumed
Apple        → non-consumable In-App Purchase
```

The USD 4.99 value is a reference base price only. The application MUST display the localized Store price returned by Google Play / App Store and MUST NOT hardcode `$4.99` as authoritative pricing in the Flutter UI.

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

The mobile app MUST NOT use the following as a way to unlock FULL access:

```text
Kaspi transfer
bank card entered into VoxPrep
Stripe checkout
QR payment
crypto
license code bought externally
manual backend grant from an unverified client request
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

Example:

```json
{
  "id": "english-basics",
  "title": "English Basics",
  "accessLevel": "FREE"
}
```

```json
{
  "id": "interview-preparation",
  "title": "Interview Preparation",
  "accessLevel": "FULL"
}
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
Topic
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

The displayed price MUST come from the Store product metadata.

Do not promise `all future content forever` in product copy in v1. The commercial promise is lifetime access to the Full Unlock entitlement and the commercially available VoxPrep catalogue under that entitlement.

---

## 8. Flutter architecture

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

The exact physical paths may follow the repository's current feature conventions, but the architectural separation MUST remain.

The content, learner-state, audio, test and sync domains MUST NOT directly depend on Google/Apple SDK types.

Billing abstraction:

```dart
abstract interface class BillingRepository {
  Future<StoreProduct> loadFullUnlockProduct();
  Future<PurchaseResult> purchaseFullUnlock();
  Future<PurchaseResult> restoreFullUnlock();
}
```

---

## 9. Client access state

Recommended client state machine:

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

The Flutter client MUST NOT grant trusted FULL access merely because a local SDK callback says `success`.

---

## 10. Backend purchase model

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

## 11. Installation entitlement

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

## 12. Access API

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

The exact URI may be aligned with the backend's established versioning convention.

---

## 13. Google purchase flow

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

## 14. Google restore

Restore/reconciliation MUST use current purchases from the supported Play Billing API (`queryPurchasesAsync` semantics for the current Billing generation).

Do not build new code around removed purchase-history APIs.

A purchase can complete while the application is not running, therefore the Android implementation MUST reconcile purchases when appropriate after billing connection/resume, without blocking every application startup on a Store network round-trip.

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

## 15. Apple purchase flow

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

## 16. Apple restore

The Full Unlock screen MUST provide an explicit `Restore Purchases` action.

Restore MUST recover an existing non-consumable entitlement for the current App Store account and then pass the recovered transaction through normal backend verification.

Do not trigger an intrusive interactive restore automatically on every application startup.

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

## 17. Cross-platform limitation

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

## 18. Backend authorization

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
- downloads;
- asset delivery/presigning;
- offline package acquisition;
- deep-link/direct-ID access;
- Continue Learning resolution.

---

## 19. Existing VoxPrep subsystems

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

Before downloading a FULL asset, access MUST be authorized. A FREE installation cannot use the download path as a paywall bypass.

### AssetResolver

`file exists locally` MUST NOT be treated as proof that the installation owns FULL.

### Continue Learning

A saved resume target MUST be revalidated. FREE access cannot use a stale Continue Learning pointer or deep link to bypass FULL gating.

---

## 20. Local persistence and offline behavior

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

When authoritative online state later confirms refund/revocation, the local entitlement MUST converge back to FREE according to the synchronization policy.

---

## 21. Refunds and revocations

### Google

Production design MUST support reconciliation using the current Google Play mechanisms, including Real-time Developer Notifications / Play Developer API and voided purchase reconciliation where applicable.

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

## 22. Privacy and Store declarations

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

Publish a Privacy Policy that explains at minimum:

- what VoxPrep sends/stores;
- installation identity;
- purchase/transaction identifiers;
- that payment credentials are handled by Google/Apple rather than VoxPrep;
- learner-state data sent to backend, if any;
- retention/deletion approach;
- contact method.

Do not state broadly that VoxPrep stores `no user data` unless a final production audit supports that exact statement under Store definitions.

---

## 23. Error model

Learner-safe errors may include:

```text
PURCHASE_CANCELLED
PURCHASE_PENDING
PURCHASE_UNAVAILABLE
PURCHASE_VERIFICATION_FAILED
RESTORE_NOT_FOUND
STORE_UNAVAILABLE
FULL_ACCESS_REQUIRED
```

Never expose to the learner UI:

```text
raw backend response
stack trace
purchaseToken
Apple signed JWS payload
filesystem path
database error
Google/Apple internal exception text
```

---

## 24. Production composition safety

Fake billing / test access may be used in development and automated tests through dependency injection.

Production composition MUST NOT contain a reachable bypass such as:

```dart
accessLevel = AccessLevel.full;
```

based on debug flags, query parameters, hidden taps, environment mistakes, or client-provided `isFull=true`.

The backend MUST never trust a client-supplied access level as authoritative.

---

## 25. Store review/test readiness

### Google Play

Before production rollout verify:

- supported Play Billing dependency;
- one-time product configured and activated;
- correct package/product configuration;
- localized product details;
- purchase;
- pending purchase;
- cancellation;
- already-owned/current-purchase behavior;
- server verification;
- acknowledgement;
- reinstall/restore;
- refund/revocation reconciliation;
- Data Safety;
- Privacy Policy.

Use appropriate Play test tracks/license testers.

### Apple

Before App Review verify:

- non-consumable IAP configured;
- StoreKit 2 product loading;
- purchase;
- verified transaction handling;
- backend verification;
- transaction finishing;
- Restore Purchases;
- reinstall/restore;
- refund/revocation path;
- App Privacy;
- Privacy Policy URL/in-app accessibility;
- App Review Notes explain where the IAP and Restore flow are found.

Suggested App Review note:

```text
VoxPrep is free to download. The first Knowledge Block is available for free.
Opening any locked Knowledge Block presents the non-consumable Full Unlock purchase.
Restore Purchases is available on the Full Unlock screen.
```

---

## 26. Mandatory qualification matrix

```text
A01 FREE can open FREE Knowledge Block
A02 FREE sees FULL Knowledge Blocks as locked
A03 FREE cannot open FULL Knowledge Block
A04 FREE cannot fetch FULL content by direct ID
A05 FREE cannot download FULL asset
A06 FREE cannot play FULL audio
A07 FREE cannot start FULL PracticeTest
A08 locked deep link fails closed
A09 Continue Learning cannot bypass access

A10 product price comes from Store metadata
A11 cancelled purchase does not grant FULL
A12 pending purchase does not grant FULL
A13 invalid/forged transaction does not grant FULL

A14 valid Google purchase grants FULL
A15 Google purchase is acknowledged
A16 Google Full Unlock is never consumed
A17 valid Apple purchase grants FULL
A18 Apple transaction is finished only after entitlement delivery

A19 repeated verify is idempotent
A20 repeated restore is idempotent
A21 repeated Store notification is idempotent

A22 restart preserves verified FULL
A23 offline restart preserves verified FULL
A24 Android reinstall + same Store ownership restores FULL
A25 iOS reinstall + same Store ownership restores FULL
A26 fresh installation without restored purchase is FREE

A27 authoritative refund/revoke converges to FREE
A28 authoritative refund reversal/restored entitlement can return FULL

A29 FREE→FULL preserves learner state
A30 purchase failure does not erase an existing valid FULL snapshot
A31 raw Store/backend errors and tokens never reach learner UI
A32 production build contains no FULL bypass
```

---

## 27. Implementation roadmap

### M1 — Access contracts

```text
AccessLevel
KnowledgeBlock.accessLevel
FULL_ACCESS_REQUIRED
```

### M2 — Catalogue gating

```text
locked rendering
navigation guard
access inheritance
deep-link protection
Continue Learning revalidation
```

### M3 — Local access state

```text
AccessController
AccessSnapshot
restart durability
offline behavior
```

### M4 — Full Unlock UI

```text
StoreProduct abstraction
localized price
Unlock screen
Restore Purchases
```

### M5 — Google Play Billing

```text
supported Billing 8+/target 9.x
ProductDetails
purchase
pending/cancel/failure
current purchase query
restore
```

### M6 — Google backend

```text
StorePurchase persistence
server verification
idempotency
acknowledgement
RTDN/reconciliation
refund/revoke
```

### M7 — Backend authorization

```text
Content
Audio
PracticeTest
Download
Asset
Continue Learning
```

### M8 — Android commercial acceptance

```text
purchase
pending
cancel
restore
restart
offline
reinstall
refund/revoke
adversarial bypass qualification
```

**Android may be commercially released after M8 is exact-SHA GREEN and Store configuration is accepted.**

### M9 — Apple StoreKit 2

```text
Product
purchase
VerificationResult
current entitlements
Restore Purchases
finish
signed transaction data
```

### M10 — Apple backend

```text
signed transaction verification
transaction/originalTransaction identity
Server Notifications V2
refund/reversal/revocation
```

### M11 — Apple commercial acceptance

```text
Sandbox/TestFlight qualification
purchase
cancel
restore
restart
offline
reinstall
refund/revoke
App Review readiness
```

**iOS may be commercially released after M11 is exact-SHA GREEN and App Review/IAP review is accepted.**

---

## 28. Out of scope

Do NOT add in Monetization v1:

```text
subscriptions
monthly/yearly plans
trials
advertising
VoxPrep registration
email/password login
social login
cross-platform Android↔iOS entitlement transfer
multiple paid tiers
consumable credits/coins
corporate licensing
web checkout
external unlock codes
```

---

## 29. Definition of Done

Monetization v1 is production-ready only when all of the following are true:

```text
✅ app is free to install
✅ first Knowledge Block is fully usable with FREE access
✅ remaining Knowledge Blocks are visible and locked
✅ exactly one Full Unlock commercial product exists
✅ localized price comes from the Store
✅ one-time purchase grants FULL
✅ FULL does not expire under normal ownership
✅ Android uses a currently supported Play Billing version
✅ Google purchase is verified server-side
✅ Google purchase is acknowledged and never consumed
✅ Apple implementation uses StoreKit 2 semantics
✅ Apple transaction is verified and correctly finished
✅ Restore Purchases works
✅ reinstall with same Store ownership restores FULL
✅ no VoxPrep account/email/password is required
✅ cross-store restore is not promised in v1
✅ backend protects all FULL resources
✅ client/local cache is not authoritative purchase proof
✅ verified FULL remains usable through restart/offline operation
✅ refund/revocation can remove entitlement after authoritative reconciliation
✅ learner state survives access transitions
✅ Store errors/tokens are learner-safe
✅ Privacy Policy exists
✅ Google Data Safety matches production behavior
✅ Apple App Privacy matches production behavior
✅ no external payment bypass exists
✅ no production FULL bypass exists
✅ Android/iOS commercial acceptance suites are GREEN
```

---

## 30. Final architecture

```text
                         VOXPREP
                            │
                      FREE INSTALL
                            │
                  FIRST BLOCK — FREE
                            │
                    BLOCK 2+ — LOCKED
                            │
                    FULL UNLOCK ONCE
                            │
                  localized Store price
                            │
              ┌─────────────┴─────────────┐
              │                           │
      Google Play Billing             StoreKit 2
              │                           │
        purchaseToken              signed transaction
              │                           │
              └─────────────┬─────────────┘
                            │
                      VoxPrep Backend
                            │
                  authoritative verify
                            │
                 ┌──────────┴──────────┐
                 │                     │
              INVALID                VALID
                 │                     │
                FREE                  FULL
                                       │
                ┌──────────────────────┼──────────────────────┐
                ↓                      ↓                      ↓
             Content                 Audio               PracticeTest
                │                      │                      │
                └──────────────────────┴──────────────────────┘
                                       │
                                  Downloads
```

Commercial v1 intentionally remains small:

```text
1 commercial product
2 access levels
0 subscriptions
0 VoxPrep accounts
0 external payment flows
```

---

## 31. Official references used for Store compliance

Google Play / Android:

- Google Play payments policy: https://support.google.com/googleplay/android-developer/answer/9858738
- Play Billing deprecation/support FAQ: https://developer.android.com/google/play/billing/deprecation-faq
- Play Billing release notes: https://developer.android.com/google/play/billing/release-notes
- Integrate Play Billing: https://developer.android.com/google/play/billing/integrate
- One-time product lifecycle: https://developer.android.com/google/play/billing/lifecycle/one-time
- Billing security / server verification: https://developer.android.com/google/play/billing/security
- Google Play Data Safety: https://support.google.com/googleplay/android-developer/answer/10787469

Apple:

- App Store Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Configure In-App Purchases: https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases
- StoreKit Transaction: https://developer.apple.com/documentation/storekit/transaction
- Restore purchased products: https://developer.apple.com/documentation/storekit/restoring-purchased-products
- App Store Server Notifications: https://developer.apple.com/documentation/appstoreservernotifications
- App Privacy details: https://developer.apple.com/app-store/app-privacy-details/

These references are compliance inputs, not substitutes for checking the current Store requirements immediately before each production submission.
