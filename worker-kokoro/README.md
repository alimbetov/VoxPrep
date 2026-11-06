# Independent Kokoro-82M Worker (K2 — in development)

This service is deliberately separate from the production Piper `worker/`.
The specification is `docs/architecture/KOKORO_WORKER_V1_1_SPEC.md`.

**Not production-ready.** Backend V2 currently responds 503 to Kokoro claim,
and lacks engine-scoped V2 heartbeat/fail/output. The backend pre-provisioning
example currently stages `onnx/model_quantized.onnx` and `voices/af_heart.bin`.
The selected kokoro-onnx adapter expects `voices.bin` (aggregate), so a
runtime-compatible, pinned and commercially reviewed model bundle must be
qualified before real inference can work. Do not rename voice files to mask
a format mismatch.

The Worker does **not** fall back to Piper V1 endpoints. If V2 is unavailable,
it fails closed rather than submitting Kokoro audio under Piper identity.

Planned flow:
```
Backend pre-provisioning → PostgreSQL/RustFS STAGED bundle
→ V2 claim (KOKORO, currently disabled)
→ authenticated manifest/artifacts → SHA-256 cache
→ verified per-voice style vectors → local NPZ → Kokoro ONNX → WAV
→ FFmpeg/ffprobe MP3
→ V2 output finalize (not yet implemented on Backend)
```

Configuration: `BASE_URL`, `KOKORO_WORKER_TOKEN`, `WORKER_ID`,
`MODEL_CACHE_DIR`, `TEMP_DIR`, `POLL_SECONDS`,
`HEARTBEAT_SECONDS`, `HTTP_TIMEOUT_SECONDS`,
`MAX_ARTIFACT_BYTES`. Never commit tokens.

Tests: `python -m pytest worker-kokoro/tests` after installing development
dependencies. Tests are not proof of real Kokoro inference.

## Pilot voice map

| voiceCode | language | role |
|---|---|---|
| `af_heart` | `en-US` | narrated lessons |
| `am_michael` | `en-US` | second dialogue speaker |
| `bf_emma` | `en-GB` | British pronunciation |

Do not allow arbitrary `voiceCode` or locale from a worker claim. Inference
rejects mismatched pairs, missing or corrupt style files, and oversized PCM.
Kokoro itself may require a different phonemizer/model export; K3 must prove
all three voices with real WAV and MP3 before production activation.

## Required real K3 smoke (NOT YET RUN)

After the Backend has genuinely pre-provisioned a pinned 4-artifact bundle
(`onnx/model_quantized.onnx`, `voices/af_heart.bin`,
`voices/am_michael.bin`, `voices/bf_emma.bin`) and the Kokoro cache
has independently verified every SHA-256, run inside the Kokoro runtime image
or a native Python 3.12 installation:

```bash
python -m voxprep_kokoro_worker.real_model_smoke \
  --model-dir /var/lib/voxprep/kokoro/models/<manifestSha256> \
  --output-dir /tmp/voxprep-kokoro/k3-evidence
```

The command performs genuine ONNX inference and FFmpeg MP3 generation for
all three voices (and writes `k3-real-inference-report.json`). It must
exit zero and all three WAV/MP3 outputs must be audible and pass acoustic QC.
This does **not** simulate successful Backend claim/finalization: that
separately requires real PostgreSQL→Backend→Kokoro Worker→RustFS READY→MVC
MP3-preview evidence after V2 lifecycle and immutable fingerprint binding.

Never mark K3/K4 accepted based on mock tests or the existence of this script.
