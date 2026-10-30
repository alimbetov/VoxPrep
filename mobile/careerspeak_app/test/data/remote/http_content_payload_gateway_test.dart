import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_content_payload_gateway.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _contentHash =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _otherHash =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

void main() {
  group('HttpContentPayloadGateway', () {
    test('fetches the exact authenticated content revision', () async {
      final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: _payloadJson(),
          ),
        ),
      ]);
      final gateway = HttpContentPayloadGateway(apiClient: apiClient);

      final result = await gateway.fetch(_target());

      expect(result, isA<Success<ContentPayload>>());
      final request = apiClient.requests.single;
      expect(request.method, ApiMethod.get);
      expect(request.path, '/api/v1/content/interview/JAVA_Q_001/revisions/3');
      expect(request.authentication, ApiAuthentication.installation);
    });

    test('rejects response that does not match requested checksum', () async {
      final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: _payloadJson()..['checksum'] = _otherHash,
            traceId: 'trace-payload',
          ),
        ),
      ]);
      final gateway = HttpContentPayloadGateway(apiClient: apiClient);

      final result = await gateway.fetch(_target());

      expect(result, isA<FailureResult<ContentPayload>>());
      final failure = (result as FailureResult<ContentPayload>).failure;
      expect(failure.code, 'CONTENT_PAYLOAD_MISMATCH');
      expect(failure.traceId, 'trace-payload');
    });

    test('rejects non-success endpoint status', () async {
      final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 404,
            headers: const <String, String>{},
            jsonBody: null,
            traceId: 'trace-404',
          ),
        ),
      ]);
      final gateway = HttpContentPayloadGateway(apiClient: apiClient);

      final result = await gateway.fetch(_target());

      expect(result, isA<FailureResult<ContentPayload>>());
      final failure = (result as FailureResult<ContentPayload>).failure;
      expect(failure.code, 'CONTENT_PAYLOAD_RESPONSE_INVALID');
      expect(failure.traceId, 'trace-404');
      expect(failure.details['statusCode'], 404);
    });

    test('propagates typed transport failure unchanged', () async {
      const failure = ApplicationFailure(
        code: 'OFFLINE',
        message: 'offline',
        retryable: true,
      );
      final apiClient = _RecordingApiClient(const <Result<ApiResponse>>[
        FailureResult<ApiResponse>(failure),
      ]);
      final gateway = HttpContentPayloadGateway(apiClient: apiClient);

      final result = await gateway.fetch(_target());

      expect(result, isA<FailureResult<ContentPayload>>());
      expect((result as FailureResult<ContentPayload>).failure, same(failure));
    });
  });
}

ContentPayloadRef _target() {
  return ContentPayloadRef(
    identity: ContentIdentity(code: 'JAVA_Q_001', type: ContentType.interview),
    revision: 3,
    checksum: _contentHash,
  );
}

Map<String, Object?> _payloadJson() {
  return <String, Object?>{
    'contentCode': 'JAVA_Q_001',
    'contentType': 'interview',
    'revision': 3,
    'checksum': _contentHash,
    'title': 'Dependency Injection',
    'subtitle': 'Java Backend',
    'description': 'Explain constructor injection and its tradeoffs.',
    'category': 'Java Backend',
    'level': 'Senior',
    'minutes': 6,
    'hasAudio': true,
  };
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient(this._responses);

  final List<Result<ApiResponse>> _responses;
  final List<ApiRequest> requests = <ApiRequest>[];
  var _index = 0;

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    requests.add(request);
    if (_index >= _responses.length) {
      throw StateError('No prepared API response.');
    }
    final response = _responses[_index];
    _index += 1;
    return response;
  }
}
