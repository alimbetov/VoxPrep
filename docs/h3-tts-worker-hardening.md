# H3 — TTS worker hardening

Branch: `feat/commercial-release`; only PR #39.

## Baseline

`TtsJobLeaseService` uses PostgreSQL `FOR UPDATE SKIP LOCKED`, a
per-claim random lease token, a lease expiry timestamp, and an incrementing
attempt counter. Heartbeat and failure updates require the current owner,
token, eligible status, and unexpired lease. Output finalization uses exact
job/file/model/fingerprint identity and replay-safe READY matching.

## H3.1 — stale callback fencing

`TtsJobWorkerLifecycleIntegrationTest.reclaimedLeaseFencesOldWorkerHeartbeatAndFailureCallbacks`
creates a job, claims it with worker A, expires the lease, and reclaims it
with worker B. It then proves:
- worker B receives the original job ID with a different token and incremented
  attempt count;
- worker A cannot heartbeat or mark the job FAILED after the takeover;
- worker B can heartbeat and fail it once;
- replaying that failure is rejected and the final persisted status is FAILED.

The initial slice adds an acceptance regression, not a production behavior
change. Qualification requires exact-commit backend CI green.

## Remaining H3 scope

- worker crash after claim and recovery after expiry;
- output callback replay following takeover, failure, and READY finalization;
- retry limits / poison-job policy (must define bounded attempt budget and
  operational reset procedure before implementing);
- lease heartbeat jitter, clock skew and timeout behavior;
- live Backend ↔ Piper Worker ↔ RustFS crash/fail/restart acceptance.

No new feature branch, PR, or Media & TTS UI work.
