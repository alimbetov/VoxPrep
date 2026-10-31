import 'package:careerspeak_app/application/content_delivery/asset_retention.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_asset_cache_retention_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('DriftAssetCacheRetentionRepository', () {
    test('records AUTO_CACHE and returns only expired unprotected audio', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      var now = DateTime.utc(2026, 1, 1);
      final repository = DriftAssetCacheRetentionRepository(
        database,
        now: () => now,
      );
      final audio = _asset('audio-1');

      expect(
        await repository.recordAccess(asset: audio),
        isA<Success<void>>(),
      );

      now = now.add(const Duration(days: 100));
      final result = await repository.findExpiredAutoCache(
        accessedBefore: now.subtract(const Duration(days: 90)),
      );
      final entries = (result as Success<List<AssetRetentionEntry>>).value;

      expect(entries, hasLength(1));
      expect(entries.single.asset.assetId, 'audio-1');
      expect(entries.single.retentionClass, AssetRetentionClass.autoCache);
    });

    test('ordinary playback never downgrades explicit download protection', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      var now = DateTime.utc(2026, 1, 1);
      final repository = DriftAssetCacheRetentionRepository(
        database,
        now: () => now,
      );
      final audio = _asset('audio-2');

      await repository.recordAccess(
        asset: audio,
        retentionClass: AssetRetentionClass.explicitDownload,
      );
      now = now.add(const Duration(days: 120));
      await repository.recordAccess(asset: audio);

      final expired = await repository.findExpiredAutoCache(
        accessedBefore: now.add(const Duration(days: 1)),
      );

      expect(
        (expired as Success<List<AssetRetentionEntry>>).value,
        isEmpty,
      );
    });

    test('required-offline audio is never returned for automatic cleanup', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      var now = DateTime.utc(2026, 1, 1);
      final repository = DriftAssetCacheRetentionRepository(
        database,
        now: () => now,
      );
      final audio = _asset('audio-required', requiredOffline: true);

      await repository.recordAccess(asset: audio);
      now = now.add(const Duration(days: 365));

      final expired = await repository.findExpiredAutoCache(
        accessedBefore: now,
      );

      expect(
        (expired as Success<List<AssetRetentionEntry>>).value,
        isEmpty,
      );
    });
  });
}

ManifestAssetDescriptor _asset(
  String assetId, {
  bool requiredOffline = false,
}) {
  return ManifestAssetDescriptor(
    assetId: assetId,
    checksumSha256: _hash,
    deliveryKey: 'audio/$assetId.mp3',
    sizeBytes: 4,
    mediaType: 'audio/mpeg',
    requiredOffline: requiredOffline,
  );
}
