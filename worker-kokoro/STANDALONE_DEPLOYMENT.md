# Kokoro standalone HTTP Worker — D1 isolated mode

This implementation is **an additional process mode**. It does not modify the
existing VoxPrep V2 `voxprep-kokoro-worker` claim/heartbeat/finalization
contract. Keep PR #54 Draft until real model inference, integration, legal review
and recovery tests are accepted.

## Architecture

- **Input:** authenticated `POST /v1/tts/jobs`; no VoxPrep Backend dependency.
- **Model:** local operator-reviewed `manifest.json` (immutable 40-hex source
  revision, manifest SHA-256, per-artifact SHA-256, size and UUID identity).
- **Sources, in order:** local folder, private RustFS/S3 bucket, then an
  explicitly configured pinned Hugging Face repository. Each successful
  source download is verified by the existing `KokoroModelCache` before use.
  When the verified cache is populated, startup works without reaching
  those sources.
- **Engine:** original Kokoro ONNX/three voice style vectors, long-text chunks,
  WAV and FFmpeg MP3. **No Piper fallback.**
- **Output:** private persistent local volume; optional direct RustFS/S3
  upload with HEAD size/hash-metadata check. Results remain accessible via
  authenticated metadata/audio GET endpoints across clean restarts.

## Prepare a pinned manifest

Use separately reviewed (and correctly licensed) files:

```text
model-source/
  onnx/model_quantized.onnx
  voices/af_heart.bin
  voices/am_michael.bin
  voices/bf_emma.bin
```

Once a real upstream repository revision has been chosen, use the manifest
generator (do not use floating `main` or `latest` as a revision):

```bash
cd worker-kokoro
python3.12 -m venv .venv
. .venv/bin/activate
python -m pip install -e '.[dev,s3]'
voxprep-kokoro-manifest \
  --source ./model-source \
  --model-code kokoro-82m-pinned \
  --revision <FULL_40_HEX_UPSTREAM_COMMIT> \
  --output ./manifest.json
```

The manifest lists **four exact objects**. Upload the same files to RustFS
under `<S3_PREFIX>/<path>`, if using a private model mirror. The manifest is
reviewed deployment configuration, not a dynamic client-supplied URL. Its
`sourceRevision` must refer to the reviewed upstream revision if HF is a
configured fallback. All model licenses and commercial redistribution rights
must be verified before deploying to customers.

## Native execution

```bash
export STANDALONE_API_TOKEN="$(python -c 'import secrets; print(secrets.token_urlsafe(32))')"
export STANDALONE_MANIFEST_PATH="$PWD/manifest.json"
export STANDALONE_MODEL_DIR="$PWD/model-source"
export MODEL_CACHE_DIR="$HOME/.cache/kokoro-standalone/models"
export STANDALONE_OUTPUT_DIR="$HOME/.local/share/kokoro-standalone/output"
export TEMP_DIR="$HOME/.cache/kokoro-standalone/tmp"
# Optional: STANDALONE_HF_REPO=org/model-repo
# Optional: STANDALONE_MODEL_S3_BUCKET=private-models
# Optional: STANDALONE_OUTPUT_S3_BUCKET=generated-audio
# Optional: STANDALONE_S3_ENDPOINT_URL=https://rustfs.example:9000
voxprep-kokoro-standalone
```

On startup, the Worker installs/verifies the pinned bundle before advertising
readiness. Source unavailability is recoverable from a healthy local cache.
An invalid/changed manifest, missing artifact or broken checksum fails closed.

## Docker Compose

```bash
cd worker-kokoro
cp .env.standalone.example .env.standalone
# Set STANDALONE_API_TOKEN to a unique random secret.
docker compose --env-file .env.standalone -f compose.standalone.yml up -d --build
```

For private RustFS/S3 keys, mount a dedicated credentials file rather than
committing credentials to source control:

```bash
# In a private .env.standalone:
# STANDALONE_AWS_CREDENTIALS_FILE=/absolute/private/path/aws-credentials
docker compose --env-file .env.standalone \
  -f compose.standalone.yml -f compose.standalone.s3.yml up -d --build
```

