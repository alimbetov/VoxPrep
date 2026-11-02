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
    final decoded =
        registry.decode(
              _payload(CatalogueKind.learningGoals, <Object>[
                <String, dynamic>{
                  'code': 'GOAL_ALPHA',
                  'verticalCode': 'FUTURE_VERTICAL_2030',
                  'title': 'Goal',
                  'description': 'Goal description',
                  'sortOrder': 0,
                  'active': true,
                },
              ]),
            )
            as List<LearningGoalProjection>;

    expect(decoded.single.verticalCode, 'FUTURE_VERTICAL_2030');
  });

  test('decodes typed track without vertical-specific branching', () {
    final decoded =
        registry.decode(
              _payload(CatalogueKind.learningTracks, <Object>[
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
              ]),
            )
            as List<LearningTrackProjection>;

    expect(decoded.single.goalCode, 'GOAL_ALPHA');
    expect(decoded.single.verticalCode, 'VERTICAL_ALPHA');
  });

  test('decodes ordered content and test members in one stream', () {
    final decoded =
        registry.decode(
              _payload(CatalogueKind.learningCollections, <Object>[
                <String, dynamic>{
                  'code': 'COLLECTION_ALPHA',
                  'verticalCode': 'VERTICAL_ALPHA',
                  'trackCode': 'TRACK_ALPHA',
                  'title': 'Collection',
                  'description': 'Collection description',
                  'sortOrder': 0,
                  'active': true,
                  'members': <Object>[
                    <String, dynamic>{
                      'position': 0,
                      'type': 'CONTENT',
                      'content': <String, dynamic>{
                        'contentCode': 'CONTENT_ALPHA',
                        'contentType': 'topic',
                        'revision': 2,
                        'checksum': _hash,
                      },
                      'practiceTest': null,
                    },
                    <String, dynamic>{
                      'position': 1,
                      'type': 'PRACTICE_TEST',
                      'content': null,
                      'practiceTest': <String, dynamic>{
                        'practiceTestCode': 'TEST_ALPHA',
                        'revision': 4,
                        'checksum': _hash,
                      },
                    },
                  ],
                },
              ]),
            )
            as List<LearningCollectionProjection>;

    expect(decoded.single.members, hasLength(2));
    expect(decoded.single.members[0].contentRef!.contentCode, 'CONTENT_ALPHA');
    expect(
      decoded.single.members[1].practiceTestRef!.practiceTestCode,
      'TEST_ALPHA',
    );
  });

  test('rejects legacy split collection refs', () {
    expect(
      () => registry.decode(
        _payload(CatalogueKind.learningCollections, <Object>[
          <String, dynamic>{
            'code': 'COLLECTION_ALPHA',
            'verticalCode': 'VERTICAL_ALPHA',
            'trackCode': 'TRACK_ALPHA',
            'title': 'Collection',
            'description': 'Collection description',
            'sortOrder': 0,
            'active': true,
            'contentRefs': <Object>[],
            'practiceTestRefs': <Object>[],
          },
        ]),
      ),
      throwsFormatException,
    );
  });

  test('rejects member that directly mixes content and test', () {
    expect(
      () => registry.decode(
        _payload(CatalogueKind.learningCollections, <Object>[
          <String, dynamic>{
            'code': 'COLLECTION_ALPHA',
            'verticalCode': 'VERTICAL_ALPHA',
            'trackCode': 'TRACK_ALPHA',
            'title': 'Collection',
            'description': 'Collection description',
            'sortOrder': 0,
            'active': true,
            'members': <Object>[
              <String, dynamic>{
                'position': 0,
                'type': 'CONTENT',
                'content': <String, dynamic>{
                  'contentCode': 'CONTENT_ALPHA',
                  'contentType': 'topic',
                  'revision': 1,
                  'checksum': _hash,
                },
                'practiceTest': <String, dynamic>{
                  'practiceTestCode': 'TEST_ALPHA',
                  'revision': 1,
                  'checksum': _hash,
                },
              },
            ],
          },
        ]),
      ),
      throwsFormatException,
    );
  });

  test('rejects mutable/runtime fields in graph catalogue item', () {
    expect(
      () => registry.decode(
        _payload(CatalogueKind.learningGoals, <Object>[
          <String, dynamic>{
            'code': 'GOAL_ALPHA',
            'verticalCode': 'VERTICAL_ALPHA',
            'title': 'Goal',
            'description': 'Goal description',
            'sortOrder': 0,
            'active': true,
            'downloadProgress': 0.4,
          },
        ]),
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
