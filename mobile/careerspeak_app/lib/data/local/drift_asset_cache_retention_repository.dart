import '../../application/content_delivery/asset_retention.dart';
import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/asset_cache_retention_repository.dart';
import '../../application/result/result.dart';
import 'database/careerspeak_database.dart';

final class DriftAssetCacheRetentionRepository
    implements AssetCacheRetentionRepository {
  DriftAssetCacheRetentionRepository(
    this._database, {
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final DateTime Function() _now;

  @override
  Future<Result<void>> recordAccess({
    required ManifestAssetDescriptor asset,
    AssetRetentionClass retentionClass = AssetRetentionClass.autoCache,
  }) async {
    try {
      final timestamp = _now().toUtc().millisecondsSinceEpoch;
      await _database.customStatement(
        '''
        INSERT INTO asset_cache_retention (
          asset_id,
          checksum_sha256,
          delivery_key,
          size_bytes,
          media_type,
          required_offline,
          retention_class,
          cached_at,
          last_accessed_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(asset_id) DO UPDATE SET
          checksum_sha256 = excluded.checksum_sha256,
          delivery_key = excluded.delivery_key,
          size_bytes = excluded.size_bytes,
          media_type = excluded.media_type,
          required_offline = excluded.required_offline,
          retention_class = CASE
            WHEN asset_cache_retention.retention_class IN ('EXPLICIT_DOWNLOAD', 'PINNED')
              AND excluded.retention_class = 'AUTO_CACHE'
            THEN asset_cache_retention.retention_class
            ELSE excluded.retention_class
          END,
          last_accessed_at = excluded.last_accessed_at
        ''',
        <Object?>[
          asset.assetId,
          asset.checksumSha256,
          asset.deliveryKey,
          asset.sizeBytes,
          asset.mediaType,
          asset.requiredOffline ? 1 : 0,
          retentionClass.storageCode,
          timestamp,
          timestamp,
        ],
      );
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(_failure('ASSET_RETENTION_WRITE_FAILED', error));
    }
  }

  @override
  Future<Result<void>> setRetentionClass({
    required String assetId,
    required AssetRetentionClass retentionClass,
  }) async {
    try {
      await _database.customStatement(
        'UPDATE asset_cache_retention SET retention_class = ? WHERE asset_id = ?',
        <Object?>[retentionClass.storageCode, assetId],
      );
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(_failure('ASSET_RETENTION_UPDATE_FAILED', error));
    }
  }

  @override
  Future<Result<List<AssetRetentionEntry>>> findExpiredAutoCache({
    required DateTime accessedBefore,
    int limit = 100,
  }) async {
    if (limit < 1) {
      return FailureResult<List<AssetRetentionEntry>>(
        ApplicationFailure(
          code: 'ASSET_RETENTION_INVALID_LIMIT',
          message: 'Asset retention cleanup limit must be positive.',
          details: <String, Object?>{'limit': limit},
        ),
      );
    }

    try {
      final rows = await _database.customSelect(
        '''
        SELECT
          asset_id,
          checksum_sha256,
          delivery_key,
          size_bytes,
          media_type,
          required_offline,
          retention_class,
          cached_at,
          last_accessed_at
        FROM asset_cache_retention
        WHERE retention_class = 'AUTO_CACHE'
          AND required_offline = 0
          AND media_type LIKE 'audio/%'
          AND last_accessed_at < ?
        ORDER BY last_accessed_at ASC, asset_id ASC
        LIMIT ?
        ''',
        variables: <Object?>[
          accessedBefore.toUtc().millisecondsSinceEpoch,
          limit,
        ],
      ).get();

      final result = <AssetRetentionEntry>[];
      for (final row in rows) {
        final retentionClass = AssetRetentionClass.fromStorageCode(
          row.read<String>('retention_class'),
        );
        if (retentionClass == null) {
          return FailureResult<List<AssetRetentionEntry>>(
            ApplicationFailure(
              code: 'ASSET_RETENTION_CORRUPT_CLASS',
              message: 'Stored asset retention class is not supported.',
              details: <String, Object?>{
                'assetId': row.read<String>('asset_id'),
              },
            ),
          );
        }

        result.add(
          AssetRetentionEntry(
            asset: ManifestAssetDescriptor(
              assetId: row.read<String>('asset_id'),
              checksumSha256: row.read<String>('checksum_sha256'),
              deliveryKey: row.read<String>('delivery_key'),
              sizeBytes: row.read<int>('size_bytes'),
              mediaType: row.read<String>('media_type'),
              requiredOffline: row.read<int>('required_offline') == 1,
            ),
            retentionClass: retentionClass,
            cachedAt: DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('cached_at'),
              isUtc: true,
            ),
            lastAccessedAt: DateTime.fromMillisecondsSinceEpoch(
              row.read<int>('last_accessed_at'),
              isUtc: true,
            ),
          ),
        );
      }
      return Success<List<AssetRetentionEntry>>(List.unmodifiable(result));
    } catch (error) {
      return FailureResult<List<AssetRetentionEntry>>(
        _failure('ASSET_RETENTION_READ_FAILED', error),
      );
    }
  }

  @override
  Future<Result<void>> forget(String assetId) async {
    try {
      await _database.customStatement(
        'DELETE FROM asset_cache_retention WHERE asset_id = ?',
        <Object?>[assetId],
      );
      return const Success<void>(null);
    } catch (error) {
      return FailureResult<void>(_failure('ASSET_RETENTION_DELETE_FAILED', error));
    }
  }

  static ApplicationFailure _failure(String code, Object error) {
    return ApplicationFailure(
      code: code,
      message: 'Managed asset retention metadata is temporarily unavailable.',
      retryable: true,
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}
