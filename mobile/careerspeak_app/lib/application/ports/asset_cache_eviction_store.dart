import '../content_delivery/content_manifest.dart';
import '../result/result.dart';

abstract interface class AssetCacheEvictionStore {
  Future<Result<bool>> evict(ManifestAssetDescriptor asset);
}
