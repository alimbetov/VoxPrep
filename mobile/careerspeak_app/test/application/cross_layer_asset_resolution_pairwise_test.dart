import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/asset_retention.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/ports/asset_cache_retention_repository.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:flutter_test/flutter_test.dart';

const _validBytes = <int>[1, 2, 3, 4];
const _validChecksum =
    '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a';

final _asset = ManifestAssetDescriptor(
  assetId: 'pairwise-audio',
  checksumSha256: _validChecksum,
  deliveryKey: 'audio/pairwise-audio.mp3',
  sizeBytes: _validBytes.length,
  mediaType: 'audio/mpeg',
  requiredOffline: false,
);

enum _CacheState { present, missing, corrupt }

enum _NetworkState { online, offline, badChecksum }

void main() {
  group('C2 cache x network x resolution-policy pairwise qualification', () {
    final scenarios =
        <
          ({
            _CacheState cache,
            _NetworkState network,
            AssetResolutionPolicy policy,
            bool succeeds,
            String? failureCode,
          })
        >[
          (
            cache: _CacheState.present,
            network: _NetworkState.offline,
            policy: AssetResolutionPolicy.localOnly,
            succeeds: true,
            failureCode: null,
          ),
          (
            cache: _CacheState.missing,
            network: _NetworkState.online,
            policy: AssetResolutionPolicy.localOnly,
            succeeds: false,
            failureCode: 'ASSET_NOT_AVAILABLE_OFFLINE',
          ),
          (
            cache: _CacheState.missing,
            network: _NetworkState.online,
            policy: AssetResolutionPolicy.downloadIfMissing,
            succeeds: true,
            failureCode: null,
          ),
          (
            cache: _CacheState.missing,
            network: _NetworkState.offline,
            policy: AssetResolutionPolicy.downloadIfMissing,
            succeeds: false,
            failureCode: 'NETWORK_OFFLINE',
          ),
          (
            cache: _CacheState.missing,
            network: _NetworkState.badChecksum,
            policy: AssetResolutionPolicy.downloadIfMissing,
            succeeds: false,
            failureCode: 'ASSET_CHECKSUM_MISMATCH',
          ),
          (
            cache: _CacheState.corrupt,
            network: _NetworkState.online,
            policy: AssetResolutionPolicy.downloadIfMissing,
            succeeds: true,
            failureCode: null,
          ),
          (
            cache: _CacheState.corrupt,
            network: _NetworkState.offline,
            policy: AssetResolutionPolicy.localOnly,
            succeeds: false,
            failureCode: 'ASSET_NOT_AVAILABLE_OFFLINE',
          ),
        ];

    for (final scenario in scenarios) {
      test(
        '${scenario.cache.name} x ${scenario.network.name} x ${scenario.policy.name}',
        () async {
          final directory = await Directory.systemTemp.createTemp(
            'asset-pairwise-',
          );
          addTearDown(() => directory.delete(recursive: true));

          final store = FileSystemAssetStore(directory);
          final source = _Source(scenario.network);
          final retention = _Retention();
          final resolver = AssetResolver(
            catalog: const _Catalog(),
            store: store,
            downloads: AssetDownloadManager(
              source: source,
              store: store,
              maxAttempts: 1,
              delay: (_) async {},
            ),
            retention: retention,
          );

          if (scenario.cache != _CacheState.missing) {
            final seeded = await AssetDownloadManager(
              source: const _SeedSource(),
              store: store,
              maxAttempts: 1,
              delay: (_) async {},
            ).ensureLocal(_asset);
            expect(seeded, isA<Success<AssetDownloadOutcome>>());
            if (scenario.cache == _CacheState.corrupt) {
              final path =
                  (seeded as Success<AssetDownloadOutcome>).value.localPath;
              await File(path).writeAsBytes(const <int>[9, 9, 9, 9]);
            }
          }

          final result = await resolver.resolve(
            _asset.assetId,
            policy: scenario.policy,
          );

          if (scenario.succeeds) {
            expect(result, isA<Success<ResolvedAsset>>());
            final resolved = (result as Success<ResolvedAsset>).value;
            expect(await File(resolved.localPath).readAsBytes(), _validBytes);
            expect(retention.accessCount, 1);
            expect(retention.lastClass, AssetRetentionClass.autoCache);
          } else {
            expect(result, isA<FailureResult<ResolvedAsset>>());
            expect(
              (result as FailureResult<ResolvedAsset>).failure.code,
              scenario.failureCode,
            );
            expect(retention.accessCount, 0);
          }
        },
      );
    }
  });
}

final class _Catalog implements AssetCatalogRepository {
  const _Catalog();

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(
    String assetId,
  ) async => Success<ManifestAssetDescriptor?>(
    assetId == _asset.assetId ? _asset : null,
  );

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async => Success<ManifestAssetDescriptor?>(_asset);
}

final class _Source implements AssetByteSource {
  const _Source(this.state);

  final _NetworkState state;

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    return switch (state) {
      _NetworkState.online => Success<AssetByteStream>(
        AssetByteStream(
          bytes: Stream<List<int>>.value(_validBytes),
          contentLength: _validBytes.length,
        ),
      ),
      _NetworkState.offline => const FailureResult<AssetByteStream>(
        ApplicationFailure(
          code: 'NETWORK_OFFLINE',
          message: 'Network unavailable in pairwise qualification.',
        ),
      ),
      _NetworkState.badChecksum => Success<AssetByteStream>(
        AssetByteStream(
          bytes: Stream<List<int>>.value(const <int>[4, 3, 2, 1]),
          contentLength: _validBytes.length,
        ),
      ),
    };
  }
}

final class _SeedSource implements AssetByteSource {
  const _SeedSource();

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async =>
      Success<AssetByteStream>(
        AssetByteStream(
          bytes: Stream<List<int>>.value(_validBytes),
          contentLength: _validBytes.length,
        ),
      );
}

final class _Retention implements AssetCacheRetentionRepository {
  int accessCount = 0;
  AssetRetentionClass? lastClass;

  @override
  Future<Result<void>> recordAccess({
    required ManifestAssetDescriptor asset,
    AssetRetentionClass retentionClass = AssetRetentionClass.autoCache,
  }) async {
    accessCount += 1;
    lastClass = retentionClass;
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AssetRetentionEntry>>> findExpiredAutoCache({
    required DateTime accessedBefore,
    int limit = 100,
  }) async => const Success<List<AssetRetentionEntry>>(<AssetRetentionEntry>[]);

  @override
  Future<Result<void>> forget(String assetId) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setRetentionClass({
    required String assetId,
    required AssetRetentionClass retentionClass,
  }) async => const Success<void>(null);
}
