import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/data/remote/universal_catalogue_decoder_registry.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  const registry = UniversalCatalogueDecoderRegistry();

  test('decodes arbitrary future vertical ownership in learning goal', () {
    final decoded = registry.decode(
      _payload(
        CatalogueKind.learningGoals,
        <Object>[
          <String, dynamic>{
            'code': 'GOAL_ALPHA',
            'verticalCode': 'FUTURE_VERTICAL_2030',
            'title': 'Goal',
            'description': 'Goal description',
            'sortOrder': 0,
            'active': true,
          },
        ],
      ),
    ) as List<LearningGoalProjection>;

    expect(decoded.single.verticalCode, 'FUTURE_VERTICAL_2030');
  });

  test('decodes typed track without vertical-specific branching', () {
    final decoded = registry.decode(
      _payload(
        CatalogueKind.learningTracks,
        <Object>[
          <String, dynamic>{
            'code': 'TRACK_ALPHA',
            'verticalCode': 'VERTICAL_ALPHA',
            'goalCode': 'GOAL_ALPHA',
            'title': 'Track',
            'description': 'Track description',
            'levelCode': 'B2',
            'careerTrackCode': null,
            'sortOrder': 0,
            'active': true,
          },
        ],
      ),
    ) as List<LearningTrackProjection>;

    expect(decoded.single.goalCode, 'GOAL_ALPHA');
    expect(decoded.single.verticalCode, 'VERTICAL_ALPHA');
  });

  test('decodes exact collection revision refs', () {
    final decoded = registry.decode(
      _payload(
        CatalogueKind.learningCollections,
        <Object>[
          <String, dynamic>{
            'code': 'COLLECTION_ALPHA',
            'verticalCode': 'VERTICAL_ALPHA',
            'trackCode': 'TRACK_ALPHA',
            'title': 'Collection',
            'description': 'Collection description',
            'sortOrder': 0,
            'active': true,
            'contentRefs': <Object>[
              <String, dynamic>{
                'contentCode': 'CONTENT_ALPHA',
                'contentType': 'topic',
                'revision': 2,
                'checksum': _hash,
              },
            ],
            'practiceTestRefs': <Object>[],
          },
        ],
      ),
    ) as List<LearningCollectionProjection>;

    expect(decoded.single.contentRefs.single.revision, 2);
    expect(decoded.single.contentRefs.single.contentCode, 'CONTENT_ALPHA');
  });

  test('rejects mutable/runtime fields in graph catalogue item', () {
    expect(
      () => registry.decode(
        _payload(
          CatalogueKind.learningGoals,
          <Object>[
            <String, dynamic>{
              'code': 'GOAL_ALPHA',
              'verticalCode': 'VERTICAL_ALPHA',
              'title': 'Goal',
              'description': 'Goal description',
              'sortOrder': 0,
              'active': true,
              'downloadProgress': 0.4,
            },
          ],
        ),
      ),
      throwsFormatException,
    );
  });

  test('rejects duplicate graph business codes', () {
    final item = <String, dynamic>{
      'code': 'GOAL_ALPHA',
      'verticalCode': 'VERTICAL_ALPHA',
      'title': 'Goal',
      'description': 'Goal description',
      'sortOrder': 0,
      'active': true,
    };

    expect(
      () => registry.decode(
        _payload(CatalogueKind.learningGoals, <Object>[item, item]),
      ),
      throwsFormatException,
    );
  });
}

CataloguePayload _payload(CatalogueKind kind, List<Object> items) {
  final ref = CatalogueRevisionRef(kind: kind, revision: 1, checksum: _hash);
  return CataloguePayload(
    ref: ref,
    items: items,
    wireJson: <String, Object?>{
      'kind': kind.wireName,
      'revision': 1,
      'checksum': _hash,
      'items': items,
    },
  );
}
