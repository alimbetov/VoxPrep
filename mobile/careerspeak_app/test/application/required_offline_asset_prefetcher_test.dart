import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/required_offline_asset_prefetcher.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';

const _sha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test(
    'downloads only requiredOffline assets before commit readiness',
    () async {
      final requested = <String>[];
      final target = _target();
      final prefetcher = RequiredOfflineAssetPrefetcher(
        manifestGateway: _Gateway(_manifest(target)),
        ensureLocal: (asset) async {
          requested.add(asset.assetId);
          return Success(
            AssetDownloadOutcome(
              localPath: '/verified/${asset.assetId}',
              reused: false,
            ),
          );
        },
      );

      final result = await prefetcher.prefetch(<PackRevisionRef>[target]);

      expect(result, isA<Success<void>>());
      expect(requested, <String>['required-a']);
    },
  );

  test(
    'required asset verification failure blocks publication barrier',
    () async {
      final target = _target();
      final prefetcher = RequiredOfflineAssetPrefetcher(
        manifestGateway: _Gateway(_manifest(target)),
        ensureLocal: (asset) async => const FailureResult(
          ApplicationFailure(
            code: 'ASSET_CHECKSUM_MISMATCH',
            message: 'bad bytes',
          ),
        ),
      );

      final result = await prefetcher.prefetch(<PackRevisionRef>[target]);

      expect(result, isA<FailureResult<void>>());
      final failure = (result as FailureResult<void>).failure;
      expect(failure.code, 'REQUIRED_OFFLINE_ASSET_UNAVAILABLE');
      expect(failure.details['assetId'], 'required-a');
      expect(failure.details['causeCode'], 'ASSET_CHECKSUM_MISMATCH');
    },
  );

  test('same required asset shared by packs is verified once', () async {
    final first = _target(code: 'PACK_A');
    final second = _target(code: 'PACK_B');
    var calls = 0;
    final gateway = _Gateway.byTarget(<String, PackContentManifest>{
      'PACK_A': _manifest(first),
      'PACK_B': _manifest(second),
    });
    final prefetcher = RequiredOfflineAssetPrefetcher(
      manifestGateway: gateway,
      ensureLocal: (asset) async {
        calls += 1;
        return Success(
          AssetDownloadOutcome(
            localPath: '/verified/shared',
            reused: calls > 1,
          ),
        );
      },
    );

    final result = await prefetcher.prefetch(<PackRevisionRef>[first, second]);

    expect(result, isA<Success<void>>());
    expect(calls, 1);
  });

  test('exact pack mismatch fails before any asset download', () async {
    final target = _target();
    final wrong = _target(revision: 2);
    var downloads = 0;
    final prefetcher = RequiredOfflineAssetPrefetcher(
      manifestGateway: _Gateway(_manifest(wrong)),
      ensureLocal: (asset) async {
        downloads += 1;
        return Success(
          AssetDownloadOutcome(localPath: '/verified/x', reused: false),
        );
      },
    );

    final result = await prefetcher.prefetch(<PackRevisionRef>[target]);

    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure.code,
      'REQUIRED_OFFLINE_PACK_MISMATCH',
    );
    expect(downloads, 0);
  });
}

PackRevisionRef _target({String code = 'PACK_A', int revision = 1}) {
  return PackRevisionRef(
    identity: PackIdentity(code: code, variant: 'canonical'),
    revision: revision,
    checksum: _sha,
  );
}

PackContentManifest _manifest(PackRevisionRef target) {
  return PackContentManifest(
    schemaVersion: 2,
    identity: target.identity,
    revision: target.revision,
    checksum: target.checksum,
    contents: const <PackContentRef>[],
    assets: <ManifestAssetDescriptor>[
      ManifestAssetDescriptor(
        assetId: 'required-a',
        checksumSha256: _sha,
        deliveryKey: 'media/required-a.bin',
        sizeBytes: 10,
        mediaType: 'application/octet-stream',
        requiredOffline: true,
      ),
      ManifestAssetDescriptor(
        assetId: 'lazy-b',
        checksumSha256: _sha,
        deliveryKey: 'media/lazy-b.bin',
        sizeBytes: 10,
        mediaType: 'application/octet-stream',
        requiredOffline: false,
      ),
    ],
    contentAssets: const <ContentAssetRef>[],
  );
}

final class _Gateway implements ContentManifestGateway {
  _Gateway(PackContentManifest manifest)
    : _byCode = <String, PackContentManifest>{manifest.identity.code: manifest};

  _Gateway.byTarget(this._byCode);

  final Map<String, PackContentManifest> _byCode;

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    final manifest = _byCode[target.identity.code];
    if (manifest == null) {
      return const FailureResult(
        ApplicationFailure(code: 'MISSING', message: 'missing'),
      );
    }
    return Success(manifest);
  }

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) {
    throw UnimplementedError();
  }
}
