import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/root_manifest_materializer.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/content_manifest_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = ContentManifestDecoder();

  test(
    'materializer follows Backend rule instead of deriving base language',
    () {
      final decoded = decoder.decodeRoot(_rootManifest());
      expect(decoded, isA<Success<RootContentManifest>>());
      final root = decoded.getOrThrow();

      final projected = const RootManifestMaterializer()
          .materialize(root: root, translationLocale: 'ru-kz')
          .getOrThrow();

      expect(projected.contentVersion, root.contentVersion);
      expect(projected.checksum, root.checksum);
      expect(
        projected.packs.map((pack) => pack.identity.variant).toList(),
        <String>['canonical', 'locale:ru-KZ', 'locale:kk'],
      );
      expect(
        projected.packs.map((pack) => pack.identity.variant),
        isNot(contains('locale:ru')),
      );
    },
  );

  test('invalid Backend fallback metadata fails manifest decoding closed', () {
    final manifest = _rootManifest();
    manifest['localeFallbacks'] = <Object?>[
      <String, Object?>{
        'locale': 'ru-KZ',
        'fallbackLocales': <Object?>['ru-KZ', 'en'],
      },
    ];

    final result = decoder.decodeRoot(manifest);

    expect(result, isA<FailureResult<RootContentManifest>>());
    expect(
      (result as FailureResult<RootContentManifest>).failure.code,
      'MANIFEST_INVALID',
    );
  });
}

Map<String, Object?> _rootManifest() => <String, Object?>{
  'schemaVersion': 1,
  'contentVersion': 77,
  'minimumAppContractVersion': 1,
  'publishedAt': '2026-10-31T05:00:00Z',
  'checksum': _rootChecksum,
  'packs': <Object?>[
    _pack('canonical', 8, _canonicalPackChecksum),
    _pack('locale:ru-KZ', 3, _regionalPackChecksum),
    _pack('locale:ru', 5, _russianPackChecksum),
    _pack('locale:kk', 4, _kazakhPackChecksum),
  ],
  'practiceTests': <Object?>[],
  'catalogues': <Object?>[],
  'localeFallbacks': <Object?>[
    <String, Object?>{
      'locale': 'ru-KZ',
      'fallbackLocales': <Object?>['kk', 'en'],
    },
  ],
  'tombstones': <Object?>[],
};

Map<String, Object?> _pack(String variant, int revision, String checksum) =>
    <String, Object?>{
      'code': 'JAVA_SENIOR',
      'variant': variant,
      'revision': revision,
      'checksum': checksum,
    };

const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _canonicalPackChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _regionalPackChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _russianPackChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _kazakhPackChecksum =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
