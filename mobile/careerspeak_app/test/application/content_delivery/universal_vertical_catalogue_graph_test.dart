import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_vertical_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('accepts backend-owned vertical graph with shelf grouping', () {
    final graph = _graph();

    expect(graph.sections.single.code, 'SOFTWARE_ENGINEERING');
    expect(graph.verticals.single.code, 'FUTURE_VERTICAL_2030');
    expect(graph.presentation.mode, VerticalCataloguePresentationMode.shelves);
  });

  test('rejects vertical that references an unknown shelf section', () {
    expect(
      () => _graph(verticalSectionCode: 'MISSING_SECTION'),
      throwsArgumentError,
    );
  });

  test('rejects track that crosses vertical ownership boundary', () {
    expect(
      () => _graph(trackVerticalCode: 'SECOND_VERTICAL'),
      throwsArgumentError,
    );
  });

  test('rejects collection that crosses vertical ownership boundary', () {
    expect(
      () => _graph(collectionVerticalCode: 'SECOND_VERTICAL'),
      throwsArgumentError,
    );
  });

  test('rejects presentation pointing at unknown featured section', () {
    expect(
      () => _graph(featuredSectionCode: 'MISSING_SECTION'),
      throwsArgumentError,
    );
  });
}

UniversalVerticalCatalogueGraph _graph({
  String verticalSectionCode = 'SOFTWARE_ENGINEERING',
  String trackVerticalCode = 'FUTURE_VERTICAL_2030',
  String collectionVerticalCode = 'FUTURE_VERTICAL_2030',
  String featuredSectionCode = 'SOFTWARE_ENGINEERING',
}) {
  const verticalCode = 'FUTURE_VERTICAL_2030';
  final goal = LearningGoalProjection(
    code: 'GOAL_ALPHA',
    verticalCode: verticalCode,
    title: 'Goal',
    description: 'Goal description',
    sortOrder: 0,
    active: true,
  );
  final track = LearningTrackProjection(
    code: 'TRACK_ALPHA',
    verticalCode: trackVerticalCode,
    goalCode: goal.code,
    title: 'Track',
    description: 'Track description',
    levelCode: 'B2',
    sortOrder: 0,
    active: true,
  );
  final collection = LearningCollectionProjection(
    code: 'COLLECTION_ALPHA',
    verticalCode: collectionVerticalCode,
    trackCode: track.code,
    title: 'Collection',
    description: 'Collection description',
    sortOrder: 0,
    active: true,
    contentRefs: <ContentRevisionRef>[
      ContentRevisionRef(
        contentCode: 'CONTENT_ALPHA',
        contentType: ContentType.topic,
        revision: 1,
        checksum: _hash,
      ),
    ],
    practiceTestRefs: const <PracticeTestRevisionRef>[],
  );

  return UniversalVerticalCatalogueGraph(
    sections: <VerticalSectionProjection>[
      VerticalSectionProjection(
        code: 'SOFTWARE_ENGINEERING',
        title: 'Software Engineering',
        sortOrder: 0,
        active: true,
      ),
    ],
    verticals: <LearningVerticalProjection>[
      LearningVerticalProjection(
        code: verticalCode,
        sectionCode: verticalSectionCode,
        title: 'Future vertical',
        description: 'Backend-owned vertical',
        iconAssetId: 'asset-future',
        sortOrder: 0,
        active: true,
      ),
      if (trackVerticalCode == 'SECOND_VERTICAL' ||
          collectionVerticalCode == 'SECOND_VERTICAL')
        LearningVerticalProjection(
          code: 'SECOND_VERTICAL',
          sectionCode: 'SOFTWARE_ENGINEERING',
          title: 'Second vertical',
          description: 'Second backend-owned vertical',
          iconAssetId: 'asset-second',
          sortOrder: 1,
          active: true,
        ),
    ],
    goals: <LearningGoalProjection>[goal],
    tracks: <LearningTrackProjection>[track],
    collections: <LearningCollectionProjection>[collection],
    presentation: VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.shelves,
      showFeatured: true,
      showSeeAll: true,
      featuredSectionCode: featuredSectionCode,
    ),
  );
}
