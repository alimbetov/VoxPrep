import 'package:careerspeak_app/domain/mock_practice_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('score counts only exact correct answers', () {
    const testModel = MockPracticeTest(
      code: 'TEST',
      title: 'Test',
      subtitle: 'Mock',
      mode: MockTestMode.quick,
      questions: [
        MockQuestion(
          code: 'Q1',
          prompt: 'Q1',
          options: ['A', 'B'],
          correctIndex: 1,
          skill: 'Skill',
          explanation: 'E1',
        ),
        MockQuestion(
          code: 'Q2',
          prompt: 'Q2',
          options: ['A', 'B'],
          correctIndex: 0,
          skill: 'Skill',
          explanation: 'E2',
        ),
      ],
    );

    expect(calculateMockTestScore(testModel, {0: 1, 1: 1}), 1);
    expect(calculateMockTestScore(testModel, {0: 1, 1: 0}), 2);
    expect(calculateMockTestScore(testModel, const {}), 0);
  });
}
