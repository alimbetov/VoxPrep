import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:careerspeak_app/domain/assessment_bundle.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _testChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _otherTestChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _q1Checksum =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _q2Checksum =
    '2222222222222222222222222222222222222222222222222222222222222222';

void main() {
  test('persists and reconstructs one exact assessment revision bundle', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = DriftAssessmentRevisionRepository(database);
    final bundle = _bundle();

    final saved = await repository.saveBundle(bundle);
    expect(saved, isA<Success<AssessmentRevisionBundle>>());

    final result = await repository.readBundle(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 4,
      checksum: _testChecksum,
    );
    final restored = (result as Success<AssessmentRevisionBundle?>).value!;

    expect(restored.test.questionRefs.map((ref) => ref.order), [0, 1]);
    expect(restored.questions.map((question) => question.id), [
      bundle.test.questionRefs[0].question,
      bundle.test.questionRefs[1].question,
    ]);

    final score = const AssessmentScorer().score(
      test: restored.test,
      questions: restored.questions,
      answersByOrder: const {0: 0, 1: 1},
    );
    expect(score.earnedPoints, 1);
    expect(score.totalPoints, 3);
    expect(score.scoreBasisPoints, 3333);
  });

  test('same logical test revision with another checksum fails closed', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = DriftAssessmentRevisionRepository(database);

    expect(
      await repository.saveBundle(_bundle()),
      isA<Success<AssessmentRevisionBundle>>(),
    );
    final conflict = await repository.saveBundle(
      _bundle(testChecksum: _otherTestChecksum),
    );

    final failure = (conflict as FailureResult<AssessmentRevisionBundle>).failure;
    expect(failure.code, 'ASSESSMENT_REVISION_CHECKSUM_CONFLICT');
  });

  test('missing exact question row fails closed as incomplete local data', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = DriftAssessmentRevisionRepository(database);

    await repository.saveBundle(_bundle());
    await (database.delete(database.assessmentQuestionReads)..where(
          (row) => row.questionCode.equals('Q2') & row.revision.equals(1),
        ))
        .go();

    final result = await repository.readBundle(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 4,
      checksum: _testChecksum,
    );

    final failure =
        (result as FailureResult<AssessmentRevisionBundle?>).failure;
    expect(failure.code, 'ASSESSMENT_LOCAL_INCOMPLETE');
  });
}

AssessmentRevisionBundle _bundle({String testChecksum = _testChecksum}) {
  final q1Id = QuestionRevisionId(
    questionCode: 'Q1',
    revision: 1,
    checksum: _q1Checksum,
  );
  final q2Id = QuestionRevisionId(
    questionCode: 'Q2',
    revision: 1,
    checksum: _q2Checksum,
  );
  final test = PracticeTestRevision(
    practiceTestCode: 'INTERVIEW_CORE',
    revision: 4,
    checksum: testChecksum,
    title: 'Core interview',
    subtitle: 'Qualification',
    mode: AssessmentMode.exam,
    passingScoreBasisPoints: 6000,
    questionRefs: [
      PracticeTestQuestionRef(order: 0, question: q1Id, points: 1),
      PracticeTestQuestionRef(order: 1, question: q2Id, points: 2),
    ],
  );
  return AssessmentRevisionBundle(
    test: test,
    questions: [
      AssessmentQuestionRevision(
        id: q1Id,
        body: SingleChoiceQuestionBody(
          prompt: 'Q1?',
          options: ['A', 'B'],
          correctOptionIndex: 0,
          skillCode: 'SKILL_ONE',
          explanation: 'A.',
        ),
      ),
      AssessmentQuestionRevision(
        id: q2Id,
        body: SingleChoiceQuestionBody(
          prompt: 'Q2?',
          options: ['A', 'B'],
          correctOptionIndex: 0,
          skillCode: 'SKILL_TWO',
          explanation: 'A.',
        ),
      ),
    ],
  );
}
