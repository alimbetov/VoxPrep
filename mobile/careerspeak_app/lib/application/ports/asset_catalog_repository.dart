import '../../domain/content_identity.dart';
import '../content_delivery/content_manifest.dart';
import '../result/result.dart';

/// Reads immutable asset bindings from the active metadata snapshot.
abstract interface class AssetCatalogRepository {
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(String assetId);

  /// Requires the exact displayed content revision and pack variant.
  /// Missing bindings return null; ambiguous roles return a failure.
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  });
}
