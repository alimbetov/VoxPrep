class PracticeTestAttempt {
  const PracticeTestAttempt({
    required this.practiceTestCode,
    required this.practiceTestRevision,
    required this.currentIndex,
    required this.answers,
    required this.startedAt,
    required this.updatedAt,
  });

  final String practiceTestCode;
  final int practiceTestRevision;
  final int currentIndex;
  final Map<int, int> answers;
  final DateTime startedAt;
  final DateTime updatedAt;

  PracticeTestAttempt copyWith({
    int? currentIndex,
    Map<int, int>? answers,
    DateTime? updatedAt,
  }) {
    return PracticeTestAttempt(
      practiceTestCode: practiceTestCode,
      practiceTestRevision: practiceTestRevision,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      startedAt: startedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
