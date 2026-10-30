# VoxPrep TTS Worker

Containerized outbound TTS worker for VoxPrep.

Current branch slice: **W2 Backend HTTP Control Adapter**.

The runtime boundary remains deliberately small:

```text
Backend owns job/file identity and durable state
Worker owns disposable compute and local model cache
```

## Qualified runtime baseline

Production dependencies are intentionally pinned rather than floating:

```text
Python       3.12.16
pip          26.2.2
httpx        0.28.1
piper-tts    1.4.2
FFmpeg       5.1.9-0+deb12u1
ffprobe      5.1.9-0+deb12u1
Debian       Bookworm
```

`worker/constraints.txt` locks the complete qualified Python runtime/test dependency graph, including HTTPX and Piper transitive dependencies.

Dependency upgrades are explicit qualification changes. Do not widen or remove pins as part of unrelated feature work.

The laboratory desktop stack may use `PySide6` and `PyInstaller`; neither belongs in this headless server Worker image. The Worker is distributed and deployed as an OCI/Docker image.

`piper-tts` is GPL-3.0-or-later software. Distribution/deployment packaging must preserve the applicable license notices and source-offer obligations required by that dependency.

## Required runtime configuration

```text
BASE_URL
WORKER_TOKEN
```

Optional:

```text
WORKER_ID=${HOSTNAME}
MODEL_CACHE_DIR=/var/lib/voxprep/tts/models
TEMP_DIR=/tmp/voxprep-tts
POLL_INTERVAL_SECONDS=2
LEASE_HEARTBEAT_INTERVAL_SECONDS=10
HTTP_CONNECT_TIMEOUT_SECONDS=5
HTTP_REQUEST_TIMEOUT_SECONDS=30
MAX_LOADED_MODELS=2
LOG_LEVEL=INFO
```

Worker HTTP calls use:

```http
Authorization: Bearer <WORKER_TOKEN>
```

The token is deployment-managed, must not be baked into the image and must never be logged.

## W2 Backend HTTP control adapter

`HttpBackendAdapter` implements the control-plane calls:

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{jobId}/heartbeat
POST /internal/v1/tts/jobs/{jobId}/fail
```

The adapter:

```text
preserves backend-owned jobId/fileId/leaseToken
uses strict connect/request timeouts
maps 401/403 to WORKER_AUTH_FAILED
maps 409/410 on lease-sensitive calls to LEASE_LOST
maps network/429/5xx to BACKEND_TEMPORARILY_UNAVAILABLE
fails closed on malformed claim payloads
performs no blind retries for mutating POST requests
```

Output upload remains W5.

Production composition intentionally continues to use the foundation adapter until W3 model acquisition, W4 Piper/FFmpeg processing and W5 output upload can complete a claimed job end-to-end. This prevents a partially implemented Worker from consuming production queue jobs.

## Build

From repository root:

```bash
docker build -t voxprep/tts-worker:w2 ./worker
```

The Docker build fails if the pinned FFmpeg package cannot be installed, the Python dependency graph is inconsistent, or Piper/ONNX Runtime cannot be imported.

## Run

Each Worker replica owns an isolated persistent model cache volume:

```bash
docker run --rm \
  -e BASE_URL=http://host.docker.internal:8080 \
  -e WORKER_TOKEN="$WORKER_TOKEN" \
  -e WORKER_ID=tts-worker-01 \
  -v voxprep-tts-models-worker-01:/var/lib/voxprep/tts/models \
  voxprep/tts-worker:w2
```

Do not share one model cache volume between Worker replicas.

## Development tests

Use the same Python minor series and committed constraints:

```bash
cd worker
python3.12 -m venv .venv
. .venv/bin/activate
python -m pip install pip==26.2.2
python -m pip install -c constraints.txt -e '.[dev]'
python -m pip check
pytest
```

## Dependency update procedure

A runtime dependency update is accepted only when all of the following remain green:

```text
exact Python dependency graph check
pip check
HTTPX + Piper + ONNX Runtime imports
FFmpeg version check
ffprobe version check
full worker unit/adapter tests
Docker image build
container startup/fail-fast/SIGTERM qualification
```

Piper model/audio listening qualification is additionally required before upgrading the Piper engine used for production synthesis.
