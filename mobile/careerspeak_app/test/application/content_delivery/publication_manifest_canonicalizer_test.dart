import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/publication_manifest_canonicalizer.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _shaA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _shaB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _shaC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  const canonicalizer = PublicationManifestCanonicalizer();

  test('root digest is deterministic and excludes declared checksum', () {
    final first = _root(checksum: _shaA);
    final second = _root(checksum: _shaB);

    expect(canonicalizer.rootDigest(first), canonicalizer.rootDigest(second));
    expect(canonicalizer.rootDigest(first), hasLength(64));
  });

  test('root digest changes when exact membership changes', () {
    final first = _root(checksum: _shaA, packRevision: 8);
    final second = _root(checksum: _shaA, packRevision: 9);

    expect(
      canonicalizer.rootDigest(first),
      isNot(canonicalizer.rootDigest(second)),
    );
  });

  test('pack digest is deterministic and excludes declared checksum', () {
    final first = _pack(checksum: _shaA);
    final second = _pack(checksum: _shaB);

    expect(canonicalizer.packDigest(first), canonicalizer.packDigest(second));
  });

  test('pack digest changes when immutable asset metadata changes', () {
    final first = _pack(checksum: _shaA, deliveryKey: 'audio/q1-r1.mp3');
    final second = _pack(checksum: _shaA, deliveryKey: 'audio/q1-r1-v2.mp3');

    expect(
      canonicalizer.packDigest(first),
      isNot(canonicalizer.packDigest(second)),
    );
  });
}

RootContentManifest _root({required String checksum, int packRevision = 8}) {
  return RootContentManifest(
    schemaVersion: 1,
    contentVersion: 109,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 31, 15),
    checksum: checksum,
    packs: <PackRevisionRef>[
      PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
        revision: packRevision,
        checksum: _shaC,
      ),
    ],
    tombstones: const <ContentTombstone>[],
  );
}

PackContentManifest _pack({
  required String checksum,
  String deliveryKey = 'audio/q1-r1.mp3',
}) {
  final identity = ContentIdentity(
    code: 'JAVA_Q_001',
    type: ContentType.interview,
  );
  return PackContentManifest(
    schemaVersion: 1,
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: 8,
    checksum: checksum,
    contents: <PackContentRef>[
      PackContentRef(
        identity: identity,
        revision: 1,
        checksum: _shaB,
        sortOrder: 1,
        publishedAt: DateTime.utc(2026, 10, 31, 14),
      ),
    ],
    assets: <ManifestAssetDescriptor>[
      ManifestAssetDescriptor(
        assetId: 'audio-q1',
        checksumSha256: _shaC,
        deliveryKey: deliveryKey,
        sizeBytes: 1024,
        mediaType: 'audio/mpeg',
        requiredOffline: true,
      ),
    ],
    contentAssets: <ContentAssetRef>[
      ContentAssetRef(
        contentIdentity: identity,
        contentRevision: 1,
        assetId: 'audio-q1',
        role: 'promptAudio',
      ),
    ],
  );
}
