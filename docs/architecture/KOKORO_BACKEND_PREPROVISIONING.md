# K1 — Backend-first Kokoro model pre-provisioning

**Status:** code added, real DEV provisioning **NOT RUN**, K1 end-to-end **NOT ACCEPTED**.  
**Goal:** use the existing Piper-style backend acquisition path to stage Kokoro artifacts **before** Kokoro Worker starts. Do not allow Worker to fetch from Hugging Face or receive RustFS keys.

## Pipeline

```text
Hugging Face (pinned exact commit)
    ↓ Backend TtsModelArtifactSource / HuggingFaceTtsModelArtifactProvider
SHA-256 + exact byte length validation
    ↓ FileAssetIngestService (REGISTERED → READY / FAILED / QUARANTINED)
RustFS  tts/models/kokoro/<modelCode>/<manifestSha256>/<logicalPath>
    ↓
PostgreSQL app.tts_kokoro_bundle + app.tts_kokoro_bundle_artifact (STAGED, append-only)
    ↓
GET /internal/v2/tts/bundles/{modelCode}
GET /internal/v2/tts/bundles/{modelCode}/artifacts/{assetId}
    ↓
Kokoro Worker local verified cache (future K2)
```

Separate bundle staging tables intentionally avoid misusing existing Piper-only `tts_voice_model` two-file model/config identity. A bundle in `STAGED` **does not activate any voice or enqueue any job**. Existing Piper provisioning is unchanged.

## Initial pinned source candidate

- Source: `onnx-community/Kokoro-82M-v1.0-ONNX`
- Revision: `1939ad2a8e416c0acfeecc08a694d14ef25f2231`
- Model: `onnx/model_quantized.onnx` (ONNX int8) SHA-256: `fbae9257e1e05ffc727e951ef9b9c98418e6d79f1c9b6b13bd59f5c9028a1478`.
- Voice: `voices/af_heart.bin` SHA-256: `d583ccff3cdca2f7fae535cb998ac07e9fcb90f09737b9a41fa2734ec44a8f0b`.
- Model page: https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/tree/1939ad2a8e416c0acfeecc08a694d14ef25f2231
- Declared model license: Apache-2.0. **Source license metadata alone is not a final legal signoff**.

These are upstream *published metadata*, not checksums of files downloaded on this Mac. The Backend verifies the downloaded bytes on execution. Verify exact remote sizes before enabling; the website rounds them to 92.4 MB and 522 kB.

## DEV configuration (template — do NOT enable until exact sizes verified)

Create a **non-secret local** config file, e.g. `config/local/kokoro-provisioning.yml`, loaded by Spring via `spring.config.additional-location` or compatible external configuration. Do not enable in production until approval.

```yaml
voxprep:
  tts:
    kokoro-provisioning:
      enabled: false # set true only for controlled initial import
      bundles:
        - model-code: kokoro-en-us-int8-af-heart-v1
          source-repository: onnx-community/Kokoro-82M-v1.0-ONNX
          source-revision: 1939ad2a8e416c0acfeecc08a694d14ef25f2231
          license-name: Apache-2.0
          license-reference: https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX
          artifacts:
            - path: onnx/model_quantized.onnx
              role: MODEL
              url: https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/1939ad2a8e416c0acfeecc08a694d14ef25f2231/onnx/model_quantized.onnx
              sha256: fbae9257e1e05ffc727e951ef9b9c98418e6d79f1c9b6b13bd59f5c9028a1478
              size-bytes: 0 # REQUIRED: replace with exact trusted size
              media-type: application/octet-stream
            - path: voices/af_heart.bin
              role: VOICE
              url: https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/1939ad2a8e416c0acfeecc08a694d14ef25f2231/voices/af_heart.bin
              sha256: d583ccff3cdca2f7fae535cb998ac07e9fcb90f09737b9a41fa2734ec44a8f0b
              size-bytes: 0 # REQUIRED: replace with exact trusted size
              media-type: application/octet-stream
            - path: voices/am_michael.bin
              role: VOICE
              url: https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/1939ad2a8e416c0acfeecc08a694d14ef25f2231/voices/am_michael.bin
              sha256: 1d1f21dd8da39c30705cd4c75d039d265e9bc4a2a93ed09bc9e1b1225eb95ba1
              size-bytes: 0 # REQUIRED: replace with exact trusted size
              media-type: application/octet-stream
            - path: voices/bf_emma.bin
              role: VOICE
              url: https://huggingface.co/onnx-community/Kokoro-82M-v1.0-ONNX/resolve/1939ad2a8e416c0acfeecc08a694d14ef25f2231/voices/bf_emma.bin
              sha256: 669fe0647f9dd04fcab92f1439a40eeb4c8b4ab1f82e4996fe3d918ce4a63b73
              size-bytes: 0 # REQUIRED: replace with exact trusted size
              media-type: application/octet-stream
```

