import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('physical input permutation cannot change catalogue presentation order', () {
    final graph = UniversalCatalogueGraph(
      sections: [
        _section('SECTION_Z', 20),
        _section('SECTION_A', 10),
      ],
      verticals: [
        _vertical('VERTICAL_Z', 'SECTION_Z', 20),
        _vertical('VERTICAL_B', 'SECTION_A', 10),
        _vertical('VERTICAL_A', 'SECTION_A', 10),
      ],
      goals: [
        _goal('GOAL_Z', 'VERTICAL_A', 20),
        _goal('GOAL_B', 'VERTICAL_A', 10),
        _goal('GOAL_A', 'VERTICAL_A', 10),
      ],
      tracks: [
        _track('TRACK_Z', 'VERTICAL_A', 'GOAL_A', 20),
        _track('TRACK_B', 'VERTICAL_A', 'GOAL_A', 10),
        _track('TRACK_A', 'VERTICAL_A', 'GOAL_A', 10),
      ],
      collections: [
        _collection('COLLECTION_Z', 'VERTICAL_A', 'TRACK_A', 20),
        _collection('COLLECTION_B', 'VERTICAL_A', 'TRACK_A', 10),
        _collection('COLLECTION_A', 'VERTICAL_A', 'TRACK_A', 10),
      ],
      presentation: const VerticalCataloguePresentation(
        mode: VerticalCataloguePresentationMode.grid,
        showFeatured: false,
        showSeeAll: true,
      ),
    );

    expect(
      graph.sections.map((item) => item.code),
      ['SECTION_A', 'SECTION_Z'],
    );
    expect(
      graph.verticals.map((item) => item.code),
      ['VERTICAL_A', 'VERTICAL_B', 'VERTICAL_Z'],
    );
    expect(
      graph.goals.map((item) => item.code),
      ['GOAL_A', 'GOAL_B', 'GOAL_Z'],
    );
    expect(
      graph.tracks.map((item) => item.code),
      ['TRACK_A', 'TRACK_B', 'TRACK_Z'],
    );
    expect(
      graph.collections.map((item) => item.code),
      ['COLLECTION_A', 'COLLECTION_B', 'COLLECTION_Z'],
    );
  });

  test('collection member learning order is not re-sorted by catalogue order', () {
    final collection = LearningCollectionProjection(
      code: 'COLLECTION_A',
      verticalCode: 'VERTICAL_A',
      trackCode: 'TRACK_A',
      title: 'Collection A',
      description: 'Ordered learning sequence',
      sortOrder: 0,
      active: true,
      members: [
        LearningCollectionMember.practiceTest(
          position: 0,
          practiceTest: PracticeTestRevisionRef(
            practiceTestCode: 'TEST_Z',
            revision: 1,
            checksum: _hash,
          ),
        ),
        LearningCollectionMember.content(
          position: 1,
          content: ContentRevisionRef(
            contentCode: 'CONTENT_A',
            contentType: ContentType.topic,
            revision: 1,
            checksum: _hash,
          ),
        ),
      ],
    );

    expect(collection.members[0].type, LearningCollectionMemberType.practiceTest);
    expect(collection.members[0].position, 0);
    expect(collection.members[1].type, LearningCollectionMemberType.content);
    expect(collection.members[1].position, 1);
  });
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

LearningGoalProjection _goal(
  String code,
  String verticalCode,
  int sortOrder,
) {
  return LearningGoalProjection(
    code: code,
    verticalCode: verticalCode,
    title: code,
    description: '$code description',
    sortOrder: sortOrder,
    active: true,
  );
}

LearningTrackProjection _track(
  String code,
  String verticalCode,
  String goalCode,
  int sortOrder,
) {
  return LearningTrackProjection(
    code: code,
    verticalCode: verticalCode,
    goalCode: goalCode,
    title: code,
    description: '$code description',
    levelCode: 'B2',
    sortOrder: sortOrder,
    active: true,
  );
}

LearningCollectionProjection _collection(
  String code,
  String verticalCode,
  String trackCode,
  int sortOrder,
) {
  return LearningCollectionProjection(
    code: code,
    verticalCode: verticalCode,
    trackCode: trackCode,
    title: code,
    description: '$code description',
    sortOrder: sortOrder,
    active: true,
    members: [
      LearningCollectionMember.content(
        position: 0,
        content: ContentRevisionRef(
          contentCode: 'CONTENT_$code',
          contentType: ContentType.topic,
          revision: 1,
          checksum: _hash,
        ),
      ),
    ],
  );
}
