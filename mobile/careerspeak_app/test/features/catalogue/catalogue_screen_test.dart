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
  for (final mode in VerticalCataloguePresentationMode.values) {
    testWidgets(
      'production catalogue home renders backend-owned ${mode.wireName}',
      (tester) async {
        final snapshot = _snapshot(mode);
        await _pump(tester, snapshot, const CatalogueHomeScreen());

        expect(find.text('Learning catalogue'), findsOneWidget);
        expect(find.text('Future Vertical 2030'), findsOneWidget);
        expect(
          find.text('Future Section'),
          mode == VerticalCataloguePresentationMode.shelves
              ? findsOneWidget
              : findsNothing,
        );
      },
    );
  }

  testWidgets('vertical drill-down is driven by generic graph ownership', (
    tester,
  ) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueVerticalScreen(verticalCode: 'FUTURE_VERTICAL_2030'),
    );

    expect(find.text('Future Vertical 2030'), findsOneWidget);
    expect(find.text('Future Goal'), findsOneWidget);
    expect(find.text('JAVA_INTERVIEW'), findsNothing);
    expect(find.text('MEDICAL_ENGLISH'), findsNothing);
  });

  testWidgets('goal drill-down renders only owned active tracks', (
    tester,
  ) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueGoalScreen(
        verticalCode: 'FUTURE_VERTICAL_2030',
        goalCode: 'GOAL_ALPHA',
      ),
    );

    expect(find.text('Future Goal'), findsOneWidget);
    expect(find.text('Future Track'), findsOneWidget);
    expect(find.text('B2'), findsOneWidget);
  });

  testWidgets('track drill-down renders collection summary', (tester) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueTrackScreen(
        verticalCode: 'FUTURE_VERTICAL_2030',
        goalCode: 'GOAL_ALPHA',
        trackCode: 'TRACK_ALPHA',
      ),
    );

    expect(find.text('Future Track'), findsOneWidget);
    expect(find.text('Future Collection'), findsOneWidget);
    expect(find.text('1 items'), findsOneWidget);
  });

  testWidgets('collection preserves ordered learning sequence', (tester) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueCollectionScreen(
        verticalCode: 'FUTURE_VERTICAL_2030',
        goalCode: 'GOAL_ALPHA',
        trackCode: 'TRACK_ALPHA',
        collectionCode: 'COLLECTION_ALPHA',
      ),
    );

    expect(find.text('Future Collection'), findsOneWidget);
    expect(find.text('Learning sequence'), findsOneWidget);
    expect(find.text('CONTENT_ALPHA'), findsOneWidget);
    expect(find.text('Step 1'), findsOneWidget);
  });

  testWidgets('unknown vertical route fails closed', (tester) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueVerticalScreen(verticalCode: 'UNKNOWN_VERTICAL'),
    );

    expect(find.text('Learning vertical is unavailable.'), findsOneWidget);
  });

  testWidgets('goal cannot be opened through a different vertical', (
    tester,
  ) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueGoalScreen(
        verticalCode: 'OTHER_VERTICAL',
        goalCode: 'GOAL_ALPHA',
      ),
    );

    expect(find.text('Learning goal is unavailable.'), findsOneWidget);
    expect(find.text('Future Goal'), findsNothing);
  });

  testWidgets('track cannot be opened through a different goal', (
    tester,
  ) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueTrackScreen(
        verticalCode: 'FUTURE_VERTICAL_2030',
        goalCode: 'OTHER_GOAL',
        trackCode: 'TRACK_ALPHA',
      ),
    );

    expect(find.text('Learning track is unavailable.'), findsOneWidget);
    expect(find.text('Future Track'), findsNothing);
  });

  testWidgets('collection cannot bypass goal ownership through a valid track', (
    tester,
  ) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueCollectionScreen(
        verticalCode: 'FUTURE_VERTICAL_2030',
        goalCode: 'OTHER_GOAL',
        trackCode: 'TRACK_ALPHA',
        collectionCode: 'COLLECTION_ALPHA',
      ),
    );

    expect(find.text('Learning collection is unavailable.'), findsOneWidget);
    expect(find.text('Future Collection'), findsNothing);
  });

  testWidgets('collection cannot bypass vertical ownership', (tester) async {
    final snapshot = _snapshot(VerticalCataloguePresentationMode.shelves);
    await _pump(
      tester,
      snapshot,
      const CatalogueCollectionScreen(
        verticalCode: 'OTHER_VERTICAL',
        goalCode: 'GOAL_ALPHA',
        trackCode: 'TRACK_ALPHA',
        collectionCode: 'COLLECTION_ALPHA',
      ),
    );

    expect(find.text('Learning collection is unavailable.'), findsOneWidget);
  });

  testWidgets('inactive vertical is never learner-visible', (tester) async {
    final snapshot = _snapshot(
      VerticalCataloguePresentationMode.grid,
      verticalActive: false,
    );
    await _pump(tester, snapshot, const CatalogueHomeScreen());

    expect(find.text('Future Vertical 2030'), findsNothing);
    expect(find.text('No active learning paths.'), findsOneWidget);
  });

  testWidgets('inactive goal is hidden from an active vertical', (tester) async {
    final snapshot = _snapshot(
      VerticalCataloguePresentationMode.shelves,
      goalActive: false,
    );
    await _pump(
      tester,
      snapshot,
      const CatalogueVerticalScreen(verticalCode: 'FUTURE_VERTICAL_2030'),
    );

    expect(find.text('Future Goal'), findsNothing);
    expect(
      find.text('No learning goals are published for this vertical.'),
      findsOneWidget,
    );
  });

  testWidgets('inactive track cannot be deep-linked', (tester) async {
    final snapshot = _snapshot(
      VerticalCataloguePresentationMode.shelves,
      trackActive: false,
    );
    await _pump(
      tester,
      snapshot,
      const CatalogueTrackScreen(
        verticalCode: 'FUTURE_VERTICAL_2030',
        goalCode: 'GOAL_ALPHA',
        trackCode: 'TRACK_ALPHA',
      ),
    );

    expect(find.text('Learning track is unavailable.'), findsOneWidget);
  });

  testWidgets('inactive collection cannot be deep-linked', (tester) async {
    final snapshot = _snapshot(
      VerticalCataloguePresentationMode.shelves,
      collectionActive: false,
    );
    await _pump(
      tester,
      snapshot,
      const CatalogueCollectionScreen(
        verticalCode: 'FUTURE_VERTICAL_2030',
        goalCode: 'GOAL_ALPHA',
        trackCode: 'TRACK_ALPHA',
        collectionCode: 'COLLECTION_ALPHA',
      ),
    );

    expect(find.text('Learning collection is unavailable.'), findsOneWidget);
  });

  testWidgets('missing CURRENT catalogue renders an explicit empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          universalCatalogueRepositoryProvider.overrideWithValue(
            const _EmptyRepository(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CatalogueHomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No published learning catalogue is available yet.'),
      findsOneWidget,
    );
  });

  testWidgets('repository failure renders an explicit catalogue error', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          universalCatalogueRepositoryProvider.overrideWithValue(
            const _FailureRepository(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: CatalogueHomeScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Unable to load catalogue.'), findsOneWidget);
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

CurrentUniversalCatalogueSnapshot _snapshot(
  VerticalCataloguePresentationMode mode, {
  bool verticalActive = true,
  bool goalActive = true,
  bool trackActive = true,
  bool collectionActive = true,
}) {
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
        active: verticalActive,
      ),
    ],
    goals: [
      LearningGoalProjection(
        code: 'GOAL_ALPHA',
        verticalCode: 'FUTURE_VERTICAL_2030',
        title: 'Future Goal',
        description: 'Goal description',
        sortOrder: 0,
        active: goalActive,
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
        active: trackActive,
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
        active: collectionActive,
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

final class _EmptyRepository implements UniversalCatalogueRepository {
  const _EmptyRepository();

  @override
  Future<Result<CurrentUniversalCatalogueSnapshot?>> readCurrent() async =>
      const Success<CurrentUniversalCatalogueSnapshot?>(null);
}

final class _FailureRepository implements UniversalCatalogueRepository {
  const _FailureRepository();

  @override
  Future<Result<CurrentUniversalCatalogueSnapshot?>> readCurrent() async =>
      const FailureResult<CurrentUniversalCatalogueSnapshot?>(
        ApplicationFailure(
          code: 'CATALOGUE_TEST_FAILURE',
          message: 'synthetic catalogue failure',
        ),
      );
}
