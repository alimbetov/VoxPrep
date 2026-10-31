import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/ports/asset_file_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _sha =
    '2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824';
const _content = ContentIdentity(code: 'ITEM_1', type: ContentType.interview);

void main() {
  test('catalogue image uses managed download path and becomes local', () async {
    final source = _Source();
    final store = _Store();
    final resolver = _resolver(
      source: source,
      store: store,
      byId: _asset('icon-1', 'image/png', 'icons/icon-1.png'),
    );

    final result = await resolver.resolveImage(
      'icon-1',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );

    expect(result.getOrThrow().mediaType, 'image/png');
    expect(result.getOrThrow().localPath, '/verified/icon-1');
    expect(source.calls, 1);
    expect(store.writes, 1);
  });

  test('catalogue image rejects non-image before network access', () async {
    final source = _Source();
    final store = _Store();
    final resolver = _resolver(
      source: source,
      store: store,
      byId: _asset('bad-icon', 'audio/mpeg', 'audio/bad.mp3'),
    );

    final result = await resolver.resolveImage(
      'bad-icon',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );

    expect(_failureCode(result), 'ASSET_MEDIA_TYPE_MISMATCH');
    expect(source.calls, 0);
    expect(store.writes, 0);
  });

  test('content audio uses managed download path and becomes local', () async {
    final source = _Source();
    final store = _Store();
    final resolver = _resolver(
      source: source,
      store: store,
      forContent: _asset('audio-1', 'audio/mpeg', 'audio/audio-1.mp3'),
    );

    final result = await resolver.resolveAudioContent(
      content: _content,
      revision: 1,
      role: 'QUESTION',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );

    expect(result.getOrThrow().mediaType, 'audio/mpeg');
    expect(result.getOrThrow().localPath, '/verified/audio-1');
    expect(source.calls, 1);
    expect(store.writes, 1);
  });

  test('content audio rejects non-audio before network access', () async {
    final source = _Source();
    final store = _Store();
    final resolver = _resolver(
      source: source,
      store: store,
      forContent: _asset('bad-audio', 'image/png', 'icons/bad.png'),
    );

    final result = await resolver.resolveAudioContent(
      content: _content,
      revision: 1,
      role: 'QUESTION',
      policy: AssetResolutionPolicy.downloadIfMissing,
    );

    expect(_failureCode(result), 'ASSET_MEDIA_TYPE_MISMATCH');
    expect(source.calls, 0);
    expect(store.writes, 0);
  });
}

AssetResolver _resolver({
  required _Source source,
  required _Store store,
  ManifestAssetDescriptor? byId,
  ManifestAssetDescriptor? forContent,
}) {
  return AssetResolver(
    catalog: _Catalog(byId: byId, forContent: forContent),
    store: store,
    downloads: AssetDownloadManager(
      source: source,
      store: store,
      maxAttempts: 1,
    ),
  );
}

ManifestAssetDescriptor _asset(String id, String mediaType, String deliveryKey) {
  return ManifestAssetDescriptor(
    assetId: id,
    checksumSha256: _sha,
    deliveryKey: deliveryKey,
    sizeBytes: 5,
    mediaType: mediaType,
    requiredOffline: false,
  );
}

String _failureCode(Result<ResolvedAsset> result) =>
    (result as FailureResult<ResolvedAsset>).failure.code;

final class _Catalog implements AssetCatalogRepository {
  const _Catalog({this.byId, this.forContent});

  final ManifestAssetDescriptor? byId;
  final ManifestAssetDescriptor? forContent;

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(String assetId) async {
    return Success(byId);
  }

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async {
    return Success(forContent);
  }
}

final class _Source implements AssetByteSource {
  int calls = 0;

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) async {
    calls += 1;
    return Success(
      AssetByteStream(
        bytes: Stream<List<int>>.value('hello'.codeUnits),
        contentLength: 5,
      ),
    );
  }
}

final class _Store implements AssetFileStore {
  int writes = 0;
  final _paths = <String, String>{};

  @override
  Future<Result<String?>> findVerified(ManifestAssetDescriptor asset) async {
    return Success(_paths[asset.assetId]);
  }

  @override
  Future<Result<String>> writeVerified({
    required ManifestAssetDescriptor asset,
    required Stream<List<int>> bytes,
  }) async {
    await bytes.drain<void>();
    writes += 1;
    final path = '/verified/${asset.assetId}';
    _paths[asset.assetId] = path;
    return Success(path);
  }
}
