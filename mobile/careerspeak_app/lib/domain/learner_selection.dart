final class LearnerSelection {
  factory LearnerSelection({
    String? selectedGoalCode,
    String? selectedTrackCode,
    String? selfAssessedLevelCode,
    bool levelDecisionMade = false,
    int generation = 0,
  }) {
    if (generation < 0) {
      throw ArgumentError.value(
        generation,
        'generation',
        'must not be negative',
      );
    }

    final goalCode = _optionalStableCode(selectedGoalCode, 'selectedGoalCode');
    final trackCode = _optionalStableCode(
      selectedTrackCode,
      'selectedTrackCode',
    );
    final levelCode = _optionalStableCode(
      selfAssessedLevelCode,
      'selfAssessedLevelCode',
    );

    if (trackCode != null && goalCode == null) {
      throw ArgumentError('selectedTrackCode requires selectedGoalCode.');
    }
    if (!levelDecisionMade && levelCode != null) {
      throw ArgumentError(
        'selfAssessedLevelCode requires levelDecisionMade=true.',
      );
    }

    return LearnerSelection._(
      selectedGoalCode: goalCode,
      selectedTrackCode: trackCode,
      selfAssessedLevelCode: levelCode,
      levelDecisionMade: levelDecisionMade,
      generation: generation,
    );
  }

  const LearnerSelection._({
    required this.selectedGoalCode,
    required this.selectedTrackCode,
    required this.selfAssessedLevelCode,
    required this.levelDecisionMade,
    required this.generation,
  });

  static final empty = LearnerSelection();

  final String? selectedGoalCode;
  final String? selectedTrackCode;
  final String? selfAssessedLevelCode;
  final bool levelDecisionMade;
  final int generation;

  bool get hasLearningDirection => selectedGoalCode != null;

  LearnerSelection copyWith({
    String? selectedGoalCode,
    bool clearSelectedGoal = false,
    String? selectedTrackCode,
    bool clearSelectedTrack = false,
    String? selfAssessedLevelCode,
    bool clearSelfAssessedLevel = false,
    bool? levelDecisionMade,
    int? generation,
  }) {
    final goalCode = clearSelectedGoal
        ? null
        : selectedGoalCode ?? this.selectedGoalCode;
    final trackCode = clearSelectedGoal || clearSelectedTrack
        ? null
        : selectedTrackCode ?? this.selectedTrackCode;
    final levelCode = clearSelfAssessedLevel
        ? null
        : selfAssessedLevelCode ?? this.selfAssessedLevelCode;

    return LearnerSelection(
      selectedGoalCode: goalCode,
      selectedTrackCode: trackCode,
      selfAssessedLevelCode: levelCode,
      levelDecisionMade: levelDecisionMade ?? this.levelDecisionMade,
      generation: generation ?? this.generation,
    );
  }

  LearnerSelection withGeneration(int value) {
    return LearnerSelection(
      selectedGoalCode: selectedGoalCode,
      selectedTrackCode: selectedTrackCode,
      selfAssessedLevelCode: selfAssessedLevelCode,
      levelDecisionMade: levelDecisionMade,
      generation: value,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LearnerSelection &&
        other.selectedGoalCode == selectedGoalCode &&
        other.selectedTrackCode == selectedTrackCode &&
        other.selfAssessedLevelCode == selfAssessedLevelCode &&
        other.levelDecisionMade == levelDecisionMade &&
        other.generation == generation;
  }

  @override
  int get hashCode => Object.hash(
    selectedGoalCode,
    selectedTrackCode,
    selfAssessedLevelCode,
    levelDecisionMade,
    generation,
  );
}

String? _optionalStableCode(String? value, String field) {
  if (value == null) return null;
  final normalized = value.trim();
  if (!_stableCodePattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must be a stable backend-owned code',
    );
  }
  return normalized;
}

final _stableCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9._-]{1,127}$');
