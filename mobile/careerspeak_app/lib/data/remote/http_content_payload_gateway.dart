import '../../application/content_delivery/content_payload.dart';
import '../../application/ports/api_client.dart';
import '../../application/ports/content_payload_gateway.dart';
import '../../application/result/result.dart';
import 'content_payload_decoder.dart';

final class HttpContentPayloadGateway implements ContentPayloadGateway {
  factory HttpContentPayloadGateway({
    required ApiClient apiClient,
    ContentPayloadDecoder decoder = const ContentPayloadDecoder(),
  }) {
    return HttpContentPayloadGateway._(apiClient, decoder);
  }

  const HttpContentPayloadGateway._(this._apiClient, this._decoder);

  final ApiClient _apiClient;
  final ContentPayloadDecoder _decoder;

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async {
    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path:
            '/api/v1/content/${Uri.encodeComponent(target.identity.type.name)}/${Uri.encodeComponent(target.identity.code)}/revisions/${target.revision}',
      ),
    );

    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<ContentPayload>(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    if (apiResponse.statusCode != 200) {
      return FailureResult<ContentPayload>(
        ApplicationFailure(
          code: 'CONTENT_PAYLOAD_RESPONSE_INVALID',
          message: 'The content payload endpoint returned an invalid status.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{'statusCode': apiResponse.statusCode},
        ),
      );
    }

    final decoded = _decoder.decode(apiResponse.jsonBody);
    if (decoded case FailureResult<ContentPayload>(:final failure)) {
      return FailureResult<ContentPayload>(failure);
    }

    final payload = (decoded as Success<ContentPayload>).value;
    if (payload.ref.identity != target.identity ||
        payload.ref.revision != target.revision ||
        payload.ref.checksum != target.checksum) {
      return FailureResult<ContentPayload>(
        ApplicationFailure(
          code: 'CONTENT_PAYLOAD_MISMATCH',
          message: 'The content payload does not match the requested revision.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{
            'expectedCode': target.identity.code,
            'expectedType': target.identity.type.name,
            'expectedRevision': target.revision,
            'actualCode': payload.ref.identity.code,
            'actualType': payload.ref.identity.type.name,
            'actualRevision': payload.ref.revision,
          },
        ),
      );
    }

    return Success<ContentPayload>(payload);
  }
}
