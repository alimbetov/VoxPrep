import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/ports/learner_selection_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/learner_selection_normalizer.dart';
import 'package:careerspeak_app/application/services/learner_selection_service.dart';
import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearnerSelectionService', () {
    test('selectGoal stores goal and clears incompatible track', () async {
      final repository = _FakeRepository(
        LearnerSelection(
          selectedGoalCode: 'GOAL_A',
          selectedTrackCode: 'TRACK_A',
        ),
      );
      final service = _service(repository);

      final result = await service.selectGoal(
        graph: _graph(),
        goalCode: 'GOAL_B',
      );

      final selection = (result as Success<LearnerSelection>).value;
      expect(selection.selectedGoalCode, 'GOAL_B');
      expect(selection.selectedTrackCode, isNull);
    });

    test('selectTrack rejects track from another goal', () async {
      final repository = _FakeRepository(
        LearnerSelection(selectedGoalCode: 'GOAL_A'),
      );
      final service = _service(repository);

      final result = await service.selectTrack(
        graph: _graph(),
        trackCode: 'TRACK_B',
      );

      expect(result, isA<FailureResult<LearnerSelection>>());
      expect(
        (result as FailureResult<LearnerSelection>).failure.code,
        'LEARNER_SELECTION_TRACK_UNAVAILABLE',
      );
    });

    test('Not sure is an explicit level decision with null level code', () async {
      final repository = _FakeRepository(LearnerSelection.empty);
      final service = _service(repository);

      final result = await service.setLevelDecision(null);

      final selection = (result as Success<LearnerSelection>).value;
      expect(selection.levelDecisionMade, isTrue);
      expect(selection.selfAssessedLevelCode, isNull);
    });

    test('normalization retries after CAS conflict and preserves newer choice', () async {
      final repository = _ConflictThenFreshRepository();
      final service = _service(repository);

      final result = await service.normalizeAgainst(_graph());

      final selection = (result as Success<LearnerSelection>).value;
      expect(selection.selectedGoalCode, 'GOAL_B');
      expect(selection.selectedTrackCode, isNull);
      expect(repository.compareAndSetCalls, 1);
    });
  });
}

LearnerSelectionService _service(LearnerSelectionRepository repository) {
  return LearnerSelectionService(
    repository: repository,
    normalizer: const LearnerSelectionNormalizer(),
  );
}

UniversalCatalogueGraph _graph() {
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
        code: 'VERT_A',
        sectionCode: 'CAREER',
        title: 'A',
        description: 'A',
        iconAssetId: 'icon-a',
        sortOrder: 0,
        active: true,
      ),
      LearningVerticalProjection(
        code: 'VERT_B',
        sectionCode: 'CAREER',
        title: 'B',
        description: 'B',
        iconAssetId: 'icon-b',
        sortOrder: 1,
        active: true,
      ),
    ],
    goals: [
      LearningGoalProjection(
        code: 'GOAL_A',
        verticalCode: 'VERT_A',
        title: 'Goal A',
        description: 'Goal A',
        sortOrder: 0,
        active: true,
      ),
      LearningGoalProjection(
        code: 'GOAL_B',
        verticalCode: 'VERT_B',
        title: 'Goal B',
        description: 'Goal B',
        sortOrder: 0,
        active: true,
      ),
    ],
    tracks: [
      LearningTrackProjection(
        code: 'TRACK_A',
        verticalCode: 'VERT_A',
        goalCode: 'GOAL_A',
        title: 'Track A',
        description: 'Track A',
        levelCode: 'B2',
        sortOrder: 0,
        active: true,
      ),
      LearningTrackProjection(
        code: 'TRACK_B',
        verticalCode: 'VERT_B',
        goalCode: 'GOAL_B',
        title: 'Track B',
        description: 'Track B',
        levelCode: 'B2',
        sortOrder: 0,
        active: true,
      ),
    ],
    collections: const [],
    presentation: VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.grid,
      showFeatured: false,
      showSeeAll: true,
    ),
  );
}

class _FakeRepository implements LearnerSelectionRepository {
  _FakeRepository(this.selection);

  LearnerSelection selection;

  @override
  Future<Result<LearnerSelection>> getSelection() async =>
      Success<LearnerSelection>(selection);

  @override
  Stream<Result<LearnerSelection>> watchSelection() =>
      Stream.value(Success<LearnerSelection>(selection));

  @override
  Future<Result<LearnerSelection>> compareAndSet({
    required int expectedGeneration,
    required LearnerSelection next,
  }) async {
    if (selection.generation != expectedGeneration) {
      return const FailureResult<LearnerSelection>(
        ApplicationFailure(
          code: 'LEARNER_SELECTION_CONFLICT',
          message: 'conflict',
          retryable: true,
        ),
      );
    }
    selection = next.withGeneration(selection.generation + 1);
    return Success<LearnerSelection>(selection);
  }
}

class _ConflictThenFreshRepository implements LearnerSelectionRepository {
  LearnerSelection selection = LearnerSelection(
    selectedGoalCode: 'MISSING_GOAL',
    generation: 1,
  );
  int compareAndSetCalls = 0;

  @override
  Future<Result<LearnerSelection>> getSelection() async =>
      Success<LearnerSelection>(selection);

  @override
  Stream<Result<LearnerSelection>> watchSelection() =>
      Stream.value(Success<LearnerSelection>(selection));

  @override
  Future<Result<LearnerSelection>> compareAndSet({
    required int expectedGeneration,
    required LearnerSelection next,
  }) async {
    compareAndSetCalls++;
    selection = LearnerSelection(selectedGoalCode: 'GOAL_B', generation: 2);
    return const FailureResult<LearnerSelection>(
      ApplicationFailure(
        code: 'LEARNER_SELECTION_CONFLICT',
        message: 'conflict',
        retryable: true,
      ),
    );
  }
}
