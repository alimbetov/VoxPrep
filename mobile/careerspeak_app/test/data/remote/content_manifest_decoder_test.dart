import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/content_manifest_decoder.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const decoder = ContentManifestDecoder();

  group('ContentManifestDecoder', () {
    test('decodes schema v1 root manifest with typed tombstones', () {
      final result = decoder.decodeRoot(_rootManifest());

      expect(result, isA<Success<RootContentManifest>>());
      final manifest = (result as Success<RootContentManifest>).value;
      expect(manifest.contentVersion, 108);
      expect(manifest.minimumAppContractVersion, 1);
      expect(manifest.publishedAt, DateTime.utc(2026, 10, 30, 9, 30));
      expect(
        manifest.packs.single.identity.toString(),
        'JAVA_SENIOR/canonical',
      );
      expect(manifest.tombstones.single.identity.type, ContentType.interview);
    });

    test('future schema is classified before deeper payload decoding', () {
      final result = decoder.decodeRoot(<String, Object?>{
        'schemaVersion': 2,
        'minimumAppContractVersion': 1,
      });

      expect(result, isA<FailureResult<RootContentManifest>>());
      final failure = (result as FailureResult<RootContentManifest>).failure;
      expect(failure.code, 'SCHEMA_UNSUPPORTED');
      expect(failure.details['remoteSchemaVersion'], 2);
    });

    test('newer app contract requirement fails closed', () {
      final manifest = _rootManifest()..['minimumAppContractVersion'] = 2;
      final result = decoder.decodeRoot(manifest);

      expect(result, isA<FailureResult<RootContentManifest>>());
      expect(
        (result as FailureResult<RootContentManifest>).failure.code,
        'APP_UPDATE_REQUIRED',
      );
    });

    test('tombstone without content type is rejected', () {
      final manifest = _rootManifest();
      final tombstone =
          (manifest['tombstones'] as List<Object?>).single
              as Map<String, Object?>;
      tombstone.remove('contentType');

      final result = decoder.decodeRoot(manifest);

      expect(result, isA<FailureResult<RootContentManifest>>());
      final failure = (result as FailureResult<RootContentManifest>).failure;
      expect(failure.code, 'MANIFEST_INVALID');
      expect(failure.details['field'], r'$.tombstones[0].contentType');
    });

    test('non-UTC manifest timestamp is rejected', () {
      final manifest = _rootManifest()
        ..['publishedAt'] = '2026-10-30T14:30:00+05:00';

      final result = decoder.decodeRoot(manifest);

      expect(result, isA<FailureResult<RootContentManifest>>());
      expect(
        (result as FailureResult<RootContentManifest>).failure.code,
        'MANIFEST_INVALID',
      );
    });

    test(
      'calendar-invalid UTC timestamp is rejected rather than normalized',
      () {
        final manifest = _rootManifest()
          ..['publishedAt'] = '2026-02-31T09:30:00Z';

        final result = decoder.decodeRoot(manifest);

        expect(result, isA<FailureResult<RootContentManifest>>());
        expect(
          (result as FailureResult<RootContentManifest>).failure.code,
          'MANIFEST_INVALID',
        );
      },
    );

    test('decodes pack manifest and verifies reference graph shape', () {
      final result = decoder.decodePack(_packManifest());

      expect(result, isA<Success<PackContentManifest>>());
      final manifest = (result as Success<PackContentManifest>).value;
      expect(manifest.identity.toString(), 'JAVA_SENIOR/canonical');
      expect(manifest.contents.single.identity.type, ContentType.interview);
      expect(manifest.assets.single.requiredOffline, isTrue);
      expect(manifest.contentAssets.single.role, 'audio');
    });

    test('future pack schema fails before deeper pack decoding', () {
      final result = decoder.decodePack(<String, Object?>{'schemaVersion': 2});

      expect(result, isA<FailureResult<PackContentManifest>>());
      expect(
        (result as FailureResult<PackContentManifest>).failure.code,
        'SCHEMA_UNSUPPORTED',
      );
    });

    test('invalid pack schema uses pack-specific failure code', () {
      final result = decoder.decodePack(<String, Object?>{'schemaVersion': 0});

      expect(result, isA<FailureResult<PackContentManifest>>());
      expect(
        (result as FailureResult<PackContentManifest>).failure.code,
        'PACK_MANIFEST_INVALID',
      );
    });

    test('unsupported content type is rejected', () {
      final manifest = _packManifest();
      final content =
          (manifest['contents'] as List<Object?>).single
              as Map<String, Object?>;
      content['contentType'] = 'future_type';

      final result = decoder.decodePack(manifest);

      expect(result, isA<FailureResult<PackContentManifest>>());
      expect(
        (result as FailureResult<PackContentManifest>).failure.code,
        'PACK_MANIFEST_INVALID',
      );
    });

    test('dangling pack asset reference is rejected', () {
      final manifest = _packManifest();
      final ref =
          (manifest['contentAssets'] as List<Object?>).single
              as Map<String, Object?>;
      ref['assetId'] = 'missing-asset';

      final result = decoder.decodePack(manifest);

      expect(result, isA<FailureResult<PackContentManifest>>());
      expect(
        (result as FailureResult<PackContentManifest>).failure.code,
        'PACK_MANIFEST_INVALID',
      );
    });
  });
}

Map<String, Object?> _rootManifest() {
  return <String, Object?>{
    'schemaVersion': 1,
    'contentVersion': 108,
    'minimumAppContractVersion': 1,
    'publishedAt': '2026-10-30T09:30:00Z',
    'checksum': _shaA,
    'packs': <Object?>[
      <String, Object?>{
        'code': 'JAVA_SENIOR',
        'variant': 'canonical',
        'revision': 8,
        'checksum': _shaB,
      },
    ],
    'tombstones': <Object?>[
      <String, Object?>{
        'contentCode': 'JAVA_QUESTION_001',
        'contentType': 'interview',
        'revision': 3,
        'reason': 'INACTIVE',
      },
    ],
  };
}

Map<String, Object?> _packManifest() {
  return <String, Object?>{
    'schemaVersion': 1,
    'code': 'JAVA_SENIOR',
    'variant': 'canonical',
    'revision': 8,
    'checksum': _shaB,
    'contents': <Object?>[
      <String, Object?>{
        'contentCode': 'JAVA_QUESTION_001',
        'contentType': 'interview',
        'revision': 3,
        'checksum': _shaC,
        'sortOrder': 10,
        'publishedAt': '2026-10-29T11:00:00Z',
      },
    ],
    'localizations': <Object?>[],
    'assets': <Object?>[
      <String, Object?>{
        'assetId': 'asset-1',
        'checksumSha256': _shaD,
        'deliveryKey': 'audio/java/question-001.mp3',
        'sizeBytes': 2048,
        'mediaType': 'audio/mpeg',
        'requiredOffline': true,
      },
    ],
    'contentAssets': <Object?>[
      <String, Object?>{
        'contentCode': 'JAVA_QUESTION_001',
        'contentType': 'interview',
        'contentRevision': 3,
        'assetId': 'asset-1',
        'role': 'audio',
      },
    ],
  };
}

const _shaA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _shaB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _shaC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _shaD =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
