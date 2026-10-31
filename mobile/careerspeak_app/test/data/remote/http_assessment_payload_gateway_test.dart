import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_assessment_payload_gateway.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:flutter_test/flutter_test.dart';

const _testChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _questionChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _otherChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  test(
    'fetches one exact practice-test revision over installation API',
    () async {
      final client = _RecordingApiClient(
        response: ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: _practiceTestPayload(checksum: _testChecksum),
        ),
      );
      final gateway = HttpAssessmentPayloadGateway(apiClient: client);

      final result = await gateway.fetchPracticeTestRevision(
        practiceTestCode: 'INTERVIEW_CORE',
        revision: 3,
        checksum: _testChecksum,
      );

      expect(result, isA<Success<PracticeTestRevision>>());
      expect(client.lastRequest?.method, ApiMethod.get);
      expect(
        client.lastRequest?.path,
        '/api/v1/assessment/practice-tests/INTERVIEW_CORE/revisions/3',
      );
      expect(
        client.lastRequest?.authentication,
        ApiAuthentication.installation,
      );
    },
  );

  test('practice-test checksum mismatch fails closed', () async {
    final client = _RecordingApiClient(
      response: ApiResponse(
        statusCode: 200,
        headers: const <String, String>{},
        jsonBody: _practiceTestPayload(checksum: _otherChecksum),
      ),
    );
    final gateway = HttpAssessmentPayloadGateway(apiClient: client);

    final result = await gateway.fetchPracticeTestRevision(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 3,
      checksum: _testChecksum,
    );

    final failure = (result as FailureResult<PracticeTestRevision>).failure;
    expect(failure.code, 'ASSESSMENT_PAYLOAD_MISMATCH');
  });

  test(
    'fetches one exact question revision and rejects substitution',
    () async {
      final target = QuestionRevisionId(
        questionCode: 'Q1',
        revision: 2,
        checksum: _questionChecksum,
      );
      final client = _RecordingApiClient(
        response: ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: _questionPayload(checksum: _otherChecksum),
        ),
      );
      final gateway = HttpAssessmentPayloadGateway(apiClient: client);

      final result = await gateway.fetchQuestionRevision(target);

      final failure =
          (result as FailureResult<AssessmentQuestionRevision>).failure;
      expect(failure.code, 'ASSESSMENT_PAYLOAD_MISMATCH');
      expect(
        client.lastRequest?.path,
        '/api/v1/assessment/questions/Q1/revisions/2',
      );
    },
  );

  test('non-200 assessment response is not decoded as content', () async {
    final client = _RecordingApiClient(
      response: ApiResponse(
        statusCode: 404,
        headers: const <String, String>{},
        jsonBody: const <String, Object?>{},
        traceId: 'trace-404',
      ),
    );
    final gateway = HttpAssessmentPayloadGateway(apiClient: client);

    final result = await gateway.fetchPracticeTestRevision(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 3,
      checksum: _testChecksum,
    );

    final failure = (result as FailureResult<PracticeTestRevision>).failure;
    expect(failure.code, 'ASSESSMENT_PAYLOAD_RESPONSE_INVALID');
    expect(failure.traceId, 'trace-404');
  });
}

Map<String, Object?> _practiceTestPayload({required String checksum}) {
  return <String, Object?>{
    'practiceTestCode': 'INTERVIEW_CORE',
    'revision': 3,
    'checksum': checksum,
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
        'points': 1,
      },
    ],
  };
}

Map<String, Object?> _questionPayload({required String checksum}) {
  return <String, Object?>{
    'questionCode': 'Q1',
    'revision': 2,
    'checksum': checksum,
    'body': <String, Object?>{
      'kind': 'singleChoice',
      'prompt': 'What is idempotency?',
      'options': <String>['Safe retry', 'Random retry'],
      'correctOptionIndex': 0,
      'skillCode': 'BACKEND_RELIABILITY',
      'explanation': 'Repeating the operation preserves the result.',
    },
  };
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({required this.response});

  final ApiResponse response;
  ApiRequest? lastRequest;

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    lastRequest = request;
    return Success<ApiResponse>(response);
  }
}
