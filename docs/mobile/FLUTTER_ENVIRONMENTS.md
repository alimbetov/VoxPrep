# Flutter Environments

Status: normative H3.1 runtime/build configuration guide.

## Environments

`CAREERSPEAK_APP_ENV` supports exactly:

```text
development
staging
production
```

Default policy is deterministic:

```text
debug/profile + no explicit CAREERSPEAK_APP_ENV -> development
release       + no explicit CAREERSPEAK_APP_ENV -> production
unknown value                                  -> fail closed
```

## Build inputs

| Variable | Purpose | Secret? |
|---|---|---|
| `CAREERSPEAK_APP_ENV` | typed environment selection | no |
| `CAREERSPEAK_API_BASE_URL` | one Backend origin for this build/runtime | no |
| `CAREERSPEAK_MOCK_BILLING` | development mock request | no |
| `CAREERSPEAK_MOCK_PURCHASE_VERIFICATION` | development verification mock request | no |
| `CAREERSPEAK_STAGING_API_HOSTS` | comma-separated staging host allowlist | no |
| `CAREERSPEAK_PRODUCTION_API_HOSTS` | comma-separated production host allowlist | no |

There are no `CAREERSPEAK_API_BASE_URL_PROD` or `CAREERSPEAK_API_BASE_URL_TEST` application variables. The environment defines policy; the build supplies one `CAREERSPEAK_API_BASE_URL`.

`CAREERSPEAK_STAGING_API_HOSTS` and `CAREERSPEAK_PRODUCTION_API_HOSTS` contain host names only, not URLs. They are deployment classification inputs used to prevent staging/production cross-wiring. Real DNS values are intentionally not hardcoded until approved.

## Network rules

### development

- HTTP or HTTPS is allowed.
- localhost/emulator/private-network Backend targets are allowed.
- non-release development defaults to mock billing and mock purchase verification unless explicitly disabled.
- an explicit API URL is still required before Backend networking is composed.

Example local Android emulator:

```text
CAREERSPEAK_APP_ENV=development
CAREERSPEAK_API_BASE_URL=http://10.0.2.2:8080
```

### staging

- HTTPS is required.
- host must be listed in `CAREERSPEAK_STAGING_API_HOSTS`.
- a host classified as production is rejected.
- localhost/private/link-local/placeholder hosts are rejected.
- real Store/Backend purchase verification adapters are the default.

### production

- HTTPS is mandatory.
- host must be listed in `CAREERSPEAK_PRODUCTION_API_HOSTS`.
- a host classified as staging is rejected.
- `http`, localhost, loopback, private/link-local IPs, `*.local`, `*.invalid`, `*.test`, and `*.example` are rejected.
- misconfiguration fails before a network request.
- mock billing cannot grant FULL.
- mock purchase verification is never composed; Backend HTTP verification is used.

## Missing API URL

An empty `CAREERSPEAK_API_BASE_URL` produces a deterministic network-disabled `AppConfiguration`. This is safe for pure local/UI tests that do not need Backend networking. Reading the Backend URI for transport composition throws before an HTTP request is created.

Invalid non-empty URI input is rejected immediately.

## Mock policy

| Environment | Mock billing | Mock purchase verification | Backend type |
|---|---|---|---|
| development, non-release | allowed; default on | allowed; default on | local/dev Backend as configured |
| staging | real by default; mock request cannot bypass environment safety | real HTTP verifier | classified staging Backend |
| production | mock request becomes unavailable/fail-closed | always real HTTP verifier | classified production Backend |
| any release build | accepting mock billing is never composed | accepting mock verifier is never composed | validated configured Backend |

A Store mock flag is not an authorization mechanism. FULL remains an entitlement produced only by accepted development mocks inside the development boundary or by successful Backend verification in real flows.

## Example commands

### Development

```bash
flutter run \
  --dart-define=CAREERSPEAK_APP_ENV=development \
  --dart-define=CAREERSPEAK_API_BASE_URL=http://10.0.2.2:8080 \
  --dart-define=CAREERSPEAK_MOCK_BILLING=true \
  --dart-define=CAREERSPEAK_MOCK_PURCHASE_VERIFICATION=true
```

### Staging

Replace the placeholder host with the approved staging DNS name.

```bash
flutter run --profile \
  --dart-define=CAREERSPEAK_APP_ENV=staging \
  --dart-define=CAREERSPEAK_API_BASE_URL=https://staging-api.example.invalid \
  --dart-define=CAREERSPEAK_STAGING_API_HOSTS=staging-api.example.invalid \
  --dart-define=CAREERSPEAK_PRODUCTION_API_HOSTS=production-api.example.invalid \
  --dart-define=CAREERSPEAK_MOCK_BILLING=false \
  --dart-define=CAREERSPEAK_MOCK_PURCHASE_VERIFICATION=false
```

The `.invalid` values above are documentation placeholders and will be rejected by the runtime safety policy. CI/release configuration must substitute approved real DNS values.

### Production Android App Bundle

```bash
flutter build appbundle --release \
  --dart-define=CAREERSPEAK_APP_ENV=production \
  --dart-define=CAREERSPEAK_API_BASE_URL=https://api.example.com \
  --dart-define=CAREERSPEAK_PRODUCTION_API_HOSTS=api.example.com \
  --dart-define=CAREERSPEAK_STAGING_API_HOSTS=staging-api.example.com \
  --dart-define=CAREERSPEAK_MOCK_BILLING=false \
  --dart-define=CAREERSPEAK_MOCK_PURCHASE_VERIFICATION=false
```

### Production APK

```bash
flutter build apk --release \
  --dart-define=CAREERSPEAK_APP_ENV=production \
  --dart-define=CAREERSPEAK_API_BASE_URL=https://api.example.com \
  --dart-define=CAREERSPEAK_PRODUCTION_API_HOSTS=api.example.com
```

## CI expectations

CI must prove at minimum:

```text
format
flutter analyze
H3.1 E01-E14 configuration/composition tests
API/provider composition tests
contract-related acceptance
full Flutter suite where practical
```

Release pipelines must supply the environment, API base URL and the correct environment host classification. A missing or cross-wired value is a release-blocking configuration error.

## Secrets and non-secrets

`CAREERSPEAK_API_BASE_URL` is configuration, not a secret.

The following MUST NOT be embedded in Flutter through dart-defines, assets or source code:

- Google/Apple server verification credentials;
- Backend signing/private credentials;
- PostgreSQL credentials;
- RustFS access key/secret key;
- bucket credentials;
- TTS Worker lease/authentication secrets.

Store verification proof received from the device is sent only to the authenticated Backend verification endpoint and must not be rendered or logged.

## Release safety rules

1. Production Backend networking requires a validated HTTPS URL and production-classified host.
2. Staging and production host allowlists must not overlap.
3. Production cannot point at staging and staging cannot point at production when classifications are known.
4. Flutter never addresses RustFS directly.
5. Release mock flags cannot manufacture FULL access.
6. Backend purchase verification remains fail-closed when provider verification is unavailable or rejected.
