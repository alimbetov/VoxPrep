import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/remote/assessment_payload_decoder.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:careerspeak_app/domain/assessment_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_database_factory.dart';

const _testChecksumV1 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _testChecksumV2 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _q1Checksum =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _q1ConflictChecksum =
    '9999999999999999999999999999999999999999999999999999999999999999';

void main() {
  test('dangling exact question ref cannot form an assessment bundle', () {
    final questionId = QuestionRevisionId(
      questionCode: 'Q1',
      revision: 1,
      checksum: _q1Checksum,
    );
    final testRevision = _testRevision(
      revision: 1,
      checksum: _testChecksumV1,
      questionId: questionId,
    );

    expect(
      () => AssessmentRevisionBundle(
        test: testRevision,
        questions: const <AssessmentQuestionRevision>[],
      ),
      throwsArgumentError,
    );
  });

  test('unknown wire field cannot be ignored by assessment decoder', () {
    const decoder = AssessmentPayloadDecoder();
    final result = decoder.decodePracticeTestRevision(<String, Object?>{
      'practiceTestCode': 'INTERVIEW_CORE',
      'revision': 1,
      'checksum': _testChecksumV1,
      'title': 'Core interview',
      'subtitle': 'Qualification',
      'mode': 'exam',
      'passingScoreBasisPoints': 6000,
      'questionRefs': <Object?>[
        <String, Object?>{
          'order': 0,
          'question': <String, Object?>{
            'questionCode': 'Q1',
            'revision': 1,
            'checksum': _q1Checksum,
          },
          'points': 1,
        },
      ],
      'serverOnlyMutation': true,
    });

    final failure = (result as FailureResult<PracticeTestRevision>).failure;
    expect(failure.code, 'ASSESSMENT_PAYLOAD_INVALID');
  });

  test(
    'question checksum conflict aborts a new test revision atomically',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftAssessmentRevisionRepository(database);

      final questionV1 = _question(
        QuestionRevisionId(
          questionCode: 'Q1',
          revision: 1,
          checksum: _q1Checksum,
        ),
      );
      final firstBundle = AssessmentRevisionBundle(
        test: _testRevision(
          revision: 1,
          checksum: _testChecksumV1,
          questionId: questionV1.id,
        ),
        questions: [questionV1],
      );
      expect(
        await repository.saveBundle(firstBundle),
        isA<Success<AssessmentRevisionBundle>>(),
      );

      final conflictingQuestion = _question(
        QuestionRevisionId(
          questionCode: 'Q1',
          revision: 1,
          checksum: _q1ConflictChecksum,
        ),
      );
      final conflictingBundle = AssessmentRevisionBundle(
        test: _testRevision(
          revision: 2,
          checksum: _testChecksumV2,
          questionId: conflictingQuestion.id,
        ),
        questions: [conflictingQuestion],
      );
      final result = await repository.saveBundle(conflictingBundle);

      final failure =
          (result as FailureResult<AssessmentRevisionBundle>).failure;
      expect(failure.code, 'ASSESSMENT_REVISION_CHECKSUM_CONFLICT');

      final leaked = await repository.readBundle(
        practiceTestCode: 'INTERVIEW_CORE',
        revision: 2,
        checksum: _testChecksumV2,
      );
      expect((leaked as Success<AssessmentRevisionBundle?>).value, isNull);
    },
  );
}

PracticeTestRevision _testRevision({
  required int revision,
  required String checksum,
  required QuestionRevisionId questionId,
}) {
  return PracticeTestRevision(
    practiceTestCode: 'INTERVIEW_CORE',
    revision: revision,
    checksum: checksum,
    title: 'Core interview',
    subtitle: 'Qualification',
    mode: AssessmentMode.exam,
    passingScoreBasisPoints: 6000,
    questionRefs: [
      PracticeTestQuestionRef(order: 0, question: questionId, points: 1),
    ],
  );
}

AssessmentQuestionRevision _question(QuestionRevisionId id) {
  return AssessmentQuestionRevision(
    id: id,
    body: SingleChoiceQuestionBody(
      prompt: 'Choose the correct statement.',
      options: ['A', 'B'],
      correctOptionIndex: 0,
      skillCode: 'ASSESSMENT_INTEGRITY',
      explanation: 'A is correct.',
    ),
  );
}
