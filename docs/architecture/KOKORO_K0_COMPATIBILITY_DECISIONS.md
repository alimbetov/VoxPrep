# K0 — Architecture & compatibility decisions (VoxPrep Kokoro Worker)

**State:** K0 contract audit recorded; K1 partial implementation landed, **model bundle NOT PINNED**, implementation **NOT ACCEPTED**.  
**Repository:** `alimbetov/VoxPrep`; companion spec `KOKORO_WORKER_V1_1_SPEC.md`.  
**Review basis:** existing code on `main` and independent Piper Worker in `worker/`.

## Verified existing system constraints

| Topic | Current production path | K1/K2 consequence |
|---|---|---|
| Model engine | `TtsEngine` enum only `PIPER`; DB CHECK `engine IN ('PIPER')` | Add `KOKORO` in a deliberate additive migration **only when** secure versioned claim/enqueue is ready |
| Model entity | Existing engine/version/provenance/license review columns | Reuse rather than duplicate; add immutable manifest/artifact references |
| Stored model | `model_asset_id`, `config_asset_id`, SHA-256 pair; 2 backend delivery endpoints | Implement multi-artifact bundle and V2 delivery without modifying legacy URLs |
| Worker claim | `ClaimRequest(workerId)`, one bearer token | V1 must be hard-fenced to PIPER; V2 identity-derived engine policy, no trust in client-supplied capabilities |
| SQL lease | `CLAIM_SQL` and `WORKER_CLAIM_SQL`; `FOR UPDATE SKIP LOCKED` | Both legacy candidate selections PIPER-only; V2 must filter before lease with bound authorized engine |
| Fingerprint | `tts-fingerprint-v1`; SHA model+config + content identity | Preserve byte-for-byte; new canonical V2 for Kokoro artifacts/phonemes/voice/parameters |
| Output | Backend multipart output + lease fencing; RustFS finalization | Keep as is; test replay, duplicate/stale output under mixed workers |
| Worker | Python 3.12 + Piper + FFmpeg; 24 kHz mono 64 kbps MP3 | New independent CPU/ONNX image; shared output profile, no runtime dependency collision |

## Compatibility and rollout contract

1. **Existing users / jobs:** V1 job fingerprint and model IDs are never recalculated, and V1 responses keep the exact Piper-specific fields. Old worker remains functional through mixed-version deployment.
2. **Legacy claims:** Backend must enforce `vm.engine='PIPER'` inside SQL, before row locking and lease allocation. Both `claimNext` and `claimNextForWorker` are in scope; there may be callers beyond the deployed Worker.
3. **New claims:** Prefer explicit `/internal/v2/tts/jobs/claim`; principal-derived allowed engine and server-side identity. New DTO contains manifest hash, frozen voice+generation configuration and exact version. V2 must not accept arbitrary engine selection from a request body.
4. **Worker identity:** distinct rotating credentials bound to engines, including heartbeat/fail/output/model download authorization. Worker ID and lease token are not substitutes for principal verification. Decide how to bind lease owner to identity in the transaction and test token theft / worker ID forgery.
5. **Database migration:** append immutable model-artifact tables or versioned JSON manifest with schema constraints, immutable hash, and engine-scoped model reference. Preserve old `model_asset_id`/`config_asset_id`, legacy records and trigger immutability; no destructive backfill. Add `KOKORO` enum/DB CHECK in the same controlled expand step.
6. **Enqueue gate:** `KOKORO_ENABLED=false` initially. No Kokoro jobs until V2 claim, token isolation, and all deployed Piper V1 consumers are proven fenced. If blocked, use 403/409 explicitly; no engine fallback.
7. **Operational rollback:** disable Kokoro enrollment; do not rewrite queued jobs; expire/recover leases with compatible worker. Keep Piper running.

## Artifact-pinning prerequisites — K0 outstanding

A model label such as `Kokoro-82M-v1.0` is not a fully reproducible bundle. Before implementing the runtime, record:

- immutable upstream repository revision/commit and authoritative model card; artifact list with path, digest and byte length;
- one verified ONNX export variant (e.g. INT8) and matching voice bundle format; do **not** assume `voices.bin` without inspecting that runtime;
- pinned `kokoro-onnx` or equivalent ONNX code; tokenizer and phonemizer versions, voice lookup semantics, text length/phoneme limits;
- independent model, code, dataset, voice and phonemizer license notices; GPL/FFmpeg/container distribution analysis and SBOM;
- native ARM64 and AMD64 inference probe and memory/RTF observations, acceptance quality corpus;
- trustworthy provenance attestation or independently reviewed source/commit; SHA-only is integrity, not authenticity.

**No model files, checksums, resource budgets, language-support matrix, or upstream permission checks have been independently executed by this change.** These are blockers for K2/K3 acceptance.

## K1 acceptance checklist (not yet all completed)

- [x] SQL candidates for both legacy claim methods require Piper before row lock; source-level regression guard added.
- [x] Added PostgreSQL fixtures for Piper and Kokoro and engine-scoped claim/concurrent same-engine checks; exact-SHA execution pending. Mixed-engine parallel / expired-lease V2 matrix remains outstanding.
- [x] Added `/internal/v2/tts/jobs/claim` with engine identity determined from token and atomic engine-scoped SQL; Kokoro returns 503 until delivery/callbacks are qualified.
- [ ] Initial separate Piper/Kokoro credential lookup added, including shared-secret fail-closed; rotation and principal-bound heartbeat/fail/output/model-artifact authorization still outstanding.
- [x] Additive engine constraint expansion; Kokoro staging bundle/artifact tables plus Backend-only prefetch and read-only V2 bundle delivery added. Real pinned DEV import and full model-to-voice linking are still NOT RUN.
- [ ] Canonical V2 manifest value object and fingerprint function with unit tests added; not yet persisted or used for enqueue; legacy V1 remains unchanged.
- [x] Kokoro enrollment is explicitly denied at job preparation; V2 Kokoro claim is disabled; configuration flag is default false.
- [ ] Exact-SHA full Piper integration and Worker regression green.
- [ ] Deployment rollback drill and evidence.

## Specific required tests

- `LegacyPiperClaimIsolationTest`: legacy candidate SQL structural guard, **not** real DB concurrency proof.
- KOK-15: mixed-version rollout with old `ClaimRequest(workerId)`.
- KOK-16: impersonation of engine/worker identity and token rotation.
- KOK-17: V1 snapshot unchanged and V2 deterministic fingerprints.
- KOK-18: real parallel PostgreSQL mixed-engine claims, SKIP LOCKED, expired lease, replay.
- KOK-19: wrong revision, path traversal, untrusted/symlinked/oversized artifacts, SHA mismatch.
- KOK-21: disable and rollback while Piper still processes jobs.

**Acceptance decision:** K0 **IN PROGRESS**, K1 **IN PROGRESS**. Kokoro generation and deployment remain disabled. This is a safe incremental boundary, not a declaration that the second Worker is ready.

## Incremental K1 source changes (not yet qualified)

- `WorkerApiKeyVerifier.authenticatedEngine`: separate credentials; V1 still Piper-only; V2 claims derive engine from token, not request body.
- `TtsJobWorkerV2Controller`: versioned claim endpoint only; Kokoro fails closed (`503`) until complete model manifest and callback auth.
- `TtsJobLeaseService.claimNextForEngine`: engine filter in atomic PostgreSQL candidate selection.
- `TtsArtifactManifest`: canonical immutable model artifact descriptor; **not yet persisted or served**.
- `TtsFingerprint.computeV2`: canonical hash for future Kokoro jobs; **not yet called by preparation**.
- Test classes: `WorkerV2EngineAuthenticationTest`, `TtsArtifactManifestTest`, `TtsFingerprintV2Test`; expanded `TtsJobLeaseIntegrationTest`.

**Open blocker:** do not enable Kokoro jobs. Staging provisioning and read-only V2 bundle delivery have been added, but real DEV import and complete Worker V2 claim/callback authorization, fingerprint persistence, and actual Kokoro inference are NOT ACCEPTED. The existing source/asset APIs buffer artifact bytes; production-size streaming and memory qualification remain open.