The zero sizes **intentionally fail validation**, preventing accidental installation with rounded/fabricated sizes.

To obtain exact size and hashes via official Hugging Face metadata (developer workstation):

```python
from huggingface_hub import HfApi

repo = "onnx-community/Kokoro-82M-v1.0-ONNX"
rev = "1939ad2a8e416c0acfeecc08a694d14ef25f2231"
info = HfApi().model_info(repo_id=repo, revision=rev, files_metadata=True)
wanted = {"onnx/model_quantized.onnx", "voices/af_heart.bin", "voices/am_michael.bin", "voices/bf_emma.bin"}
for file in info.siblings:
    if file.rfilename in wanted:
        print(file.rfilename, "size=", file.size, "lfs=", file.lfs)
```

Check output against the upstream model file cards, pin exact sizes, then set `enabled: true` in DEV. If the Hub metadata API cannot provide trustworthy exact values, **do not guess**. Verify artifact provenance with another trusted method before running.

## Runtime and idempotency

- Startup calls `KokoroBundleProvisioningBootstrap` only when explicitly enabled; disabled by default across environments. A missing configured bundle fails startup closed.
- Validate an exact 40-hex-character revision, repository identity and HTTPS URL path before downloading.
- Each artifact is validated against exact SHA-256 and declared byte count.
- Each FileAsset is persisted and read back via shared `FileAssetIngestService`, then bundle identity + all artifact references are committed together to the staging catalog.
- A model-code lock prevents concurrent provisioning of the same bundle. Re-running the same manifest returns the existing staged ID after checking artifact references. A changed revision/hash under the same code fails.
- Failed partial attempts can leave orphaned READY model assets for retry/reconciliation, but never a completed STAGED manifest.
- Staging tables are append-only; no overwrite. Provisioning does not mark `tts_voice_model` ACTIVE.
- Existing model delivery V1 endpoints stay unchanged.

## Worker V2 read-only access

With a distinct configured Kokoro Bearer token:

```http
GET /internal/v2/tts/bundles/kokoro-en-us-int8-af-heart-v1
Authorization: Bearer <KOKORO_WORKER_TOKEN>
```

The result includes model code, pinned revision, manifest SHA, artifact paths, file IDs, sizes and hashes. Fetch by the returned ID:

```http
GET /internal/v2/tts/bundles/kokoro-en-us-int8-af-heart-v1/artifacts/<assetId>
Authorization: Bearer <KOKORO_WORKER_TOKEN>
```

Backend checks that the file belongs to the staged bundle, asset is READY, SHA/size match Postgres and bytes from RustFS match again. Currently this endpoint uses bounded in-memory `byte[]` reads capped at 256 MiB; streaming must be implemented before permitting larger artifacts or high download concurrency.

## Remaining blockers before commercial / Worker activation

1. Verify pinned revision and exact bytes on a real DEV Backend, RustFS and PostgreSQL.
2. Add fully streaming/bounded upstream and RustFS downloads. Current upstream provider `byte[]` reads and shared ingest copies can increase RAM usage; unsuitable for unlimited model sizes.
3. Complete V2 claim, callback principal binding, lease-safe worker access and fingerprint V2 persistence; Kokoro claim currently remains disabled with 503.
4. Confirm ONNX export compatibility with planned Kokoro inference runtime, phonemizer and voice format; license review, then real synthesis acceptance.
5. Test restart, corrupt asset, concurrent bootstrap, replay, rollback and exact SHA CI.

**Never assert a model is downloaded merely because these code/config files were committed.**

## Educational voice pilot (source-pinned, not yet runtime-qualified)

| Voice code | Language | Product intent | SHA256 |
|---|---|---|---|
| `af_heart` | en-US | Main narrator / lessons | `d583ccff3cdca2f7fae535cb998ac07e9fcb90f09737b9a41fa2734ec44a8f0b` |
| `am_michael` | en-US | Second dialogue speaker | `1d1f21dd8da39c30705cd4c75d039d265e9bc4a2a93ed09bc9e1b1225eb95ba1` |
| `bf_emma` | en-GB | British pronunciation practice | `669fe0647f9dd04fcab92f1439a40eeb4c8b4ab1f82e4996fe3d918ce4a63b73` |

Source: pinned official Hugging Face `onnx-community/Kokoro-82M-v1.0-ONNX` file cards. The published file sizes are rounded; configure exact byte sizes only after trusted metadata retrieval.

**Runtime compatibility blocker:** these three `voices/<code>.bin` files are per-voice style arrays. The chosen Python `kokoro-onnx` library expects an aggregated `voices.bin` (NumPy NPZ archive containing named voice arrays) from its model release. No on-the-fly repackaging or cross-repository mixing is authorized until compatibility tests prove the resulting bundle. For K3, use one verified upstream model+aggregate voice release or implement and qualify a decoder for this ONNX-community export. Do not enable Kokoro based only on this documentation.
