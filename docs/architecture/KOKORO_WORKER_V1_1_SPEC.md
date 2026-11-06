# VoxPrep — Kokoro Worker V1.1: technical specification

**Status:** implementation-ready specification, **not implemented / not accepted**  
**Scope:** independent `worker-kokoro/` and minimal backwards-compatible Backend TTS extensions.  
**Baseline:** `main` at `297b57242c5e59bbb6c0b6bdd0708d84723996e1`; synchronize with actual head at implementation time.  
**Priority:** optional enhancement; no dependency of commercial release upon Kokoro.  
**Acceptance:** exact-SHA CI + genuine PostgreSQL → Backend → Worker → RustFS → MVC MP3-preview evidence. No mock synthesizer, mock stores or pre-generated audio for real acceptance.

## 1. Architectural decision and non-goals

Implement a second, independent Docker/OCI service `worker-kokoro`. Keep `worker/` (Piper) as an independently deployed, qualified engine. **One** Backend owns `tts_job`, catalog, lease/finalization, model assets and RustFS. Both workers consume the same backend protocol, with backend-enforced engine authorization. The published learner API, Flutter/Drift, content publication/CURRENT, and Content Studio forms remain unchanged, except narrowly justified voice-selector compatibility.

Do **not** duplicate job tables, worker-facing persistence, media object storage, Content Studio approval workflow, or implicit engine fallback. No direct Worker → PostgreSQL/RustFS or production Worker → Hugging Face network access.

The existing `TtsVoiceModelEntity` **already includes** `TtsEngine engine`, `engineVersion`, `modelVersion`, pinned source provenance, and commercial-use review metadata. `TtsEngine` currently contains **only PIPER**. Do not add duplicate columns for existing metadata. Introduce `KOKORO` in the enum and add the minimum schema required for multi-artifact revisions.

Existing `TtsJobWorkerController.ClaimRequest` contains `workerId` only; `TtsJobLeaseService.WORKER_CLAIM_SQL` has **no engine filtering**; `WorkerApiKeyVerifier` checks **one shared Bearer token**. `WorkerTtsJobClaim` carries Piper-specific `modelSha256`/`configSha256`, no engine or general manifest. These are real compatibility/security blockers, not hypothetical functionality.

## 2. Contract versioning / compatibility — P0

1. Add a versioned claim contract with explicit `engine`, immutable `manifestSha256`, named artifacts (with SHA-256, byte length, media type), `voiceCode`, pinned revision and synthesis parameters. Names must be validated, deterministic, and canonicalized.
2. Preserve **legacy Piper V1** claim payload and endpoints while upgrading. For a legacy caller, missing engine/capabilities means **PIPER only**, never "any engine". Its existing lease/finalization/fingerprint semantics remain unchanged.
3. Evolve `POST /internal/v1/tts/jobs/claim` in a backwards-compatible way: either versioned endpoint `/internal/v2/tts/jobs/claim` (preferred if DTO behavior cannot be safely negotiated) or an explicit protocol version header. A separate versioned DTO prevents incompatible response fields being silently ignored.
4. Backend enforces allowed engines from the **authenticated worker principal**, not untrusted JSON `supportedEngines` or `workerId`. Accept capabilities only as the intersection with backend policy. Unsupported capability or token/engine mismatch must fail closed (403), not return mismatched work.
5. Register separate credentials/identities for Piper and Kokoro, allow staged secret rotation and revocation; never log credentials or lease token. A `workerId` identifies an instance for lease ownership and is not an authorization boundary.
6. Claim returns only jobs for an authorized engine; empty compatible queue returns 204. Preserve actual HTTP 401/403/409 contracts and document retry policy. Changes to output/heartbeat/fail are permitted only when needed for protocol compatibility, with tests against V1.
7. Rollout via expand → deploy → migrate → enable → contract; **no Kokoro jobs may be created until all running Piper versions are incapable of claiming them**. Explicit feature flag default OFF for Kokoro enqueue/activation.

## 3. Atomic engine-aware SQL claim — P0

Modify `TtsJobLeaseService` so engine filtering happens **inside the candidate selection transaction before acquiring any lease**, never after claim. Preserve PostgreSQL `FOR UPDATE OF j SKIP LOCKED`, consistent ordering, `UPDATE ... RETURNING`, bounded lease, incremented attempts/version, expired-lease reclamation, and `file_id IS NOT NULL` semantics. Join `app.tts_voice_model vm` on `j.voice_model_id` and filter `vm.engine = :authorizedEngine`; lock only the job rows. Check the existing independent `CLAIM_SQL` for any other consumer before changes: if used, restrict it appropriately or document why it is isolated.

Concurrency tests against real PostgreSQL: 2 Piper + 2 Kokoro workers, mixed PENDING rows, two instances same engine, expired leases, 204 idle, queue fairness, duplicate claim absence, and concurrent output finalize. A worker MUST NOT fetch an incompatible job even temporarily.

## 4. Immutable model bundle + fingerprint — P0

