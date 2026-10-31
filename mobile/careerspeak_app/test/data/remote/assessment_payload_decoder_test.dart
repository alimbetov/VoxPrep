import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/assessment_payload_decoder.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:flutter_test/flutter_test.dart';

const _testChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _questionChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  const decoder = AssessmentPayloadDecoder();

  test('decodes exact practice-test revision without normalizing order', () {
    final result = decoder.decodePracticeTestRevision(<String, Object?>{
      'practiceTestCode': 'INTERVIEW_CORE',
      'revision': 3,
      'checksum': _testChecksum,
      'title': 'Core interview',
      'subtitle': 'Qualification',
      'mode': 'exam',
      'passingScoreBasisPoints': 7000,
      'questionRefs': <Object?>[
        <String, Object?>{
          'order': 0,
          'question': <String, Object?>{
            'questionCode': 'Q1',
            'revision': 2,
            'checksum': _questionChecksum,
          },
          'points': 2,
        },
      ],
    });

    final payload = (result as Success<PracticeTestRevision>).value;
    expect(payload.practiceTestCode, 'INTERVIEW_CORE');
    expect(payload.revision, 3);
    expect(payload.questionRefs.single.order, 0);
    expect(payload.questionRefs.single.question.revision, 2);
  });

  test('decodes frozen single-choice question body', () {
    final result = decoder.decodeQuestionRevision(<String, Object?>{
      'questionCode': 'Q1',
      'revision': 2,
      'checksum': _questionChecksum,
      'body': <String, Object?>{
        'kind': 'singleChoice',
        'prompt': 'What is idempotency?',
        'options': <String>['Safe retry', 'Random retry'],
        'correctOptionIndex': 0,
        'skillCode': 'BACKEND_RELIABILITY',
        'explanation': 'Repeating the operation preserves the result.',
      },
    });

    final payload = (result as Success<AssessmentQuestionRevision>).value;
    final body = payload.body as SingleChoiceQuestionBody;
    expect(body.correctOptionIndex, 0);
    expect(body.skillCode, 'BACKEND_RELIABILITY');
  });

  test('unknown assessment payload field fails closed', () {
    final result = decoder.decodeQuestionRevision(<String, Object?>{
      'questionCode': 'Q1',
      'revision': 2,
      'checksum': _questionChecksum,
      'body': <String, Object?>{
        'kind': 'singleChoice',
        'prompt': 'Prompt',
        'options': <String>['A', 'B'],
        'correctOptionIndex': 0,
        'skillCode': 'SKILL',
        'explanation': 'Explanation',
        'unexpected': true,
      },
    });

    final failure =
        (result as FailureResult<AssessmentQuestionRevision>).failure;
    expect(failure.code, 'ASSESSMENT_PAYLOAD_INVALID');
  });

  test('unsupported question kind fails closed', () {
    final result = decoder.decodeQuestionRevision(<String, Object?>{
      'questionCode': 'Q1',
      'revision': 2,
      'checksum': _questionChecksum,
      'body': <String, Object?>{
        'kind': 'freeText',
        'prompt': 'Prompt',
        'options': <String>['A', 'B'],
        'correctOptionIndex': 0,
        'skillCode': 'SKILL',
        'explanation': 'Explanation',
      },
    });

    final failure =
        (result as FailureResult<AssessmentQuestionRevision>).failure;
    expect(failure.code, 'ASSESSMENT_PAYLOAD_INVALID');
  });

  test('wire permutation that disagrees with order fails closed', () {
    final result = decoder.decodePracticeTestRevision(<String, Object?>{
      'practiceTestCode': 'INTERVIEW_CORE',
      'revision': 3,
      'checksum': _testChecksum,
      'title': 'Core interview',
      'subtitle': 'Qualification',
      'mode': 'exam',
      'passingScoreBasisPoints': 7000,
      'questionRefs': <Object?>[
        <String, Object?>{
          'order': 1,
          'question': <String, Object?>{
            'questionCode': 'Q1',
            'revision': 2,
            'checksum': _questionChecksum,
          },
          'points': 1,
        },
      ],
    });

    final failure = (result as FailureResult<PracticeTestRevision>).failure;
    expect(failure.code, 'ASSESSMENT_PAYLOAD_INVALID');
  });
}
