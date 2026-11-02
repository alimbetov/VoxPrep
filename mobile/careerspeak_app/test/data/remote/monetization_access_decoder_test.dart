import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/data/remote/universal_catalogue_decoder_registry.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  const registry = UniversalCatalogueDecoderRegistry();

  test('legacy v2 collection without accessLevel fails closed to FULL', () {
    final decoded = registry.decode(
      _payload(_collection()),
    ) as List<LearningCollectionProjection>;

    expect(decoded.single.accessLevel, AccessLevel.full);
    expect(decoded.single.requiresFullAccess, isTrue);
  });

  test('explicit v3 FREE collection is decoded as FREE', () {
    final decoded = registry.decode(
      _payload(_collection(accessLevel: 'FREE')),
    ) as List<LearningCollectionProjection>;

    expect(decoded.single.accessLevel, AccessLevel.free);
    expect(decoded.single.requiresFullAccess, isFalse);
  });

  test('explicit v3 FULL collection is decoded as FULL', () {
    final decoded = registry.decode(
      _payload(_collection(accessLevel: 'FULL')),
    ) as List<LearningCollectionProjection>;

    expect(decoded.single.accessLevel, AccessLevel.full);
  });

  test('unknown accessLevel is rejected instead of inferred', () {
    expect(
      () => registry.decode(_payload(_collection(accessLevel: 'TRIAL'))),
      throwsFormatException,
    );
  });

  test('access is never inferred from collection ordering', () {
    final first = _collection(
      code: 'COLLECTION_FIRST',
      sortOrder: 0,
      accessLevel: 'FULL',
    );
    final second = _collection(
      code: 'COLLECTION_SECOND',
      sortOrder: 1,
      accessLevel: 'FREE',
    );

    final decoded = registry.decode(
      _payload(first, additional: <Object>[second]),
    ) as List<LearningCollectionProjection>;

    expect(decoded[0].accessLevel, AccessLevel.full);
    expect(decoded[1].accessLevel, AccessLevel.free);
  });
}

Map<String, dynamic> _collection({
  String code = 'COLLECTION_ALPHA',
  int sortOrder = 0,
  String? accessLevel,
}) {
  return <String, dynamic>{
    'code': code,
    'verticalCode': 'VERTICAL_ALPHA',
    'trackCode': 'TRACK_ALPHA',
    'title': 'Collection',
    'description': 'Collection description',
    if (accessLevel != null) 'accessLevel': accessLevel,
    'sortOrder': sortOrder,
    'active': true,
    'members': <Object>[
      <String, dynamic>{
        'position': 0,
        'type': 'CONTENT',
        'content': <String, dynamic>{
          'contentCode': '${code}_CONTENT',
          'contentType': 'topic',
          'revision': 1,
          'checksum': _hash,
        },
        'practiceTest': null,
      },
    ],
  };
}

CataloguePayload _payload(
  Map<String, dynamic> first, {
  List<Object> additional = const <Object>[],
}) {
  final items = <Object>[first, ...additional];
  final ref = CatalogueRevisionRef(
    kind: CatalogueKind.learningCollections,
    revision: 1,
    checksum: _hash,
  );
  return CataloguePayload(
    ref: ref,
    items: items,
    wireJson: <String, Object?>{
      'kind': CatalogueKind.learningCollections.wireName,
      'revision': 1,
      'checksum': _hash,
      'items': items,
    },
  );
}
