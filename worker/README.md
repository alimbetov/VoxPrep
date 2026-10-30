# VoxPrep TTS Worker

Containerized outbound TTS worker for VoxPrep.

Current slice: **Functional TTS Worker (W3 + W4 + W5) with test hardening**.

The runtime boundary remains deliberately small:

```text
Backend owns job/file identity, model catalog and durable state
Worker owns disposable compute and a private persistent model cache
```

## Functional pipeline

The production composition performs:

```text
claim job from Backend
→ resolve exact voiceModelId + checksums from claim
→ reuse exact local model revision when cached
→ otherwise download model/config through Backend API
→ verify SHA-256 and atomically install cache revision
→ synthesize temporary WAV with Piper
→ convert to mono 24 kHz 64 kbps MP3 with FFmpeg
→ validate MP3 with ffprobe
→ revalidate lease
→ upload generated audio to Backend
→ Backend finalizes durable asset/job state
```

Worker never keeps or synchronizes a list of available models. Backend owns the model catalog. A job supplies one exact `voiceModelId`, `modelSha256` and `configSha256`; Worker either resolves that exact revision or fails. Silent fallback to another model is forbidden.

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

Test qualification tooling is pinned too:

```text
pytest       8.4.2
pytest-cov   7.1.0
coverage     7.17.0
```

`worker/constraints.txt` locks the complete qualified Python runtime/test dependency graph, including HTTPX, Piper and coverage transitive dependencies.

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

## Backend APIs used by Worker

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{jobId}/heartbeat
POST /internal/v1/tts/jobs/{jobId}/output
POST /internal/v1/tts/jobs/{jobId}/fail
GET  /internal/v1/tts/models/{voiceModelId}/model
GET  /internal/v1/tts/models/{voiceModelId}/config
```

A valid `WORKER_TOKEN` authenticates the process. `leaseToken` independently proves ownership of one claimed job.

## Model cache

Each Worker replica owns an isolated persistent cache:

```text
/var/lib/voxprep/tts/models/
└── <voiceModelId>/
    └── <modelSha256>/
        ├── model.onnx
        ├── model.onnx.json
        └── installed.json
```

On cache miss Worker downloads only through `BASE_URL`, verifies both checksums and publishes the revision atomically. A partial or checksum-invalid revision is never used.

Do not share one cache volume between Worker replicas.

## Audio output

Qualified production profile:

```text
format        MP3
MIME          audio/mpeg
channels      mono
sample rate   24 kHz
bitrate       64 kbps
profile       mp3-mono-24k-64k-v1
```

The Docker qualification runs a real WAV → FFmpeg → MP3 → ffprobe smoke test.

## Failure/recovery behavior

```text
model missing on Backend          → VOICE_MODEL_NOT_FOUND
model/config checksum mismatch    → VOICE_MODEL_CHECKSUM_MISMATCH
Piper load/synthesis failure      → classified worker failure
FFmpeg/QC failure                 → classified worker failure
lease lost                        → never finalize stale output
Backend temporarily unavailable   → do not invent FAILED; lease recovery remains authoritative
output response lost              → do not report false failure; Backend idempotency/lease state decides recovery
```

Worker does not retry mutating HTTP calls blindly.

## Build

From repository root:

```bash
docker build -t voxprep/tts-worker:functional ./worker
```

## Run

```bash
docker run --rm \
  -e BASE_URL=http://host.docker.internal:8080 \
  -e WORKER_TOKEN="$WORKER_TOKEN" \
  -e WORKER_ID=tts-worker-01 \
  -v voxprep-tts-models-worker-01:/var/lib/voxprep/tts/models \
  voxprep/tts-worker:functional
```

## Development tests

```bash
cd worker
python3.12 -m venv .venv
. .venv/bin/activate
python -m pip install pip==26.2.2
python -m pip install -c constraints.txt -e '.[dev]'
python -m pip check
pytest --cov=voxprep_tts_worker --cov-branch --cov-report=term-missing --cov-fail-under=90
```

Coverage is measured against the production Worker path. The deprecated foundation adapter and the standalone container smoke helper are not part of the coverage denominator; both remain protected by container qualification.

## Qualification gates

A functional Worker change is accepted only when all of the following remain green:

```text
exact Python dependency graph check
pip check
HTTPX + Piper + ONNX Runtime imports
model download/cache happy + failure paths
claim/heartbeat/fail/output adapter happy + failure paths
lease loss and transient Backend recovery tests
Piper load/synthesis happy + failure paths
FFmpeg/ffprobe profile and QC failure tests
production composition and shutdown tests
>= 90% branch-aware production-path coverage
Docker image build
real in-container audio smoke
container polling against Backend stub
SIGTERM shutdown qualification
WORKER_TOKEN non-leak check
```

Piper model/audio listening qualification is additionally required before upgrading the Piper engine used for production synthesis.
