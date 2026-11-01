import '../content_delivery/universal_catalogue_graph.dart';
import '../ports/learner_selection_repository.dart';
import '../result/result.dart';
import '../../domain/learner_selection.dart';
import 'learner_selection_normalizer.dart';

final class LearnerSelectionService {
  const LearnerSelectionService({
    required LearnerSelectionRepository repository,
    required LearnerSelectionNormalizer normalizer,
  }) : this._(repository, normalizer);

  const LearnerSelectionService._(this._repository, this._normalizer);

  final LearnerSelectionRepository _repository;
  final LearnerSelectionNormalizer _normalizer;

  Future<Result<LearnerSelection>> normalizeAgainst(
    UniversalCatalogueGraph graph,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final currentResult = await _repository.getSelection();
      if (currentResult case FailureResult<LearnerSelection>()) {
        return currentResult;
      }
      final current = (currentResult as Success<LearnerSelection>).value;
      final normalized = _normalizer.normalize(
        selection: current,
        graph: graph,
      );
      if (!normalized.changed) {
        return Success<LearnerSelection>(current);
      }

      final write = await _repository.compareAndSet(
        expectedGeneration: current.generation,
        next: normalized.selection,
      );
      if (write case Success<LearnerSelection>()) {
        return write;
      }
      if (!_isConflict(write)) {
        return write;
      }
    }

    return FailureResult<LearnerSelection>(
      const ApplicationFailure(
        code: 'LEARNER_SELECTION_NORMALIZATION_CONFLICT',
        message: 'Learner selection changed repeatedly during normalization.',
        retryable: true,
      ),
    );
  }

  Future<Result<LearnerSelection>> selectGoal({
    required UniversalCatalogueGraph graph,
    required String goalCode,
  }) async {
    final goal = _firstOrNull(
      graph.goals.where((item) => item.code == goalCode),
    );
    if (goal == null || !goal.active) {
      return _invalidSelection('LEARNER_SELECTION_GOAL_UNAVAILABLE');
    }
    final vertical = _firstOrNull(
      graph.verticals.where((item) => item.code == goal.verticalCode),
    );
    if (vertical == null || !vertical.active) {
      return _invalidSelection('LEARNER_SELECTION_VERTICAL_UNAVAILABLE');
    }

    return _mutate((current) {
      return current.copyWith(
        selectedGoalCode: goal.code,
        clearSelectedTrack: true,
      );
    });
  }

  Future<Result<LearnerSelection>> selectTrack({
    required UniversalCatalogueGraph graph,
    required String trackCode,
  }) async {
    final currentResult = await _repository.getSelection();
    if (currentResult case FailureResult<LearnerSelection>()) {
      return currentResult;
    }
    final current = (currentResult as Success<LearnerSelection>).value;
    final goalCode = current.selectedGoalCode;
    if (goalCode == null) {
      return _invalidSelection('LEARNER_SELECTION_GOAL_REQUIRED');
    }

    final track = _firstOrNull(
      graph.tracks.where((item) => item.code == trackCode),
    );
    if (track == null || !track.active || track.goalCode != goalCode) {
      return _invalidSelection('LEARNER_SELECTION_TRACK_UNAVAILABLE');
    }

    return _repository.compareAndSet(
      expectedGeneration: current.generation,
      next: current.copyWith(selectedTrackCode: track.code),
    );
  }

  Future<Result<LearnerSelection>> setLevelDecision(String? levelCode) {
    return _mutate((current) {
      return current.copyWith(
        selfAssessedLevelCode: levelCode,
        clearSelfAssessedLevel: levelCode == null,
        levelDecisionMade: true,
      );
    });
  }

  Future<Result<LearnerSelection>> clearLearningDirection() {
    return _mutate(
      (current) =>
          current.copyWith(clearSelectedGoal: true, clearSelectedTrack: true),
    );
  }

  Future<Result<LearnerSelection>> _mutate(
    LearnerSelection Function(LearnerSelection current) mutation,
  ) async {
    final currentResult = await _repository.getSelection();
    if (currentResult case FailureResult<LearnerSelection>()) {
      return currentResult;
    }
    final current = (currentResult as Success<LearnerSelection>).value;
    return _repository.compareAndSet(
      expectedGeneration: current.generation,
      next: mutation(current),
    );
  }

  static bool _isConflict(Result<LearnerSelection> result) {
    return result is FailureResult<LearnerSelection> &&
        result.failure.code == 'LEARNER_SELECTION_CONFLICT';
  }

  static FailureResult<LearnerSelection> _invalidSelection(String code) {
    return FailureResult<LearnerSelection>(
      ApplicationFailure(
        code: code,
        message: 'The selected learning direction is not available.',
      ),
    );
  }
}

T? _firstOrNull<T>(Iterable<T> values) {
  final iterator = values.iterator;
  return iterator.moveNext() ? iterator.current : null;
}
