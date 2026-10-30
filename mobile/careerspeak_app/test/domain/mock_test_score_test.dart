import 'package:careerspeak_app/domain/practice_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score counts only exact correct answers', () {
    const testModel = PracticeTest(
      code: 'TEST',
      title: 'Test',
      subtitle: 'Qualification',
      mode: PracticeTestMode.quick,
      questions: [
        PracticeQuestion(
          code: 'Q1',
          prompt: 'Q1',
          options: ['A', 'B'],
          correctIndex: 1,
          skill: 'Skill',
          explanation: 'E1',
        ),
        PracticeQuestion(
          code: 'Q2',
          prompt: 'Q2',
          options: ['A', 'B'],
          correctIndex: 0,
          skill: 'Skill',
          explanation: 'E2',
        ),
      ],
    );

    expect(calculatePracticeTestScore(testModel, {0: 1, 1: 1}), 1);
    expect(calculatePracticeTestScore(testModel, {0: 1, 1: 0}), 2);
    expect(calculatePracticeTestScore(testModel, const {}), 0);
  });
}
