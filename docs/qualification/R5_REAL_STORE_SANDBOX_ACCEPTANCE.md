# R5.5–R5.7 — Real Google Play / Apple sandbox acceptance

Status: **RUNBOOK / NOT EXECUTED**. Simulated verifier tests do not constitute
real provider acceptance. Never attach purchase tokens, private keys, JWS or
installation bearer tokens to GitHub issues, artifacts or CI logs.

## Source-of-truth APIs

- Google Play Developer API: `purchases.productsv2.getproductpurchasev2`
  (`GET /androidpublisher/v3/applications/{packageName}/purchases/productsv2/tokens/{token}`).
  Validate `purchaseStateContext.purchaseState=PURCHASED`, the exact
  `productLineItem.productId`, purchase completion time, package configured
  in backend and testPurchaseContext. Acknowledge non-consumable product;
  never consume the lifetime unlock. After notification, requery Google
  rather than trusting the Pub/Sub message's asserted purchase state.
  https://developer.android.com/google/play/billing/lifecycle/one-time
  https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.productsv2
- Apple App Store Server API: `Get Transaction Info` and Apple-signed JWS,
  validated using App Store Server Library trusted Apple root CAs. Require
  exact bundle ID, StoreKit NON_CONSUMABLE type, product ID, transaction
  identity and environment. Store Notification V2 `signedPayload` is JWS;
  reject unsigned payloads. Use refund history/status and verified
  notification types as authoritative changes.
  https://developer.apple.com/documentation/appstoreserverapi
  https://developer.apple.com/documentation/appstoreservernotifications/receiving-app-store-server-notifications

## Provisioned environments

**Staging (real Store sandboxes, not simulated):**

- Configure product `voxprep_full_unlock` in Play Console and App Store
  Connect as one-time non-consumable. Confirm Flutter package name and iOS
  bundle ID exactly match registered applications.
- Play: enroll license testers, distribute a signed internal testing build,
  grant service account access to Google Play Developer API, mount its key
  in the backend process; set `GOOGLE_APPLICATION_CREDENTIALS`.
- Configure a Google Cloud Pub/Sub push subscription for Play RTDN to
  `POST /api/v1/store/notifications/google`. Enable **authenticated push**
  with a dedicated OIDC service account and explicit push audience; supply
  `VOXPREP_GOOGLE_PUBSUB_AUDIENCE` and
  `VOXPREP_GOOGLE_PUBSUB_SERVICE_ACCOUNT_EMAIL`. Production billing fails
  startup without both values. The JWT signature, issuer, exact audience,
  email and `email_verified` are enforced before decoding notifications.
  The service account must be authorized only for this Pub/Sub push endpoint;
  do not use shared unverified tokens or make the endpoint publicly trusted.
- The RTDN envelope must match the configured package. Purchased/canceled
  events are reverified through Google productsv2. Full one-time-product
  voided notices are rechecked against the Developer API before entitlement
  revocation. Backend responds 503 to transient Store errors so Pub/Sub retries;
  no raw purchase tokens may appear in request logs or diagnostic artifacts.
- Apple: provision Sandbox testers and TestFlight build; mount App Store
  Server API `p8` key and trusted Apple `cer` roots. Configure issuer ID,
  key ID, bundle ID and Apple API environment.
- Start backend with `staging` profile,
  `VOXPREP_BILLING_MODE=production`,
  `VOXPREP_GOOGLE_ACCEPT_TEST_PURCHASES=true`,
  `VOXPREP_APPLE_ENVIRONMENT=SANDBOX`. Supply the remaining
  `VOXPREP_GOOGLE_PACKAGE_NAME`, `VOXPREP_APPLE_BUNDLE_ID`,
  `VOXPREP_APPLE_ISSUER_ID`, `VOXPREP_APPLE_KEY_ID`,
  `VOXPREP_APPLE_KEY_FILE`, `VOXPREP_APPLE_ROOTS_DIR`
  and optional `VOXPREP_APPLE_APP_ID` from secured deployment settings.
  Never commit or echo these credentials.
- Production uses Spring `prod`, Store production environments,
  `VOXPREP_GOOGLE_ACCEPT_TEST_PURCHASES=false` and nonzero Apple app ID;
  production startup must fail closed on sandbox or simulated modes.

## Provider acceptance matrix

| ID | Real user action and observable invariant |
|---|---|
| S01 | Device A fresh install: FREE accessible, FULL denied before purchase |
| S02 | Android license tester buys non-consumable. Server queries Google productsv2, acknowledges, validates app/product and grants FULL |
| S03 | iOS StoreKit sandbox buys non-consumable. Server validates signed Apple transaction and grants FULL |
| S04 | Clean device/install B (new installation token) restores independently from the same Store ownership proof; no bearer/SQLite reuse; FULL granted |
| S05 | Repeat identical event ID/proof: idempotent. Same ID/different proof: HTTP 409; no extra entitlement |
| S06 | Provider PENDING is FREE. Invalid provider/product/environment is fail-closed; a Store decision for a different product never grants |
| S07 | Refund/revoke with verified Apple Notification V2 or Google voided purchase reconciliation removes FULL for every claimed installation; stale client GRANTED proof cannot reverse more recent Store event |
| S08 | Delayed/duplicate Store notification cannot undo a newer Store decision; valid, authenticated refund reversal may restore where provider supports it |
| S09 | Airplane mode: explicitly approved offline entitlement TTL/representation is enforced; reconnect refresh or revoke must not grant indefinitely |
| S10 | N→N+1 content publication after purchase preserves local progress and entitlement without falsely migrating progress from separate fresh installation B |

Record for **each** case: platform and app build identifier, backend image
digest and Git SHA, environment, anonymized installation IDs, test run
timestamp, provider case/reference ID **hashed**, store response status
(excluding secrets), server purchase ledger state and device screenshots.
Log only redacted event IDs/trace IDs.

**Release blockers:** Any unverified transaction grants FULL, refunded
purchase stays FULL online, restore requires an old installation bearer,
replayed event changes a newer Store decision, sandbox proof works in prod,
or offline TTL/receipt integrity policy remains undecided.

## Execution readiness

The backend already has `GooglePlayStoreVerifier`, `AppleStoreVerifier`,
`AppleStoreNotificationController`, `GoogleVoidedPurchasesReconciler` and
production startup guard. This is *implementation readiness only*.
No Store credentials or real sandbox device transaction evidence is attached
to this repository. Mark S01–S10 ACCEPTED only after actual execution.
