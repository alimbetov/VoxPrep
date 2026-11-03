# B4 Media & RustFS Reconciliation

## Scope

B4 extends the existing `FileAsset` + RustFS foundation into a shared media capability. It does not introduce a second object-store subsystem.

## B4.1 findings

- `FileAssetEntity` already carries the generic storage identity: bucket, object key, media type, size, SHA-256 and lifecycle status.
- `FileAssetKind` is currently TTS-only (`TTS_MODEL`, `TTS_CONFIG`, `TTS_AUDIO`). Media kinds will be added in B4.5 rather than mixed into the storage-port extraction.
- `FileAssetStatus` already provides `REGISTERED`, `READY`, `FAILED`, and `QUARANTINED`. B4.3 will reconcile these states into the staging-to-ready media lifecycle without breaking existing TTS rows.
- RustFS is already configured through the S3-compatible AWS SDK client.
- The remaining coupling is in TTS application services: model delivery reads directly from `S3Client`, and output finalization writes directly to `S3Client`.

## B4.2 decision

Introduce one application-facing `ObjectStoragePort` under the asset boundary and one RustFS/S3 adapter in infrastructure. Existing TTS services depend on the port while retaining their current object keys, metadata, database transaction semantics, replay behavior, and `FileAsset` records.

No schema change is part of B4.2.

## Next slices

1. B4.3: staging/registered to READY lifecycle.
2. B4.4: checksum and size invariants at the shared media boundary.
3. B4.5: `COVER_IMAGE` and `CONTENT_IMAGE` kinds.
4. B4.6-B4.7: ADMIN upload/preview and learner delivery.
5. B4.8-B4.9: PostgreSQL + real RustFS acceptance and exact-SHA qualification.
