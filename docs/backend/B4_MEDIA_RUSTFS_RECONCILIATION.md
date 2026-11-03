# B4 Media & RustFS Reconciliation

## Scope

B4 extends the existing `FileAsset` + RustFS foundation into a shared media capability. It does not introduce a second object-store subsystem.

## B4.1 findings

- `FileAssetEntity` already carries the generic storage identity: bucket, object key, media type, size, SHA-256 and lifecycle status.
- `FileAssetKind` is currently TTS-only (`TTS_MODEL`, `TTS_CONFIG`, `TTS_AUDIO`). Media kinds will be added in B4.5 rather than mixed into the storage-port extraction.
- `FileAssetStatus` already provides `REGISTERED`, `READY`, `FAILED`, and `QUARANTINED`.
- RustFS is already configured through the S3-compatible AWS SDK client.
- TTS model delivery and TTS output finalization previously coupled their application services directly to `S3Client`.

## B4.2 shared object storage boundary

`ObjectStoragePort` is the single application-facing storage boundary. `RustFsObjectStorageAdapter` owns the AWS SDK / S3-compatible RustFS implementation. Existing TTS object keys, metadata, database transaction semantics and replay behavior remain unchanged.

## B4.3 lifecycle decision

The existing statuses are retained; no duplicate `STAGING` state is introduced.

```text
REGISTERED
   |-- storage write/read succeeds and integrity matches --> READY
   |-- storage operation fails ---------------------------> FAILED
   `-- read-back checksum/size mismatch -----------------> QUARANTINED
```

Lifecycle transitions are explicit on `FileAssetEntity`. `READY` cannot be moved back to `FAILED` or `REGISTERED`; a previously READY object may still be moved to `QUARANTINED` if later integrity checks discover corruption.

`FileAssetIngestService` deliberately does not wrap the object-store call in one database transaction. `REGISTERED` must be committed before I/O starts and failure/quarantine state must remain durable if the storage call fails.

TTS finalization is not migrated to the generic ingest lifecycle in B4.3 because its lease fencing and replay-safe finalization form a stricter transactional protocol. TTS uses the shared `ObjectStoragePort` while retaining that protocol.

## B4.4 integrity invariants

The shared ingest boundary computes SHA-256 and size from the actual payload; callers cannot supply authoritative checksum or size values.

Before READY:

1. persist `REGISTERED` with computed SHA-256 and size;
2. write the object with `sha256` and `size-bytes` metadata;
3. read the object back through `ObjectStoragePort`;
4. verify exact byte size and SHA-256;
5. only then transition to `READY`.

A mismatch transitions the asset to `QUARANTINED`. Storage write/read errors transition it to `FAILED`.

## Next slices

1. B4.5: `COVER_IMAGE` and `CONTENT_IMAGE` kinds plus media policy.
2. B4.6: ADMIN upload and preview.
3. B4.7: learner media streaming.
4. B4.8: PostgreSQL + real RustFS acceptance of the generic media lifecycle.
5. B4.9: exact-SHA qualification and B4 closure.