The present `tts_voice_model` holds `model_asset_id`, `config_asset_id`, `model_sha256`, `config_sha256`; Piper caches `model.onnx` + `model.onnx.json`. Kokoro bundles may contain ONNX, aggregated or per-voice embeddings, tokenizer/phonemizer resources; exact file layout depends on chosen runtime. Implement a **versioned, canonical, immutable artifact manifest** rather than assuming `voices.bin` or one voice file. Every file has relative logical path, sha256, size, media type, source revision, and role. Disallow absolute paths, traversal, symlink escape, duplicate normalized names, huge entries, unbounded count, arbitrary remote URLs and executable manifests.

Model identity includes engine, model version, exact ONNX export, voice embeddings, tokenizer/phonemizer dependency and version, voice code, language, speed and relevant inference options. **All concrete dependencies must be pinned and tested as a compatible bundle**; no dynamic `main` revisions.

Introduce `tts-fingerprint-v2` for Kokoro with canonical UTF-8 deterministic serialization and stable representation of decimals/arrays; include: content revision & checksum, normalized utterance, role, language, text normalizer revision, engine + runtime version, full manifest hash, voice embedding hash/voice code, phonemizer/tokenizer version/config, synthesis settings and output profile. Old Piper jobs and artifacts retain `tts-fingerprint-v1` without recalculation or backfill. No silent reuse of V1 or V2 output across different bundle/settings. DB migration must preserve old IDs, references, and historical jobs.

Define a manifest delivery API that fetches **exact pinned revision and specific artifact**, and rejects wrong revision, unknown file, checksum mismatch and unauthorized download. Download shall be streaming/bounded, not unlimited in-memory buffering; consider existing `TtsModelDeliveryController` which currently serves byte[] at `/{voiceModelId}/model` and `/config`. Preserve those legacy routes.

## 5. Worker implementation — P1

New directory:
```
worker-kokoro/
  Dockerfile
  .dockerignore
  pyproject.toml
  constraints.txt
  README.md
  src/voxprep_kokoro_worker/{domain,application,adapters,ports}/
  tests/
```

Single-engine process: Kokoro only. Python 3.12, pinned ONNX Runtime CPU + `kokoro-onnx` or equivalent version **verified against the exact bundle**, phonemizer, httpx, FFmpeg/ffprobe. Keep an independent OCI image, non-root runtime, graceful SIGTERM, readonly root FS where feasible, controlled writable temp/cache, no build-time credentials. Qualify `linux/arm64` on actual ARM64 and `linux/amd64` on an actual matching runner; emulated build alone does not prove usable performance.

Adapter inputs: a claimed normalized text and frozen voice parameters. Output: nonempty WAV in job-scoped temporary directory. Reuse output postprocessor behavior: MP3 `audio/mpeg`, mono 24 kHz, nominal 64 kbps (QC range 60–68 kbps), duration, sha256, file size. Keep Backend output API for final RustFS state. No direct RustFS writes.

Manage a private, bounded disk cache keyed by `manifestSha256`: download only via Backend, validate **every** file, atomically install only complete revision, robustly handle cache corruption, protect in-use files from LRU eviction, protect against concurrent cache writers; separate cache volumes per replica. Bound ONNX session memory, number of loaded sessions, thread count, temp dir, input bytes, generated duration and subprocess time. Begin with **one concurrent synthesis/job per replica**. Establish numeric RAM/CPU/time budgets from on-device measurement rather than inventing default performance claims.

Chunk long input on phoneme/tokenizer boundaries to satisfy the **measured** model limits; retain punctuation pauses and order, reject unsupported languages/voices and malformed text; prevent arbitrary file access or code execution from model metadata. Ensure deterministic formatting/normalization, although byte-identical PCM across platforms is not guaranteed without proof.

Failure/recovery: heartbeat throughout model download and inference; on lease loss, do not upload; on uncertain output response, do not blindly reupload/reassign; rely on Backend authoritative idempotency and lease rules. Worker crash/OOM must not create duplicate finalized assets. Define bounded retry/backoff and terminal vs retryable error taxonomy; avoid endless poison-job attempts. Log job ID, model manifest ID and duration metrics, but no credentials or potentially sensitive raw text.

## 6. Production safety, licensing and supply chain — P1

- Model, voice, ONNX export and phonemizer are independently sourced; save origin, immutable revision/commit, hash, license reference, notices, commercial-use review decision and review date. A hash confirms integrity **not provenance**.
- Require trusted-origin provisioning, immutable artifact storage and approval before model becomes ACTIVE. Deny unverified or noncommercial license and document license of code, weights, voice pack, phonemizer, espeak-ng if used, FFmpeg build, ONNX dependencies and container packages.
- Apache-2.0/MIT do permit commercial use subject to notices; GPL dependencies may impose obligations upon **distribution**, and must be reviewed in context of Worker deployment. No blanket claim that all Kokoro-related files have one license.
- Generate SBOM, dependency vulnerability scan, image digest and attestations where CI supports them. Production must not fetch live unreviewed external weights.
- Respect worker token isolation; rotate and revoke credentials without downtime; maintain network egress constraints and metrics.
- Define feature flag `KOKORO_ENABLED`, alert on pending age, lease churn, failed syntheses, OOM, cache exhaustion, duration/RTF, unavailable model and 401/403 rates.
- Rollback: disable new Kokoro enqueue; let valid in-flight leases complete or expire; queue remains KOKORO-owned, **no implicit Piper fallback**. Resume with compatible Kokoro Worker or explicit authorized regeneration as a new job/fingerprint. No deletion of historical jobs/assets.

