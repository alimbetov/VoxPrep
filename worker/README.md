# VoxPrep TTS Worker

Containerized outbound TTS worker for VoxPrep.

Current branch slice: **W1 Runtime Foundation**.

The runtime contract is intentionally stable before production adapters are enabled:

```text
Backend owns job/file identity and durable state
Worker owns disposable compute and local model cache
```

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

```bash
cd worker
python -m venv .venv
. .venv/bin/activate
pip install -e '.[dev]'
pytest
```

## W1 limitation

The image currently composes the W1 foundation backend adapter, which intentionally claims no real work. This proves configuration, package/container lifecycle, orchestration boundaries, cleanup and shutdown behavior.

The next slice replaces that adapter with the real `BASE_URL` machine-token HTTP control adapter without changing the application/domain layer.
