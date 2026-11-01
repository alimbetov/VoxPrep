import 'package:careerspeak_app/app/catalogue_payload_providers.dart';
import 'package:careerspeak_app/app/learner_selection_providers.dart';
import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/ports/universal_catalogue_repository.dart';
import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'derives selected Goal and owning Vertical from CURRENT graph',
    () async {
      final container = _container(
        selection: LearnerSelection(selectedGoalCode: 'GOAL_A'),
        graph: _graph(),
      );
      addTearDown(container.dispose);

      await _settle(container);

      expect(container.read(learnerLearningContextProvider).value, (
        verticalCode: 'VERT_A',
        verticalTitle: 'Vertical A',
        goalCode: 'GOAL_A',
        goalTitle: 'Goal A',
      ));
    },
  );

  test(
    'returns null when persisted Goal is absent from CURRENT graph',
    () async {
      final container = _container(
        selection: LearnerSelection(selectedGoalCode: 'STALE_GOAL'),
        graph: _graph(),
      );
      addTearDown(container.dispose);

      await _settle(container);

      expect(container.read(learnerLearningContextProvider).value, isNull);
    },
  );

  test(
    'returns null when selected Goal is inactive in CURRENT graph',
    () async {
      final container = _container(
        selection: LearnerSelection(selectedGoalCode: 'GOAL_A'),
        graph: _graph(goalActive: false),
      );
      addTearDown(container.dispose);

      await _settle(container);

      expect(container.read(learnerLearningContextProvider).value, isNull);
    },
  );

  test(
    'returns null when owning Vertical is inactive in CURRENT graph',
    () async {
      final container = _container(
        selection: LearnerSelection(selectedGoalCode: 'GOAL_A'),
        graph: _graph(verticalActive: false),
      );
      addTearDown(container.dispose);

      await _settle(container);

      expect(container.read(learnerLearningContextProvider).value, isNull);
    },
  );
}

ProviderContainer _container({
  required LearnerSelection selection,
  required UniversalCatalogueGraph graph,
}) {
  return ProviderContainer(
    overrides: [
      learnerSelectionProvider.overrideWith(
        (ref) => Stream<LearnerSelection>.value(selection),
      ),
      currentUniversalCatalogueProvider.overrideWith(
        (ref) async =>
            CurrentUniversalCatalogueSnapshot(contentVersion: 1, graph: graph),
      ),
    ],
  );
}

Future<void> _settle(ProviderContainer container) async {
  await container.read(learnerSelectionProvider.future);
  await container.read(currentUniversalCatalogueProvider.future);
  await Future<void>.delayed(Duration.zero);
}

UniversalCatalogueGraph _graph({
  bool goalActive = true,
  bool verticalActive = true,
}) {
  return UniversalCatalogueGraph(
    sections: [
      VerticalSectionProjection(
        code: 'SECTION_A',
        title: 'Section A',
        sortOrder: 0,
        active: true,
      ),
    ],
    verticals: [
      LearningVerticalProjection(
        code: 'VERT_A',
        sectionCode: 'SECTION_A',
        title: 'Vertical A',
        description: 'Vertical A description',
        iconAssetId: 'asset-vertical-a',
        sortOrder: 0,
        active: verticalActive,
      ),
    ],
    goals: [
      LearningGoalProjection(
        code: 'GOAL_A',
        verticalCode: 'VERT_A',
        title: 'Goal A',
        description: 'Goal A description',
        sortOrder: 0,
        active: goalActive,
      ),
    ],
    tracks: const [],
    collections: const [],
    presentation: VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.grid,
      showFeatured: false,
      showSeeAll: true,
    ),
  );
}
