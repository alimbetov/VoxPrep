enum PracticeTestMode { learn, exam, quick }

class PracticeQuestion {
  const PracticeQuestion({
    required this.code,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.skill,
    required this.explanation,
  });

  final String code;
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final String skill;
  final String explanation;
}

class PracticeTestSummary {
  const PracticeTestSummary({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.questionCount,
  });

  final String code;
  final String title;
  final String subtitle;
  final PracticeTestMode mode;
  final int questionCount;
}

class PracticeTest {
  const PracticeTest({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.questions,
  });

  final String code;
  final String title;
  final String subtitle;
  final PracticeTestMode mode;
  final List<PracticeQuestion> questions;

  PracticeTestSummary get summary => PracticeTestSummary(
    code: code,
    title: title,
    subtitle: subtitle,
    mode: mode,
    questionCount: questions.length,
  );
}

int calculatePracticeTestScore(PracticeTest test, Map<int, int> answers) {
  var score = 0;
  for (var index = 0; index < test.questions.length; index++) {
    if (answers[index] == test.questions[index].correctIndex) {
      score++;
    }
  }
  return score;
}
