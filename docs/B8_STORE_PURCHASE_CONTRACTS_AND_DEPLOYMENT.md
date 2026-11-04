# B8 — Store Verified Lifetime Unlock: contracts, environments and deployment

**Updated 2026-11-04 · branch `feat/commercial-release` · status: IMPLEMENTATION / STORE ACCEPTANCE PENDING**

## 1. Product design and privacy

VoxPrep has **no application user accounts**. The first published knowledge block is FREE; all other blocks require the **one-time, non-consumable** product `voxprep_full_unlock`. Price is configured independently by each store (target US base price **$4.99**; taxes/local currencies are Store-owned). No subscription, renewal, consumables or separate paid app.

This application does not save personal profiles, names, contact information or payment card details. It DOES store technical installation UUIDs, SHA-256 of transaction identities, verification-event fingerprints, provider, product ID, state and timestamps. Do not claim the app stores "no data whatsoever". This minimal entitlement state is necessary for server-side restore and revoke.

| Mode/profile | Store verifier | Allowed proof | Safety |
|---|---|---|---|
| Default / `disabled` | `DisabledStorePurchaseVerifier` | none | 503; FREE access only |
| `dev`, `test` | `SimulatedStorePurchaseVerifier` | strictly `sim:v1:` fixtures | LOCAL ONLY; no real Store calls |
| `staging` | Real Google Play Developer API + Apple Sandbox API | real test purchases | Isolated DB/credentials, no production entitlements |
| `prod` | Real Google Play Developer API + Apple Production API | real paid purchases only | Fails startup if keys or certificates are missing |

**No source code or config should ever silently switch from failed store verification to mock.** Production endpoints accept only verified Store responses. Mocks are Spring profile conditional beans, never classpath fallbacks.

## 2. Exact Flutter ↔ Backend HTTP contract

`POST /api/v1/purchases/verify` uses an existing installation Bearer token and:

```json
{
  "provider": "GOOGLE_PLAY",
  "productId": "voxprep_full_unlock",
  "purchaseEventId": "store-<stable-sha256>",
  "verificationData": "<opaque-google-purchase-token-or-apple-transaction-id>"
}
```

```json
{
  "verified": true,
  "accessLevel": "FULL",
  "verifiedAt": "2026-11-04T00:00:00Z"
}
```

A non-verified, PENDING, REVOKED or previously refunded purchase does **not** grant FULL. Same installation+purchaseEventId+proof is idempotent; reusing that event ID for different provider/product/proof yields 409. Access is authoritative in PostgreSQL and checked on protected backend content paths. The proof is never returned to Flutter or persisted verbatim. A newly restored device can claim a **store-verified** non-consumable, even with a new anonymous installation UUID.

Flutter `in_app_purchase`: Android `verificationData.serverVerificationData` contains the Google purchase token; iOS sends `PurchaseDetails.purchaseID` (numeric StoreKit transaction ID), because the generic StoreKit bridge's `serverVerificationData` may be a base64 app receipt, NOT an App Store Server API JWS. Server fetches and validates Apple's signed transaction. Flutter uses a stable derived `purchaseEventId` rather than an incrementing counter.

## 3. Google Play: official production contract

- [Google Play Developer API — ProductPurchaseV2](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.productsv2/getproductpurchasev2): `GET /androidpublisher/v3/applications/{packageName}/purchases/productsv2/tokens/{token}` with OAuth2 scope `androidpublisher`.
- Check `productLineItem` includes exactly the expected SKU and `purchaseStateContext.purchaseState == PURCHASED`. `PENDING` never grants; `CANCELLED` revokes.
- If not acknowledged, call [`purchases.products.acknowledge`](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.products/acknowledge) before acknowledging it to Flutter. NEVER call `consume` for a non-consumable.
- Server runs [Voided Purchases API](https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.voidedpurchases/list) reconciliation every 15 minutes by default, updates all linked installations to REVOKED, and preserves monotonic event timestamps. This API looks back at most 30 days; alert on failed reconciliation. Google RTDN Pub/Sub OIDC push is an optional latency optimization **NOT wired yet**; do not expose an unauthenticated RTDN endpoint.
- Production refuses `testPurchaseContext` by default. Staging accepts Play license-tester purchases after authenticating to the same Google API.

