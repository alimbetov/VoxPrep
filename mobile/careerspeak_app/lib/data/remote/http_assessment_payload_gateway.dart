import '../../application/ports/api_client.dart';
import '../../application/ports/assessment_payload_gateway.dart';
import '../../application/result/result.dart';
import '../../domain/assessment.dart';
import 'assessment_payload_decoder.dart';

final class HttpAssessmentPayloadGateway implements AssessmentPayloadGateway {
  factory HttpAssessmentPayloadGateway({
    required ApiClient apiClient,
    AssessmentPayloadDecoder decoder = const AssessmentPayloadDecoder(),
  }) {
    return HttpAssessmentPayloadGateway._(apiClient, decoder);
  }

  const HttpAssessmentPayloadGateway._(this._apiClient, this._decoder);

  final ApiClient _apiClient;
  final AssessmentPayloadDecoder _decoder;

  @override
  Future<Result<PracticeTestRevision>> fetchPracticeTestRevision({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) async {
    final targetFailure = _validatePracticeTestTarget(
      practiceTestCode: practiceTestCode,
      revision: revision,
      checksum: checksum,
    );
    if (targetFailure != null) {
      return FailureResult<PracticeTestRevision>(targetFailure);
    }

    final normalizedCode = practiceTestCode.trim();
    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path:
            '/api/v1/assessment/practice-tests/${Uri.encodeComponent(normalizedCode)}/revisions/$revision',
      ),
    );
    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<PracticeTestRevision>(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    if (apiResponse.statusCode != 200) {
      return FailureResult<PracticeTestRevision>(_invalidStatus(apiResponse));
    }

    final decoded = _decoder.decodePracticeTestRevision(apiResponse.jsonBody);
    if (decoded case FailureResult<PracticeTestRevision>(:final failure)) {
      return FailureResult<PracticeTestRevision>(failure);
    }
    final payload = (decoded as Success<PracticeTestRevision>).value;
    if (payload.practiceTestCode != normalizedCode ||
        payload.revision != revision ||
        payload.checksum != checksum) {
      return FailureResult<PracticeTestRevision>(
        ApplicationFailure(
          code: 'ASSESSMENT_PAYLOAD_MISMATCH',
          message:
              'The practice-test payload does not match the requested revision.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{
            'expectedCode': normalizedCode,
            'expectedRevision': revision,
            'actualCode': payload.practiceTestCode,
            'actualRevision': payload.revision,
          },
        ),
      );
    }

    return Success<PracticeTestRevision>(payload);
  }

  @override
  Future<Result<AssessmentQuestionRevision>> fetchQuestionRevision(
    QuestionRevisionId target,
  ) async {
    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path:
            '/api/v1/assessment/questions/${Uri.encodeComponent(target.questionCode)}/revisions/${target.revision}',
      ),
    );
    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<AssessmentQuestionRevision>(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    if (apiResponse.statusCode != 200) {
      return FailureResult<AssessmentQuestionRevision>(
        _invalidStatus(apiResponse),
      );
    }

    final decoded = _decoder.decodeQuestionRevision(apiResponse.jsonBody);
    if (decoded case FailureResult<AssessmentQuestionRevision>(
      :final failure,
    )) {
      return FailureResult<AssessmentQuestionRevision>(failure);
    }
    final payload = (decoded as Success<AssessmentQuestionRevision>).value;
    if (payload.id != target) {
      return FailureResult<AssessmentQuestionRevision>(
        ApplicationFailure(
          code: 'ASSESSMENT_PAYLOAD_MISMATCH',
          message:
              'The question payload does not match the requested revision.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{
            'expectedCode': target.questionCode,
            'expectedRevision': target.revision,
            'actualCode': payload.id.questionCode,
            'actualRevision': payload.id.revision,
          },
        ),
      );
    }

    return Success<AssessmentQuestionRevision>(payload);
  }

  ApplicationFailure _invalidStatus(ApiResponse response) {
    return ApplicationFailure(
      code: 'ASSESSMENT_PAYLOAD_RESPONSE_INVALID',
      message: 'The assessment payload endpoint returned an invalid status.',
      traceId: response.traceId,
      details: <String, Object?>{'statusCode': response.statusCode},
    );
  }

  ApplicationFailure? _validatePracticeTestTarget({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) {
    final code = practiceTestCode.trim();
    if (!_businessCodePattern.hasMatch(code) ||
        revision < 1 ||
        !_sha256Pattern.hasMatch(checksum)) {
      return const ApplicationFailure(
        code: 'ASSESSMENT_TARGET_INVALID',
        message: 'The requested practice-test revision identity is invalid.',
      );
    }
    return null;
  }
}

final _businessCodePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
