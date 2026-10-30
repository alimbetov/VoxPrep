import '../content_delivery/content_manifest.dart';
import '../result/result.dart';

abstract interface class AssetFileStore {
  Future<Result<String?>> findVerified(ManifestAssetDescriptor asset);

  Future<Result<String>> writeVerified({
    required ManifestAssetDescriptor asset,
    required Stream<List<int>> bytes,
  });
}