## K1 addendum: Backend pre-download for Kokoro

An explicit opt-in `KokoroBundleProvisioningBootstrap` prefetches a pinned ONNX+voice bundle from Hugging Face using existing `TtsModelArtifactSource`, validates exact hash/byte count, ingests READY assets into RustFS with `FileAssetIngestService`, and commits an append-only STAGED bundle manifest in PostgreSQL. The V2 read-only bundle API serves these files to a separately authenticated Kokoro identity; direct Worker→Hugging Face is unnecessary. The startup flag defaults OFF. See `KOKORO_BACKEND_PREPROVISIONING.md` for verified source revision, external config, and still-unverified exact byte sizes. Staging != voice activation.


## MVC-K01–MVC-K07: Content Studio engine visibility slice

The Content Studio TTS panel now exposes the engine identity for existing jobs and selectable voice models. It shows an engine selector with PIPER available and a **disabled** KOKORO option accompanied by an explicit readiness explanation. The approved voice list is currently filtered to ACTIVE and PIPER, matching the `TtsJobPreparationService` fail-closed guard; no unsupported Kokoro job is offered merely because a database row says ACTIVE.

The form still submits the existing `voiceModelCode` contract. The engine selector is informative while only Piper can be selected, and it must never be trusted as an authorization input. Once Kokoro V2 lifecycle and real inference are qualified, make the engine selector functional: filter voice options by engine, require server-side validation, and add browser E2E coverage for both engines.

- [x] MVC-K01: `ModelView` carries engine; `JobView` displays engine.
- [x] MVC-K02: Engine selector present with explicit unavailable Kokoro option.
- [x] MVC-K03 (safe preliminary): Backend offers only ACTIVE Piper models until Kokoro acceptance; test that ACTIVE Kokoro is hidden.
- [ ] MVC-K04: Link approved Kokoro bundle to shared `tts_voice_model`.
- [ ] MVC-K05: Enable Kokoro preparation only after V2 lifecycle qualification.
- [ ] MVC-K06: Engine and model visible in TTS history; worker availability/health status still outstanding.
- [ ] MVC-K07: Real browser acceptance on Piper and Kokoro.

## K1 continuation — immutable Kokoro model binding and job snapshot (partial)

Added Liquibase migrations `k1-kokoro-model-binding.sql` and
`k1-kokoro-job-snapshot.sql` as **additive Kokoro-only schema**.
Existing Piper rows, fingerprints, models and `worker/` are unchanged.

- `app.tts_kokoro_model_binding`: immutable, engine-checked mapping from
  shared `tts_voice_model` into a pinned `tts_kokoro_bundle`, with
  approved `af_heart`, `am_michael`, or `bf_emma`, exact voice artifact,
  frozen phonemizer version, speed. `KokoroModelBindingService` requires a
  legally reviewed and approved voice model and the four READY assets
  (quantized ONNX + three named voice style vectors).
- `app.tts_kokoro_job_snapshot`: append-only job-level bundle/manifest,
  voice code/hash, runtime and phonemizer versions, speed and V2 fingerprint.
  PostgreSQL rejects inserts that conflict with the job's voice model,
  fingerprint, bundle, selected voice, or runtime version.
- `KokoroJobSnapshotService` provides a typed append-only snapshot write/read
  primitive for the future transactional Kokoro preparation path.
- Unit tests cover mismatched voices, unapproved/incomplete binding, and
  cross-model or malformed snapshot denial.

**Not yet wired:** `TtsJobPreparationService` still intentionally rejects
KOKORO; no ACTIVE voice model records are automatically created. Claim V2
continues to return 503 for KOKORO. Before enabling, compute and persist V2
fingerprint **in the same transaction as the job snapshot**, return
`manifestSha256`, `voiceCode`, `speed`, and the exact pinned bundle code
from claim, then qualify principal-bound finalization/replay under PostgreSQL.

**No actual model import or Kokoro ONNX real inference is claimed.**
