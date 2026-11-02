import 'package:careerspeak_app/app/asset_resolver_providers.dart';
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
import 'package:careerspeak_app/features/shared/content_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _content = ContentIdentity(code: 'TOPIC_1', type: ContentType.topic);
const _hostKey = Key('content-cover-host');

void main() {
  testWidgets('missing cover reserves no layout space', (tester) async {
    await _pump(
      tester,
      binding: const Success<ManifestAssetDescriptor?>(null),
      localPath: null,
      imageBuilder: _visibleImage,
    );

    expect(tester.getSize(find.byKey(_hostKey)), Size.zero);
  });

  testWidgets('decode failure collapses instead of showing a placeholder', (
    tester,
  ) async {
    await _pump(
      tester,
      binding: Success<ManifestAssetDescriptor?>(_descriptor()),
      localPath: '/verified/cover.png',
      imageBuilder: _collapsedImage,
    );

    expect(tester.getSize(find.byKey(_hostKey)), Size.zero);
  });

  testWidgets('valid verified cover occupies its requested layout', (
    tester,
  ) async {
    await _pump(
      tester,
      binding: Success<ManifestAssetDescriptor?>(_descriptor()),
      localPath: '/verified/cover.png',
      imageBuilder: _visibleImage,
    );

    expect(tester.getSize(find.byKey(_hostKey)), const Size(160, 80));
    expect(find.byKey(const Key('decoded-cover')), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Result<ManifestAssetDescriptor?> binding,
  required String? localPath,
  required ContentCoverImageBuilder imageBuilder,
}) async {
  final store = _Store(localPath);
  final resolver = ContentCoverResolver(
    AssetResolver(
      catalog: _Catalog(binding),
      store: store,
      downloads: AssetDownloadManager(
        source: const _NeverSource(),
        store: store,
        maxAttempts: 1,
      ),
    ),
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentCoverResolverProvider.overrideWith((ref) async => resolver),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: Container(
              key: _hostKey,
              child: ContentCover(
                content: _content,
                revision: 3,
                width: 160,
                height: 80,
                imageBuilder: imageBuilder,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump();
}

Widget _visibleImage({
  required BuildContext context,
  required String localPath,
  required double? width,
  required double? height,
  required BoxFit fit,
  required BorderRadius borderRadius,
  required String? semanticLabel,
}) {
  return SizedBox(
    key: const Key('decoded-cover'),
    width: width,
    height: height,
  );
}

Widget _collapsedImage({
  required BuildContext context,
  required String localPath,
  required double? width,
  required double? height,
  required BoxFit fit,
  required BorderRadius borderRadius,
  required String? semanticLabel,
}) {
  return const SizedBox.shrink();
}

ManifestAssetDescriptor _descriptor() {
  return ManifestAssetDescriptor(
    assetId: 'cover-1',
    checksumSha256: _hash,
    deliveryKey: 'images/cover.png',
    sizeBytes: 1,
    mediaType: 'image/png',
    requiredOffline: false,
  );
}

final class _Catalog implements AssetCatalogRepository {
  const _Catalog(this.binding);

  final Result<ManifestAssetDescriptor?> binding;

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(
    String assetId,
  ) async {
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
