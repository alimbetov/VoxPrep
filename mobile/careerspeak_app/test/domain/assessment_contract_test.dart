import 'package:careerspeak_app/domain/assessment.dart';
import 'package:flutter_test/flutter_test.dart';

const _q1Checksum =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _q2Checksum =
    '2222222222222222222222222222222222222222222222222222222222222222';
const _testChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('test revision freezes contiguous ordered exact question refs', () {
    final q1 = QuestionRevisionId(
      questionCode: 'Q1',
      revision: 1,
      checksum: _q1Checksum,
    );
    final q2 = QuestionRevisionId(
      questionCode: 'Q2',
      revision: 3,
      checksum: _q2Checksum,
    );

    final testRevision = PracticeTestRevision(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 4,
      checksum: _testChecksum,
      title: 'Core interview',
      subtitle: 'Qualification',
      mode: AssessmentMode.exam,
      passingScoreBasisPoints: 7500,
      questionRefs: [
        PracticeTestQuestionRef(order: 1, question: q2, points: 2),
        PracticeTestQuestionRef(order: 0, question: q1, points: 1),
      ],
    );

    expect(testRevision.questionRefs.map((ref) => ref.order), [0, 1]);
    expect(testRevision.questionRefs[1].question.revision, 3);
  });

  test('non-contiguous question order fails closed', () {
    final q1 = QuestionRevisionId(
      questionCode: 'Q1',
      revision: 1,
      checksum: _q1Checksum,
    );

    expect(
      () => PracticeTestRevision(
        practiceTestCode: 'BROKEN',
        revision: 1,
        checksum: _testChecksum,
        title: 'Broken',
        subtitle: 'Broken ordering',
        mode: AssessmentMode.quick,
        passingScoreBasisPoints: 5000,
        questionRefs: [
          PracticeTestQuestionRef(order: 1, question: q1, points: 1),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('score is deterministic against exact immutable question revisions', () {
    final q1Id = QuestionRevisionId(
      questionCode: 'Q1',
      revision: 1,
      checksum: _q1Checksum,
    );
    final q2Id = QuestionRevisionId(
      questionCode: 'Q2',
      revision: 2,
      checksum: _q2Checksum,
    );
    final testRevision = PracticeTestRevision(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 4,
      checksum: _testChecksum,
      title: 'Core interview',
      subtitle: 'Qualification',
      mode: AssessmentMode.exam,
      passingScoreBasisPoints: 6000,
      questionRefs: [
        PracticeTestQuestionRef(order: 0, question: q1Id, points: 1),
        PracticeTestQuestionRef(order: 1, question: q2Id, points: 2),
      ],
    );
    final q1 = AssessmentQuestionRevision(
      id: q1Id,
      body: SingleChoiceQuestionBody(
        prompt: 'What does idempotent mean?',
        options: ['Safe to retry', 'Always asynchronous'],
        correctOptionIndex: 0,
        skillCode: 'BACKEND_RELIABILITY',
        explanation: 'Repeating the same operation preserves the result.',
      ),
    );
    final q2 = AssessmentQuestionRevision(
      id: q2Id,
      body: SingleChoiceQuestionBody(
        prompt: 'Which boundary owns transaction atomicity?',
        options: ['Repository transaction', 'Widget tree'],
        correctOptionIndex: 0,
        skillCode: 'BACKEND_TRANSACTIONS',
        explanation: 'Atomicity belongs to the persistence transaction.',
      ),
    );

    final score = const AssessmentScorer().score(
      test: testRevision,
      questions: [q2, q1],
      answersByOrder: {1: 0, 0: 1},
    );

    expect(score.earnedPoints, 2);
    expect(score.totalPoints, 3);
    expect(score.correctCount, 1);
    expect(score.questionCount, 2);
    expect(score.scoreBasisPoints, 6666);
    expect(score.passed, isTrue);
  });

  test('a newer question revision cannot satisfy an old exact ref', () {
    final oldId = QuestionRevisionId(
      questionCode: 'Q1',
      revision: 1,
      checksum: _q1Checksum,
    );
    final newId = QuestionRevisionId(
      questionCode: 'Q1',
      revision: 2,
      checksum: _q2Checksum,
    );
    final testRevision = PracticeTestRevision(
      practiceTestCode: 'HISTORY',
      revision: 1,
      checksum: _testChecksum,
      title: 'History',
      subtitle: 'Exact revisions',
      mode: AssessmentMode.learn,
      passingScoreBasisPoints: 0,
      questionRefs: [
        PracticeTestQuestionRef(order: 0, question: oldId, points: 1),
      ],
    );
    final newerQuestion = AssessmentQuestionRevision(
      id: newId,
      body: SingleChoiceQuestionBody(
        prompt: 'Changed prompt',
        options: ['A', 'B'],
        correctOptionIndex: 1,
        skillCode: 'REVISIONING',
        explanation: 'Changed explanation',
      ),
    );

    expect(
      () => const AssessmentScorer().score(
        test: testRevision,
        questions: [newerQuestion],
        answersByOrder: const {0: 1},
      ),
      throwsStateError,
    );
  });

  test('answer outside the exact option set fails closed', () {
    final id = QuestionRevisionId(
      questionCode: 'Q1',
      revision: 1,
      checksum: _q1Checksum,
    );
    final question = AssessmentQuestionRevision(
      id: id,
      body: SingleChoiceQuestionBody(
        prompt: 'Choose one',
        options: ['A', 'B'],
        correctOptionIndex: 0,
        skillCode: 'VALIDATION',
        explanation: 'A is correct.',
      ),
    );
    final testRevision = PracticeTestRevision(
      practiceTestCode: 'VALIDATION',
      revision: 1,
      checksum: _testChecksum,
      title: 'Validation',
      subtitle: 'Fail closed',
      mode: AssessmentMode.quick,
      passingScoreBasisPoints: 5000,
      questionRefs: [
        PracticeTestQuestionRef(order: 0, question: id, points: 1),
      ],
    );

    expect(
      () => const AssessmentScorer().score(
        test: testRevision,
        questions: [question],
        answersByOrder: const {0: 2},
      ),
      throwsArgumentError,
    );
  });
}
