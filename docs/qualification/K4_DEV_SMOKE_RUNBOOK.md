# K4 DEV smoke gate — Kokoro + real Flutter (2026-11-06)

Scope: branch `feat/tts-kokoro-worker-spec-v1-1`, PR #54. This is an operator runbook, **not** acceptance evidence. Keep PR Draft and production Kokoro disabled.

## 0. Exact-SHA preflight

- Record `git rev-parse HEAD`; ensure clean checkout and compare against exact-SHA CI.
- On Apple Silicon verify native macOS Python 3.12 dependencies for `kokoro-onnx` / `onnxruntime`, `ffmpeg`, `ffprobe`, `espeak-ng`. Python tests are not audio QC.
- Preserve old Piper worker and data. No destructive Docker `down -v`.

## 1. DEV services

From repository root:

```sh
./infra/scripts/init-secrets.sh dev
docker compose --env-file infra/env/dev.env.example -f infra/compose/compose.dev.yml up -d --wait postgres rustfs
docker compose --env-file infra/env/dev.env.example -f infra/compose/compose.dev.yml run --rm rustfs-bootstrap
docker compose --env-file infra/env/dev.env.example -f infra/compose/compose.dev.yml ps -a
```

Readiness: PostgreSQL accepts connections, RustFS has backend IAM + private bucket, one-shot bootstrap exits 0. Backend:

```sh
cd backend
mvn -B -ntp spring-boot:run -Dspring-boot.run.profiles=dev
# second terminal
curl -fsS http://127.0.0.1:8080/actuator/health/readiness
```

Check `UP`. Run Liquibase as configured (migrator role), not as app runtime user.

## 2. Pinned bundle + Kokoro activation (controlled DEV only)

Start with `VOXPREP_KOKORO_ENABLED=false`. Use the exact four pinned artifacts, digests and sizes from `docs/architecture/KOKORO_BACKEND_PREPROVISIONING.md`.
A separate non-secret external YAML file must set `voxprep.tts.kokoro-provisioning.enabled=true` with the four-artifact bundle, and be loaded by Spring using `spring.config.additional-location` (or equivalent). Provisioner imports model on startup, verifies content and stages to real PostgreSQL + RustFS. Confirm `app.tts_kokoro_bundle` / artifacts and READY FileAssets before enabling jobs. Do not edit the committed config to store secrets.

Review/register/activate the three voice models using the approved operator workflow. STAGED bundle alone does not activate a voice.

Only **after** model data and voice activation have been verified: configure a separate DEV `VOXPREP_KOKORO_WORKER_API_KEY`, set `VOXPREP_KOKORO_ENABLED=true` **on Backend**, and restart Backend. Worker receives identical secret through `KOKORO_WORKER_TOKEN`; do not share the Piper key.

## 3. Run Kokoro Worker

```sh
cd worker-kokoro
python3.12 -m venv .venv
source .venv/bin/activate
pip install -e '.[dev]'
python -m pytest tests
export BASE_URL=http://127.0.0.1:8080
export WORKER_ID=kokoro-mac-dev-01
export MODEL_CACHE_DIR="$HOME/.cache/voxprep/kokoro"
export TEMP_DIR=/tmp/voxprep-kokoro
export HEARTBEAT_SECONDS=10
export POLL_SECONDS=2
mkdir -p "$MODEL_CACHE_DIR" "$TEMP_DIR"
# Set KOKORO_WORKER_TOKEN using a non-committed local secret, then:
python -m voxprep_kokoro_worker.main
```

Run three approved voices sequentially; inspect `PENDING -> PROCESSING -> READY`, correct file SHA/size, one output MP3 per immutable fingerprint, real RustFS object and MVC preview. Confirm original Piper path still works. Include one 1–2 sentence and one long text example. Use `ffprobe` to check mono MP3/24 kHz/64 kbps; listen for clipped words and unnatural pauses.

## 4. Failure and replay probes

1. Submit same text/voice/revision twice: check dedupe and single result.
2. Restart Worker mid-job: expired lease is reclaimed only once, stale finalize is rejected.
3. Attempt duplicate output and stale-lease finalize: no second READY asset.
4. Temporarily stop RustFS during upload, restart it, reprocess safely.
5. Run two Workers sharing cache: concurrent install downloads once; no repair while model in use.
6. Present wrong Piper credential to Kokoro V2: rejected; original Piper path unchanged.
7. Rotate Kokoro DEV key after jobs drain: old token rejected, new key accepted.

Record job ID, SHA, timestamps, HTTP status and logs; redact credentials.

## 5. Flutter acceptance is a separate gate

```sh
cd mobile/careerspeak_app
flutter doctor -v
flutter pub get
flutter analyze
flutter test
flutter devices
```

For iOS simulator when platform runners are missing: `flutter create --platforms=ios .` and select the simulator. Real-backend build settings:

```sh
flutter run -d ios \
  --dart-define=VOXPREP_ENV=development \
  --dart-define=VOXPREP_API_URL=http://127.0.0.1:8080 \
  --dart-define=VOXPREP_MOCK_BILLING=false \
  --dart-define=VOXPREP_MOCK_PURCHASE=false
```

A simulator on the same Mac can use 127.0.0.1; physical phones require a reachable host and platform network permissions. Flutter sees only **published CURRENT** material, not arbitrary TTS READY drafts. Complete Content Studio review/approval and immutable publication first, then verify actual HTTP catalogue -> Drift -> media download -> playback -> offline reopen after process restart.

## Release decision

PASS requires evidence on the same exact SHA for real model provisioning, three-voice audio, negative lease/replay, RustFS READY + MVC preview, and published Flutter playback/offline. The pre-existing K2/B1/B8/A1/H2/Flutter workflows do not prove the entire K4 chain. Keep `VOXPREP_KOKORO_ENABLED=false` in production; never merge PR #54 based solely on this checklist.

Known remaining hardening: initial Hugging Face fetch and FileAsset ingest still buffer artifacts in byte arrays, so complete upstream streaming ingestion and memory-limit testing are required before production activation.
