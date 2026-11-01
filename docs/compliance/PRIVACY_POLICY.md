# CareerSpeak Privacy Policy

**Release status:** production template — publisher fields must be completed before public release.  
**Effective date:** set at release.  
**Publisher / data controller:** `CAREERSPEAK_LEGAL_NAME`  
**Privacy contact:** `CAREERSPEAK_PRIVACY_EMAIL`

## 1. Privacy model

CareerSpeak is designed to work without a personal account. The application does not require a user to provide a name, email address, phone number, social-login profile, contacts, precise location, advertising identifier, or other direct real-world identity information for the normal learning experience.

CareerSpeak may use a random installation identifier and an installation credential. These values are pseudonymous: they identify an application installation for security and service continuity but are not intended to identify the user's real-world identity.

## 2. Data CareerSpeak may process

Depending on the released features and whether backend synchronization is enabled, CareerSpeak may process:

- a random installation identifier and installation authentication state;
- learning state such as favorites, listened/completed markers and playback position;
- practice-test attempts and learning progress;
- selected country/region, interface/content language, preferred English accent and theme;
- synchronization metadata and content revision identifiers;
- downloaded/offline content metadata and files on the device;
- limited technical request/security information produced by normal network infrastructure.

The application is not designed to require advertising IDs, contact lists, precise location, microphone recordings, photographs, or social graphs for normal learning functionality.

## 3. Why data is processed

The minimum data above may be used to:

- authenticate and protect an application installation;
- deliver and synchronize learning content;
- preserve and restore learning progress;
- resume audio and practice sessions;
- apply language and application preferences;
- maintain service reliability, security and abuse prevention;
- comply with legal obligations that apply to the publisher.

CareerSpeak does not use installation identity or learner state for cross-app behavioral advertising.

## 4. Legal bases where GDPR applies

Where the GDPR or equivalent law applies, processing must use a documented legal basis appropriate to the released function. Core installation security, content delivery and learning-state continuity are generally expected to rely on performance of the service requested by the user and/or the publisher's legitimate interests in security and reliable operation. Processing that legally requires consent must not start until valid consent has been obtained and must remain withdrawable.

The final production data inventory must identify the actual legal basis for every backend data category before release.

## 5. Sharing and processors

CareerSpeak does not sell learner data.

The publisher may use service providers only where necessary to operate hosting, content delivery, security, support or other released functionality. The production processor/subprocessor register must name the providers actually used in production, their purpose, data categories and transfer mechanism where applicable. A provider must not be added to production without updating the privacy review and store disclosures when required.

## 6. International transfers

If production infrastructure or a service provider processes covered data outside the user's jurisdiction, the publisher must use the transfer mechanism required by applicable law and disclose it in the public policy where required. No transfer mechanism should be claimed until the production hosting and processor locations are fixed.

## 7. Retention

Local data can remain on the device until removed by application functionality, application storage is cleared, or the application is uninstalled, subject to operating-system behavior.

Server-side installation and learning state must be retained only for the documented service purpose and for no longer than the production retention schedule permits. The release must not publish a numerical retention period that the backend does not actually enforce.

Security/access logs may exist at infrastructure layers. Their production retention period must be documented and minimized before release.

## 8. Deletion and privacy requests

Clearing application data or uninstalling CareerSpeak affects local data but does not by itself prove deletion of server-side records.

Where server-side records are associated with the current installation, users must be provided a documented privacy-request mechanism. Until an authenticated automated deletion endpoint is production-qualified, deletion and access requests are handled through the published privacy contact. The publisher must verify requests using a method that does not require collecting unnecessary identity data.

Where applicable, users may request access, correction, deletion, restriction, portability, objection, or withdrawal of consent, subject to applicable law and lawful exceptions.

## 9. Security

Release builds require HTTPS for API communication. Installation credentials are stored using platform secure-storage facilities. The application is designed to show learner-safe errors instead of exposing credentials, backend secrets or filesystem details.

No security measure provides an absolute guarantee. The publisher maintains technical and organizational safeguards appropriate to the released service and data actually processed.

## 10. Advertising and tracking

The v1 product policy is:

- no third-party advertising;
- no cross-app advertising tracking;
- no requirement for an advertising identifier;
- no sale of learner data.

Adding an advertising, analytics, attribution or telemetry SDK requires a new privacy impact review and updates to Apple App Privacy and Google Play Data Safety declarations before release.

## 11. Children

The initial public release is not designed or marketed as a child-directed/Kids service. Store audience and age-rating declarations must match the actual released product and regional legal requirements. A future child-directed release requires a separate compliance review before functionality is enabled for that audience.

## 12. Changes

Material changes to data processing require an updated policy, updated effective date, updated store disclosures where required, and renewed consent where law requires it.

## 13. Contact

Before public release, replace the release configuration with the real publisher/controller name and a monitored privacy contact. The public Privacy Policy URL must be HTTPS and publicly reachable without authentication.

---

## Release gate

This document is not production-complete until all of the following are true:

- `CAREERSPEAK_LEGAL_NAME` is the real publisher/controller;
- `CAREERSPEAK_PRIVACY_EMAIL` is monitored;
- production hosting locations are recorded;
- actual processors/subprocessors are recorded;
- backend retention matches the retention schedule;
- deletion/access request handling is operational;
- Apple App Privacy and Google Data Safety forms match this policy and the shipped binaries.
