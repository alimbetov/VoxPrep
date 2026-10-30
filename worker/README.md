# VoxPrep TTS Worker

Containerized outbound TTS worker for VoxPrep.

Current slice: **Functional TTS Worker with production hardening**.

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
→ keep only bounded disk-cache revisions by LRU
→ reuse loaded PiperVoice instances through bounded in-memory LRU
→ synthesize temporary WAV with Piper
→ convert to mono 24 kHz 64 kbps MP3 with FFmpeg
→ validate codec/sample-rate/channels/bitrate/duration with ffprobe
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

`worker/constraints.txt` locks the complete qualified Python runtime/test dependency graph. Dependency upgrades are explicit qualification changes.

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
MODEL_CACHE_MAX_BYTES=5368709120
TEMP_DIR=/tmp/voxprep-tts
POLL_INTERVAL_SECONDS=2
LEASE_HEARTBEAT_INTERVAL_SECONDS=10
HTTP_CONNECT_TIMEOUT_SECONDS=5
HTTP_REQUEST_TIMEOUT_SECONDS=30
MAX_LOADED_MODELS=2
LOG_LEVEL=INFO
```

`MAX_LOADED_MODELS` bounds loaded `PiperVoice` instances with LRU eviction. `MODEL_CACHE_MAX_BYTES` bounds old on-disk model revisions with LRU cleanup; the exact model revision needed by the current job is protected from eviction even when it alone exceeds the configured cache target.

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

On cache miss Worker downloads only through `BASE_URL`, verifies both checksums and publishes the revision atomically. A partial or checksum-invalid revision is never used. Old exact revisions are evicted least-recently-used when the configured disk-cache target is exceeded.

Do not share one cache volume between Worker replicas.

## Audio output

Qualified production profile:

```text
format        MP3
MIME          audio/mpeg
channels      mono
sample rate   24 kHz
bitrate       64 kbps (QC tolerance 60-68 kbps)
profile       mp3-mono-24k-64k-v1
```

The Docker qualification runs a real WAV → FFmpeg → MP3 → ffprobe smoke test.

## Container security

The image runs as numeric non-root UID/GID `10001:10001`. The image-owned model-cache and temp directories are writable by that identity. For bind mounts, the host path must be writable by UID/GID 10001; named Docker volumes initialized from the image are preferred.

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

## Functional test matrix

```text
runtime config          required values, defaults, invalid values, writable paths
Backend claim           empty queue, strict DTO parsing, auth/protocol/transport failures
model acquisition       Backend-only download, 404, model/config checksum failures
model disk cache        hit/miss, corruption repair, atomic install, LRU size cleanup
Piper memory cache      reuse, LRU eviction, configured loaded-model bound
Piper synthesis         exact model/config, load failure, synthesis failure, empty WAV
FFmpeg + ffprobe        codec, 24 kHz, mono, 64 kbps profile, duration and failures
lease                    heartbeat success, transient outage, confirmed lease loss
job processing           immutable IDs, failure routing, stale lease, ambiguous upload response
output upload            multipart identity/metadata, stale lease, Backend outage
polling                  idle queue, claimed job, transient outage, fail-fast contract errors
production composition   real adapter wiring, cache limits, shutdown, client cleanup
container                non-root UID/GID, writable runtime dirs, audio smoke, polling, SIGTERM
```

## Qualification gates

A functional Worker change is accepted only when all of the following remain green:

```text
exact Python dependency graph check
pip check
model/cache happy + failure paths
Piper LRU cache qualification
FFmpeg/ffprobe profile and bitrate QC
lease loss and transient Backend recovery tests
>= 90% branch-aware production-path coverage
Docker image build
non-root UID/GID and writable-directory checks
real in-container audio smoke
container polling against Backend stub
SIGTERM shutdown qualification
WORKER_TOKEN non-leak check
```

Before merge, a Worker feature branch must be synchronized with the current `main` and the integrated exact HEAD must pass these gates. Qualification of an older pre-sync SHA is not sufficient.

Piper model/audio listening qualification is additionally required before upgrading the Piper engine used for production synthesis.
