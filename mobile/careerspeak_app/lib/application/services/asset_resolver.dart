import '../../domain/content_identity.dart';
import '../content_delivery/content_manifest.dart';
import '../ports/asset_catalog_repository.dart';
import '../ports/asset_file_store.dart';
import '../result/result.dart';
import 'asset_download_manager.dart';

enum AssetResolutionPolicy { localOnly, downloadIfMissing }

/// A verified local source suitable for an audio player or image reader.
final class ResolvedAsset {
  const ResolvedAsset({
    required this.assetId,
    required this.localPath,
    required this.mediaType,
  });

  final String assetId;
  final String localPath;
  final String mediaType;
}

final class AssetResolver {
  factory AssetResolver({
    required AssetCatalogRepository catalog,
    required AssetFileStore store,
    required AssetDownloadManager downloads,
  }) => AssetResolver._(catalog, store, downloads);

  AssetResolver._(this._catalog, this._store, this._downloads);

  final AssetCatalogRepository _catalog;
  final AssetFileStore _store;
  final AssetDownloadManager _downloads;
  final _inFlight = <String, Future<Result<AssetDownloadOutcome>>>{};

  Future<Result<ResolvedAsset>> resolve(
    String assetId, {
    AssetResolutionPolicy policy = AssetResolutionPolicy.localOnly,
  }) async {
    return _resolve(await _catalog.findCurrentById(assetId), policy);
  }

  Future<Result<ResolvedAsset>> resolveContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
    AssetResolutionPolicy policy = AssetResolutionPolicy.localOnly,
  }) async {
    final descriptor = await _catalog.findCurrentForContent(
      content: content,
      revision: revision,
      role: role,
      variant: variant,
    );
    return _resolve(descriptor, policy);
  }

  Future<Result<ResolvedAsset>> _resolve(
    Result<ManifestAssetDescriptor?> descriptor,
    AssetResolutionPolicy policy,
  ) async {
    if (descriptor case FailureResult<ManifestAssetDescriptor?>(
      :final failure,
    )) {
      return FailureResult(failure);
    }
    final asset = (descriptor as Success<ManifestAssetDescriptor?>).value;
    if (asset == null) {
      return const FailureResult(
        ApplicationFailure(
          code: 'ASSET_NOT_CURRENT',
          message: 'The asset binding is not available in current metadata.',
        ),
      );
    }

    if (policy == AssetResolutionPolicy.localOnly) {
      final local = await _store.findVerified(asset);
      if (local case FailureResult<String?>(:final failure)) {
        return FailureResult(failure);
      }
      final path = (local as Success<String?>).value;
      if (path == null) {
        return FailureResult(
          ApplicationFailure(
            code: 'ASSET_NOT_AVAILABLE_OFFLINE',
            message: 'A verified local copy of the asset is not available.',
            details: <String, Object?>{'assetId': asset.assetId},
          ),
        );
      }
      return Success(_resolved(asset, path));
    }

    final downloaded = await _inFlight.putIfAbsent(
      asset.assetId,
      () => _downloads.ensureLocal(asset).whenComplete(() {
        _inFlight.remove(asset.assetId);
      }),
    );
    if (downloaded case FailureResult<AssetDownloadOutcome>(:final failure)) {
      return FailureResult(failure);
    }
    final path = (downloaded as Success<AssetDownloadOutcome>).value.localPath;
    return Success(_resolved(asset, path));
  }

  static ResolvedAsset _resolved(ManifestAssetDescriptor asset, String path) {
    return ResolvedAsset(
      assetId: asset.assetId,
      localPath: path,
      mediaType: asset.mediaType,
    );
  }
}
