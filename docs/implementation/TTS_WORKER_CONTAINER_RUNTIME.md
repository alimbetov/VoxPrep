# CareerSpeak — TTS Worker Container Runtime Contract

**Branch:** `feat/tts-worker-foundation`  
**Status:** W0 normative runtime design

## Decision

`tts-worker` is delivered as one immutable OCI/Docker image.

The image contains the worker application and required audio tooling. Environment-specific addresses and credentials are supplied only at container runtime.

The same image artifact MUST be deployable unchanged in development, test and production.

Each Worker replica owns its own persistent local model cache. Cache volumes/directories are never shared between Worker replicas or machines.

```text
immutable image
    + runtime BASE_URL
    + runtime WORKER_TOKEN
    + private persistent model-cache volume
        ↓
    TTS Worker
```

Backend URL, credentials and environment names MUST NOT be baked into the image.

## Canonical runtime variables

Required:

```text
BASE_URL
WORKER_TOKEN
```

Optional with defaults:

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

`BASE_URL` is the canonical backend base URL variable. Do not introduce a second alias such as `BACKEND_URL` in production configuration.

Examples:

```text
BASE_URL=http://host.docker.internal:8080
BASE_URL=http://voxprep-backend:8080
BASE_URL=https://api.voxprep.example
```

The worker constructs only known internal paths below this base, for example:

```text
${BASE_URL}/internal/v1/tts/jobs/claim
${BASE_URL}/internal/v1/tts/jobs/{jobId}/heartbeat
${BASE_URL}/internal/v1/tts/jobs/{jobId}/output
${BASE_URL}/internal/v1/tts/jobs/{jobId}/fail
${BASE_URL}/internal/v1/tts/models/{voiceModelId}/model
${BASE_URL}/internal/v1/tts/models/{voiceModelId}/config
```

`BASE_URL` SHOULD NOT end with `/`; configuration normalization removes a single trailing slash before requests are built.

## Worker identity

Manual worker identity is not required for ordinary container deployment.

Default:

```text
WORKER_ID = HOSTNAME
```

Docker/container platforms already provide a per-container hostname, so parallel replicas naturally receive different worker identities.

An explicit `WORKER_ID` may override the default for controlled environments or tests.

`WORKER_ID` is operational identity only. It is not a secret and it does not replace lease ownership.

Authoritative job ownership remains:

```text
jobId
+ workerId
+ leaseToken
+ leaseUntil
```

## Authentication

Worker authenticates to Backend using a dedicated machine credential:

```http
Authorization: Bearer <WORKER_TOKEN>
```

The token is injected at runtime by the deployment environment.

The token MUST NOT be:

```text
committed to Git
stored in the image
printed in logs
included in exception messages
written to temporary files
```

Future secret-store integration may change how the environment variable is populated without changing worker code.

## No inbound service requirement

The worker is an outbound polling process, not an HTTP server.

Initial production image therefore exposes no application port.

```text
Worker
  ├─ outbound HTTP → Backend
  ├─ local Piper subprocess
  ├─ local FFmpeg subprocess
  └─ private local model cache
```

Backend never calls the worker directly.

Horizontal scaling is performed by starting additional identical containers.

## Persistent and ephemeral filesystem

Persistent and private to one Worker replica:

```text
/var/lib/voxprep/tts/models
```

This directory contains verified immutable Piper model revisions and MUST be backed by storage owned only by that Worker replica.

Do not mount the same NFS/SMB/shared Docker volume into multiple Worker replicas.

Examples:

```text
Worker 01 → voxprep-tts-models-worker-01
Worker 02 → voxprep-tts-models-worker-02
Worker 03 → voxprep-tts-models-worker-03
```

Ephemeral:

```text
/tmp/voxprep-tts
```

Temporary job directories contain transient WAV/MP3 files only and may disappear when the container terminates.

Example:

```text
/tmp/voxprep-tts/<jobId>/source.wav
/tmp/voxprep-tts/<jobId>/output.mp3
```

Temporary job data MUST be cleaned after READY, FAILED, lease loss or graceful cancellation when possible.

## Image content

The production image must provide exact qualified versions of:

```text
Python runtime
VoxPrep tts-worker package
Piper runtime
FFmpeg / ffprobe
required OS runtime libraries
CA certificate bundle
```

Voice models are not baked into the application image.

Models are downloaded from Backend through `BASE_URL` by exact immutable revision, verified by SHA-256 and stored in that Worker's own mounted model cache. This prevents rebuilding the worker image for every voice-model revision.

A new Worker machine starts with an empty cache and lazily downloads only models required by jobs it actually claims.

## Image versioning

