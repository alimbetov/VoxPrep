import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_content_manifest_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HttpContentManifestGateway', () {
    test('sends ETag without locale when checking the root manifest', () async {
      final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 304,
            headers: const <String, String>{'ETag': 'etag-108'},
            jsonBody: null,
          ),
        ),
      ]);
      final gateway = HttpContentManifestGateway(apiClient: apiClient);

      final result = await gateway.fetchRootManifest(etag: 'etag-107');

      expect(result, isA<Success<RootManifestFetch>>());
      final fetch = (result as Success<RootManifestFetch>).value;
      expect(fetch, isA<RootManifestNotModified>());
      expect(fetch.etag, 'etag-108');
      expect(apiClient.requests, hasLength(1));
      final request = apiClient.requests.single;
      expect(request.method, ApiMethod.get);
      expect(request.path, '/api/v1/content/manifest');
      expect(request.queryParameters, isEmpty);
      expect(request.headers['if-none-match'], 'etag-107');
      expect(request.authentication, ApiAuthentication.installation);
    });

    test('rejects 304 when request has no ETag baseline', () async {
      final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 304,
            headers: const <String, String>{'etag': 'etag-108'},
            jsonBody: null,
            traceId: 'trace-304',
          ),
        ),
      ]);
      final gateway = HttpContentManifestGateway(apiClient: apiClient);

      final result = await gateway.fetchRootManifest();

      expect(result, isA<FailureResult<RootManifestFetch>>());
      final failure = (result as FailureResult<RootManifestFetch>).failure;
      expect(failure.code, 'MANIFEST_RESPONSE_INVALID');
      expect(failure.traceId, 'trace-304');
      expect(failure.details['statusCode'], 304);
      expect(apiClient.requests, hasLength(1));
      expect(apiClient.requests.single.headers, isEmpty);
    });

    test('rejects CRLF ETag before transport', () async {
      final apiClient = _RecordingApiClient(const <Result<ApiResponse>>[]);
      final gateway = HttpContentManifestGateway(apiClient: apiClient);

      final result = await gateway.fetchRootManifest(
        etag: 'etag-107\r\nx-injected: true',
      );

      expect(result, isA<FailureResult<RootManifestFetch>>());
      expect(
        (result as FailureResult<RootManifestFetch>).failure.code,
        'ETAG_INVALID',
      );
      expect(apiClient.requests, isEmpty);
    });

    test(
      'decodes changed locale-independent root through typed boundary',
      () async {
        final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
          Success<ApiResponse>(
            ApiResponse(
              statusCode: 200,
              headers: const <String, String>{'etag': 'etag-108'},
              jsonBody: _rootManifest(),
            ),
          ),
        ]);
        final gateway = HttpContentManifestGateway(apiClient: apiClient);

        final result = await gateway.fetchRootManifest();

        expect(result, isA<Success<RootManifestFetch>>());
        final fetch = (result as Success<RootManifestFetch>).value;
        expect(fetch, isA<RootManifestChanged>());
        final changed = fetch as RootManifestChanged;
        expect(changed.manifest.contentVersion, 108);
        expect(changed.manifest.practiceTests, isEmpty);
        expect(changed.manifest.catalogues, isEmpty);
        expect(changed.etag, 'etag-108');
        expect(apiClient.requests.single.queryParameters, isEmpty);
      },
    );

    test('fetches exact pack target from root manifest identity', () async {
      final target = PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
        revision: 8,
        checksum: _shaB,
      );
      final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: _packManifest(),
          ),
        ),
      ]);
      final gateway = HttpContentManifestGateway(apiClient: apiClient);

      final result = await gateway.fetchPackManifest(target);

      expect(result, isA<Success<PackContentManifest>>());
      final request = apiClient.requests.single;
      expect(request.path, '/api/v1/content/packs/JAVA_SENIOR/manifest');
      expect(request.queryParameters, const <String, String>{
        'variant': 'canonical',
        'revision': '8',
      });
    });

    test('rejects pack response that does not match root target', () async {
      final target = PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
        revision: 8,
        checksum: _shaA,
      );
      final apiClient = _RecordingApiClient(<Result<ApiResponse>>[
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: _packManifest(),
          ),
        ),
      ]);
      final gateway = HttpContentManifestGateway(apiClient: apiClient);

      final result = await gateway.fetchPackManifest(target);

      expect(result, isA<FailureResult<PackContentManifest>>());
      expect(
        (result as FailureResult<PackContentManifest>).failure.code,
        'PACK_MANIFEST_MISMATCH',
      );
    });

    test('propagates typed transport failure without rewriting it', () async {
      const failure = ApplicationFailure(
        code: 'OFFLINE',
        message: 'offline',
        retryable: true,
      );
      final apiClient = _RecordingApiClient(const <Result<ApiResponse>>[
        FailureResult<ApiResponse>(failure),
      ]);
      final gateway = HttpContentManifestGateway(apiClient: apiClient);

      final result = await gateway.fetchRootManifest();

      expect(result, isA<FailureResult<RootManifestFetch>>());
      expect(
        (result as FailureResult<RootManifestFetch>).failure,
        same(failure),
      );
    });
  });
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

Map<String, Object?> _rootManifest() {
  return <String, Object?>{
    'schemaVersion': 1,
    'contentVersion': 108,
    'minimumAppContractVersion': 1,
    'publishedAt': '2026-10-30T09:30:00Z',
    'checksum': _shaA,
    'packs': <Object?>[
      <String, Object?>{
        'code': 'JAVA_SENIOR',
        'variant': 'canonical',
        'revision': 8,
        'checksum': _shaB,
      },
    ],
    'practiceTests': const <Object?>[],
    'catalogues': const <Object?>[],
    'tombstones': const <Object?>[],
  };
}

Map<String, Object?> _packManifest() {
  return <String, Object?>{
    'schemaVersion': 1,
    'code': 'JAVA_SENIOR',
    'variant': 'canonical',
    'revision': 8,
    'checksum': _shaB,
    'contents': const <Object?>[],
    'localizations': const <Object?>[],
    'assets': const <Object?>[],
    'contentAssets': const <Object?>[],
  };
}

const _shaA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _shaB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
