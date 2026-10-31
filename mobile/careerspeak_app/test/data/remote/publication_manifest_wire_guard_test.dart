import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/publication_manifest_wire_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const guard = PublicationManifestWireGuard();

  test('accepts root publication-only shape', () {
    final result = guard.validateRoot(<String, Object?>{
      'schemaVersion': 1,
      'contentVersion': 109,
      'minimumAppContractVersion': 1,
      'publishedAt': '2026-10-31T15:00:00Z',
      'checksum': _shaA,
      'packs': <Object?>[],
      'practiceTests': <Object?>[],
      'catalogues': <Object?>[],
      'localeFallbacks': <Object?>[],
      'tombstones': <Object?>[],
    });

    expect(result, isA<Success<void>>());
  });

  test('rejects runtime ETag embedded into root body', () {
    final result = guard.validateRoot(<String, Object?>{
      'schemaVersion': 1,
      'contentVersion': 109,
      'minimumAppContractVersion': 1,
      'publishedAt': '2026-10-31T15:00:00Z',
      'checksum': _shaA,
      'packs': <Object?>[],
      'practiceTests': <Object?>[],
      'catalogues': <Object?>[],
      'localeFallbacks': <Object?>[],
      'tombstones': <Object?>[],
      'etag': 'runtime-etag',
    });

    expect(result, isA<FailureResult<void>>());
    final failure = (result as FailureResult<void>).failure;
    expect(failure.code, 'MANIFEST_NON_PUBLICATION_FIELD');
    expect(failure.details['field'], r'$.etag');
  });

  test('rejects security/runtime field nested in asset descriptor', () {
    final result = guard.validatePack(<String, Object?>{
      'schemaVersion': 1,
      'code': 'JAVA_SENIOR',
      'variant': 'canonical',
      'revision': 8,
      'checksum': _shaA,
      'contents': <Object?>[],
      'localizations': <Object?>[],
      'assets': <Object?>[
        <String, Object?>{
          'assetId': 'audio-q1',
          'checksumSha256': _shaB,
          'deliveryKey': 'audio/q1.mp3',
          'sizeBytes': 1024,
          'mediaType': 'audio/mpeg',
          'requiredOffline': true,
          'signedUrl': 'https://example.invalid/signed',
        },
      ],
      'contentAssets': <Object?>[],
    });

    expect(result, isA<FailureResult<void>>());
    final failure = (result as FailureResult<void>).failure;
    expect(failure.code, 'PACK_MANIFEST_NON_PUBLICATION_FIELD');
    expect(failure.details['field'], r'$.assets[0].signedUrl');
  });
}

const _shaA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _shaB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