## 7. Deployment order / changesets

**K0 — architecture & pinning:** identify actual model/voice files, ONNX runtime, tokenizer and phonemizer versions; document compatibility, licenses, ABI/platform support and resource benchmark test harness; write API V2 schemas, V1 compatibility matrix, DB migration/rollback plan. No data writes.

**K1 — backward-compatible Backend:** additive Liquibase migrations for manifest metadata and optionally worker identities; extend `TtsEngine`; principal-enforced engine routing in atomic claim; versioned protocol; fingerprint V2; security/lease/idempotency tests. Keep `KOKORO_ENABLED=false`; qualify all Piper regression on exact SHA.

**K2 — independent Worker:** Dockerfile, provisioning/download and verified cache, heartbeat, logging, error categories, 401/403 handling, container ARM64+AMD64 smoke.

**K3 — real Kokoro synthesis:** pinned ONNX + voice/phonemizer, WAV chunks, FFmpeg, ffprobe, audio quality fixtures; benchmark cold/warm inference.

**K4 — actual backend integration:** authorized DEV model provisioning, real Content Studio TTS job, mixed Piper/Kokoro claim, RustFS READY asset, backend MP3 preview/browser playback. No replacement of Content Studio forms or learner API.

**K5 — hardening:** malicious manifest/URL/path, corrupted weights, checksum and artifact limits, lease loss, concurrent claim, network outage, SIGTERM/restart/OOM, duplicate finalize, disabled engine and rollback.

**K6 — exact-SHA qualification:** run all gates below, collect hashes/SQL snapshots/job states/ffprobe and screen/playback evidence, full Piper checks, report risks and license evidence. No merge before gates are green; qualification only for the final tested SHA.

## 8. Required acceptance matrix (all PASS before CLOSED)

| ID | Gate | Proof |
|---|---|---|
| KOK-01 | Native ARM64 image | Build, import, real inference on linux/arm64 |
| KOK-02 | AMD64 image | Build and real inference on linux/amd64 |
| KOK-03 | Model manifest/provision | Authenticated backend download; checksums all files |
| KOK-04 | Engine routing | Piper cannot claim Kokoro; Kokoro cannot claim Piper |
| KOK-05 | Real inference | Nonempty genuine Kokoro-generated WAV |
| KOK-06 | MP3 profile | ffprobe 24 kHz mono 60–68 kbps, positive duration |
| KOK-07 | Finalization | Actual PENDING → CLAIMED/PROCESSING → READY |
| KOK-08 | RustFS | Durable S3 asset, preview and SHA-256 verification |
| KOK-09 | MVC playback | Authenticated editor real MP3 playback / evidence |
| KOK-10 | Cache | Cache hit, miss, corruption re-download, LRU bounds |
| KOK-11 | Lease/replay | Stale lease denied, duplicate finalize safe |
| KOK-12 | Piper regression | Existing Piper full test + E2E acceptance green |
| KOK-13 | Operational safety | Identity, no token leaks, memory/CPU, restart |
| KOK-14 | Legal/supply chain | Artifact provenance, license review, SBOM |
| KOK-15 | Rolling deployment | Mixed-version Piper cannot claim Kokoro jobs |
| KOK-16 | Authz | Wrong token/forged engine/workerId rejected |
| KOK-17 | Fingerprint | V1 stable, V2 deterministic and distinct |
| KOK-18 | SQL concurrency | Parallel mixed claims, no duplicates |
| KOK-19 | Artifact hardening | Bad SHA, unknown file, traversal, wrong revision denied |
| KOK-20 | Linguistic QA | 100-domain-utterance annotated listening suite; numbers, acronyms, questions, punctuation, long text; record quality and RTF |
| KOK-21 | Disable/rollback | New Kokoro jobs stop, old ones recover; Piper unaffected |

For each gate record **PASS / FAIL / BLOCKED / NOT RUN**, exact git SHA, image digest, date, command and exit code, and redacted evidence paths. Integration gates require genuine PostgreSQL + Backend + Kokoro ONNX + RustFS, not stubs. Automated ASR transcription may supplement but must not replace linguistic listening review. Release-quality thresholds and target device resource budgets must be defined **before** comparing implementations.

## 9. Definition of Done

All KOK-01–21 PASS on one final commit SHA; actual model/voice/phonemizer compatible and pinned; isolation and reversible rollout proven; Piper V1 regression green; model provenance/commercial use documented; real job READY and audible MP3 in Content Studio; metrics/operations/rollback documented; required CI checks green. Production rollout and commercial approval are separate decisions.

**No actual implementation, build, test execution or legal clearance is claimed by this specification.**
