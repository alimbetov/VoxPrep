import 'package:drift/drift.dart';

import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_sync/sync_models.dart';
import '../../application/ports/content_manifest_gateway.dart';
import '../../application/ports/sync_plan_executor.dart';
import '../../application/result/result.dart';
import '../../domain/content_item.dart';
import 'database/careerspeak_database.dart'
    hide ContentAssetRef, PackContentRef;

final class DriftSyncPlanExecutor implements SyncPlanExecutor {
  DriftSyncPlanExecutor(
    this._database,
    this._manifestGateway, {
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final ContentManifestGateway _manifestGateway;
  final DateTime Function() _now;

  @override
  Future<Result<void>> execute({
    required String runId,
    required SyncPlan plan,
  }) async {
    try {
      for (final target in plan.changedPacks) {
        await _setPackState(
          runId,
          target,
          SyncPackUpdateState.fetchingManifest,
        );
        final fetched = await _manifestGateway.fetchPackManifest(target);
        if (fetched case FailureResult<PackContentManifest>(:final failure)) {
          return FailureResult(failure);
        }

        await _setPackState(runId, target, SyncPackUpdateState.stagingMetadata);
        await _stagePack(
          plan: plan,
          target: target,
          manifest: (fetched as Success<PackContentManifest>).value,
        );
        await _setPackState(runId, target, SyncPackUpdateState.readyToCommit);
      }

      await _setRunState(runId, SyncRunState.verifying);
      await _setRunState(runId, SyncRunState.committing);
      await _commit(runId: runId, plan: plan);
      return const Success(null);
    } on _SyncExecutorInvariant catch (error) {
      return FailureResult(error.failure);
    } catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'SYNC_METADATA_EXECUTION_FAILED',
          message: 'Local metadata synchronization failed.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  Future<void> _stagePack({
    required SyncPlan plan,
    required PackRevisionRef target,
    required PackContentManifest manifest,
  }) async {
    if (manifest.identity != target.identity ||
        manifest.revision != target.revision ||
        manifest.checksum != target.checksum) {
      throw _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'PACK_MANIFEST_MISMATCH',
          message: 'The fetched pack manifest does not match the sync target.',
          details: <String, Object?>{
            'packCode': target.identity.code,
            'variant': target.identity.variant,
            'revision': target.revision,
          },
        ),
      );
    }

