# CareerSpeak Compliance & Policy Index

Canonical v1 policy set for global distribution.

## Public-facing policies

- `PRIVACY_POLICY.md` — privacy/data processing policy.
- `TERMS_OF_USE.md` — commercial/use terms; v1 is USD 2.99 one-time, no subscription, no ads.

## Engineering governance

- `DATA_GOVERNANCE.md` — canonical data inventory, minimization, retention/deletion and processor gates.
- `STORE_PRIVACY_DECLARATIONS.md` — Apple App Privacy and Google Play Data Safety working matrices.
- `GLOBAL_RELEASE_CHECKLIST.md` — exact-SHA, platform, legal, store and physical-device release gates.

## Mandatory production values

Release binaries must be supplied with real values for:

- `CAREERSPEAK_LEGAL_NAME`
- `CAREERSPEAK_PRIVACY_EMAIL`
- `CAREERSPEAK_PRIVACY_POLICY_URL`
- `CAREERSPEAK_TERMS_URL`
- `CAREERSPEAK_SUPPORT_URL`
- `CAREERSPEAK_API_BASE_URL`

Public policy/support URLs must be absolute HTTPS URLs. Release startup is intentionally fail-closed when mandatory legal configuration is missing.

## v1 product policy

- one-time paid app: USD 2.99 reference storefront price;
- no recurring subscription;
- no third-party advertising;
- no cross-app tracking;
- no personal account required;
- no direct identity profile required for core learning;
- pseudonymous installation identity and minimum learner state only where required for app functionality/security/synchronization.

## Change-control rule

Any change involving accounts, email/phone collection, analytics, crash-reporting SDKs, advertising, attribution, location, camera, microphone, contacts, health data, payments outside store billing, or user-generated content reopens privacy/store/legal qualification before release.
