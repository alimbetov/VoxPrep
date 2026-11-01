# CareerSpeak Global Release Checklist

A release is `PRODUCTION ACCEPTED` only when every mandatory item below is proven on the same immutable release candidate SHA or is explicitly a store/account operation tied to that SHA.

## PRD-01 Exact-SHA qualification

- [ ] `dart format` green
- [ ] `flutter analyze` green
- [ ] full `flutter test --coverage` green
- [ ] production line coverage >= 90%
- [ ] Drift generated source/schema/migrations reproducible
- [ ] exact SHA recorded in qualification output

## PRD-02 Transport security

- [x] release API base URL fails closed unless HTTPS
- [ ] production endpoint certificate/TLS verified
- [ ] no secrets/tokens in logs

## PRD-03 Authoritative CI

- [x] `Flutter Production Qualification` workflow exists
- [ ] workflow green on final exact SHA
- [ ] required status check configured on protected `main`

## PRD-04 Coverage

- [x] 90% production coverage gate is wired into production qualification
- [ ] final exact SHA meets threshold

## PRD-05 Platform release shells

### Android
- [ ] `android/` production shell present
- [ ] applicationId finalized
- [ ] min/target/compile SDK policy finalized
- [ ] permissions minimized
- [ ] cleartext traffic disabled for release
- [ ] release signing configured outside repository
- [ ] release AAB built and smoke-tested

### Apple iOS/iPadOS
- [ ] `ios/` production shell present
- [ ] Bundle ID finalized
- [ ] signing/provisioning configured
- [ ] Info.plist purpose strings audited
- [ ] App Transport Security audited
- [ ] privacy manifest/SDK manifests audited
- [ ] release archive built
- [ ] TestFlight build exercised on physical iPhone/iPad

### Web/Desktop
- [ ] web release CSP/hosting/cache policy qualified before web launch
- [ ] macOS signing/notarization qualified before macOS launch
- [ ] Windows signing/installer/update policy qualified before Windows launch
- [ ] Linux packaging/update policy qualified before Linux launch

## PRD-06 Privacy / Legal

- [x] in-app Privacy Policy route
- [x] in-app Data & Privacy route
- [x] in-app Terms route
- [x] public Privacy Policy source document
- [x] public Terms source document
- [x] canonical data inventory/retention/deletion policy
- [x] Apple App Privacy working matrix
- [x] Google Play Data Safety working matrix
- [x] release fails closed on missing legal publisher/contact/HTTPS policy URLs
- [ ] real legal publisher/controller supplied
- [ ] monitored privacy email supplied
- [ ] public Privacy Policy HTTPS URL deployed
- [ ] public Terms HTTPS URL deployed
- [ ] support HTTPS URL deployed
- [ ] production hosting locations documented
- [ ] actual processors/subprocessors documented
- [ ] backend retention/deletion behavior verified
- [ ] final jurisdiction-specific legal review completed

## PRD-07 Observability

- [ ] production crash/error strategy selected
- [ ] no tracking/analytics introduced without privacy review
- [ ] sensitive fields redacted
- [ ] trace ID usable for support without exposing credentials

## PRD-08 Physical-device matrix

- [ ] Android phone
- [ ] Android tablet
- [ ] iPhone
- [ ] iPad
- [ ] wired/Bluetooth audio lifecycle
- [ ] network loss/recovery
- [ ] background/foreground/process death
- [ ] oldest supported OS and current OS

## PRD-09 Accessibility / localization

- [ ] VoiceOver qualification
- [ ] TalkBack qualification
- [ ] large text >= 200% qualification
- [ ] reduced motion qualification
- [ ] RTL qualification where supported
- [ ] all release UI strings localized for declared storefront languages or product explicitly launches English-only UI

## PRD-10 Chaos / soak / lifecycle

- [ ] kill during sync/write/download
- [ ] corrupt/missing/stale local asset handling
- [ ] 401 renewal once / second 401 fail closed
- [ ] 403/404/408/429/5xx handling
- [ ] slow/truncated/invalid response handling
- [ ] storage pressure/full-disk handling
- [ ] migration/reopen repeated qualification
- [ ] multi-hour soak with memory/resource monitoring

## PRD-11 Signed release candidate

- [ ] immutable RC SHA
- [ ] signed/tagged release policy
- [ ] dependency lock recorded
- [ ] Flutter/Dart version recorded
- [ ] DB schema version recorded
- [ ] Android artifact checksum recorded
- [ ] iOS archive/build identity recorded
- [ ] store privacy declarations reviewed against exact artifacts

## Apple launch

- [ ] Apple Developer/App Store Connect account ready
- [ ] paid app price configured: USD 2.99 reference storefront
- [ ] no recurring subscription configured for v1
- [ ] Privacy Policy URL populated
- [ ] App Privacy form completed against exact binary
- [ ] age rating/target audience correct
- [ ] screenshots/metadata/support URL complete
- [ ] backend live for review
- [ ] TestFlight acceptance complete
- [ ] App Review notes explain installation-based identity/offline behavior where useful

## Google Play launch

- [ ] Play Console account ready
- [ ] paid app price configured: USD 2.99 reference storefront
- [ ] no recurring subscription configured for v1
- [ ] Privacy Policy URL populated
- [ ] Data Safety form completed against exact AAB
- [ ] target audience/content rating correct
- [ ] release signing/Play App Signing configured
- [ ] production track smoke qualification complete

## Release verdict

Do not mark `PRODUCTION ACCEPTED` while any P0 release invariant, required platform build, store privacy declaration, or final exact-SHA qualification remains unproven.
