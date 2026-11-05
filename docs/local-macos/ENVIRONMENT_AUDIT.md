# A0 — actual MacBook audit

Observed 2026-11-05 (Asia/Almaty). Branch: `feat/local-macos-fullstack-acceptance`.
Source SHA: `fc02331b1574162382d4436d38bf3e5e0a14d45e`; starting main
`9ae3d7e646e3e39d0886765bfa6a60d77dde0529` is an ancestor (exit 0).
Checkout was clean before implementation. This is environment evidence, not E2E acceptance.

Run `./scripts/local/audit.sh` from the checkout. The first recorded run is
`artifacts/local-smoke/20261105T160120Z/index.json`: each entry contains the exact
command, UTC timestamp, exit code and output file. All 19 probes exited 0;
that means successful inventory, not readiness of every dependency. Initial
sandbox Docker/Simulator failures disappeared when repeated with host access.

| Check | Actual observation | State / next action |
|---|---|---|
| Host | macOS 15.6, build 24G84, arm64; 16 GiB RAM | READY for further qualification |
| Disk | 4.7 GiB available, data volume 98% used | BLOCKED for full-stack downloads/builds; operator must provide space or a larger workspace; no cleanup performed |
| Docker | Desktop 4.43.2; engine 28.3.2 linux/arm64; client 28.3.3; Compose 2.38.2 | READY daemon; pinned image ARM64 support NOT RUN |
| Java/Maven | Default Java 17.0.9; Maven 3.8.7 | Default BLOCKED; Java 21.0.1 exists under SDKMAN and its binary runs successfully; select it per process |
| Python | 3.12.7 | READY audit runtime; worker uses pinned container Python 3.12.16 |
| Flutter | stable 3.47.7; Dart 3.13.5 | Available; CI pins 3.47.9, exact SDK qualification pending |
| Xcode / CocoaPods | Xcode 26.3, build 17C529; Pods 1.17.0 | READY tools; iOS 26.3 simulator devices available, all shutdown |
| Android | SDK absent per doctor | MISSING; not required for macOS/iOS scope |
| Ports | 5432: local_postgres (PostgreSQL 15); 9000/9001: local_rustfs (latest); 8080: astradeployment-astravector-1 | BLOCKED defaults; A1/A2 must choose isolated ports; existing containers are unrelated |
| Volumes | Docker volume inventory succeeded; no voxprep DEV volumes observed | Existing volumes preserved; persistence smoke NOT RUN |
| Flutter runners | No macos/, ios/ or android/ directory tracked | BLOCKED GUI run; A4 must generate and qualify selected runner |

## Source findings

- Backend `pom.xml`: Java 21, Spring Boot 4.1.2. `application-dev.yml`
  imports only `infra/secrets/dev/backend/`; runtime and migrator identities remain
  separate. Default HTTP port 8080 is configurable with `SERVER_PORT`.
- Actual MVC entry is `/admin`; content routes use `/admin/content`, publication
  `/admin/publication`, media `/admin/media`. Health routes are
  `/actuator/health/liveness` and `/actuator/health/readiness` (DB + RustFS).
- Learner routes include `/api/v1/content/manifest`, `/api/v1/catalogue`,
  `/api/v1/content/{contentType}/{contentCode}` and exact revision/localization
  routes. Installation/auth prerequisites still need runtime qualification.
- Worker uses Bearer authentication and lease tokens on `/internal/v1/tts/jobs/*`,
  exact model/config delivery under `/internal/v1/tts/models/{voiceModelId}`.
  `init-secrets.sh` generates `worker_api_key` and projects it to backend config;
  worker `WORKER_TOKEN` must receive that same value without printing it.
  Host backend is reached via `http://host.docker.internal:<selected-port>`.
- Flutter `lib/main.dart` enables real bootstrap. `catalogue_source_providers.dart`
  defaults to production HTTP adapters; `app_configuration.dart` reads
  `VOXPREP_ENV` / `VOXPREP_API_URL` via dart defines. Drift is persistent through
  `driftDatabase(name: 'careerspeak')`, with repositories wired through Riverpod.
  Mock fixtures in the old README do not describe this default composition.
- Existing CI `a1-real-flutter-backend.yml` exercises
  `A1RealBackendFlutterAcceptanceTest` and `R5MediaLibraryLiveHttpAcceptanceTest`
  with real isolated infrastructure. These are reusable test entry points;
  no such test has been run in this checkout yet.

## Next execution

A1 owns isolated port selection and pinned image/platform checks; A2 owns
process-local Java selection and real backend startup; A4 owns platform runners
and Flutter SDK/plugin qualification. Available disk is a shared operator blocker.
Do not reuse unrelated PostgreSQL/RustFS instances or stop their containers.
A1–A5 acceptance remains NOT RUN. No production configuration was changed.
