// ignore_for_file: prefer_initializing_formals

import '../content_delivery/content_manifest.dart';
import '../ports/content_manifest_gateway.dart';
import '../result/result.dart';
import '../services/asset_download_manager.dart';

typedef EnsureRequiredOfflineAsset =
    Future<Result<AssetDownloadOutcome>> Function(
      ManifestAssetDescriptor asset,
    );

/// Pre-commit barrier for assets whose publication contract requires a verified
/// local copy. Optional/cacheable media remains lazy and does not block commit.
final class RequiredOfflineAssetPrefetcher {
  const RequiredOfflineAssetPrefetcher({
    required ContentManifestGateway manifestGateway,
    required EnsureRequiredOfflineAsset ensureLocal,
  }) : _manifestGateway = manifestGateway,
       _ensureLocal = ensureLocal;

  final ContentManifestGateway _manifestGateway;
  final EnsureRequiredOfflineAsset _ensureLocal;

  Future<Result<void>> prefetch(Iterable<PackRevisionRef> packs) async {
    final seenAssets = <String>{};

    for (final target in packs) {
      final fetched = await _manifestGateway.fetchPackManifest(target);
      if (fetched case FailureResult<PackContentManifest>(:final failure)) {
        return FailureResult(failure);
      }

      final manifest = (fetched as Success<PackContentManifest>).value;
      if (manifest.identity != target.identity ||
          manifest.revision != target.revision ||
          manifest.checksum != target.checksum) {
        return FailureResult<void>(
          ApplicationFailure(
            code: 'REQUIRED_OFFLINE_PACK_MISMATCH',
            message:
                'Required-offline prefetch received a pack outside the exact publication target.',
            details: <String, Object?>{
              'packCode': target.identity.code,
              'variant': target.identity.variant,
              'revision': target.revision,
            },
          ),
        );
      }

      for (final asset in manifest.assets) {
        if (!asset.requiredOffline || !seenAssets.add(asset.assetId)) continue;

        final downloaded = await _ensureLocal(asset);
        if (downloaded case FailureResult<AssetDownloadOutcome>(
          :final failure,
        )) {
          return FailureResult<void>(
            ApplicationFailure(
              code: 'REQUIRED_OFFLINE_ASSET_UNAVAILABLE',
              message:
                  'A publication-required offline asset could not be verified locally.',
              retryable: failure.retryable,
              traceId: failure.traceId,
              details: <String, Object?>{
                'assetId': asset.assetId,
                'causeCode': failure.code,
              },
            ),
          );
        }
      }
    }

    return const Success<void>(null);
  }
}
