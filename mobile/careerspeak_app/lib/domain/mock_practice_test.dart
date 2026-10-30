enum MockTestMode { learn, exam, quick }

class MockQuestion {
  const MockQuestion({
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

class MockPracticeTest {
  const MockPracticeTest({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.mode,
    required this.questions,
  });

  final String code;
  final String title;
  final String subtitle;
  final MockTestMode mode;
  final List<MockQuestion> questions;
}

int calculateMockTestScore(
  MockPracticeTest test,
  Map<int, int> answers,
) {
  var score = 0;
  for (var index = 0; index < test.questions.length; index++) {
    if (answers[index] == test.questions[index].correctIndex) {
      score++;
    }
  }
  return score;
}
