# CareerSpeak Data Governance

This document is the canonical engineering inventory for privacy-sensitive data in the v1 product. It must be kept synchronized with the shipped application, backend contracts, infrastructure and store declarations.

## Product principle

CareerSpeak uses a pseudonymous installation model instead of a personal account. The production goal is data minimization: process only what is required to deliver, secure and restore the learning experience.

## Data inventory

| Data category | Example | Local device | Backend | Purpose | Direct identity | Delete/reset expectation |
|---|---|---:|---:|---|---:|---|
| Installation identifier | random installation ID | yes | when backend enabled | authentication, continuity | no | local reset + server request |
| Installation credential | token/credential | secure storage | auth system | security | no | revoke/replace; local reset |
| Learning markers | favorite/listened/completed | yes | if sync enabled | progress | no | local reset + server request |
| Audio progress | playback position/revision | yes | if sync enabled | resume | no | local reset + server request |
| Practice state | attempts/results/active attempt | yes | if sync enabled | learning/testing | no | local reset + server request |
| Preferences | locale/country/accent/theme | yes | only if feature requires | UX/localization | no | local reset + server request if synced |
| Sync metadata | revisions/status/timestamps | yes | yes when syncing | consistency/recovery | no | follows associated state |
| Offline assets | learning files/cache | yes | content service source | offline learning | no | cache/reset policy |
| Network/security logs | IP, request metadata, trace ID | infrastructure dependent | infrastructure dependent | security/operations | potentially personal under law | minimized production retention |

## Data deliberately excluded from the v1 core model

The v1 application must not require these categories for normal learning functionality:

- name;
- personal email or phone number;
- postal address;
- contacts/address book;
- precise location;
- advertising ID;
- social-login identity/social graph;
- photographs;
- microphone recordings;
- biometric data;
- payment-card details (handled by app stores, not CareerSpeak application storage).

If any excluded category becomes necessary, it requires a new architecture/privacy review before implementation.

## Retention policy

### Local

Local learner state may remain until the user resets application data, removes relevant downloaded content, or uninstalls the app, subject to platform behavior. Cache eviction may remove downloaded assets without deleting logical progress.

### Backend

Do not publish arbitrary retention durations until the backend enforces them. Before production acceptance, every server-side table/object/log containing installation or learner state must have one of:

1. a documented lifecycle tied to the installation/service state;
2. an explicit TTL/retention job; or
3. a documented legal/security retention reason and deletion process.

### Logs

Production access/security logs must have a documented short retention appropriate to incident response and abuse prevention. Tokens, authorization headers and raw secrets must never be written to application logs.

## Deletion model

`Reset this device` and `Delete server-side learning data` are distinct operations.

### Reset this device

Expected local scope:

- local Drift learner/application state where appropriate;
- downloaded/cache assets;
- preferences that are part of reset scope;
- installation ID/credential from secure storage.

The reset flow must warn when removing the current installation identity can make existing server-side records impossible to authenticate for later deletion.

### Server-side deletion

Until an authenticated deletion API is production-qualified, the public privacy contact is the supported request channel. The backend release roadmap should add a replay-safe deletion mechanism tied to the current installation identity, with audit status that does not require collecting unnecessary real-world identity.

## Consent

Do not add a blanket consent dialog for processing that does not legally require consent merely to obtain a checkbox. If a future feature requires consent (for example optional analytics or a protected-resource permission), consent must be specific, informed, withdrawable and independent of paid core functionality where required.

## Processor/subprocessor gate

Before adding any SDK or infrastructure provider that can receive covered data, record:

- provider legal name;
- purpose;
- data categories;
- processing/storage region;
- retention;
- DPA/contract status;
- international-transfer mechanism where applicable;
- Apple App Privacy impact;
- Google Data Safety impact.

## Release invariant

The shipped binary, backend behavior, public Privacy Policy, Apple App Privacy declaration and Google Play Data Safety form must describe the same data flows. A mismatch is a release blocker.
