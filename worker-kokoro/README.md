# Independent Kokoro-82M Worker (K3 inference proven; K4 acceptance pending)

This service is deliberately separate from the production Piper `worker/`.
The specification is `docs/architecture/KOKORO_WORKER_V1_1_SPEC.md`.

**Not production-ready.** K3 real ONNX → WAV → MP3 ran successfully for
`af_heart`, `am_michael`, `bf_emma` in GitHub Actions run 42175794324
(SHA `3368e88e2928b5a656c03b6e033bb2b790041e41`). This proves real
inference, not real Backend → PostgreSQL → RustFS → Content Studio acceptance.
Backend V2 Kokoro lifecycle and immutable snapshot contracts are implemented
on this feature branch; Kokoro remains disabled by default pending K4.

The Worker does **not** fall back to Piper V1 endpoints. If V2 is unavailable,
it fails closed rather than submitting Kokoro audio under Piper identity.

Implemented contract (end-to-end DEV acceptance still pending):
```
Backend pre-provisioning → PostgreSQL/RustFS STAGED bundle
→ V2 claim (KOKORO; behind explicit feature flag)
→ authenticated manifest/artifacts → SHA-256 cache
→ verified per-voice style vectors → local NPZ → Kokoro ONNX → WAV
→ FFmpeg/ffprobe MP3
→ V2 engine-fenced output finalization (implemented, real E2E pending)
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

## Reproduce real K3 smoke (passed in CI)

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

## K4 release gate (not yet accepted)

1. Provision pinned 4-artifact model bundle into real DEV PostgreSQL/RustFS; verify exact SHA-256 and sizes.
2. Register, review and explicitly activate three Kokoro voice models, retaining Piper isolation.
3. With isolated Kokoro worker token and feature flag enabled only in DEV, create content through real MVC Content Studio.
4. Confirm one immutable V2 job per fingerprint, authenticated engine-scoped claim and voice SHA binding.
5. Run real worker inference, heartbeat, MP3 upload, finalization to RustFS, READY state and browser preview.
6. Adversarial tests: parallel claims, expired lease, duplicate finalize, corrupt bundle, restart, token rotation and RustFS outage/retry.
7. Run exact-head-SHA complete CI and human audio/license review. Disable Kokoro again if any check fails.

K3 CI alone does **not** satisfy K4. Do not merge this Draft PR or enable Kokoro in production before K4 evidence.

## Long-text synthesis (K4.1 implementation)

The worker splits up to 12,000 characters into bounded chunks of up to 400
characters, preferring sentence endings and otherwise splitting at whitespace.
It refuses unbreakable tokens above the limit or more than 128 chunks. ONNX
creates PCM for one chunk at a time, with validated mono sample-rate consistency,
and appends each chunk to one WAV (at most 20 minutes of output). FFmpeg then
produces one MP3; SHA-256 is calculated in 1 MiB streamed blocks.

This avoids concatenating all PCM samples in RAM, but **does not yet make the
Backend model delivery/ingest streaming**, nor remove the audio file's temporary
on-disk footprint. Real long-form audio QC, lease expiry and RustFS acceptance
are still K4 blockers. Sentence detection uses simple punctuation heuristics,
not linguistic segmentation; pauses across chunks need human listening review.

## K4.3 hardening update (2026-11-06)

- Shared manifest cache installations use a persistent per-digest advisory
  `flock`, covering validation, download, checksum and atomic directory install.
  A crashed process releases the OS lock; never delete stable lock files.
  The current implementation targets macOS/Linux worker hosts.
- The derived three-voice `voices.bin` is recreated from checked source
  vectors and atomically replaced, without an unlink window for concurrent readers.
- Backend Kokoro V2 model delivery uses the production RustFS adapter's
  `openRead` streaming path, 64-KiB blocks and two verification passes.
  Corrupt upstream bytes fail the preflight SHA/size verification; corrupted
  bytes during the second pass cause stream failure and the Worker still
  validates exact downloaded SHA/size before installation.
- **Outstanding:** initial upstream Hugging Face fetch and
  `FileAssetIngestService.IngestCommand` still use `byte[]` and copies.
  True end-to-end streaming ingestion needs a separate change to the shared
  storage/ingest boundary, with backwards compatibility tests.
- **Outstanding:** no real local Backend + PostgreSQL + RustFS + MVC browser
  acceptance has been executed for this branch. Full lease/claim/replay,
  token-rotation, long-duration and restart scenarios require K4 evidence.

Production Kokoro feature flag remains OFF; PR remains Draft.
