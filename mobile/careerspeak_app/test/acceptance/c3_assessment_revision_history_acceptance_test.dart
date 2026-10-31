import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:careerspeak_app/domain/assessment_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_database_factory.dart';

const _testChecksumV1 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _testChecksumV2 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _questionChecksumV1 =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _questionChecksumV2 =
    '2222222222222222222222222222222222222222222222222222222222222222';

void main() {
  test('new revisions do not rewrite historical assessment scoring', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = DriftAssessmentRevisionRepository(database);

    final revision1 = _bundle(
      testRevision: 1,
      testChecksum: _testChecksumV1,
      questionRevision: 1,
      questionChecksum: _questionChecksumV1,
      correctOptionIndex: 0,
    );
    final revision2 = _bundle(
      testRevision: 2,
      testChecksum: _testChecksumV2,
      questionRevision: 2,
      questionChecksum: _questionChecksumV2,
      correctOptionIndex: 1,
    );

    expect(
      await repository.saveBundle(revision1),
      isA<Success<AssessmentRevisionBundle>>(),
    );
    final before = _score(revision1);
    expect(before.scoreBasisPoints, 10000);

    expect(
      await repository.saveBundle(revision2),
      isA<Success<AssessmentRevisionBundle>>(),
    );

    final restoredResult = await repository.readBundle(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 1,
      checksum: _testChecksumV1,
    );
    final restored =
        (restoredResult as Success<AssessmentRevisionBundle?>).value!;
    final after = _score(restored);

    expect(after.earnedPoints, before.earnedPoints);
    expect(after.totalPoints, before.totalPoints);
    expect(after.scoreBasisPoints, before.scoreBasisPoints);
    expect(after.passed, before.passed);
    expect(restored.test.revision, 1);
    expect(restored.questions.single.id.revision, 1);
  });
}

AssessmentScore _score(AssessmentRevisionBundle bundle) {
  return const AssessmentScorer().score(
    test: bundle.test,
    questions: bundle.questions,
    answersByOrder: const {0: 0},
  );
}

AssessmentRevisionBundle _bundle({
  required int testRevision,
  required String testChecksum,
  required int questionRevision,
  required String questionChecksum,
  required int correctOptionIndex,
}) {
  final questionId = QuestionRevisionId(
    questionCode: 'Q1',
    revision: questionRevision,
    checksum: questionChecksum,
  );
  return AssessmentRevisionBundle(
    test: PracticeTestRevision(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: testRevision,
      checksum: testChecksum,
      title: 'Core interview',
      subtitle: 'Qualification',
      mode: AssessmentMode.exam,
      passingScoreBasisPoints: 6000,
      questionRefs: [
        PracticeTestQuestionRef(order: 0, question: questionId, points: 1),
      ],
    ),
    questions: [
      AssessmentQuestionRevision(
        id: questionId,
        body: SingleChoiceQuestionBody(
          prompt: 'Choose one.',
          options: const ['A', 'B'],
          correctOptionIndex: correctOptionIndex,
          skillCode: 'REVISION_HISTORY',
          explanation: 'Exact revision scoring must remain reproducible.',
        ),
      ),
    ],
  );
}
