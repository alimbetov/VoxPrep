import 'package:careerspeak_app/app/catalogue_payload_providers.dart';
import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/ports/universal_catalogue_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/features/catalogue/catalogue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  for (final mode in VerticalCataloguePresentationMode.values) {
    testWidgets('renders backend-owned ${mode.wireName} without vertical branching', (
      tester,
    ) async {
      final snapshot = _snapshot(mode);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            universalCatalogueRepositoryProvider.overrideWithValue(
              _FakeRepository(snapshot),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: CatalogueScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning catalogue'), findsOneWidget);
      expect(find.text('Future Vertical 2030'), findsOneWidget);
      expect(find.text('Future Section'),
          mode == VerticalCataloguePresentationMode.shelves
              ? findsOneWidget
              : findsNothing);
    });
  }

  testWidgets('vertical drill-down is driven by generic graph ownership', (
    tester,
  ) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          universalCatalogueRepositoryProvider.overrideWithValue(
            _FakeRepository(snapshot),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: CatalogueVerticalScreen(verticalCode: 'FUTURE_VERTICAL_2030'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Future Vertical 2030'), findsOneWidget);
    expect(find.text('Future Goal'), findsOneWidget);
    expect(find.text('JAVA_INTERVIEW'), findsNothing);
    expect(find.text('MEDICAL_ENGLISH'), findsNothing);
  });

  test('route helpers preserve arbitrary backend codes', () {
    expect(
      catalogueCollectionLocation(
        'FUTURE_VERTICAL_2030',
        'GOAL_ALPHA',
        'TRACK_ALPHA',
        'COLLECTION_ALPHA',
      ),
      '/catalogue/vertical/FUTURE_VERTICAL_2030/goal/GOAL_ALPHA/track/TRACK_ALPHA/collection/COLLECTION_ALPHA',
    );
  });
}

CurrentUniversalCatalogueSnapshot _snapshot(
  VerticalCataloguePresentationMode mode,
) {
  final graph = UniversalCatalogueGraph(
    sections: [
      VerticalSectionProjection(
        code: 'FUTURE_SECTION',
        title: 'Future Section',
        description: 'Backend-owned section',
        sortOrder: 0,
        active: true,
      ),
    ],
    verticals: [
      LearningVerticalProjection(
        code: 'FUTURE_VERTICAL_2030',
        sectionCode: 'FUTURE_SECTION',
        title: 'Future Vertical 2030',
        description: 'A vertical unknown to this Flutter release.',
        iconAssetId: 'asset-future',
        sortOrder: 0,
        active: true,
      ),
    ],
    goals: [
      LearningGoalProjection(
        code: 'GOAL_ALPHA',
        verticalCode: 'FUTURE_VERTICAL_2030',
        title: 'Future Goal',
        description: 'Goal description',
        sortOrder: 0,
        active: true,
      ),
    ],
    tracks: [
      LearningTrackProjection(
        code: 'TRACK_ALPHA',
        verticalCode: 'FUTURE_VERTICAL_2030',
        goalCode: 'GOAL_ALPHA',
        title: 'Future Track',
        description: 'Track description',
        levelCode: 'B2',
        sortOrder: 0,
        active: true,
      ),
    ],
    collections: [
      LearningCollectionProjection(
        code: 'COLLECTION_ALPHA',
        verticalCode: 'FUTURE_VERTICAL_2030',
        trackCode: 'TRACK_ALPHA',
        title: 'Future Collection',
        description: 'Collection description',
        sortOrder: 0,
        active: true,
        members: [
          LearningCollectionMember.content(
            position: 0,
            content: ContentRevisionRef(
              contentCode: 'CONTENT_ALPHA',
              contentType: ContentType.topic,
              revision: 1,
              checksum: _hash,
            ),
          ),
        ],
      ),
    ],
    presentation: VerticalCataloguePresentation(
      mode: mode,
      showFeatured: false,
      showSeeAll: true,
    ),
  );
  return CurrentUniversalCatalogueSnapshot(contentVersion: 1, graph: graph);
}

final class _FakeRepository implements UniversalCatalogueRepository {
  const _FakeRepository(this.snapshot);

  final CurrentUniversalCatalogueSnapshot snapshot;

  @override
  Future<Result<CurrentUniversalCatalogueSnapshot?>> readCurrent() async =>
      Success<CurrentUniversalCatalogueSnapshot?>(snapshot);
}
