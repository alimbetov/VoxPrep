# CareerSpeak — TTS Worker Model Acquisition Contract

**Branch:** `feat/tts-worker-foundation`  
**Status:** W3 design baseline

## Decision

The TTS Worker downloads Piper models only through the Backend identified by `BASE_URL`.

The Worker does not receive RustFS credentials, RustFS endpoints, presigned URLs, or model files baked into the container image.

```text
BASE_URL
   │
   ├─ claim job
   │     └─ voiceModelId + modelSha256 + configSha256
   │
   └─ model download API
          │
          ▼
       Worker
          │
          ├─ verify SHA-256
          ├─ atomic install
          └─ persistent local model cache
```

## Backend endpoints

Recommended explicit endpoints:

```http
GET /internal/v1/tts/models/{voiceModelId}/model
GET /internal/v1/tts/models/{voiceModelId}/config
Authorization: Bearer <WORKER_TOKEN>
```

The Worker constructs both URLs from the same runtime `BASE_URL` used for job APIs.

No storage-specific URL may appear in the worker configuration.

## Claim requirements

The job claim must provide the exact immutable revision identity and checksums:

```text
voiceModelId
voiceModelCode
modelSha256
configSha256
```

The Worker MUST NOT select a newer model implicitly.

The claimed `voiceModelId` is authoritative for that job even if another model revision becomes active after the claim.

## Local cache identity

A cached model installation is valid only for the exact claimed checksums.

Recommended directory layout:

```text
/var/lib/voxprep/tts/models/
└── <voiceModelId>/
    └── <modelSha256>/
        ├── model.onnx
        ├── model.onnx.json
        └── installed.json
```

`installed.json` records at least:

```json
{
  "voiceModelId": "...",
  "modelSha256": "...",
  "configSha256": "..."
}
```

The metadata file is local cache evidence only. Backend remains authoritative for model lifecycle.

## Cache hit

Before any download the Worker checks:

```text
final directory exists
model.onnx exists
model.onnx.json exists
installed.json matches voiceModelId/modelSha256/configSha256
```

Optionally, full SHA-256 may be revalidated on startup or according to cache policy. A cache entry whose metadata or files are inconsistent is treated as invalid and reacquired.

## Cache miss / installation

Required flow:

```text
claim voiceModelId + checksums
        ↓
cache miss
        ↓
create unique temp directory
        ↓
GET ${BASE_URL}/internal/v1/tts/models/{id}/model
        ↓
stream to temp/model.onnx
        ↓
verify modelSha256
        ↓
GET ${BASE_URL}/internal/v1/tts/models/{id}/config
        ↓
stream to temp/model.onnx.json
        ↓
verify configSha256
        ↓
write installed.json
        ↓
fsync/close
        ↓
atomic rename temp → final cache directory
```

The final cache directory MUST never become visible before both artifacts pass checksum verification.

## Download behavior

Model downloads should be streamed to disk rather than loaded completely into memory.

Worker HTTP client must support:

```text
connect timeout
read/request timeout suitable for large model files
streamed response body
bounded retry for transport-level failure
cancellation on shutdown where practical
```

Backend retry policy for jobs remains authoritative; the Worker must not perform unbounded model-download retries.

## Authentication

Every model download uses the same dedicated worker machine credential:

```http
Authorization: Bearer <WORKER_TOKEN>
```

The token is never written to cache metadata or logs.

## Failure mapping

Minimum model acquisition failures:

```text
VOICE_MODEL_NOT_FOUND
VOICE_MODEL_DOWNLOAD_FAILED
VOICE_MODEL_CHECKSUM_MISMATCH
VOICE_MODEL_CACHE_INSTALL_FAILED
VOICE_MODEL_LOAD_FAILED
```

Examples:

```text
404 from model/config endpoint
→ VOICE_MODEL_NOT_FOUND

5xx / connection failure / incomplete body
→ VOICE_MODEL_DOWNLOAD_FAILED

SHA-256 mismatch
→ VOICE_MODEL_CHECKSUM_MISMATCH

atomic install/filesystem failure
→ VOICE_MODEL_CACHE_INSTALL_FAILED
```

A checksum mismatch MUST delete the temporary candidate and MUST NOT fall back silently to another voice model.

## Persistent volume semantics

The model cache is mounted outside the container writable layer:

```bash
-v voxprep-tts-models:/var/lib/voxprep/tts/models
```

Therefore:

```text
container restart
→ verified model remains installed
→ next matching job is cache hit
```

Replacing the Worker image does not require re-downloading unchanged model revisions as long as the cache volume is retained.

## Image boundary

The Docker image contains:

```text
worker code
Piper runtime
FFmpeg/ffprobe
OS/runtime dependencies
```

The Docker image does NOT contain:

```text
voice model .onnx files
voice model config files
Backend URL
worker token
RustFS credentials
```

This allows independent deployment of:

```text
worker software revision
voice model revision
Backend environment
```

## Concurrency

The first Worker implementation processes one job at a time, so one process will not download the same model twice concurrently.

If multiple worker containers share one model-cache volume later, cache installation must add an inter-process lock or equivalent atomic coordination before that deployment mode is qualified.

Until then, recommended deployment is one persistent cache volume per worker replica or otherwise isolated cache ownership.

## W3 acceptance

W3 is accepted only when tests prove:

```text
cache hit performs zero model HTTP downloads
cache miss downloads model and config from BASE_URL
WORKER_TOKEN authenticates both downloads
model SHA-256 mismatch is rejected
config SHA-256 mismatch is rejected
partial download is never installed
failed install leaves no valid final cache directory
successful install is atomic
container restart reuses mounted cached model
Worker never needs RustFS address or credentials
claimed voiceModelId is never silently substituted
```
