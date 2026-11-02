import '../../domain/learner_selection.dart';
import '../content_delivery/universal_catalogue_graph.dart';

enum LearnerSelectionNormalizationReason {
  goalMissing,
  goalInactive,
  verticalInactive,
  trackMissing,
  trackInactive,
  trackWrongGoal,
}

final class LearnerSelectionNormalization {
  const LearnerSelectionNormalization({
    required this.selection,
    required this.reasons,
  });

  final LearnerSelection selection;
  final Set<LearnerSelectionNormalizationReason> reasons;

  bool get changed => reasons.isNotEmpty;
}

final class LearnerSelectionNormalizer {
  const LearnerSelectionNormalizer();

  LearnerSelectionNormalization normalize({
    required LearnerSelection selection,
    required UniversalCatalogueGraph graph,
  }) {
    final goalCode = selection.selectedGoalCode;
    if (goalCode == null) {
      return LearnerSelectionNormalization(
        selection: selection,
        reasons: const <LearnerSelectionNormalizationReason>{},
      );
    }

    final goal = _firstOrNull(
      graph.goals.where((item) => item.code == goalCode),
    );
    if (goal == null) {
      return _clearGoalAndTrack(
        selection,
        LearnerSelectionNormalizationReason.goalMissing,
      );
    }
    if (!goal.active) {
      return _clearGoalAndTrack(
        selection,
        LearnerSelectionNormalizationReason.goalInactive,
      );
    }

    final vertical = _firstOrNull(
      graph.verticals.where((item) => item.code == goal.verticalCode),
    );
    if (!vertical!.active) {
      return _clearGoalAndTrack(
        selection,
        LearnerSelectionNormalizationReason.verticalInactive,
      );
    }

    final trackCode = selection.selectedTrackCode;
    if (trackCode == null) {
      return LearnerSelectionNormalization(
        selection: selection,
        reasons: const <LearnerSelectionNormalizationReason>{},
      );
    }

    final track = _firstOrNull(
      graph.tracks.where((item) => item.code == trackCode),
    );
    if (track == null) {
      return _clearTrack(
        selection,
        LearnerSelectionNormalizationReason.trackMissing,
      );
    }
    if (!track.active) {
      return _clearTrack(
        selection,
        LearnerSelectionNormalizationReason.trackInactive,
      );
    }
    if (track.goalCode != goal.code) {
      return _clearTrack(
        selection,
        LearnerSelectionNormalizationReason.trackWrongGoal,
      );
    }

    return LearnerSelectionNormalization(
      selection: selection,
      reasons: const <LearnerSelectionNormalizationReason>{},
    );
  }

  String? currentVerticalCode({
    required LearnerSelection selection,
    required UniversalCatalogueGraph graph,
  }) {
    final normalized = normalize(selection: selection, graph: graph).selection;
    final goalCode = normalized.selectedGoalCode;
    if (goalCode == null) return null;
    return _firstOrNull(graph.goals.where((item) => item.code == goalCode))
        ?.verticalCode;
  }

  LearnerSelectionNormalization _clearGoalAndTrack(
    LearnerSelection selection,
    LearnerSelectionNormalizationReason reason,
  ) {
    return LearnerSelectionNormalization(
      selection: selection.copyWith(
        clearSelectedGoal: true,
        clearSelectedTrack: true,
      ),
      reasons: <LearnerSelectionNormalizationReason>{reason},
    );
  }

  LearnerSelectionNormalization _clearTrack(
    LearnerSelection selection,
    LearnerSelectionNormalizationReason reason,
  ) {
    return LearnerSelectionNormalization(
      selection: selection.copyWith(clearSelectedTrack: true),
      reasons: <LearnerSelectionNormalizationReason>{reason},
    );
  }
}

T? _firstOrNull<T>(Iterable<T> values) {
  final iterator = values.iterator;
  return iterator.moveNext() ? iterator.current : null;
}
