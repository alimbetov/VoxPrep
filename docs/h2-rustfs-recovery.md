# H2.1 — RustFS object recovery (fail closed)

Branch: `feat/commercial-release`, existing PR #39.

## Failure model

An ingest stores `REGISTERED` in PostgreSQL, uploads bytes into RustFS, reads them
back and finally marks the asset `READY`. A process crash between the object
write and the READY transition leaves a durable REGISTERED row and potentially a
complete object. A database transaction cannot atomically commit with object storage.

## Implementation

`FileAssetRecoveryService.reconcile(UUID, Duration)` is an **explicit** recovery
operation for an identified file asset, not an automatic background sweep.

1. Read the persisted file asset. Ignore absent, READY, FAILED and QUARANTINED rows.
2. Enforce `minimumAge` on `created_at` to avoid touching active uploads.
3. Read the object from RustFS *outside* a row lock.
4. Verify the exact byte length and SHA-256 against persisted metadata.
5. Within a short transaction, re-read the asset with a pessimistic write lock.
6. If still REGISTERED and unchanged, mark READY for a matching object or
   QUARANTINED for a verified mismatch.
7. If storage is unavailable, preserve REGISTERED (retryable). Never delete
   object bytes or mutate an already settled asset.

The service is safe to retry. Multiple callers cannot overwrite an already
settled asset because of the final database row lock and state check.

## Qualification

`FileAssetRecoveryIntegrationTest` exercises real PostgreSQL state transitions
with a controlled storage port:
- Verified interrupted ingest -> READY, idempotent subsequent reconcile.
- Corrupt object -> QUARANTINED, never READY.
- RustFS read failure -> REGISTERED preserved.
- Too-young asset -> skipped.

## Remaining H2 work

- Opt-in, bounded scanning of stale REGISTERED rows (no blind scanning of all assets).
- Observability: backlog age, status counters, failure rates and alerting.
- Safe, separately authorized orphan object inventory, without automatic deletion.
- Enforce immutability of object keys or re-verify object integrity on reads to
  eliminate a possible external overwrite between recovery verification and use.
- End-to-end RustFS restart, network partitions and process-kill fault injection.

Do not claim H2 is closed until exact-SHA CI is green and the remaining items
are deliberately qualified.


## H2.2 bounded on-demand reconciliation

`FileAssetRecoveryBatchService.reconcileStale(minimumAge, batchSize)` finds old
REGISTERED asset IDs using a deterministic `created_at, id` ordering.
`minimumAge` must be positive and `batchSize` must be within 1..100.
It delegates each ID to the H2.1 verification/row-lock service and returns an
outcome summary for each explicit invocation.

This is *not* a scheduled task: operations must explicitly invoke this service
through a trusted backend entry point or a future controlled worker. It does not
list or delete RustFS objects. Its scope is known database records, not orphan
objects with no database row.

The bounded selection prevents unbounded per-invocation processing, but does
not cap total bytes read from RustFS. Add a streaming verification interface and
byte budgets before turning on unattended production sweeps.

Acceptance:
- stable query, oldest first, with `Pageable` cap
- input bounds are rejected before database access
- result counters include successful recovery and storage-unavailable outcomes
- tests remain isolated from other suites' committed PostgreSQL fixtures

Remaining: end-to-end fault injection, automatic triggering policy, metrics/alerts,
streaming read size limit, orphan inventory and guarded cleanup.


## H2.3 streaming integrity and advisory orphan inventory

- `ObjectStoragePort.openRead` supports streaming verification, and the RustFS
  adapter uses `S3Client.getObject` without allocating an object-sized byte array.
- `FileAssetRecoveryService` reads in 8 KiB chunks and applies a hard 64 MiB
  per-object verification cap. Metadata larger than the cap or a stream exceeding
  the cap returns `TOO_LARGE` while keeping the database row `REGISTERED`.
  A truncated or failed network stream returns `STORAGE_UNAVAILABLE` and
  preserves the retryable state. No object is deleted.
- `RustFsOrphanInventoryService.scan(prefix, continuationToken, pageSize)`
  lists at most 100 keys for an explicit prefix, checks whether a matching
  `file_asset` record exists, and returns *suspected* orphan entries. A suspected
  orphan is never proof of safe deletion because concurrent uploads, replication,
  and external producer paths may make the inventory temporarily inconsistent.
- The orphan-inventory service is internal only: no public endpoint or
  background sweep has been enabled.
- Fault-injection integration acceptance simulates stream failure then successful
  retry, size-limit rejection and idempotent completion using real PostgreSQL
  transactions and a controlled storage boundary. This **does not** qualify an
  actual RustFS container stop/restart or a network-partition deployment.
- Production follow-up: use a fault-injection job with a real RustFS container
  (kill RustFS after REGISTERED/upload, restart it, then reconcile), establish
  metrics/backlog thresholds, and require retention windows, repeated scans and
  human approval before any destructive orphan cleanup. Large TTS model objects
  require a separately budgeted streaming path.


## H2.4 real restart qualification

`.github/workflows/h2-rustfs-restart-acceptance.yml` provisions isolated
PostgreSQL/RustFS, creates a REGISTERED file asset while uploading bytes into
the real S3-compatible store, then **SIGKILLs RustFS** before an independent
Spring Boot process calls `FileAssetRecoveryService.reconcile`. It must
return STORAGE_UNAVAILABLE without mutating the database state. RustFS is
restarted with the same persistent Compose volumes, then a third independent
test invocation verifies RECOVERED_READY followed by ALREADY_SETTLED.
The staged test is disabled for ordinary Maven test suites unless explicitly
enabled through `-Dh2.restart.acceptance=true`.

This acceptance proves the storage-outage/crash-restart boundary only when
the exact-head GitHub workflow is green; it does not prove arbitrary
network partition, multi-node failover or disk data loss.

## H2.5 orphan handling safety contract

`RustFsOrphanInventoryService` is an internal, read-only paginated scanner.
The result `suspectedOrphan=true` means only that a key did not match
`file_asset(bucket, object_key)` at the moment of lookup. It is not authorization
for garbage collection. Production deletion must be separately approved,
age-graced, repeat-inventoried, key/version-checked and subject to an audit trail.
There is no destructive orphan cleanup or background scheduler in this slice.

H2 streaming verification is hard-capped at 64 MiB of object data and uses
8 KiB chunks. Objects above budget remain REGISTERED (TOO_LARGE) rather
than being auto-quarantined. Additional production qualification should prove
the same safety invariants for large model assets using independently budgeted
streaming.
