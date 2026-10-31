enum AssessmentMode { learn, exam, quick }

final class QuestionRevisionId {
  factory QuestionRevisionId({
    required String questionCode,
    required int revision,
    required String checksum,
  }) {
    final normalizedCode = questionCode.trim();
    if (normalizedCode.isEmpty) {
      throw ArgumentError.value(
        questionCode,
        'questionCode',
        'must not be blank',
      );
    }
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    if (!_sha256Pattern.hasMatch(checksum)) {
      throw ArgumentError.value(
        checksum,
        'checksum',
        'must be lowercase SHA-256 hex',
      );
    }
    return QuestionRevisionId._(
      questionCode: normalizedCode,
      revision: revision,
      checksum: checksum,
    );
  }

  const QuestionRevisionId._({
    required this.questionCode,
    required this.revision,
    required this.checksum,
  });

  final String questionCode;
  final int revision;
  final String checksum;

  @override
  bool operator ==(Object other) =>
      other is QuestionRevisionId &&
      other.questionCode == questionCode &&
      other.revision == revision &&
      other.checksum == checksum;

  @override
  int get hashCode => Object.hash(questionCode, revision, checksum);
}

sealed class AssessmentQuestionBody {
  const AssessmentQuestionBody();
}

final class SingleChoiceQuestionBody extends AssessmentQuestionBody {
  factory SingleChoiceQuestionBody({
    required String prompt,
    required Iterable<String> options,
    required int correctOptionIndex,
    required String skillCode,
    required String explanation,
  }) {
    final normalizedPrompt = _nonBlank(prompt, 'prompt');
    final normalizedSkillCode = _nonBlank(skillCode, 'skillCode');
    final normalizedExplanation = _nonBlank(explanation, 'explanation');
    final normalizedOptions = options
        .map((option) => _nonBlank(option, 'options'))
        .toList(growable: false);
    if (normalizedOptions.length < 2) {
      throw ArgumentError.value(
        options,
        'options',
        'must contain at least two',
      );
    }
    if (normalizedOptions.toSet().length != normalizedOptions.length) {
      throw ArgumentError.value(
        options,
        'options',
        'must not contain duplicates',
      );
    }
    if (correctOptionIndex < 0 ||
        correctOptionIndex >= normalizedOptions.length) {
      throw ArgumentError.value(
        correctOptionIndex,
        'correctOptionIndex',
        'must reference an option',
      );
    }
    return SingleChoiceQuestionBody._(
      prompt: normalizedPrompt,
      options: List<String>.unmodifiable(normalizedOptions),
      correctOptionIndex: correctOptionIndex,
      skillCode: normalizedSkillCode,
      explanation: normalizedExplanation,
    );
  }

