import 'package:careerspeak_app/app/catalogue_payload_providers.dart';
import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/ports/universal_catalogue_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/features/catalogue/catalogue_home_screen.dart';
import 'package:careerspeak_app/features/catalogue/catalogue_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  testWidgets('active goal cannot be deep-linked through inactive vertical', (
    tester,
  ) async {
    await _pump(
      tester,
      _snapshot(verticalActive: false),
      const CatalogueGoalScreen(
        verticalCode: 'VERTICAL_A',
        goalCode: 'GOAL_A',
      ),
    );

    expect(find.text('Learning goal is unavailable.'), findsOneWidget);
    expect(find.text('Goal A'), findsNothing);
  });

  testWidgets('active track cannot be deep-linked through inactive goal', (
    tester,
  ) async {
    await _pump(
      tester,
      _snapshot(goalActive: false),
      const CatalogueTrackScreen(
        verticalCode: 'VERTICAL_A',
        goalCode: 'GOAL_A',
        trackCode: 'TRACK_A',
      ),
    );

    expect(find.text('Learning track is unavailable.'), findsOneWidget);
    expect(find.text('Track A'), findsNothing);
  });

  testWidgets('active collection cannot be deep-linked through inactive goal', (
    tester,
  ) async {
    await _pump(
      tester,
      _snapshot(goalActive: false),
      const CatalogueCollectionScreen(
        verticalCode: 'VERTICAL_A',
        goalCode: 'GOAL_A',
        trackCode: 'TRACK_A',
        collectionCode: 'COLLECTION_A',
      ),
    );

    expect(find.text('Learning collection is unavailable.'), findsOneWidget);
    expect(find.text('Collection A'), findsNothing);
  });

  testWidgets('active collection cannot be deep-linked through inactive track', (
    tester,
  ) async {
    await _pump(
      tester,
      _snapshot(trackActive: false),
      const CatalogueCollectionScreen(
        verticalCode: 'VERTICAL_A',
        goalCode: 'GOAL_A',
        trackCode: 'TRACK_A',
        collectionCode: 'COLLECTION_A',
      ),
    );

    expect(find.text('Learning collection is unavailable.'), findsOneWidget);
  });

  for (final mode in VerticalCataloguePresentationMode.values) {
    testWidgets('inactive section hides its vertical in ${mode.wireName}', (
      tester,
    ) async {
      await _pump(
        tester,
        _snapshot(sectionActive: false, mode: mode),
        const CatalogueHomeScreen(),
      );

      expect(find.text('Vertical A'), findsNothing);
      expect(find.text('No active learning paths.'), findsOneWidget);
    });
  }
}

Future<void> _pump(
  WidgetTester tester,
  CurrentUniversalCatalogueSnapshot snapshot,
  Widget child,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        universalCatalogueRepositoryProvider.overrideWithValue(
          _FakeRepository(snapshot),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

CurrentUniversalCatalogueSnapshot _snapshot({
  VerticalCataloguePresentationMode mode =
      VerticalCataloguePresentationMode.shelves,
  bool sectionActive = true,
  bool verticalActive = true,
  bool goalActive = true,
  bool trackActive = true,
}) {
  return CurrentUniversalCatalogueSnapshot(
    contentVersion: 1,
    graph: UniversalCatalogueGraph(
      sections: [
        VerticalSectionProjection(
          code: 'SECTION_A',
          title: 'Section A',
          sortOrder: 0,
          active: sectionActive,
        ),
      ],
      verticals: [
        LearningVerticalProjection(
          code: 'VERTICAL_A',
          sectionCode: 'SECTION_A',
          title: 'Vertical A',
          description: 'Vertical description',
          iconAssetId: 'asset-vertical-a',
          sortOrder: 0,
          active: verticalActive,
        ),
      ],
      goals: [
        LearningGoalProjection(
          code: 'GOAL_A',
          verticalCode: 'VERTICAL_A',
          title: 'Goal A',
          description: 'Goal description',
          sortOrder: 0,
          active: goalActive,
        ),
      ],
      tracks: [
        LearningTrackProjection(
          code: 'TRACK_A',
          verticalCode: 'VERTICAL_A',
          goalCode: 'GOAL_A',
          title: 'Track A',
          description: 'Track description',
          levelCode: 'B2',
          sortOrder: 0,
          active: trackActive,
        ),
      ],
      collections: [
        LearningCollectionProjection(
          code: 'COLLECTION_A',
          verticalCode: 'VERTICAL_A',
          trackCode: 'TRACK_A',
          title: 'Collection A',
          description: 'Collection description',
          sortOrder: 0,
          active: true,
          members: [
            LearningCollectionMember.content(
              position: 0,
              content: ContentRevisionRef(
                contentCode: 'CONTENT_A',
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
    ),
  );
}

final class _FakeRepository implements UniversalCatalogueRepository {
  const _FakeRepository(this.snapshot);

  final CurrentUniversalCatalogueSnapshot snapshot;

  @override
  Future<Result<CurrentUniversalCatalogueSnapshot?>> readCurrent() async =>
      Success<CurrentUniversalCatalogueSnapshot?>(snapshot);
}
