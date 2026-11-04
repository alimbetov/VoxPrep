# R5 environment matrix — pre-Store registration

**Purpose:** develop and qualify VoxPrep locally without Play Console or
App Store Connect accounts, while leaving release builds incapable of granting
FULL from fake receipts. No real Store credentials are committed.

| Environment | Backend Spring profile | `VOXPREP_BILLING_MODE` | Flutter flags | FULL semantics |
|---|---|---|---|---|
| Development | `dev` | `simulated` | `VOXPREP_ENV=development`, `VOXPREP_MOCK_BILLING=true`, `VOXPREP_MOCK_PURCHASE=true` | UI-only demo or dev simulator, never real revenue |
| CI / integration | `test` | `simulated` | explicit test doubles | Test fixtures validated by CI only |
| Production-ready without Store accounts | `prod` | **`disabled`** (default) | `VOXPREP_ENV=production`, mocks **false** | FREE only; purchase verification returns 503; no fake FULL |
| Sandbox acceptance (when accounts exist) | `staging` | `production` | real purchase/restore, mocks false | Real Play license tests and Apple sandbox, server verification |
| Commercial production (after Store acceptance) | `prod` | `production` | real purchase/restore, mocks false | Only verified Store transactions grant FULL |

## Local development

Backend (from repository root, with existing DEV secrets and Docker infrastructure):

```powershell
cd backend
mvn spring-boot:run "-Dspring-boot.run.profiles=dev"
```

Frontend (from `mobile/careerspeak_app`, debug build):

```powershell
flutter run -d chrome --dart-define=VOXPREP_ENV=development --dart-define=VOXPREP_MOCK_BILLING=true --dart-define=VOXPREP_MOCK_PURCHASE=true
```

**Caveat:** web runner and Drift SQLite Web setup are separate from the billing
configuration; this command does not bypass existing Flutter Web limitations.

CI `test` uses a deterministic `sim:v1:...` purchase proof format. Production
backend must not be deployed with `simulated`; the startup guard rejects it.

## Pre-registration production deployment

```text
SPRING_PROFILES_ACTIVE=prod
VOXPREP_BILLING_MODE=disabled
VOXPREP_GOOGLE_ACCEPT_TEST_PURCHASES=false
VOXPREP_APPLE_ENVIRONMENT=PRODUCTION
```

The app is **not commercially ready** in this mode; it can present content
and FREE access, but must not advertise a working purchase or restore checkout.
The backend returns `STORE_VERIFICATION_UNAVAILABLE` (HTTP 503) on attempted
verification, not a fake successful entitlement.

Flutter production builds:

```text
VOXPREP_ENV=production
VOXPREP_MOCK_BILLING=false
VOXPREP_MOCK_PURCHASE=false
```

No Store API keys, product IDs (other than public `voxprep_full_unlock`),
provisioning certificates or signing secrets should be fabricated.

## Switching to real commercial acceptance later

1. Create/register apps and a non-consumable `voxprep_full_unlock` in both
   developer consoles.
2. Provide provider service-account credentials, Apple signing key and
   trusted CA roots via secret mounts, not tracked files.
3. Activate staging `VOXPREP_BILLING_MODE=production` with Google test
   purchase acceptance and Apple SANDBOX environment; keep this isolated from
   prod. Validate S01–S10 in `R5_REAL_STORE_SANDBOX_ACCEPTANCE.md`.
4. Only after provider acceptance, configure prod billing `production` and
   build signed release apps with mocks false.

**Never** silently turn `VOXPREP_BILLING_MODE=simulated` on in `prod`, even
temporarily: this would permit users to grant themselves paid access without a
purchase. To show pretend purchases, use the local DEV debug demo.