  const SingleChoiceQuestionBody._({
    required this.prompt,
    required this.options,
    required this.correctOptionIndex,
    required this.skillCode,
    required this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int correctOptionIndex;
  final String skillCode;
  final String explanation;
}

final class AssessmentQuestionRevision {
  const AssessmentQuestionRevision({required this.id, required this.body});

  final QuestionRevisionId id;
  final AssessmentQuestionBody body;
}

final class PracticeTestQuestionRef {
  factory PracticeTestQuestionRef({
    required int order,
    required QuestionRevisionId question,
    required int points,
  }) {
    if (order < 0) {
      throw ArgumentError.value(order, 'order', 'must be non-negative');
    }
    if (points < 1) {
      throw ArgumentError.value(points, 'points', 'must be positive');
    }
    return PracticeTestQuestionRef._(
      order: order,
      question: question,
      points: points,
    );
  }

  const PracticeTestQuestionRef._({
    required this.order,
    required this.question,
    required this.points,
  });

  final int order;
  final QuestionRevisionId question;
  final int points;
}

final class PracticeTestRevision {
  factory PracticeTestRevision({
    required String practiceTestCode,
    required int revision,
    required String checksum,
    required String title,
    required String subtitle,
    required AssessmentMode mode,
    required int passingScoreBasisPoints,
    required Iterable<PracticeTestQuestionRef> questionRefs,
  }) {
    final normalizedCode = _nonBlank(practiceTestCode, 'practiceTestCode');
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    if (!_sha256Pattern.hasMatch(checksum)) {
      throw ArgumentError.value(
        checksum,
        'checksum',
        'must be lowercase SHA-256 hex',
      );
    }
    if (passingScoreBasisPoints < 0 || passingScoreBasisPoints > 10000) {
      throw ArgumentError.value(
        passingScoreBasisPoints,
        'passingScoreBasisPoints',
        'must be between 0 and 10000',
      );
    }

    final refs = questionRefs.toList(growable: false)
      ..sort((left, right) => left.order.compareTo(right.order));
    if (refs.isEmpty) {
      throw ArgumentError.value(
        questionRefs,
        'questionRefs',
        'must not be empty',
      );
    }
    for (var index = 0; index < refs.length; index++) {
      if (refs[index].order != index) {
        throw ArgumentError.value(
          questionRefs,
          'questionRefs',
          'orders must be contiguous starting at zero',
        );
      }
    }
    final identities = refs.map((ref) => ref.question).toSet();
    if (identities.length != refs.length) {
      throw ArgumentError.value(
        questionRefs,
        'questionRefs',
        'must not repeat an exact question revision',
      );
    }

    return PracticeTestRevision._(
      practiceTestCode: normalizedCode,
      revision: revision,
      checksum: checksum,
      title: _nonBlank(title, 'title'),
      subtitle: _nonBlank(subtitle, 'subtitle'),
      mode: mode,
      passingScoreBasisPoints: passingScoreBasisPoints,
      questionRefs: List<PracticeTestQuestionRef>.unmodifiable(refs),
    );
  }

  const PracticeTestRevision._({
    required this.practiceTestCode,
    required this.revision,
    required this.checksum,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.passingScoreBasisPoints,
    required this.questionRefs,
  });

  final String practiceTestCode;
  final int revision;
  final String checksum;
  final String title;
  final String subtitle;
  final AssessmentMode mode;
  final int passingScoreBasisPoints;
  final List<PracticeTestQuestionRef> questionRefs;
}

final class AssessmentScore {
  const AssessmentScore({
    required this.earnedPoints,
    required this.totalPoints,
    required this.correctCount,
    required this.questionCount,
    required this.scoreBasisPoints,
    required this.passed,
  });

  final int earnedPoints;
  final int totalPoints;
  final int correctCount;
  final int questionCount;
  final int scoreBasisPoints;
  final bool passed;
}

final class AssessmentScorer {
  const AssessmentScorer();

  AssessmentScore score({
    required PracticeTestRevision test,
    required Iterable<AssessmentQuestionRevision> questions,
    required Map<int, int> answersByOrder,
  }) {
    final byIdentity = <QuestionRevisionId, AssessmentQuestionRevision>{};
    for (final question in questions) {
      if (byIdentity.putIfAbsent(question.id, () => question) != question) {
        throw ArgumentError.value(
          question.id,
          'questions',
          'contains duplicate exact question revisions',
        );
      }
    }

    final validOrders = test.questionRefs.map((ref) => ref.order).toSet();
    for (final order in answersByOrder.keys) {
      if (!validOrders.contains(order)) {
        throw ArgumentError.value(
          order,
          'answersByOrder',
          'does not belong to this test revision',
        );
      }
    }

    var earnedPoints = 0;
    var totalPoints = 0;
    var correctCount = 0;

    for (final ref in test.questionRefs) {
      final question = byIdentity[ref.question];
      if (question == null) {
        throw StateError(
          'Missing exact question revision '
          '${ref.question.questionCode}@${ref.question.revision}',
        );
      }
      final body = question.body;
      if (body is! SingleChoiceQuestionBody) {
        throw StateError('Unsupported assessment question body');
      }

      totalPoints += ref.points;
      final selectedIndex = answersByOrder[ref.order];
      if (selectedIndex == null) {
        continue;
      }
      if (selectedIndex < 0 || selectedIndex >= body.options.length) {
        throw ArgumentError.value(
          selectedIndex,
          'answersByOrder',
          'must reference an option in the exact question revision',
        );
      }
      if (selectedIndex == body.correctOptionIndex) {
        earnedPoints += ref.points;
        correctCount++;
      }
    }

    final scoreBasisPoints = (earnedPoints * 10000) ~/ totalPoints;
    return AssessmentScore(
      earnedPoints: earnedPoints,
      totalPoints: totalPoints,
      correctCount: correctCount,
      questionCount: test.questionRefs.length,
      scoreBasisPoints: scoreBasisPoints,
      passed: scoreBasisPoints >= test.passingScoreBasisPoints,
    );
  }
}

final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

String _nonBlank(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return normalized;
}
