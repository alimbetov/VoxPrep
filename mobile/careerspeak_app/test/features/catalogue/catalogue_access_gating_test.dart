import 'package:careerspeak_app/app/access_providers.dart';
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
  testWidgets('FREE learner sees FULL collection as locked', (tester) async {
    await _pump(
      tester,
      child: const CatalogueTrackScreen(
        verticalCode: 'VERTICAL',
        goalCode: 'GOAL',
        trackCode: 'TRACK',
      ),
      learnerAccess: AccessLevel.free,
      collectionAccess: AccessLevel.full,
    );

    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('1 items · Full'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('FREE learner direct route cannot reveal FULL members', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const CatalogueCollectionScreen(
        verticalCode: 'VERTICAL',
        goalCode: 'GOAL',
        trackCode: 'TRACK',
        collectionCode: 'COLLECTION',
      ),
      learnerAccess: AccessLevel.free,
      collectionAccess: AccessLevel.full,
    );

    expect(find.text('Full access required'), findsOneWidget);
    expect(find.text('Collection is part of Full VoxPrep.'), findsOneWidget);
    expect(find.text('Learning sequence'), findsNothing);
    expect(find.text('CONTENT'), findsNothing);
  });

  testWidgets('FULL learner direct route can reveal FULL members', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const CatalogueCollectionScreen(
        verticalCode: 'VERTICAL',
        goalCode: 'GOAL',
        trackCode: 'TRACK',
        collectionCode: 'COLLECTION',
      ),
      learnerAccess: AccessLevel.full,
      collectionAccess: AccessLevel.full,
    );

    expect(find.text('Full access required'), findsNothing);
    expect(find.text('Learning sequence'), findsOneWidget);
    expect(find.text('CONTENT'), findsOneWidget);
  });

  testWidgets('FREE learner can open explicitly FREE collection', (
    tester,
  ) async {
    await _pump(
      tester,
      child: const CatalogueCollectionScreen(
        verticalCode: 'VERTICAL',
        goalCode: 'GOAL',
        trackCode: 'TRACK',
        collectionCode: 'COLLECTION',
      ),
      learnerAccess: AccessLevel.free,
      collectionAccess: AccessLevel.free,
    );

    expect(find.text('Full access required'), findsNothing);
    expect(find.text('Learning sequence'), findsOneWidget);
    expect(find.text('CONTENT'), findsOneWidget);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  required AccessLevel learnerAccess,
  required AccessLevel collectionAccess,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerAccessLevelProvider.overrideWithValue(learnerAccess),
        universalCatalogueRepositoryProvider.overrideWithValue(
          _Repository(_snapshot(collectionAccess)),
        ),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

CurrentUniversalCatalogueSnapshot _snapshot(AccessLevel collectionAccess) {
  return CurrentUniversalCatalogueSnapshot(
    contentVersion: 1,
    graph: UniversalCatalogueGraph(
      sections: <VerticalSectionProjection>[
        VerticalSectionProjection(
          code: 'SECTION',
          title: 'Section',
          sortOrder: 0,
          active: true,
        ),
      ],
      verticals: <LearningVerticalProjection>[
        LearningVerticalProjection(
          code: 'VERTICAL',
          sectionCode: 'SECTION',
          title: 'Vertical',
          description: 'Vertical description',
          iconAssetId: 'icon',
          sortOrder: 0,
          active: true,
        ),
      ],
      goals: <LearningGoalProjection>[
        LearningGoalProjection(
          code: 'GOAL',
          verticalCode: 'VERTICAL',
          title: 'Goal',
          description: 'Goal description',
          sortOrder: 0,
          active: true,
        ),
      ],
      tracks: <LearningTrackProjection>[
        LearningTrackProjection(
          code: 'TRACK',
          verticalCode: 'VERTICAL',
          goalCode: 'GOAL',
          title: 'Track',
          description: 'Track description',
          levelCode: 'B1',
          sortOrder: 0,
          active: true,
        ),
      ],
      collections: <LearningCollectionProjection>[
        LearningCollectionProjection(
          code: 'COLLECTION',
          verticalCode: 'VERTICAL',
          trackCode: 'TRACK',
          title: 'Collection',
          description: 'Collection description',
          accessLevel: collectionAccess,
          sortOrder: 0,
          active: true,
          members: <LearningCollectionMember>[
            LearningCollectionMember.content(
              position: 0,
              content: ContentRevisionRef(
                contentCode: 'CONTENT',
                contentType: ContentType.topic,
                revision: 1,
                checksum: _hash,
              ),
            ),
          ],
        ),
      ],
      presentation: VerticalCataloguePresentation(
        mode: VerticalCataloguePresentationMode.shelves,
        showFeatured: false,
        showSeeAll: true,
      ),
    ),
  );
}

final class _Repository implements UniversalCatalogueRepository {
  const _Repository(this.snapshot);

  final CurrentUniversalCatalogueSnapshot snapshot;

  @override
  Future<Result<CurrentUniversalCatalogueSnapshot?>> readCurrent() async =>
      Success<CurrentUniversalCatalogueSnapshot?>(snapshot);
}
