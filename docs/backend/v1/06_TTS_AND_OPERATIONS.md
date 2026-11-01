# 06 — TTS and Operational Requirements

**Status:** FROZEN DESIGN INPUT FOR V1 BACKEND

## 1. TTS architecture

TTS is a backend-owned production workflow executed by an external Worker.

```text
Admin/content authoring
→ Backend creates TtsJob
→ Worker claims through Backend API
→ Backend serves model/config inputs
→ Worker runs Piper + FFmpeg
→ Worker uploads result to Backend
→ Backend persists FileAsset in RustFS
→ Backend finalizes TtsJob
→ Admin/review selects audio for content publication
```

Worker never publishes learner content directly.

## 2. Durable queue

Keep PostgreSQL as the durable queue for MVP.

Atomic claim pattern:

```sql
SELECT ...
FROM tts_job
WHERE status = 'PENDING'
ORDER BY created_at
FOR UPDATE SKIP LOCKED
LIMIT 1;
```

A broker is not required merely to distribute TTS work.

## 3. TtsJob conceptual state

Minimum conceptual data:

```text
jobId
status
voice/model identity
input identity/fingerprint
attemptCount
leaseToken
leaseUntil
workerId audit label
createdAt
updatedAt
outputAssetId
lastFailureCode
```

Suggested lifecycle:

```text
PENDING
→ PROCESSING/LEASED
→ READY
or
→ retryable PENDING
or
→ FAILED
```

Exact names may differ internally as long as contract semantics remain stable.

## 4. Claim ownership

Claim must atomically establish:

```text
job ownership
leaseToken
leaseUntil
attempt increment where required
```

`jobId` alone is insufficient authorization to heartbeat/complete/fail.

Heartbeat and terminal operations require current valid lease ownership.

## 5. Lease recovery

Worker crash must not permanently lose a job.

```text
Worker dies
→ lease expires
→ Backend marks/reclaims stale processing state
→ another Worker may claim
```

Stale completion after lease loss must be rejected.

## 6. Idempotency and duplicate output

Backend design must prevent concurrent/replayed jobs from corrupting the current audio slot.

Recommended uniqueness/fingerprint model should make these operations replay-safe:

```text
same synthesis inputs
same voice/model version
same canonical text/config
```

Repeated complete/fail calls for an already terminal lease must have deterministic outcomes.

## 7. Model delivery

Worker downloads Piper model/config through Backend APIs.

Worker must not receive direct RustFS credentials.

Model identity needs exact version/fingerprint/checksum semantics so a Worker cannot synthesize using an ambiguous model revision.

Raw config/model bytes must preserve exact checksum identity; do not coerce binary/config artifacts through an unsafe string representation.

## 8. Output finalization

Output acceptance sequence:

```text
lease valid
→ uploaded bytes accepted
→ validate expected fingerprint/metadata
→ persist object in RustFS
→ create/finalize FileAsset
→ atomically associate output with TtsJob
→ mark READY
```

A failed finalization must not leave a READY job pointing to missing bytes.

## 9. Publication separation

`TtsJob READY` does not mean learner-published.

Required separation:

```text
TTS production state
≠ content publication state
```

Only a published ContentRevision/PublicationSnapshot can make the resulting FileAsset learner-visible.

## 10. Worker authentication

Worker uses `/internal/v1/tts/**` and separate Worker authentication.

MVP may use the already accepted shared static Worker token model, with the explicit limitation that `workerId` is primarily an audit label rather than strongly authenticated independent identity.

This does not weaken Flutter installation auth because security zones are separate.

## 11. Operational observability

Backend must expose internal metrics/audit sufficient to diagnose:

```text
pending job count
oldest pending age
active leases
expired/reclaimed leases
attempt distribution
READY/FAILED rate
synthesis duration
upload/finalization duration
model download failures
RustFS failures
publication failures
installation auth failures/rate limits
media delivery failures
```

Trace IDs should cross Backend API boundaries where practical.

Do not place tokens/secrets in metrics labels or logs.

## 12. Backup and restore

Production acceptance requires a coordinated durability plan for PostgreSQL and RustFS.

At minimum define:

```text
PostgreSQL backup/restore
RustFS backup/versioning policy
FileAsset ↔ object reconciliation
missing-object detection
orphan-object cleanup policy
recovery ordering
```

Database restore must not silently claim a FileAsset is READY when corresponding RustFS bytes are missing.

## 13. Reconciliation job

Recommended operational reconciliation can verify:

```text
READY FileAsset has object
object size matches metadata
optional checksum sampling/full verification
published asset refs resolve
TTS READY output resolves
orphaned unreferenced objects are classified before deletion
```

This is operational hardening, not learner runtime logic.

## 14. Admin boundary

Admin is separate from learner installation auth.

Backend design must keep:

```text
/admin/** → Admin security/session
/api/v1/** → installation token
/internal/v1/tts/** → Worker token
```

Even if MVP uses one fixed Admin account, credentials must not be embedded into Flutter or Worker artifacts.

## 15. Backend TTS implementation order

Recommended stream:

```text
T1 voice + model catalog
T2 FileAsset + TtsJob persistence
T3 atomic claim + lease
T4 exact model delivery
T5 heartbeat/fail/reclaim
T6 RustFS output upload/finalization
T7 idempotent/replay-safe completion
T8 real Piper acceptance
T9 operational reconciliation/metrics
```
