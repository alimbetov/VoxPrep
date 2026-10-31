import 'dart:async';
import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/asset_retention.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/ports/asset_cache_retention_repository.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_cache_retention_manager.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/data/local/file_system_asset_store.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:flutter_test/flutter_test.dart';

const _checksum =
    '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a';
const _bytes = <int>[1, 2, 3, 4];
final _asset = ManifestAssetDescriptor(
  assetId: 'concurrent-audio',
  checksumSha256: _checksum,
  deliveryKey: 'audio/concurrent.mp3',
  sizeBytes: 4,
  mediaType: 'audio/mpeg',
  requiredOffline: false,
);

void main() {
  test('concurrent resolve calls coalesce to one immutable download', () async {
    final directory = await Directory.systemTemp.createTemp('resolver-race-');
    addTearDown(() => directory.delete(recursive: true));

    final source = _BlockingSource();
    final store = FileSystemAssetStore(directory);
    final retention = _Retention();
    final resolver = _resolver(source, store, retention);

    final first = resolver.resolve(
      _asset.assetId,
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    final second = resolver.resolve(
      _asset.assetId,
      policy: AssetResolutionPolicy.downloadIfMissing,
    );

    await _waitUntil(() => source.openCount == 1);
    expect(source.openCount, 1);

    source.release();
    final results = await Future.wait(<Future<Result<ResolvedAsset>>>[
      first,
      second,
    ]);

    expect(results.every((result) => result is Success<ResolvedAsset>), isTrue);
    expect(source.openCount, 1);
    final firstPath = (results[0] as Success<ResolvedAsset>).value.localPath;
    final secondPath = (results[1] as Success<ResolvedAsset>).value.localPath;
    expect(firstPath, secondPath);
    expect(await File(firstPath).readAsBytes(), _bytes);
  });

  test(
    'cleanup during in-flight resolve cannot evict incomplete download',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'resolver-evict-race-',
      );
      addTearDown(() => directory.delete(recursive: true));

      var now = DateTime.utc(2026, 1, 1);
      final source = _BlockingSource();
      final store = FileSystemAssetStore(directory, now: () => now);
      final retention = _Retention(now: () => now);
      final resolver = _resolver(source, store, retention);

      final pending = resolver.resolve(
        _asset.assetId,
        policy: AssetResolutionPolicy.downloadIfMissing,
      );
      await _waitUntil(() => source.openCount == 1);

      now = now.add(const Duration(days: 100));
      final duringDownload = await AssetCacheRetentionManager(
        retention: retention,
        evictionStore: store,
        audioTtl: const Duration(days: 90),
        now: () => now,
      ).cleanupExpiredAudio();

      expect(duringDownload, isA<Success<AssetRetentionCleanupReport>>());
      expect(
        (duringDownload as Success<AssetRetentionCleanupReport>).value.evicted,
        0,
      );

      source.release();
      final result = await pending;
      expect(result, isA<Success<ResolvedAsset>>());
      final path = (result as Success<ResolvedAsset>).value.localPath;
      expect(await File(path).readAsBytes(), _bytes);
      expect(retention.entry, isNotNull);
      expect(retention.entry!.lastAccessedAt, now);
    },
  );
}

AssetResolver _resolver(
  AssetByteSource source,
  FileSystemAssetStore store,
  AssetCacheRetentionRepository retention,
) {
  return AssetResolver(
    catalog: const _Catalog(),
    store: store,
    downloads: AssetDownloadManager(
      source: source,
      store: store,
      delay: (_) async {},
    ),
    retention: retention,
  );
}

Future<void> _waitUntil(bool Function() predicate) async {
  for (var i = 0; i < 100 && !predicate(); i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(predicate(), isTrue);
}

final class _BlockingSource implements AssetByteSource {
  final Completer<void> _release = Completer<void>();
  int openCount = 0;

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    openCount += 1;
    await _release.future;
    return Success<AssetByteStream>(
      AssetByteStream(
        bytes: Stream<List<int>>.value(_bytes),
        contentLength: _bytes.length,
      ),
    );
  }
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

final class _Retention implements AssetCacheRetentionRepository {
  _Retention({DateTime Function()? now})
    : _now = now ?? (() => DateTime.utc(2026, 1, 1));

  final DateTime Function() _now;
  AssetRetentionEntry? entry;

  @override
  Future<Result<void>> recordAccess({
    required ManifestAssetDescriptor asset,
    AssetRetentionClass retentionClass = AssetRetentionClass.autoCache,
  }) async {
    final previous = entry;
    entry = AssetRetentionEntry(
      asset: asset,
      retentionClass: previous?.retentionClass ?? retentionClass,
      cachedAt: previous?.cachedAt ?? _now(),
      lastAccessedAt: _now(),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AssetRetentionEntry>>> findExpiredAutoCache({
    required DateTime accessedBefore,
    int limit = 100,
  }) async {
    final current = entry;
    if (current == null ||
        current.retentionClass != AssetRetentionClass.autoCache ||
        !current.lastAccessedAt.isBefore(accessedBefore)) {
      return const Success<List<AssetRetentionEntry>>(<AssetRetentionEntry>[]);
    }
    return Success<List<AssetRetentionEntry>>(<AssetRetentionEntry>[current]);
  }

  @override
  Future<Result<void>> forget(String assetId) async {
    if (entry?.asset.assetId == assetId) entry = null;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> setRetentionClass({
    required String assetId,
    required AssetRetentionClass retentionClass,
  }) async {
    final current = entry;
    if (current != null && current.asset.assetId == assetId) {
      entry = AssetRetentionEntry(
        asset: current.asset,
        retentionClass: retentionClass,
        cachedAt: current.cachedAt,
        lastAccessedAt: current.lastAccessedAt,
      );
    }
    return const Success<void>(null);
  }
}
