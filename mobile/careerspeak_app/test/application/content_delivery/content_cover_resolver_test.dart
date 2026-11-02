import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/asset_byte_source.dart';
import 'package:careerspeak_app/application/ports/asset_catalog_repository.dart';
import 'package:careerspeak_app/application/ports/asset_file_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:careerspeak_app/application/services/asset_resolver.dart';
import 'package:careerspeak_app/application/services/content_cover_resolver.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _content = ContentIdentity(code: 'TOPIC_1', type: ContentType.topic);

void main() {
  test('absence of a cover binding is a valid collapsed state', () async {
    final resolver = _coverResolver(
      const Success<ManifestAssetDescriptor?>(null),
      localPath: null,
    );

    final cover = await resolver.resolve(
      content: _content,
      revision: 3,
      policy: AssetResolutionPolicy.localOnly,
    );

    expect(cover, isNull);
  });

  test('missing verified local cover fails soft', () async {
    final resolver = _coverResolver(
      Success<ManifestAssetDescriptor?>(_descriptor('image/png')),
      localPath: null,
    );

    final cover = await resolver.resolve(
      content: _content,
      revision: 3,
      policy: AssetResolutionPolicy.localOnly,
    );

    expect(cover, isNull);
  });

  test('supported verified cover resolves through AssetResolver', () async {
    final resolver = _coverResolver(
      Success<ManifestAssetDescriptor?>(_descriptor('image/webp')),
      localPath: '/verified/cover.webp',
    );

    final cover = await resolver.resolve(
      content: _content,
      revision: 3,
      policy: AssetResolutionPolicy.localOnly,
    );

    expect(cover, isNotNull);
    expect(cover!.assetId, 'cover-1');
    expect(cover.localPath, '/verified/cover.webp');
    expect(cover.mediaType, 'image/webp');
  });

  test('non-image and unsupported image media both fail soft', () async {
    for (final mediaType in <String>['audio/mpeg', 'image/gif']) {
      final resolver = _coverResolver(
        Success<ManifestAssetDescriptor?>(_descriptor(mediaType)),
        localPath: '/verified/cover.bin',
      );

      final cover = await resolver.resolve(
        content: _content,
        revision: 3,
        policy: AssetResolutionPolicy.localOnly,
      );

      expect(cover, isNull, reason: mediaType);
    }
  });
}

ContentCoverResolver _coverResolver(
  Result<ManifestAssetDescriptor?> binding, {
  required String? localPath,
}) {
  final store = _Store(localPath);
  final assets = AssetResolver(
    catalog: _Catalog(binding),
    store: store,
    downloads: AssetDownloadManager(
      source: const _NeverSource(),
      store: store,
      maxAttempts: 1,
    ),
  );
  return ContentCoverResolver(assets);
}

ManifestAssetDescriptor _descriptor(String mediaType) {
  return ManifestAssetDescriptor(
    assetId: 'cover-1',
    checksumSha256: _hash,
    deliveryKey: 'images/cover.bin',
    sizeBytes: 1,
    mediaType: mediaType,
    requiredOffline: false,
  );
}

final class _Catalog implements AssetCatalogRepository {
  const _Catalog(this.binding);

  final Result<ManifestAssetDescriptor?> binding;

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(String assetId) async {
    return binding;
  }

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) async {
    return binding;
  }
}

final class _Store implements AssetFileStore {
  const _Store(this.localPath);

  final String? localPath;

  @override
  Future<Result<String?>> findVerified(ManifestAssetDescriptor asset) async {
    return Success<String?>(localPath);
  }

  @override
  Future<Result<String>> writeVerified({
    required ManifestAssetDescriptor asset,
    required Stream<List<int>> bytes,
  }) {
    throw UnsupportedError('download is not expected in this test');
  }
}

final class _NeverSource implements AssetByteSource {
  const _NeverSource();

  @override
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset) {
    throw UnsupportedError('network is not expected in this test');
  }
}