Provision Google:
1. Create an **in-app product** with ID `voxprep_full_unlock` in Google Play Console and mark it active (configure regional prices).
2. Link the Google Cloud project and Play Console; enable **Google Play Developer API**, create least-privilege service account and assign required Play Console financial purchase/order verification permissions for the app.
3. Mount the JSON service account at a read-only path and set `GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/voxprep/google-play-service-account.json` or use Workload Identity.
4. Set `VOXPREP_GOOGLE_PACKAGE_NAME` to the actual Android applicationId. Do not invent it.
5. Configure Real-time Developer Notifications and Pub/Sub separately when authenticated push handler is implemented; for now ensure the voided reconciliation schedule is healthy.

## 4. Apple: official production contract

- [Get Transaction Info](https://developer.apple.com/documentation/appstoreserverapi/get-transaction-info): `GET https://api.storekit.apple.com/inApps/v1/transactions/{transactionId}`; sandbox `https://api.storekit-sandbox.apple.com/inApps/v1/transactions/{transactionId}`.
- Apple [App Store Server Library for Java 5.2.0](https://github.com/apple/app-store-server-library-java) generates the ES256 App Store Server API authentication token and verifies `signedTransactionInfo` JWS signature, Apple root chain, bundle ID, environment and app Apple ID. No manually decoded unverified JWT may grant FULL.
- Require **NON_CONSUMABLE**, exact product ID, matching StoreKit transaction ID, originalTransactionId, purchaseDate, no revocationDate. Hash originalTransactionId for cross-device restore.
- App Store Server Notifications V2: `POST /api/v1/store/notifications/apple` accepts a `signedPayload` only; validate Apple-signed notification and nested transaction before handling `REFUND`, `REVOKE`, `REFUND_REVERSED`. Use signed timestamp to reject out-of-order events. Configure this URL in App Store Connect; require HTTPS, ingress rate limiting.
- Apple sandbox uses the same official API but distinct `Environment.SANDBOX` and cannot create production entitlements if staging/production databases are isolated.

Provision Apple:
1. Create the **Non-Consumable** `voxprep_full_unlock` IAP in App Store Connect. Configure localizations/price.
2. App Store Connect → Users and Access → Integrations → In-App Purchase: create issuer ID, key ID, download `.p8` (private key downloaded once). Record actual Bundle ID and numeric Apple App ID.
3. Download official Apple Root CAs from [Apple PKI](https://www.apple.com/certificateauthority/), put `.cer` files in a read-only directory. The trusted roots are public certificates; the `.p8` and service account are secrets.
4. Configure **App Store Server Notifications V2** URL in App Store Connect for production and sandbox endpoints separately, after HTTPS/WAF deployment.
5. Run sandbox StoreKit purchase/restore/refund notifications and final production smoke tests.

## 5. Production and staging environment variables

```bash
# Existing backend profile and DB/storage secrets still required.
SPRING_PROFILES_ACTIVE=prod
VOXPREP_BILLING_MODE=production
VOXPREP_GOOGLE_PACKAGE_NAME=<actual Android applicationId>
GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/voxprep/google-play-service-account.json
VOXPREP_APPLE_BUNDLE_ID=<actual iOS bundle identifier>
VOXPREP_APPLE_APP_ID=<numeric App Store Apple ID>
VOXPREP_APPLE_ISSUER_ID=<App Store Connect issuer UUID>
VOXPREP_APPLE_KEY_ID=<IAP key ID>
VOXPREP_APPLE_KEY_FILE=/run/secrets/voxprep/SubscriptionKey.p8
VOXPREP_APPLE_ROOTS_DIR=/run/voxprep/apple-root-cas
VOXPREP_GOOGLE_VOIDED_POLL_DELAY_MS=900000
```

**Actual secrets MUST be supplied externally**, never committed or printed in logs. The checked-in `application-prod.yml` fixes Apple environment to PRODUCTION and rejects Google test purchases. The `staging` profile enables Apple SANDBOX and Google license-tester purchases with separate infrastructure and isolated database. If using `SPRING_PROFILES_ACTIVE=staging`, ensure the base app's DB/secret mount and TLS endpoints are staging, not production.

**Deployment rule:** `VOXPREP_BILLING_MODE=simulated` is unacceptable on publicly accessible deployments. Keep `dev/test` DBs and service ports internal; a simulator intentionally grants access to synthetic proofs.

## 6. Deterministic DEV/TEST simulation

On a local backend with `SPRING_PROFILES_ACTIVE=dev` or `test` and a valid issued installation Bearer, send:

```bash
curl -X POST http://localhost:8080/api/v1/purchases/verify \
  -H "Authorization: Bearer ${INSTALLATION_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"provider":"GOOGLE_PLAY","productId":"voxprep_full_unlock", "purchaseEventId":"test-event-1", "verificationData":"sim:v1:GOOGLE_PLAY:GRANTED:purchase001"}'
```

To simulate PENDING/refund, use the SAME transaction identity but a NEW event id:
```
sim:v1:GOOGLE_PLAY:PENDING:purchase002
sim:v1:GOOGLE_PLAY:GRANTED:purchase002
sim:v1:GOOGLE_PLAY:REVOKED:purchase002
```
To simulate Apple:
```
sim:v1:APP_STORE:GRANTED:apple01
sim:v1:APP_STORE:REVOKED:apple01
```

These strings are never valid proof in production. Flutter's mock billing adapter now emits them. The mock restore reuses the originally owned transaction, unlike an arbitrary new purchase.

## 7. Acceptance ledger and limitations

- [x] Exact JSON shape for Flutter `POST /api/v1/purchases/verify`.
- [x] Provider/product ID validation, same-event semantic conflict (409), database unique transaction identity, idempotent grants and multi-install restoration.
- [x] DEV/TEST-only deterministic simulator and production fail-closed mode.
- [x] Production Google productsv2 + acknowledgement adapter (service account OAuth) and Apple transaction-info + JWS verifier.
- [x] Apple signed `REFUND/REVOKE/REFUND_REVERSED` handler and Google Voided Purchases polling.
- [ ] Latest SHA must pass full B1/Flutter/Renderer CI; existing unit/integration tests do not prove real store authority yet.
- [ ] Real Play Console license-tester purchases and Apple StoreKit sandbox transactions on isolated staging, including acknowledgment and restore.
- [ ] Configure production keys, App Store Connect V2 notification endpoint, Google permissions and alerting (requires developer accounts).
- [ ] Expose and consume an authoritative entitlement refresh endpoint in Flutter to synchronize refunds after reconnect. Previously downloaded offline files cannot be remotely recalled while the device is offline.
- [ ] Add per-install rate limits, App Attest/Play Integrity risk checks if needed, unusual restore-rate alerting, and Store notification history backfill.
- [ ] Full Backend ↔ Flutter v2 catalogue/media/assessment/Drift offline qualification, twelve-language QA, responsive Renderer CI.

**Replay/security limitation without app accounts:** a Store-verified transaction ID/purchase token is not in itself proof that a second anonymous device belongs to the original purchaser if the token leaks. We allow legitimate Store restore and share access across installations only after rechecking the Store, but cannot eliminate stolen-proof cross-device replay without device attestation or user binding. Never portray hash uniqueness as a complete anti-fraud solution. Use short request rate limits, no proof logging and optional Play Integrity/App Attest.

**Release decision:** NO MERGE / NO COMMERCIAL LAUNCH until official sandbox E2E, refund/restore and all exact-SHA CI gates are accepted.
