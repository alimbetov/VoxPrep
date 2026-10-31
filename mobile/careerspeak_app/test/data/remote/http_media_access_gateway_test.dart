import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/ports/media_access_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_media_access_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'posts exact assetId through installation-authenticated media API',
    () async {
      final client = _RecordingApiClient(
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: <String, Object?>{
              'assetId': 'asset-a',
              'url': 'https://media.example.test/signed/a?signature=abc',
              'expiresAt': '2026-11-01T12:05:00Z',
            },
          ),
        ),
      );
      final gateway = HttpMediaAccessGateway(apiClient: client);

      final result = await gateway.resolve('asset-a');

      expect(result, isA<Success<MediaAccessGrant>>());
      final grant = (result as Success<MediaAccessGrant>).value;
      expect(grant.assetId, 'asset-a');
      expect(grant.url.scheme, 'https');
      expect(client.requests, hasLength(1));
      final request = client.requests.single;
      expect(request.method, ApiMethod.post);
      expect(request.path, '/api/v1/media/access');
      expect(request.authentication, ApiAuthentication.installation);
      expect(request.jsonBody, <String, Object?>{'assetId': 'asset-a'});
    },
  );

  test('rejects mismatched asset identity in access grant', () async {
    final gateway = HttpMediaAccessGateway(
      apiClient: _RecordingApiClient(
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: <String, Object?>{
              'assetId': 'asset-b',
              'url': 'https://media.example.test/signed/b',
              'expiresAt': '2026-11-01T12:05:00Z',
            },
          ),
        ),
      ),
    );

    final result = await gateway.resolve('asset-a');

    expect(result, isA<FailureResult<MediaAccessGrant>>());
    expect(
      (result as FailureResult<MediaAccessGrant>).failure.code,
      'MEDIA_ACCESS_RESPONSE_INVALID',
    );
  });

  test('rejects unknown response fields and insecure URLs', () async {
    for (final body in <Map<String, Object?>>[
      <String, Object?>{
        'assetId': 'asset-a',
        'url': 'https://media.example.test/signed/a',
        'expiresAt': '2026-11-01T12:05:00Z',
        'deliveryKey': 'must-not-leak',
      },
      <String, Object?>{
        'assetId': 'asset-a',
        'url': 'http://media.example.test/signed/a',
        'expiresAt': '2026-11-01T12:05:00Z',
      },
    ]) {
      final gateway = HttpMediaAccessGateway(
        apiClient: _RecordingApiClient(
          Success<ApiResponse>(
            ApiResponse(
              statusCode: 200,
              headers: const <String, String>{},
              jsonBody: body,
            ),
          ),
        ),
      );

      final result = await gateway.resolve('asset-a');
      expect(result, isA<FailureResult<MediaAccessGrant>>());
      expect(
        (result as FailureResult<MediaAccessGrant>).failure.code,
        'MEDIA_ACCESS_RESPONSE_INVALID',
      );
    }
  });

  test('maps backend media lifecycle statuses explicitly', () async {
    const expected = <int, String>{
      401: 'INSTALLATION_UNAUTHORIZED',
      403: 'MEDIA_ACCESS_FORBIDDEN',
      404: 'ASSET_NOT_FOUND',
      409: 'ASSET_NOT_READY',
      429: 'RATE_LIMITED',
      503: 'MEDIA_ACCESS_UNAVAILABLE',
    };

    for (final entry in expected.entries) {
      final gateway = HttpMediaAccessGateway(
        apiClient: _RecordingApiClient(
          Success<ApiResponse>(
            ApiResponse(
              statusCode: entry.key,
              headers: const <String, String>{},
              jsonBody: const <String, Object?>{},
            ),
          ),
        ),
      );

      final result = await gateway.resolve('asset-a');
      expect(result, isA<FailureResult<MediaAccessGrant>>());
      expect(
        (result as FailureResult<MediaAccessGrant>).failure.code,
        entry.value,
      );
    }
  });
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient(this.response);

  final Result<ApiResponse> response;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    requests.add(request);
    return response;
  }
}
