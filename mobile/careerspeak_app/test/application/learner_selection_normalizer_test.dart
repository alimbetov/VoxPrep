import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/services/learner_selection_normalizer.dart';
import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normalizer = LearnerSelectionNormalizer();

  group('LearnerSelectionNormalizer', () {
    test('keeps empty selection unchanged', () {
      final selection = LearnerSelection.empty;

      final result = normalizer.normalize(
        selection: selection,
        graph: _graph(),
      );

      expect(result.changed, isFalse);
      expect(result.selection, selection);
    });

    test('keeps valid goal and track and derives vertical from goal', () {
      final selection = LearnerSelection(
        selectedGoalCode: 'JOB_INTERVIEW',
        selectedTrackCode: 'JAVA_SENIOR',
        selfAssessedLevelCode: 'B2',
        levelDecisionMade: true,
        generation: 7,
      );
      final graph = _graph();

      final result = normalizer.normalize(selection: selection, graph: graph);

      expect(result.changed, isFalse);
      expect(result.selection, selection);
      expect(
        normalizer.currentVerticalCode(selection: selection, graph: graph),
        'JAVA',
      );
    });

    test('missing goal clears goal and track but preserves level state', () {
      final selection = LearnerSelection(
        selectedGoalCode: 'MISSING_GOAL',
        selectedTrackCode: 'JAVA_SENIOR',
        selfAssessedLevelCode: 'B2',
        levelDecisionMade: true,
        generation: 3,
      );

      final result = normalizer.normalize(
        selection: selection,
        graph: _graph(),
      );

      expect(
        result.reasons,
        {LearnerSelectionNormalizationReason.goalMissing},
      );
      expect(result.selection.selectedGoalCode, isNull);
      expect(result.selection.selectedTrackCode, isNull);
      expect(result.selection.selfAssessedLevelCode, 'B2');
      expect(result.selection.levelDecisionMade, isTrue);
      expect(result.selection.generation, 3);
    });

    test('inactive goal clears goal and track without selecting sibling', () {
      final selection = LearnerSelection(
        selectedGoalCode: 'JOB_INTERVIEW',
        selectedTrackCode: 'JAVA_SENIOR',
      );

      final result = normalizer.normalize(
        selection: selection,
        graph: _graph(goalActive: false, includeSiblingGoal: true),
      );

      expect(
        result.reasons,
        {LearnerSelectionNormalizationReason.goalInactive},
      );
      expect(result.selection.selectedGoalCode, isNull);
      expect(result.selection.selectedTrackCode, isNull);
      expect(result.selection.selectedGoalCode, isNot('OTHER_GOAL'));
    });

    test('inactive parent vertical clears goal and track', () {
      final result = normalizer.normalize(
        selection: LearnerSelection(
          selectedGoalCode: 'JOB_INTERVIEW',
          selectedTrackCode: 'JAVA_SENIOR',
        ),
        graph: _graph(verticalActive: false),
      );

      expect(
        result.reasons,
        {LearnerSelectionNormalizationReason.verticalInactive},
      );
      expect(result.selection.selectedGoalCode, isNull);
      expect(result.selection.selectedTrackCode, isNull);
    });

    test('missing track clears track only', () {
      final result = normalizer.normalize(
        selection: LearnerSelection(
          selectedGoalCode: 'JOB_INTERVIEW',
          selectedTrackCode: 'MISSING_TRACK',
        ),
        graph: _graph(),
      );

      expect(
        result.reasons,
        {LearnerSelectionNormalizationReason.trackMissing},
      );
      expect(result.selection.selectedGoalCode, 'JOB_INTERVIEW');
      expect(result.selection.selectedTrackCode, isNull);
    });

    test('inactive track clears track only', () {
      final result = normalizer.normalize(
        selection: LearnerSelection(
          selectedGoalCode: 'JOB_INTERVIEW',
          selectedTrackCode: 'JAVA_SENIOR',
        ),
        graph: _graph(trackActive: false),
      );

      expect(
        result.reasons,
        {LearnerSelectionNormalizationReason.trackInactive},
      );
      expect(result.selection.selectedGoalCode, 'JOB_INTERVIEW');
      expect(result.selection.selectedTrackCode, isNull);
    });

    test('track belonging to another goal clears track only', () {
      final result = normalizer.normalize(
        selection: LearnerSelection(
          selectedGoalCode: 'JOB_INTERVIEW',
          selectedTrackCode: 'OTHER_TRACK',
        ),
        graph: _graph(includeSiblingGoal: true),
      );

      expect(
        result.reasons,
        {LearnerSelectionNormalizationReason.trackWrongGoal},
      );
      expect(result.selection.selectedGoalCode, 'JOB_INTERVIEW');
      expect(result.selection.selectedTrackCode, isNull);
    });

    test('goal without track remains a valid learning direction', () {
      final selection = LearnerSelection(selectedGoalCode: 'JOB_INTERVIEW');

      final result = normalizer.normalize(
        selection: selection,
        graph: _graph(),
      );

      expect(result.changed, isFalse);
      expect(result.selection, selection);
    });
  });
}

UniversalCatalogueGraph _graph({
  bool verticalActive = true,
  bool goalActive = true,
  bool trackActive = true,
  bool includeSiblingGoal = false,
}) {
  final goals = <LearningGoalProjection>[
    LearningGoalProjection(
      code: 'JOB_INTERVIEW',
      verticalCode: 'JAVA',
      title: 'Job interview',
      description: 'Prepare for Java interviews',
      sortOrder: 0,
      active: goalActive,
    ),
    if (includeSiblingGoal)
      LearningGoalProjection(
        code: 'OTHER_GOAL',
        verticalCode: 'JAVA',
        title: 'Other goal',
        description: 'Another learning goal',
        sortOrder: 1,
        active: true,
      ),
  ];

  final tracks = <LearningTrackProjection>[
    LearningTrackProjection(
      code: 'JAVA_SENIOR',
      verticalCode: 'JAVA',
      goalCode: 'JOB_INTERVIEW',
      title: 'Java senior',
      description: 'Senior interview path',
      levelCode: 'B2',
      sortOrder: 0,
      active: trackActive,
    ),
    if (includeSiblingGoal)
      LearningTrackProjection(
        code: 'OTHER_TRACK',
        verticalCode: 'JAVA',
        goalCode: 'OTHER_GOAL',
        title: 'Other track',
        description: 'Track for another goal',
        levelCode: 'B2',
        sortOrder: 1,
        active: true,
      ),
  ];

  return UniversalCatalogueGraph(
    sections: [
      VerticalSectionProjection(
        code: 'CAREER',
        title: 'Career',
        sortOrder: 0,
        active: true,
      ),
    ],
    verticals: [
      LearningVerticalProjection(
        code: 'JAVA',
        sectionCode: 'CAREER',
        title: 'Java',
        description: 'Java professional English',
        iconAssetId: 'java-icon',
        sortOrder: 0,
        active: verticalActive,
      ),
    ],
    goals: goals,
    tracks: tracks,
    collections: const [],
    presentation: VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.grid,
      showFeatured: false,
      showSeeAll: true,
    ),
  );
}
