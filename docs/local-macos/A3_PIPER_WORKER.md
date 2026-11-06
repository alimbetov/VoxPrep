# A3 — Real Piper TTS Worker + MP3

## Codex task

Reuse `worker/Dockerfile`, `pyproject.toml`, `constraints.txt` and actual backend private APIs. The worker runs Python 3.12, Piper and FFmpeg; its README documents pinning, cache and audio QC.

1. Build the worker image for the Mac architecture and record platform; prefer native `linux/arm64` where supported.
2. Configure `BASE_URL`, `WORKER_TOKEN`, `WORKER_ID` without embedding tokens. From Docker Desktop, do not call the host backend at container `localhost`; use a verified reachable hostname such as `host.docker.internal`, ensure Spring backend binds appropriately and secure endpoint access.
3. In real backend model catalog, select an available authorized `voiceModelId` and exact model/config SHA-256; trigger real TTS job.
4. Verify PENDING → claim/lease → exact revision download → integrity verification → Piper-generated WAV → FFmpeg-generated MP3 → backend output finalization → RustFS asset → READY.
5. Verify `ffprobe`: `audio/mpeg`, mono, 24kHz, nominal 64 kbps (qualified QC tolerance 60–68 kbps), measurable duration. Preview via backend authorized API; never distribute RustFS root credentials.
6. Negative: 401 wrong token, bad model checksum rejected, expired lease, backend restart/disconnection, repeated/replayed output, Worker restart; verify no duplicate finalized assets.
7. Implement `scripts/local/worker-start.sh`, `smoke-tts.sh`, persistent private model cache, clean redacted logs.

## Real worker routes to verify (from worker README)

```text
POST /internal/v1/tts/jobs/claim
POST /internal/v1/tts/jobs/{jobId}/heartbeat
POST /internal/v1/tts/jobs/{jobId}/output
POST /internal/v1/tts/jobs/{jobId}/fail
GET  /internal/v1/tts/models/{voiceModelId}/model
GET  /internal/v1/tts/models/{voiceModelId}/config
```

Do not assume the current backend actually implements each endpoint; prove by source and HTTP.

## Smoke IDs

TTS-01 worker authenticated connectivity; TTS-02 checksummed real model; TTS-03 real job PENDING→READY; TTS-04 valid newly synthesized MP3; TTS-05 uploaded persisted RustFS asset; TTS-06 replay/lease recovery.

## Done

Captured real job UUID, model revision, job state trace, S3 asset ID and FFprobe JSON evidence. Missing model = BLOCKED, never generate test MP3 in place of synthesis.
