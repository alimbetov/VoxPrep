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
