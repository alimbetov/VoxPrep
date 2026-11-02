import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/content_visual_policy.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  final identity = ContentIdentity(code: 'CONTENT', type: ContentType.topic);

  test('cover image is preview-safe and uses stable wire role', () {
    expect(ContentVisualRole.coverImage.wireName, 'coverImage');
    expect(
      ContentVisualRole.fromWireName('coverImage'),
      ContentVisualRole.coverImage,
    );
    expect(ContentVisualRole.fromWireName('unknown'), isNull);
    expect(
      ContentVisualPolicy.isPreviewSafe(ContentVisualRole.coverImage),
      isTrue,
    );
  });

  test('no cover image is a valid state', () {
    final cover = ContentVisualPolicy.resolveCover(
      refs: const <ContentAssetRef>[],
      assets: const <ManifestAssetDescriptor>[],
    );

    expect(cover, isNull);
  });

  test('resolves one exact-revision cover through manifest asset metadata', () {
    final ref = ContentAssetRef(
      contentIdentity: identity,
      contentRevision: 3,
      assetId: 'cover-1',
      role: ContentVisualRole.coverImage.wireName,
    );
    final asset = ManifestAssetDescriptor(
      assetId: 'cover-1',
      checksumSha256: _hash,
      deliveryKey: 'images/content-cover.webp',
      sizeBytes: 100000,
      mediaType: 'image/webp',
      requiredOffline: false,
    );

    final cover = ContentVisualPolicy.resolveCover(
      refs: <ContentAssetRef>[ref],
      assets: <ManifestAssetDescriptor>[asset],
    );

    expect(cover, isNotNull);
    expect(cover!.ref.contentRevision, 3);
    expect(cover.asset.assetId, 'cover-1');
    expect(cover.asset.checksumSha256, _hash);
  });

  test('rejects duplicate cover refs for one exact revision', () {
    final first = ContentAssetRef(
      contentIdentity: identity,
      contentRevision: 3,
      assetId: 'cover-1',
      role: ContentVisualRole.coverImage.wireName,
    );
    final second = ContentAssetRef(
      contentIdentity: identity,
      contentRevision: 3,
      assetId: 'cover-2',
      role: ContentVisualRole.coverImage.wireName,
    );

    expect(
      () => ContentVisualPolicy.resolveCover(
        refs: <ContentAssetRef>[first, second],
        assets: <ManifestAssetDescriptor>[],
      ),
      throwsFormatException,
    );
  });

  test('rejects missing or unsupported cover asset metadata', () {
    final ref = ContentAssetRef(
      contentIdentity: identity,
      contentRevision: 3,
      assetId: 'cover-1',
      role: ContentVisualRole.coverImage.wireName,
    );

    expect(
      () => ContentVisualPolicy.resolveCover(
        refs: <ContentAssetRef>[ref],
        assets: const <ManifestAssetDescriptor>[],
      ),
      throwsFormatException,
    );

    final unsupported = ManifestAssetDescriptor(
      assetId: 'cover-1',
      checksumSha256: _hash,
      deliveryKey: 'images/content-cover.svg',
      sizeBytes: 1000,
      mediaType: 'image/svg+xml',
      requiredOffline: false,
    );

    expect(
      () => ContentVisualPolicy.resolveCover(
        refs: <ContentAssetRef>[ref],
        assets: <ManifestAssetDescriptor>[unsupported],
      ),
      throwsFormatException,
    );
  });

  test('supports only WebP JPEG and PNG covers in v1', () {
    expect(ContentVisualPolicy.isSupportedCoverMediaType('image/webp'), isTrue);
    expect(ContentVisualPolicy.isSupportedCoverMediaType('image/jpeg'), isTrue);
    expect(ContentVisualPolicy.isSupportedCoverMediaType('image/png'), isTrue);
    expect(
      ContentVisualPolicy.isSupportedCoverMediaType('image/svg+xml'),
      isFalse,
    );
    expect(ContentVisualPolicy.isSupportedCoverMediaType('video/mp4'), isFalse);
  });
}
