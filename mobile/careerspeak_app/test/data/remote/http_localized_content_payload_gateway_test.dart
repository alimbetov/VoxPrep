import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/localized_content_payload.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_localized_content_payload_gateway.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _otherHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  group('HttpLocalizedContentPayloadGateway', () {
    test(
      'fetches exact localization revision using installation auth',
      () async {
        final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
          Success<ApiResponse>(
            ApiResponse(
              statusCode: 200,
              headers: const <String, String>{},
              jsonBody: _payloadJson(),
            ),
          ),
        ]);
        final gateway = HttpLocalizedContentPayloadGateway(
          apiClient: apiClient,
        );

        final result = await gateway.fetch(_target());

        expect(result, isA<Success<LocalizedContentPayload>>());
        final request = apiClient.requests.single;
        expect(request.method, ApiMethod.get);
        expect(
          request.path,
          '/api/v1/content/interview/JAVA_Q_001/revisions/3/localizations/ru/revisions/2',
        );
        expect(request.authentication, ApiAuthentication.installation);
      },
    );

    test('rejects response with mismatched localization checksum', () async {
      final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: _payloadJson()..['checksum'] = _otherHash,
            traceId: 'trace-localized',
          ),
        ),
      ]);
      final gateway = HttpLocalizedContentPayloadGateway(apiClient: apiClient);

      final result = await gateway.fetch(_target());

      expect(result, isA<FailureResult<LocalizedContentPayload>>());
      final failure =
          (result as FailureResult<LocalizedContentPayload>).failure;
      expect(failure.code, 'LOCALIZED_CONTENT_PAYLOAD_MISMATCH');
      expect(failure.traceId, 'trace-localized');
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
      final gateway = HttpLocalizedContentPayloadGateway(apiClient: apiClient);

      final result = await gateway.fetch(_target());

      expect(result, isA<FailureResult<LocalizedContentPayload>>());
      expect(
        (result as FailureResult<LocalizedContentPayload>).failure,
        same(failure),
      );
    });
  });
}

LocalizedContentRef _target() {
  return LocalizedContentRef(
    identity: ContentIdentity(code: 'JAVA_Q_001', type: ContentType.interview),
    contentRevision: 3,
    locale: 'ru',
    localizationRevision: 2,
    checksum: _hash,
  );
}

Map<String, Object?> _payloadJson() {
  return <String, Object?>{
    'contentCode': 'JAVA_Q_001',
    'contentType': 'interview',
    'contentRevision': 3,
    'locale': 'ru',
    'localizationRevision': 2,
    'checksum': _hash,
    'title': 'Внедрение зависимостей',
    'subtitle': 'Java Backend',
    'description': 'Объясните constructor injection.',
    'translation': null,
    'hint': 'Сравните constructor и field injection.',
    'explanation': null,
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
