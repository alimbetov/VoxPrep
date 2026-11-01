import '../content_delivery/asset_retention.dart';
import '../content_delivery/content_manifest.dart';
import '../result/result.dart';

abstract interface class AssetCacheRetentionRepository {
  Future<Result<void>> recordAccess({
    required ManifestAssetDescriptor asset,
    AssetRetentionClass retentionClass = AssetRetentionClass.autoCache,
  });

  Future<Result<void>> setRetentionClass({
    required String assetId,
    required AssetRetentionClass retentionClass,
  });

  Future<Result<List<AssetRetentionEntry>>> findExpiredAutoCache({
    required DateTime accessedBefore,
    int limit = 100,
  });

  Future<Result<void>> forget(String assetId);
}
