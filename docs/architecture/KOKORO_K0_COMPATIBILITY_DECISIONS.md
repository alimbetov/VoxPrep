# K0 — Architecture & compatibility decisions (VoxPrep Kokoro Worker)

**State:** K0 contract audit recorded; **model bundle NOT PINNED**, implementation **NOT ACCEPTED**.  
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
- [ ] Real PostgreSQL test creates Piper and Kokoro models and proves cross-engine isolation under parallel claims, including expired leases.
- [ ] Versioned V2 claim and response DTO with actual authenticated engine ownership.
- [ ] Rotatable separate secrets and cross-worker authz of claim, heartbeat, fail, output and artifacts.
- [ ] Schema expand migration with manifest assets and engine constraints.
- [ ] Immutable V2 fingerprint contract with canonical test vectors and legacy V1 fixtures.
- [ ] Feature flag disables Kokoro enqueue by default.
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
