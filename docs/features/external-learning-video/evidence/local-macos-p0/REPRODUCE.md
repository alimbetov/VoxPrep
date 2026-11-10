# Reproduce / resume PR #56 local acceptance

Use a clean checkout of `feat/content-external-learning-video-v1`; record
`git rev-parse HEAD`, `git status --short`, timestamps, commands and exit codes.
Read the main acceptance report before treating any previous result as PASS.

## Dependency and Flutter qualification

Use the repository CI-pinned Flutter 3.47.9 in an isolated SDK. Do not globally
upgrade the existing SDK, regenerate goldens or run `pub upgrade` to hide a failure.

```bash
cd mobile/careerspeak_app
flutter --version
flutter pub get
flutter pub get --enforce-lockfile
flutter analyze
flutter test --concurrency=1 --reporter expanded
```

Replay the exact commands in `.github/workflows/flutter-main-ci.yml`,
`flutter-mock-ui.yml`, `a1-flutter-regression-slice.yml` and
`renderer-acceptance.yml` for their individual regression slices.

## Infrastructure and existing regression entry points

Use existing Compose configurations. Existing DEV uses 55432/19000, and existing
qualification uses 56432/29000; inspect ownership before starting/stopping any
service. This run reused qualification containers with separate PR databases.
Secret projections remain ignored under `infra/secrets/test/`. Never print or
commit their contents. No volume deletion or global Docker restart is part of
this runbook.

Select Java 21 using the repository `scripts/local/java-env.sh`. Export
`VOXPREP_DB_URL`, `VOXPREP_SECRET_DIR`, `VOXPREP_STORAGE_ENDPOINT` and the test
profile for the **dedicated PR test database**, then use existing commands:

```bash
mvn -B -ntp -f backend/pom.xml verify
mvn -B -ntp -f backend/pom.xml \
  -Dtest=A1RealBackendFlutterAcceptanceTest,R5MediaLibraryLiveHttpAcceptanceTest \
  -Dvoxprep.a1.enabled=true -Dvoxprep.r5.enabled=true test
```

For real A1 browser screenshots, install the workflow-pinned `playwright==1.56.0`
in a local venv and put that venv on PATH for Maven's Python subprocess. The
existing `infra/acceptance/r1-content-studio-browser.py` accepts optional
`VOXPREP_BROWSER_EXECUTABLE` for installed Chrome; otherwise it uses installed
Playwright Chromium. Keep the JVM bounded on this 16 GiB host.

Follow `.github/workflows/h2-rustfs-restart-acceptance.yml` only on a dedicated
restart-safe RustFS instance. Do not SIGKILL the shared user RustFS. Inspect
`infra/acceptance/b8-real-tts.sh` before local use: it assumes Linux utilities,
fixed host ports and disposable CI fixtures. Its default ports collide with
existing DEV here. No claim that the Linux shell script passed on macOS.

## Actual EV1 browser workflow

Backend feature flag must be true, with actual PostgreSQL/RustFS. Provision
`en_US.ljspeech.medium` using the existing opt-in `LocalMacTtsModelSetupTest`
against the dedicated Studio database. Start a real worker built from the same
PR SHA, with credentials in an ignored env file and a dedicated cache volume.
The Studio database must not be the destructive regression-suite database.

Configure these environment variables without logging credentials:

- `VOXPREP_EV1_BASE_URL` — dedicated backend HTTP URL.
- `VOXPREP_EV1_ADMIN_USERNAME`, `VOXPREP_EV1_ADMIN_PASSWORD` — ephemeral local admin.
- `VOXPREP_EV1_DATABASE`, `VOXPREP_EV1_POSTGRES_PORT` — dedicated Studio DB.
- `PGPASSWORD` — runtime-role password, read from its existing ignored projection.
- `VOXPREP_EV1_OUTPUT_DIR` — new ignored evidence directory for each attempt.
- Optional `VOXPREP_BROWSER_EXECUTABLE` — installed Chrome executable.

```bash
python3 infra/acceptance/ev1-content-studio-browser.py
```

This script is **not yet qualified end-to-end**: its earlier partial browser
execution passed actual authoring and audio, but infrastructure blocked the
corrected publication/entitlement/snapshot phase. It uses real pages/forms,
real Piper, normal publication, and runtime-role SQL reads/rolled-back probes.
Use a dedicated fixture DB: active collections require published members.
Keep failed reports/logs and exact source hashes; a timeout is never PASS.

After this script, independently test a live flag-disabled instance and a
non-admin authenticated session, full-entitled access, and image/audio HTTP
bytes/ETags against the frozen publication. These are not all covered by the
partial script result or by controller mocks.

## Native devices

The standard iOS runner is committed. Build from `lib/main.dart` with a test API
URL via `VOXPREP_API_URL` (development environment / real network data):

```bash
cd mobile/careerspeak_app
flutter devices
flutter build ios --simulator --debug --no-pub \
  --dart-define=VOXPREP_API_URL=http://127.0.0.1:18082
```

Use an available simulator without erasing its data. Build/install/launch are
not external-launch acceptance. Perform the complete checklist in the report.
Native RunnerTests checks only the system HTTPS-handler prerequisite and was
not executed in this run. Android remains blocked until an SDK/device exists.

Stop sequentially if host space collapses; preserve evidence and all user data.

## Exact SHA CI

Push without force. Inspect each workflow's `head_sha`/commit association through
GitHub, not just a green workflow name. Require all eight names listed in the
main report on the delivery HEAD. Evidence-only commits also need their own CI.
Do not mark Ready or merge while any manual P0 gate remains BLOCKED.
