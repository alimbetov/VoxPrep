import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('C3 positive catalogue scenarios', () {
    test('mixed content and practice-test sequence remains normative', () {
      final graph = _graph();
      final members = graph.collections.single.members;

      expect(members, hasLength(2));
      expect(members[0].type, LearningCollectionMemberType.content);
      expect(members[0].position, 0);
      expect(members[1].type, LearningCollectionMemberType.practiceTest);
      expect(members[1].position, 1);
    });

    test('physical input permutation is normalized deterministically', () {
      final graph = _graph(
        sections: [_section('SECTION_B', 20), _section('SECTION_A', 10)],
        additionalVerticals: [
          _vertical('VERTICAL_B', 'SECTION_B', 20),
          _vertical('VERTICAL_A', 'SECTION_A', 10),
        ],
      );

      expect(graph.sections.map((item) => item.code), [
        'SECTION_A',
        'SECTION_B',
        'SECTION_MAIN',
      ]);
      expect(graph.verticals.map((item) => item.code), [
        'VERTICAL_A',
        'VERTICAL_B',
        'VERTICAL_MAIN',
      ]);
    });
  });

  group('C4 negative catalogue scenarios', () {
    final scenarios = <({String name, UniversalCatalogueGraph Function() run})>[
      (
        name: 'missing section',
        run: () => _graph(verticalSection: 'NO_SECTION'),
      ),
      (
        name: 'missing vertical for goal',
        run: () => _graph(goalVertical: 'NO_VERTICAL'),
      ),
      (name: 'missing goal for track', run: () => _graph(trackGoal: 'NO_GOAL')),
      (
        name: 'cross-vertical track ownership',
        run: () => _graph(trackVertical: 'OTHER_VERTICAL'),
      ),
      (
        name: 'missing track for collection',
        run: () => _graph(collectionTrack: 'NO_TRACK'),
      ),
      (
        name: 'cross-vertical collection ownership',
        run: () => _graph(collectionVertical: 'OTHER_VERTICAL'),
      ),
      (
        name: 'missing featured section',
        run: () => _graph(featuredSection: 'NO_SECTION'),
      ),
    ];

    for (final scenario in scenarios) {
      test('rejects ${scenario.name}', () {
        expect(scenario.run, throwsFormatException);
      });
    }
  });

  group('C5 adversarial catalogue scenarios', () {
    test('duplicate backend-owned vertical code fails closed', () {
      expect(
        () => _graph(
          additionalVerticals: [_vertical('VERTICAL_MAIN', 'SECTION_MAIN', 99)],
        ),
        throwsFormatException,
      );
    });

    test('collection rejects sparse member positions', () {
      expect(
        () => LearningCollectionProjection(
          code: 'COLLECTION_BAD_ORDER',
          verticalCode: 'VERTICAL_MAIN',
          trackCode: 'TRACK_MAIN',
          title: 'Bad order',
          description: 'Adversarial sparse sequence.',
          sortOrder: 0,
          active: true,
          members: [
            LearningCollectionMember.content(
              position: 1,
              content: _content('CONTENT_A'),
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('collection rejects duplicate exact member identity', () {
      final content = _content('CONTENT_DUPLICATE');
      expect(
        () => LearningCollectionProjection(
          code: 'COLLECTION_DUPLICATE',
          verticalCode: 'VERTICAL_MAIN',
          trackCode: 'TRACK_MAIN',
          title: 'Duplicate member',
          description: 'Adversarial duplicate exact identity.',
          sortOrder: 0,
          active: true,
          members: [
            LearningCollectionMember.content(position: 0, content: content),
            LearningCollectionMember.content(position: 1, content: content),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}

UniversalCatalogueGraph _graph({
  List<VerticalSectionProjection> sections = const [],
  List<LearningVerticalProjection> additionalVerticals = const [],
  String verticalSection = 'SECTION_MAIN',
  String goalVertical = 'VERTICAL_MAIN',
  String trackVertical = 'VERTICAL_MAIN',
  String trackGoal = 'GOAL_MAIN',
  String collectionVertical = 'VERTICAL_MAIN',
  String collectionTrack = 'TRACK_MAIN',
  String? featuredSection,
}) {
  final mainSection = _section('SECTION_MAIN', 30);
  final mainVertical = _vertical('VERTICAL_MAIN', verticalSection, 30);
  final goal = LearningGoalProjection(
    code: 'GOAL_MAIN',
    verticalCode: goalVertical,
    title: 'Goal',
    description: 'Goal description',
    sortOrder: 0,
    active: true,
  );
  final track = LearningTrackProjection(
    code: 'TRACK_MAIN',
    verticalCode: trackVertical,
    goalCode: trackGoal,
    title: 'Track',
    description: 'Track description',
    levelCode: 'B2',
    sortOrder: 0,
    active: true,
  );
  final collection = LearningCollectionProjection(
    code: 'COLLECTION_MAIN',
    verticalCode: collectionVertical,
    trackCode: collectionTrack,
    title: 'Collection',
    description: 'Collection description',
    sortOrder: 0,
    active: true,
    members: [
      LearningCollectionMember.content(
        position: 0,
        content: _content('CONTENT_MAIN'),
      ),
      LearningCollectionMember.practiceTest(
        position: 1,
        practiceTest: PracticeTestRevisionRef(
          practiceTestCode: 'TEST_MAIN',
          revision: 1,
          checksum: _hash,
        ),
      ),
    ],
  );

  return UniversalCatalogueGraph(
    sections: [mainSection, ...sections],
    verticals: [
      mainVertical,
      if (trackVertical == 'OTHER_VERTICAL' ||
          collectionVertical == 'OTHER_VERTICAL')
        _vertical('OTHER_VERTICAL', 'SECTION_MAIN', 40),
      ...additionalVerticals,
    ],
    goals: [goal],
    tracks: [track],
    collections: [collection],
    presentation: VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.shelves,
      showFeatured: featuredSection != null,
      showSeeAll: true,
      featuredSectionCode: featuredSection,
    ),
  );
}

VerticalSectionProjection _section(String code, int sortOrder) {
  return VerticalSectionProjection(
    code: code,
    title: code,
    sortOrder: sortOrder,
    active: true,
  );
}

LearningVerticalProjection _vertical(
  String code,
  String sectionCode,
  int sortOrder,
) {
  return LearningVerticalProjection(
    code: code,
    sectionCode: sectionCode,
    title: code,
    description: '$code description',
    iconAssetId: 'asset-${code.toLowerCase()}',
    sortOrder: sortOrder,
    active: true,
  );
}

ContentRevisionRef _content(String code) {
  return ContentRevisionRef(
    contentCode: code,
    contentType: ContentType.topic,
    revision: 1,
    checksum: _hash,
  );
}
