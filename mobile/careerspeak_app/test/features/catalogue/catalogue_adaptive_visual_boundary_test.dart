import 'package:careerspeak_app/app/access_providers.dart';
import 'package:careerspeak_app/app/asset_resolver_providers.dart';
import 'package:careerspeak_app/app/catalogue_payload_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
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

import '../../support/ui_boundary_harness.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

const _longSectionTitle =
    'Профессиональная подготовка и техническая терминология для международной практики';
const _longVerticalTitle =
    'Инженерная подготовка к сложным международным техническим собеседованиям';
const _longDescription =
    'Подробная программа с практическими сценариями, профессиональной терминологией, '
    'объяснениями и последовательной подготовкой пользователя к реальным рабочим ситуациям.';

void main() {
  for (final boundary in adaptiveUiBoundaryCases) {
    for (final mode in VerticalCataloguePresentationMode.values) {
      testWidgets(
        'catalogue ${mode.wireName} has no layout defects at $boundary',
        (tester) async {
          await _pumpCatalogue(
            tester,
            boundary: boundary,
            child: const CatalogueHomeScreen(),
            mode: mode,
          );

          expect(find.text('Learning catalogue'), findsOneWidget);
          expect(find.text(_longVerticalTitle), findsWidgets);
          expectNoLayoutExceptions(
            tester,
            reason: 'Catalogue home overflowed for $mode at $boundary',
          );
          expectFinderInsideViewport(
            tester,
            find.text('Learning catalogue'),
            viewport: boundary.size,
            reason:
                'Catalogue heading must remain inside viewport at $boundary',
          );
          expectFinderInsideViewport(
            tester,
            find.byTooltip('See all learning paths'),
            viewport: boundary.size,
            reason: 'See-all action must remain reachable at $boundary',
          );
        },
      );
    }

    testWidgets('hierarchy cards tolerate long copy at $boundary', (
      tester,
    ) async {
      await _pumpCatalogue(
        tester,
        boundary: boundary,
        child: const CatalogueVerticalScreen(verticalCode: 'LONG_VERTICAL'),
        mode: VerticalCataloguePresentationMode.shelves,
      );

      expect(find.text(_longVerticalTitle), findsOneWidget);
      // On a 2x text-scaled phone the goal cards are below the lazy-list
      // viewport. Scroll until their description is actually materialized.
      for (var attempt = 0;
          attempt < 15 && find.text(_longDescription).evaluate().isEmpty;
          attempt++) {
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -160),
        );
        await tester.pumpAndSettle();
      }
      expect(find.text(_longDescription), findsWidgets);
      expectNoLayoutExceptions(
        tester,
        reason: 'Hierarchy card overflowed at $boundary',
      );
    });

    testWidgets('collection sequence tolerates long identifiers at $boundary', (
      tester,
    ) async {
      await _pumpCatalogue(
        tester,
        boundary: boundary,
        child: const CatalogueCollectionScreen(
          verticalCode: 'LONG_VERTICAL',
          goalCode: 'LONG_GOAL',
          trackCode: 'LONG_TRACK',
          collectionCode: 'LONG_COLLECTION',
        ),
        mode: VerticalCataloguePresentationMode.shelves,
      );

      await tester.scrollUntilVisible(
        find.text('Your learning sequence'),
        140,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Your learning sequence'), findsOneWidget);
      expectNoLayoutExceptions(
        tester,
        reason: 'Collection sequence overflowed at $boundary',
      );
    });
  }
}

Future<void> _pumpCatalogue(
  WidgetTester tester, {
  required UiBoundaryCase boundary,
  required Widget child,
  required VerticalCataloguePresentationMode mode,
}) async {
  await configureAdaptiveSurface(tester, boundary: boundary);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        learnerAccessLevelProvider.overrideWithValue(AccessLevel.full),
        // These widget tests exercise catalogue rendering, not network asset
        // delivery. The separate A1 suite tests real RustFS downloads.
        catalogueIconAssetProvider.overrideWith((ref, assetId) async => null),
        contentCoverAssetProvider.overrideWith((ref, request) async => null),
        contentByIdentityProvider.overrideWith((ref, identity) async => null),
        universalCatalogueRepositoryProvider.overrideWithValue(
          _FakeRepository(_snapshot(mode)),
        ),
      ],
      child: MaterialApp(
        builder: adaptiveMediaQueryBuilder(boundary),
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CurrentUniversalCatalogueSnapshot _snapshot(
  VerticalCataloguePresentationMode mode,
) {
  final graph = UniversalCatalogueGraph(
    sections: [
      VerticalSectionProjection(
        code: 'LONG_SECTION',
        title: _longSectionTitle,
        description: _longDescription,
        sortOrder: 0,
        active: true,
      ),
    ],
    verticals: [
      LearningVerticalProjection(
        code: 'LONG_VERTICAL',
        sectionCode: 'LONG_SECTION',
        title: _longVerticalTitle,
        description: _longDescription,
        iconAssetId: 'asset-long-vertical',
        sortOrder: 0,
        active: true,
      ),
    ],
    goals: [
      LearningGoalProjection(
        code: 'LONG_GOAL',
        verticalCode: 'LONG_VERTICAL',
        title:
            'Развитие уверенной профессиональной коммуникации в сложных технических сценариях',
        description: _longDescription,
        sortOrder: 0,
        active: true,
      ),
    ],
    tracks: [
      LearningTrackProjection(
        code: 'LONG_TRACK',
        verticalCode: 'LONG_VERTICAL',
        goalCode: 'LONG_GOAL',
        title:
            'Углублённый трек подготовки для senior-инженеров и технических лидеров',
        description: _longDescription,
        levelCode: 'ADVANCED_PROFESSIONAL_LEVEL_WITH_LONG_LABEL',
        sortOrder: 0,
        active: true,
      ),
    ],
    collections: [
      LearningCollectionProjection(
        code: 'LONG_COLLECTION',
        verticalCode: 'LONG_VERTICAL',
        trackCode: 'LONG_TRACK',
        title:
            'Большая практическая коллекция с развёрнутыми сценариями и пояснениями',
        description: _longDescription,
        sortOrder: 0,
        active: true,
        members: [
          LearningCollectionMember.content(
            position: 0,
            content: ContentRevisionRef(
              contentCode:
                  'VERY_LONG_BACKEND_OWNED_CONTENT_IDENTIFIER_FOR_VISUAL_BOUNDARY_TEST',
              contentType: ContentType.topic,
              revision: 12,
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