    await _database.transaction(() async {
      final existingPack =
          await (_database.select(_database.contentPackRevisions)..where(
                (row) =>
                    row.packCode.equals(target.identity.code) &
                    row.variantKey.equals(target.identity.variant) &
                    row.revision.equals(target.revision),
              ))
              .getSingleOrNull();
      final now = _now();

      if (existingPack == null) {
        await _database
            .into(_database.contentPackRevisions)
            .insert(
              ContentPackRevisionsCompanion.insert(
                packCode: target.identity.code,
                variantKey: target.identity.variant,
                revision: target.revision,
                schemaVersion: manifest.schemaVersion,
                checksum: target.checksum,
                state: 'STAGING',
                sourceContentVersion: plan.target.contentVersion,
                stagedAt: now,
              ),
            );
      } else if (existingPack.checksum != target.checksum ||
          existingPack.schemaVersion != manifest.schemaVersion) {
        throw const _SyncExecutorInvariant(
          ApplicationFailure(
            code: 'PACK_REVISION_IMMUTABLE_CONFLICT',
            message:
                'A persisted pack revision conflicts with immutable metadata.',
          ),
        );
      } else if (existingPack.state != 'CURRENT') {
        await (_database.update(_database.contentPackRevisions)..where(
              (row) =>
                  row.packCode.equals(target.identity.code) &
                  row.variantKey.equals(target.identity.variant) &
                  row.revision.equals(target.revision),
            ))
            .write(
              ContentPackRevisionsCompanion(
                state: const Value('STAGING'),
                sourceContentVersion: Value(plan.target.contentVersion),
                stagedAt: Value(now),
              ),
            );
      }

      await (_database.delete(_database.packContentRefs)..where(
            (row) =>
                row.packCode.equals(target.identity.code) &
                row.variantKey.equals(target.identity.variant) &
                row.packRevision.equals(target.revision),
          ))
          .go();
      await (_database.delete(_database.packAssetRefs)..where(
            (row) =>
                row.packCode.equals(target.identity.code) &
                row.variantKey.equals(target.identity.variant) &
                row.packRevision.equals(target.revision),
          ))
          .go();

      for (final content in manifest.contents) {
        await _ensureContentRecord(content, manifest.schemaVersion, now);
        await _database
            .into(_database.packContentRefs)
            .insert(
              PackContentRefsCompanion.insert(
                packCode: target.identity.code,
                variantKey: target.identity.variant,
                packRevision: target.revision,
                contentCode: content.identity.code,
                contentType: _contentTypeToStorage(content.identity.type),
                contentRevision: content.revision,
              ),
            );
      }

      for (final asset in manifest.assets) {
        await _ensureAsset(asset, now);
        await _database
            .into(_database.packAssetRefs)
            .insert(
              PackAssetRefsCompanion.insert(
                packCode: target.identity.code,
                variantKey: target.identity.variant,
                packRevision: target.revision,
                assetId: asset.assetId,
                requiredOffline: Value(asset.requiredOffline),
              ),
            );
      }

      final assetById = <String, ManifestAssetDescriptor>{
        for (final asset in manifest.assets) asset.assetId: asset,
      };
      for (final content in manifest.contents) {
        final expected = manifest.contentAssets
            .where(
              (ref) =>
                  ref.contentIdentity == content.identity &&
                  ref.contentRevision == content.revision,
            )
            .toList(growable: false);
        await _ensureContentAssetRefs(content, expected, assetById);
      }
    });
  }

  Future<void> _ensureContentRecord(
    PackContentRef content,
    int schemaVersion,
    DateTime now,
  ) async {
    final type = _contentTypeToStorage(content.identity.type);
    final existing =
        await (_database.select(_database.localContentRecords)..where(
              (row) =>
                  row.contentCode.equals(content.identity.code) &
                  row.contentType.equals(type) &
                  row.revision.equals(content.revision),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.localContentRecords)
          .insert(
            LocalContentRecordsCompanion.insert(
              contentCode: content.identity.code,
              contentType: type,
              revision: content.revision,
              checksum: content.checksum,
              sortOrder: Value(content.sortOrder),
              publishedAt: Value(content.publishedAt),
              snapshotState: 'STAGED',
              sourceSchemaVersion: schemaVersion,
              createdAt: now,
            ),
          );
      return;
    }

    if (existing.checksum != content.checksum ||
        existing.sortOrder != content.sortOrder ||
        existing.publishedAt != content.publishedAt ||
        existing.sourceSchemaVersion != schemaVersion) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_REVISION_IMMUTABLE_CONFLICT',
          message:
              'A persisted content revision conflicts with immutable metadata.',
        ),
      );
    }
    if (existing.snapshotState == 'TOMBSTONED') {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_REVISION_TOMBSTONED',
          message: 'A tombstoned content revision cannot be reactivated.',
        ),
      );
    }
  }

  Future<void> _ensureAsset(ManifestAssetDescriptor asset, DateTime now) async {
    final existing = await (_database.select(
      _database.assetCatalog,
    )..where((row) => row.assetId.equals(asset.assetId))).getSingleOrNull();
    final kind = _assetKind(asset.mediaType);

    if (existing == null) {
      await _database
          .into(_database.assetCatalog)
          .insert(
            AssetCatalogCompanion.insert(
              assetId: asset.assetId,
              checksumSha256: asset.checksumSha256,
              assetKind: kind,
              mimeType: asset.mediaType,
              sizeBytes: asset.sizeBytes,
              deliveryKey: asset.deliveryKey,
              createdAt: now,
            ),
          );
      return;
    }

    if (existing.checksumSha256 != asset.checksumSha256 ||
        existing.assetKind != kind ||
        existing.mimeType != asset.mediaType ||
        existing.sizeBytes != asset.sizeBytes ||
        existing.deliveryKey != asset.deliveryKey) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'ASSET_IMMUTABLE_CONFLICT',
          message: 'A persisted asset id conflicts with immutable metadata.',
        ),
      );
    }
  }

  Future<void> _ensureContentAssetRefs(
    PackContentRef content,
    List<ContentAssetRef> expected,
    Map<String, ManifestAssetDescriptor> assetById,
  ) async {
    final type = _contentTypeToStorage(content.identity.type);
    final existing =
        await (_database.select(_database.contentAssetRefs)..where(
              (row) =>
                  row.contentCode.equals(content.identity.code) &
                  row.contentType.equals(type) &
                  row.contentRevision.equals(content.revision),
            ))
            .get();

    final existingKeys = <String>{
      for (final ref in existing)
        '${ref.assetId}|${ref.assetRole}|${ref.requiredOffline}',
    };
    final expectedKeys = <String>{
      for (final ref in expected)
        '${ref.assetId}|${ref.role}|${assetById[ref.assetId]!.requiredOffline}',
    };

    if (existingKeys.isNotEmpty &&
        existingKeys.length == expectedKeys.length &&
        existingKeys.containsAll(expectedKeys)) {
      return;
    }
    if (existingKeys.isNotEmpty) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_ASSET_IMMUTABLE_CONFLICT',
          message:
              'Persisted content asset references conflict with immutable metadata.',
        ),
      );
    }

    for (final ref in expected) {
      final asset = assetById[ref.assetId]!;
      await _database
          .into(_database.contentAssetRefs)
          .insert(
            ContentAssetRefsCompanion.insert(
              contentCode: content.identity.code,
              contentType: type,
              contentRevision: content.revision,
              assetId: ref.assetId,
              assetRole: ref.role,
              requiredOffline: Value(asset.requiredOffline),
            ),
          );
    }
  }

  Future<void> _commit({required String runId, required SyncPlan plan}) async {
    await _database.transaction(() async {
      final now = _now();
      final run = await (_database.select(
        _database.syncRuns,
      )..where((row) => row.runId.equals(runId))).getSingleOrNull();
      if (run == null ||
          run.targetContentVersion != plan.target.contentVersion ||
          run.targetSchemaVersion != plan.target.schemaVersion) {
        throw const _SyncExecutorInvariant(
          ApplicationFailure(
            code: 'SYNC_TARGET_MISMATCH',
            message:
                'The durable sync run does not match the execution target.',
          ),
        );
      }

      final updates = await (_database.select(
        _database.syncPackUpdates,
      )..where((row) => row.runId.equals(runId))).get();
      if (updates.any(
        (row) => row.state != SyncPackUpdateState.readyToCommit.storageCode,
      )) {
        throw const _SyncExecutorInvariant(
          ApplicationFailure(
            code: 'SYNC_PACK_NOT_READY',
            message: 'At least one changed pack is not ready to commit.',
          ),
        );
      }

      final targetByIdentity = <String, PackRevisionRef>{
        for (final target in plan.target.packs)
          _packKey(target.identity.code, target.identity.variant): target,
      };
      final currentPacks = await (_database.select(
        _database.contentPackRevisions,
      )..where((row) => row.state.equals('CURRENT'))).get();

      for (final current in currentPacks) {
        final target =
            targetByIdentity[_packKey(current.packCode, current.variantKey)];
        if (target == null || target.revision != current.revision) {
          await (_database.update(_database.contentPackRevisions)..where(
                (row) =>
                    row.packCode.equals(current.packCode) &
                    row.variantKey.equals(current.variantKey) &
                    row.revision.equals(current.revision),
              ))
              .write(
                ContentPackRevisionsCompanion(
                  state: const Value('SUPERSEDED'),
                  supersededAt: Value(now),
                ),
              );
        }
      }

      for (final target in plan.target.packs) {
        final targetRow =
            await (_database.select(_database.contentPackRevisions)..where(
                  (row) =>
                      row.packCode.equals(target.identity.code) &
                      row.variantKey.equals(target.identity.variant) &
                      row.revision.equals(target.revision),
                ))
                .getSingleOrNull();
        if (targetRow == null || targetRow.checksum != target.checksum) {
          throw const _SyncExecutorInvariant(
            ApplicationFailure(
              code: 'SYNC_TARGET_PACK_MISSING',
              message: 'A target pack revision is missing from local metadata.',
            ),
          );
        }
        await (_database.update(_database.contentPackRevisions)..where(
              (row) =>
                  row.packCode.equals(target.identity.code) &
                  row.variantKey.equals(target.identity.variant) &
                  row.revision.equals(target.revision),
            ))
            .write(
              ContentPackRevisionsCompanion(
                state: const Value('CURRENT'),
                verifiedAt: Value(targetRow.verifiedAt ?? now),
                currentAt: Value(now),
              ),
            );
      }

      final currentContentKeys = <String>{};
      final currentIdentities = <String>{};
      for (final target in plan.target.packs) {
        final refs =
            await (_database.select(_database.packContentRefs)..where(
                  (row) =>
                      row.packCode.equals(target.identity.code) &
                      row.variantKey.equals(target.identity.variant) &
                      row.packRevision.equals(target.revision),
                ))
                .get();
        for (final ref in refs) {
          currentContentKeys.add(
            _contentKey(ref.contentCode, ref.contentType, ref.contentRevision),
          );
          currentIdentities.add(_identityKey(ref.contentCode, ref.contentType));
        }
      }

      for (final tombstone in plan.tombstones) {
        final type = _contentTypeToStorage(tombstone.identity.type);
        if (currentIdentities.contains(
          _identityKey(tombstone.identity.code, type),
        )) {
          throw const _SyncExecutorInvariant(
            ApplicationFailure(
              code: 'TOMBSTONE_TARGET_CONFLICT',
              message:
                  'A target root cannot publish and tombstone the same content.',
            ),
          );
        }
      }

      final currentContent = await (_database.select(
        _database.localContentRecords,
      )..where((row) => row.snapshotState.equals('CURRENT'))).get();
      for (final content in currentContent) {
        final key = _contentKey(
          content.contentCode,
          content.contentType,
          content.revision,
        );
        if (!currentContentKeys.contains(key)) {
          await (_database.update(_database.localContentRecords)..where(
                (row) =>
                    row.contentCode.equals(content.contentCode) &
                    row.contentType.equals(content.contentType) &
                    row.revision.equals(content.revision),
              ))
              .write(
                const LocalContentRecordsCompanion(
                  snapshotState: Value('SUPERSEDED'),
                ),
              );
        }
      }

      for (final target in plan.target.packs) {
        final refs =
            await (_database.select(_database.packContentRefs)..where(
                  (row) =>
                      row.packCode.equals(target.identity.code) &
                      row.variantKey.equals(target.identity.variant) &
                      row.packRevision.equals(target.revision),
                ))
                .get();
        for (final ref in refs) {
          final changed =
              await (_database.update(_database.localContentRecords)..where(
                    (row) =>
                        row.contentCode.equals(ref.contentCode) &
                        row.contentType.equals(ref.contentType) &
                        row.revision.equals(ref.contentRevision),
                  ))
                  .write(
                    const LocalContentRecordsCompanion(
                      snapshotState: Value('CURRENT'),
                    ),
                  );
          if (changed != 1) {
            throw const _SyncExecutorInvariant(
              ApplicationFailure(
                code: 'SYNC_TARGET_CONTENT_MISSING',
                message:
                    'A target content revision is missing from local metadata.',
              ),
            );
          }
        }
      }

      for (final tombstone in plan.tombstones) {
        final type = _contentTypeToStorage(tombstone.identity.type);
        await (_database.update(_database.localContentRecords)..where(
              (row) =>
                  row.contentCode.equals(tombstone.identity.code) &
                  row.contentType.equals(type),
            ))
            .write(
              const LocalContentRecordsCompanion(
                snapshotState: Value('TOMBSTONED'),
              ),
            );
        await (_database.update(_database.syncTombstones)..where(
              (row) =>
                  row.runId.equals(runId) &
                  row.contentCode.equals(tombstone.identity.code) &
                  row.contentType.equals(type),
            ))
            .write(
              SyncTombstonesCompanion(
                state: Value(SyncTombstoneState.applied.storageCode),
                appliedAt: Value(now),
              ),
            );
      }

      await _database
          .into(_database.contentManifestStates)
          .insertOnConflictUpdate(
            ContentManifestStatesCompanion.insert(
              id: const Value(1),
              schemaVersion: plan.target.schemaVersion,
              currentContentVersion: plan.target.contentVersion,
              currentManifestChecksum: plan.target.checksum,
              remoteContentVersionSeen: Value(plan.target.contentVersion),
              remoteManifestChecksum: Value(plan.target.checksum),
              etag: const Value(null),
              lastCheckedAt: Value(now),
              lastSuccessfulSyncAt: Value(now),
              updatedAt: now,
            ),
          );

      await (_database.update(
        _database.syncPackUpdates,
      )..where((row) => row.runId.equals(runId))).write(
        SyncPackUpdatesCompanion(
          state: Value(SyncPackUpdateState.committed.storageCode),
          updatedAt: Value(now),
        ),
      );
      await (_database.update(
        _database.syncRuns,
      )..where((row) => row.runId.equals(runId))).write(
        SyncRunsCompanion(
          state: Value(SyncRunState.cleaning.storageCode),
          updatedAt: Value(now),
        ),
      );
    });
  }

  Future<void> _setRunState(String runId, SyncRunState state) async {
    final changed =
        await (_database.update(
          _database.syncRuns,
        )..where((row) => row.runId.equals(runId))).write(
          SyncRunsCompanion(
            state: Value(state.storageCode),
            updatedAt: Value(_now()),
          ),
        );
    if (changed != 1) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'SYNC_RUN_NOT_FOUND',
          message: 'The sync run does not exist.',
        ),
      );
    }
  }

  Future<void> _setPackState(
    String runId,
    PackRevisionRef target,
    SyncPackUpdateState state,
  ) async {
    final changed =
        await (_database.update(_database.syncPackUpdates)..where(
              (row) =>
                  row.runId.equals(runId) &
                  row.packCode.equals(target.identity.code) &
                  row.variantKey.equals(target.identity.variant),
            ))
            .write(
              SyncPackUpdatesCompanion(
                state: Value(state.storageCode),
                updatedAt: Value(_now()),
              ),
            );
    if (changed != 1) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'SYNC_PACK_UPDATE_NOT_FOUND',
          message: 'The planned pack update does not exist.',
        ),
      );
    }
  }
}

final class _SyncExecutorInvariant implements Exception {
  const _SyncExecutorInvariant(this.failure);
  final ApplicationFailure failure;
}

String _assetKind(String mediaType) {
  if (mediaType.startsWith('audio/')) return 'AUDIO';
  if (mediaType.startsWith('image/')) return 'IMAGE';
  return 'BINARY';
}

String _contentTypeToStorage(ContentType type) => switch (type) {
  ContentType.vocabulary => 'VOCABULARY',
  ContentType.interview => 'INTERVIEW',
  ContentType.topic => 'TOPIC',
  ContentType.shadowing => 'SHADOWING',
  ContentType.phrase => 'PHRASE',
};

String _packKey(String code, String variant) => '$code|$variant';
String _identityKey(String code, String type) => '$code|$type';
String _contentKey(String code, String type, int revision) =>
    '$code|$type|$revision';
