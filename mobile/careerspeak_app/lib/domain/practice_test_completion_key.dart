final class PracticeTestCompletionKey {
  const PracticeTestCompletionKey({
    required this.practiceTestCode,
    required this.revision,
  });

  final String practiceTestCode;
  final int revision;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PracticeTestCompletionKey &&
            other.practiceTestCode == practiceTestCode &&
            other.revision == revision;
  }

  @override
  int get hashCode => Object.hash(practiceTestCode, revision);
}