Do not deploy mutable `latest` as the qualified production identity.

Preferred image identity:

```text
voxprep/tts-worker:<release-or-git-sha>
```

For example:

```text
voxprep/tts-worker:0.1.0
voxprep/tts-worker:a0537a4
```

Production deployment should be reproducible from an exact immutable image digest or exact version tag.

## Docker startup examples

Local backend on host:

```bash
docker run --rm \
  -e BASE_URL=http://host.docker.internal:8080 \
  -e WORKER_TOKEN="$WORKER_TOKEN" \
  -v voxprep-tts-models-worker-local:/var/lib/voxprep/tts/models \
  voxprep/tts-worker:<version>
```

Docker network, Worker 01:

```bash
docker run --rm \
  --network voxprep \
  -e BASE_URL=http://voxprep-backend:8080 \
  -e WORKER_TOKEN="$WORKER_TOKEN" \
  -e WORKER_ID=tts-worker-01 \
  -v voxprep-tts-models-worker-01:/var/lib/voxprep/tts/models \
  voxprep/tts-worker:<version>
```

A second replica uses a distinct cache:

```bash
docker run --rm \
  --network voxprep \
  -e BASE_URL=http://voxprep-backend:8080 \
  -e WORKER_TOKEN="$WORKER_TOKEN" \
  -e WORKER_ID=tts-worker-02 \
  -v voxprep-tts-models-worker-02:/var/lib/voxprep/tts/models \
  voxprep/tts-worker:<version>
```

## Startup validation

The process MUST fail fast before polling when required configuration is invalid.

Reject at startup:

```text
missing BASE_URL
invalid/non-http(s) BASE_URL
missing WORKER_TOKEN
invalid numeric interval configuration
unwritable TEMP_DIR
unusable configured MODEL_CACHE_DIR
```

The token value itself MUST never be included in validation output.

Example safe failure:

```text
configuration error: WORKER_TOKEN is required
```

## Graceful shutdown

Container shutdown normally sends `SIGTERM`.

Required behavior:

```text
SIGTERM
→ stop claiming new jobs
→ mark shutdown requested
→ stop/finish current safe stage according to lease rules
→ never upload after lease ownership is lost
→ stop heartbeat
→ remove temporary files when possible
→ exit
```

The Backend lease remains the recovery mechanism if the process is killed before graceful completion.

## Restart policy

Process supervision is deployment-owned.

Typical Docker policy:

```text
restart: unless-stopped
```

or the platform equivalent.

The worker must be safe to restart at any point because Backend queue/lease state is durable.

Restarting or replacing one Worker cannot invalidate model caches owned by any other Worker because cache ownership is isolated.

## Networking and storage boundaries

Worker receives:

```text
BASE_URL
WORKER_TOKEN
```

Worker does not receive:

```text
PostgreSQL URL/password
RustFS access key
RustFS secret key
ADMIN credentials
learner installation credentials
```

Final generated MP3 is uploaded to Backend API using `jobId + fileId + leaseToken + fingerprint`; Backend owns the RustFS write.

Model artifacts are also acquired only from Backend endpoints under `BASE_URL`.

## Scaling contract

Horizontal scale does not introduce shared Worker state:

```text
Backend
  ├─ Worker A → private cache A
  ├─ Worker B → private cache B
  └─ Worker C → private cache C
```

Adding a Worker requires only:

```text
same immutable image
BASE_URL
WORKER_TOKEN
private local cache volume/directory
```

No shared filesystem, cache synchronization service or distributed cache lock is required.

Duplicate copies of the same model on different Worker machines are acceptable by design. Operational simplicity and failure isolation take precedence over deduplicating model disk usage across hosts.

## W1 implementation impact

Container-readiness is part of the runtime foundation rather than an afterthought.

W1 should therefore introduce:

```text
worker/pyproject.toml
worker/Dockerfile
worker/.dockerignore
worker/src/.../config.py
worker/src/.../main.py
```

The initial Docker image may use fake application adapters for qualification, but startup/configuration/container lifecycle must already match the production boundary.

Production Piper/FFmpeg/model-cache integration remains implemented in later slices.

## Acceptance

The container runtime contract is accepted when tests or CI prove:

```text
same image starts against different BASE_URL values
missing BASE_URL fails fast
missing WORKER_TOKEN fails fast
WORKER_ID defaults deterministically from HOSTNAME
explicit WORKER_ID overrides HOSTNAME
no PostgreSQL/RustFS credentials are required
model cache path can be mounted externally
cache volume is private to one Worker replica
new Worker bootstraps models independently from BASE_URL
SIGTERM stops further claims
no inbound application port is required
logs never expose WORKER_TOKEN
```
