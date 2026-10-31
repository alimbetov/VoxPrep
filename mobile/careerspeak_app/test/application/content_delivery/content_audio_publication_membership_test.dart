import 'package:careerspeak_app/application/content_delivery/content_audio_policy.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/publication_revision_membership.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _packChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _contentChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _assetChecksum1 =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _assetChecksum2 =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  test('accepts independent interview question and sample-answer audio', () {
    final manifest = _manifest(
      type: ContentType.interview,
      bindings: <ContentAssetRef>[
        _binding(
          ContentType.interview,
          'audio-question',
          ContentAudioRole.question,
        ),
        _binding(
          ContentType.interview,
          'audio-answer',
          ContentAudioRole.sampleAnswer,
        ),
      ],
      assets: <ManifestAssetDescriptor>[
        _asset('audio-question', _assetChecksum1),
        _asset('audio-answer', _assetChecksum2),
      ],
    );

    expect(() => _membership(manifest), returnsNormally);
  });

  test('rejects schema v2 shadowing without its required audio role', () {
    final manifest = _manifest(
      type: ContentType.shadowing,
      bindings: const <ContentAssetRef>[],
      assets: const <ManifestAssetDescriptor>[],
    );

    expect(() => _membership(manifest), throwsArgumentError);
  });

  test('rejects an audio role that belongs to another content type', () {
    final manifest = _manifest(
      type: ContentType.topic,
      bindings: <ContentAssetRef>[
        _binding(
          ContentType.topic,
          'audio-answer',
          ContentAudioRole.sampleAnswer,
        ),
      ],
      assets: <ManifestAssetDescriptor>[
        _asset('audio-answer', _assetChecksum1),
      ],
    );

    expect(() => _membership(manifest), throwsArgumentError);
  });

  test('rejects two assets for the same exact audio role', () {
    final manifest = _manifest(
      type: ContentType.interview,
      bindings: <ContentAssetRef>[
        _binding(ContentType.interview, 'audio-q1', ContentAudioRole.question),
        _binding(ContentType.interview, 'audio-q2', ContentAudioRole.question),
      ],
      assets: <ManifestAssetDescriptor>[
        _asset('audio-q1', _assetChecksum1),
        _asset('audio-q2', _assetChecksum2),
      ],
    );

    expect(() => _membership(manifest), throwsArgumentError);
  });

  test(
    'allows legacy promptAudio to satisfy v1 required audio during migration',
    () {
      final identity = const ContentIdentity(
        code: 'CONTENT_1',
        type: ContentType.shadowing,
      );
      final packIdentity = PackIdentity(code: 'PACK', variant: 'canonical');
      final manifest = PackContentManifest(
        schemaVersion: 1,
        identity: packIdentity,
        revision: 1,
        checksum: _packChecksum,
        contents: <PackContentRef>[
          PackContentRef(
            identity: identity,
            revision: 1,
            checksum: _contentChecksum,
            sortOrder: 0,
          ),
        ],
        assets: <ManifestAssetDescriptor>[
          _asset('legacy-audio', _assetChecksum1),
        ],
        contentAssets: <ContentAssetRef>[
          ContentAssetRef(
            contentIdentity: identity,
            contentRevision: 1,
            assetId: 'legacy-audio',
            role: 'promptAudio',
          ),
        ],
      );

      expect(() => _membership(manifest), returnsNormally);
    },
  );
}

PackContentManifest _manifest({
  required ContentType type,
  required List<ContentAssetRef> bindings,
  required List<ManifestAssetDescriptor> assets,
}) {
  return PackContentManifest(
    schemaVersion: 2,
    identity: PackIdentity(code: 'PACK', variant: 'canonical'),
    revision: 1,
    checksum: _packChecksum,
    contents: <PackContentRef>[
      PackContentRef(
        identity: ContentIdentity(code: 'CONTENT_1', type: type),
        revision: 1,
        checksum: _contentChecksum,
        sortOrder: 0,
      ),
    ],
    assets: assets,
    contentAssets: bindings,
  );
}

PublicationRevisionMembership _membership(PackContentManifest manifest) {
  return PublicationRevisionMembership(
    packs: <PackRevisionRef>[
      PackRevisionRef(
        identity: manifest.identity,
        revision: manifest.revision,
        checksum: manifest.checksum,
      ),
    ],
    packManifests: <PackContentManifest>[manifest],
  );
}

ContentAssetRef _binding(
  ContentType type,
  String assetId,
  ContentAudioRole role,
) {
  return ContentAssetRef(
    contentIdentity: ContentIdentity(code: 'CONTENT_1', type: type),
    contentRevision: 1,
    assetId: assetId,
    role: role.wireName,
  );
}

ManifestAssetDescriptor _asset(String assetId, String checksum) {
  return ManifestAssetDescriptor(
    assetId: assetId,
    checksumSha256: checksum,
    deliveryKey: 'audio/$assetId.mp3',
    sizeBytes: 1024,
    mediaType: 'audio/mpeg',
    requiredOffline: false,
  );
}
