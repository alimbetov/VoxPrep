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

void main() {
  test('expired auto-cached audio is redownloaded on the next resolve', () async {
    final directory = await Directory.systemTemp.createTemp(
      'careerspeak-audio-retention-',
    );
    addTearDown(() => directory.delete(recursive: true));

    var now = DateTime.utc(2026, 1, 1);
    final asset = ManifestAssetDescriptor(
      assetId: 'audio-interview-question-r1',
      checksumSha256: _checksum,
      deliveryKey: 'audio/interview/question-r1.mp3',
      sizeBytes: _bytes.length,
      mediaType: 'audio/mpeg',
      requiredOffline: false,
    );
    final source = _CountingSource();
    final store = FileSystemAssetStore(directory, now: () => now);
    final retention = _MemoryRetentionRepository(() => now);
    final resolver = AssetResolver(
      catalog: _Catalog(asset),
      store: store,
      downloads: AssetDownloadManager(
        source: source,
        store: store,
        delay: (_) async {},
      ),
      retention: retention,
    );

    final first = await resolver.resolve(
      asset.assetId,
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(first, isA<Success<ResolvedAsset>>());
    expect(source.openCount, 1);
    final firstPath = (first as Success<ResolvedAsset>).value.localPath;
    expect(await File(firstPath).exists(), isTrue);

    now = now.add(const Duration(days: 100));
    final cleanup = await AssetCacheRetentionManager(
      retention: retention,
      evictionStore: store,
      audioTtl: const Duration(days: 90),
      now: () => now,
    ).cleanupExpiredAudio();

    expect(cleanup, isA<Success<AssetRetentionCleanupReport>>());
    expect(
      (cleanup as Success<AssetRetentionCleanupReport>).value.evicted,
      1,
    );
    expect(await File(firstPath).exists(), isFalse);

    final second = await resolver.resolve(
      asset.assetId,
      policy: AssetResolutionPolicy.downloadIfMissing,
    );
    expect(second, isA<Success<ResolvedAsset>>());
    expect(source.openCount, 2);
    final secondPath = (second as Success<ResolvedAsset>).value.localPath;
    expect(secondPath, firstPath);
    expect(await File(secondPath).readAsBytes(), _bytes);
  });
}

final class _CountingSource implements AssetByteSource {
  int openCount = 0;

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    openCount += 1;
    return Success<AssetByteStream>(
      AssetByteStream(
        bytes: Stream<List<int>>.value(_bytes),
        contentLength: _bytes.length,
      ),
    );
  }
}

final class _Catalog implements AssetCatalogRepository {
  const _Catalog(this.asset);

  final ManifestAssetDescriptor asset;

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(String assetId) async {
    return Success<ManifestAssetDescriptor?>(
      asset.assetId == assetId ? asset : null,
    );
  }

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async => Success<ManifestAssetDescriptor?>(asset);
}

final class _MemoryRetentionRepository
    implements AssetCacheRetentionRepository {
  _MemoryRetentionRepository(this._now);

  final DateTime Function() _now;
  AssetRetentionEntry? entry;

  @override
  Future<Result<void>> recordAccess({
    required ManifestAssetDescriptor asset,
    AssetRetentionClass retentionClass = AssetRetentionClass.autoCache,
  }) async {
    final previous = entry;
    final effectiveClass =
        previous != null && previous.retentionClass != AssetRetentionClass.autoCache
        ? previous.retentionClass
        : retentionClass;
    entry = AssetRetentionEntry(
      asset: asset,
      retentionClass: effectiveClass,
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
        current.asset.requiredOffline ||
        !current.asset.mediaType.startsWith('audio/') ||
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
