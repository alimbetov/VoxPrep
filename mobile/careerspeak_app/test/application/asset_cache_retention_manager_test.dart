import 'package:careerspeak_app/application/content_delivery/asset_retention.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_cache_eviction_store.dart';
import 'package:careerspeak_app/application/ports/asset_cache_retention_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_cache_retention_manager.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('AssetCacheRetentionManager', () {
    test('evicts only expired unprotected audio cache entries', () async {
      final now = DateTime.utc(2026, 10, 31, 20);
      final oldAudio = _entry(
        assetId: 'audio-old',
        mediaType: 'audio/mpeg',
        accessedAt: now.subtract(const Duration(days: 120)),
      );
      final protected = _entry(
        assetId: 'audio-required',
        mediaType: 'audio/mpeg',
        accessedAt: now.subtract(const Duration(days: 120)),
        requiredOffline: true,
      );
      final repository = _RetentionRepository(<AssetRetentionEntry>[
        oldAudio,
        protected,
      ]);
      final store = _EvictionStore();
      final manager = AssetCacheRetentionManager(
        retention: repository,
        evictionStore: store,
        now: () => now,
      );

      final result = await manager.cleanupExpiredAudio();
      final report = (result as Success<AssetRetentionCleanupReport>).value;

      expect(store.evictedAssetIds, <String>['audio-old']);
      expect(repository.forgottenAssetIds, <String>['audio-old']);
      expect(report.examined, 2);
      expect(report.evicted, 1);
      expect(report.reclaimedBytes, 4);
      expect(report.skippedProtected, 1);
    });

    test('fails closed when eviction store fails', () async {
      final now = DateTime.utc(2026, 10, 31, 20);
      final repository = _RetentionRepository(<AssetRetentionEntry>[
        _entry(
          assetId: 'audio-old',
          mediaType: 'audio/mpeg',
          accessedAt: now.subtract(const Duration(days: 120)),
        ),
      ]);
      final store = _EvictionStore(fail: true);
      final manager = AssetCacheRetentionManager(
        retention: repository,
        evictionStore: store,
        now: () => now,
      );

      final result = await manager.cleanupExpiredAudio();

      expect(result, isA<FailureResult<AssetRetentionCleanupReport>>());
      expect(repository.forgottenAssetIds, isEmpty);
    });
  });
}

AssetRetentionEntry _entry({
  required String assetId,
  required String mediaType,
  required DateTime accessedAt,
  bool requiredOffline = false,
  AssetRetentionClass retentionClass = AssetRetentionClass.autoCache,
}) {
  return AssetRetentionEntry(
    asset: ManifestAssetDescriptor(
      assetId: assetId,
      checksumSha256: _hash,
      deliveryKey: 'audio/$assetId.mp3',
      sizeBytes: 4,
      mediaType: mediaType,
      requiredOffline: requiredOffline,
    ),
    retentionClass: retentionClass,
    cachedAt: accessedAt,
    lastAccessedAt: accessedAt,
  );
}

final class _RetentionRepository implements AssetCacheRetentionRepository {
  _RetentionRepository(this.entries);

  final List<AssetRetentionEntry> entries;
  final forgottenAssetIds = <String>[];

  @override
  Future<Result<List<AssetRetentionEntry>>> findExpiredAutoCache({
    required DateTime accessedBefore,
    int limit = 100,
  }) async {
    return Success<List<AssetRetentionEntry>>(
      entries
          .where((entry) => entry.lastAccessedAt.isBefore(accessedBefore))
          .take(limit)
          .toList(),
    );
  }

  @override
  Future<Result<void>> forget(String assetId) async {
    forgottenAssetIds.add(assetId);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> recordAccess({
    required ManifestAssetDescriptor asset,
    AssetRetentionClass retentionClass = AssetRetentionClass.autoCache,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setRetentionClass({
    required String assetId,
    required AssetRetentionClass retentionClass,
  }) async => const Success<void>(null);
}

final class _EvictionStore implements AssetCacheEvictionStore {
  _EvictionStore({this.fail = false});

  final bool fail;
  final evictedAssetIds = <String>[];

  @override
  Future<Result<bool>> evict(ManifestAssetDescriptor asset) async {
    if (fail) {
      return const FailureResult<bool>(
        ApplicationFailure(
          code: 'TEST_EVICTION_FAILURE',
          message: 'forced failure',
        ),
      );
    }
    evictedAssetIds.add(asset.assetId);
    return const Success<bool>(true);
  }
}
