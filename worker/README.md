# VoxPrep TTS Worker

Containerized outbound TTS worker for VoxPrep.

Current branch slice: **W1 Runtime Foundation**.

The runtime contract is intentionally stable before production adapters are enabled:

```text
Backend owns job/file identity and durable state
Worker owns disposable compute and local model cache
```

## Qualified runtime baseline

Production dependencies are intentionally pinned rather than floating:

```text
Python       3.12.16
pip          26.2.2
piper-tts    1.4.2
FFmpeg       5.1.9-0+deb12u1
ffprobe      5.1.9-0+deb12u1
Debian       Bookworm
```

`worker/constraints.txt` locks the complete currently qualified Python runtime/test dependency graph, including Piper transitive dependencies such as ONNX Runtime and NumPy.

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

## Build

From repository root:

```bash
docker build -t voxprep/tts-worker:w1 ./worker
```

The Docker build fails if the pinned FFmpeg package cannot be installed, the Python dependency graph is inconsistent, or Piper/ONNX Runtime cannot be imported.

## Run

Each worker replica owns an isolated persistent model cache volume:

```bash
docker run --rm \
  -e BASE_URL=http://host.docker.internal:8080 \
  -e WORKER_TOKEN="$WORKER_TOKEN" \
  -e WORKER_ID=tts-worker-01 \
  -v voxprep-tts-models-worker-01:/var/lib/voxprep/tts/models \
  voxprep/tts-worker:w1
```

Do not share one model cache volume between worker replicas.

## Development tests

Use the same Python minor series and the committed constraints:

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
Piper + ONNX Runtime import
FFmpeg version check
ffprobe version check
full worker unit tests
Docker image build
container startup/fail-fast/SIGTERM qualification
```

Piper model/audio listening qualification is additionally required before upgrading the Piper engine used for production synthesis.

## W1 limitation

The image currently composes the W1 foundation backend adapter, which intentionally claims no real work. This proves configuration, package/container lifecycle, orchestration boundaries, cleanup and shutdown behavior.

The next slice replaces that adapter with the real `BASE_URL` machine-token HTTP control adapter without changing the application/domain layer.
