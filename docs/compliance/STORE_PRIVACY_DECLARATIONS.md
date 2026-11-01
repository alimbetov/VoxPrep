# CareerSpeak Store Privacy Declarations

This file is the engineering source for preparing Apple App Privacy and Google Play Data Safety submissions. The final store answers must be verified against the exact release binary, backend, SDK dependency graph and production infrastructure.

## v1 product commitments

- Paid application: USD 2.99 reference storefront price, one-time purchase.
- No recurring subscription in v1.
- No third-party advertising.
- No cross-app tracking.
- No personal account required.
- No direct identity profile required for normal learning use.
- Pseudonymous installation identity may be used for security/synchronization.

## Apple App Privacy working matrix

| Category | v1 expectation | Linked to user? | Tracking? | Purpose | Release verification |
|---|---|---|---|---|---|
| User ID / device-related identifier | pseudonymous installation ID may be collected by backend | pseudonymous installation relationship only | no | app functionality, security | verify API/backend |
| Product interaction / learning progress | may be collected if synchronization is enabled | associated with installation | no | app functionality | verify sync contracts |
| Diagnostics | only if production diagnostics actually transmit them | depends on implementation | no | app functionality / diagnostics | inspect exact SDK/build |
| Precise location | not required | no | no | none | confirm permissions/manifests |
| Contacts | not required | no | no | none | confirm permissions |
| Photos/videos | not required | no | no | none | confirm permissions |
| Audio recordings | not required by v1 core learning model | no | no | none | confirm permissions |
| Advertising data | not used | no | no | none | confirm no ad SDK |
| Purchases | purchase processed by App Store; application should not store card data | store/platform dependent | no | app acquisition | verify app code/store configuration |

### Apple submission gate

Before submission, compare the exact binary against:

1. `pubspec.lock` and native SDK dependencies;
2. iOS privacy manifests and permission purpose strings;
3. backend request/response contracts;
4. production logging/telemetry;
5. this matrix.

The App Store Connect privacy answers must describe data collected by the application and relevant third-party SDKs, not just data intentionally stored in CareerSpeak domain tables.

## Google Play Data Safety working matrix

| Data type | Collected by v1 app/service? | Shared? | Purpose | Optional? | Deletion expectation |
|---|---|---|---|---|---|
| App/device identifier | pseudonymous installation ID when backend enabled | only processors required to operate service, if any | app functionality/security | core when backend auth required | reset + privacy request/server deletion path |
| App interactions / learning progress | if synchronized | only operational processors, if any | app functionality | core to sync; local use otherwise | local reset + server deletion path |
| Diagnostics | only if production telemetry/logging sends them | depends on processor | diagnostics/security | implementation dependent | production retention schedule |
| Location | no v1 requirement | no | n/a | n/a | n/a |
| Contacts | no | no | n/a | n/a | n/a |
| Photos/videos | no | no | n/a | n/a | n/a |
| Audio files/recordings | no v1 core collection | no | n/a | n/a | n/a |
| Financial/payment info | application does not store card/payment credentials | handled by store | purchase | n/a | store policy |

### Google submission gate

Before Play production release:

- verify Data Safety against exact release AAB and all SDKs;
- verify public Privacy Policy URL is HTTPS and reachable without login;
- verify in-app Privacy Policy is easily accessible;
- verify deletion/request statements match backend capability;
- verify target audience and age declarations;
- verify permissions requested by AndroidManifest are necessary and disclosed.

## Change-control rule

Adding any analytics, crash-reporting, attribution, advertising, identity, payment, location, camera, microphone, contacts, health or social SDK automatically reopens this document and both store privacy declarations before release.