The default container runs non-root UID 10002, exposes HTTP only via host
loopback, drops Linux capabilities, uses read-only root FS and persistent
volumes, limits memory to 3 GiB and CPU to 2. When running behind another host
or a reverse proxy, enforce HTTPS, network ACLs and isolated API credentials.

**Do not share the standalone token with VoxPrep V2 Worker.**

## HTTP contract

```bash
curl -fsS http://127.0.0.1:8086/health/live
curl -fsS -H "Authorization: Bearer $STANDALONE_API_TOKEN" \
  http://127.0.0.1:8086/health/ready
curl -fsS -H "Authorization: Bearer $STANDALONE_API_TOKEN" \
  http://127.0.0.1:8086/v1/models/active
curl -fsS -H "Authorization: Bearer $STANDALONE_API_TOKEN" \
  http://127.0.0.1:8086/v1/metrics
curl --fail-with-body -H "Authorization: Bearer $STANDALONE_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"Hello, welcome!","voiceCode":"af_heart","speed":1.0}' \
  http://127.0.0.1:8086/v1/tts/jobs
```

The synthesis call returns **201 only after MP3 is fully generated, verified
and committed**. Response includes `id`, `sha256`, `sizeBytes`,
`durationMs`, `audioProfile`, `manifestSha256`, `voiceCode`,
`downloadPath` and optional `s3Key`. Client may subsequently use
`GET /v1/tts/jobs/{id}` and `GET /v1/tts/jobs/{id}/audio` with the same bearer.
Both routes require authentication; corrupted local MP3 returns 404 instead of
being served. All three voice codes are explicit and enforced.

Invalid input -> 400; missing/invalid token -> 401; busy -> 429; model not
ready or inference/storage unavailable -> 503. Requests are limited to 64 KiB
and 12,000 characters, output to 16 MiB, one active ONNX inference and eight
concurrent HTTP connections. The service never logs request text or secrets.

## Resilience, observability and known limitations

- Model cache holds a cross-process `flock` throughout synthesis.
- Completed local outputs remain accessible on restart. Aborted temporary
  workspaces are cleaned at startup; incomplete jobs **are not retried**.
- Source fallback is ordered, but every artifact is checked against the same
  manifest. A source cannot silently substitute another model revision.
- `/health/live` is unauthenticated (for infrastructure probes).
  `/health/ready`, `/v1/models/active` and `/v1/metrics` require bearer auth.
- The server synchronously handles synthesis. Long inference may exceed
  reverse-proxy/client timeouts; **durable asynchronous job queue, idempotency,
  crash recovery and cancellation must be added before general production**.
- There is no per-tenant quota, no horizontal scheduler or multi-tenant
  authorization. This endpoint is a single-tenant internal service, not a
  public internet API.
- Exact real ONNX QC for three voices and K4
  `PostgreSQL -> Backend -> Worker -> RustFS -> Content Studio Preview`
  still need actual evidence; unit tests use injected fake inference.
- Multiarch image build checks only packaging/import compatibility. They do
  **not** prove performance or memory sufficiency on Apple Silicon.
- Operational monitoring should scrape the authenticated metrics endpoint
  through an adapter; the current endpoint is a small JSON diagnostic, not
  Prometheus/OpenTelemetry telemetry.

## Exit criteria before production

1. Real model bootstrap: local, private RustFS and pinned HF paths with hash
   mismatch, interruption and offline restart tests.
2. Real ONNX inference and listened-to MP3 for all three voices.
3. Independent API to S3 integration with real access controls, outage and
   corrupt-object scenarios.
4. Async durable queue/replay/idempotency, bounded waiting and SIGTERM handling.
5. Exact-SHA worker unit CI, real native ARM64/AMD64 smoke and audio licensing.
6. VoxPrep V2 K4, Piper regression and cross-project adapter acceptance.

The independent mode remains **experimental** until those gates are met.
