import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_catalogue_payload_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

const _checksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test(
    'fetches the exact catalogue revision from publication membership',
    () async {
      final client = _RecordingApiClient(
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: <String, Object?>{
              'kind': 'categories',
              'revision': 7,
              'checksum': _checksum,
              'items': <Object?>[
                <String, Object?>{
                  'code': 'JAVA_BACKEND',
                  'label': 'Java Backend',
                  'sortOrder': 0,
                  'active': true,
                },
              ],
            },
          ),
        ),
      );
      final gateway = HttpCataloguePayloadGateway(apiClient: client);
      final target = CatalogueRevisionRef(
        kind: CatalogueKind.categories,
        revision: 7,
        checksum: _checksum,
      );

      final result = await gateway.fetch(target);

      expect(result, isA<Success<CataloguePayload>>());
      expect(
        (result as Success<CataloguePayload>).value.ref.identityKey,
        target.identityKey,
      );
      expect(client.requests, hasLength(1));
      expect(
        client.requests.single.path,
        '/api/v1/catalogues/categories/revisions/7',
      );
      expect(
        client.requests.single.authentication,
        ApiAuthentication.installation,
      );
    },
  );

  test('rejects runtime fields inside immutable catalogue payload', () async {
    final client = _RecordingApiClient(
      Success<ApiResponse>(
        ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: <String, Object?>{
            'kind': 'categories',
            'revision': 7,
            'checksum': _checksum,
            'items': const <Object?>[],
            'signedUrl': 'https://example.invalid/catalogue',
          },
        ),
      ),
    );
    final gateway = HttpCataloguePayloadGateway(apiClient: client);

    final result = await gateway.fetch(
      CatalogueRevisionRef(
        kind: CatalogueKind.categories,
        revision: 7,
        checksum: _checksum,
      ),
    );

    expect(result, isA<FailureResult<CataloguePayload>>());
    expect(
      (result as FailureResult<CataloguePayload>).failure.code,
      'CATALOGUE_NON_PUBLICATION_FIELD',
    );
  });

  test(
    'rejects a different revision even when the endpoint returns 200',
    () async {
      final client = _RecordingApiClient(
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: <String, Object?>{
              'kind': 'categories',
              'revision': 8,
              'checksum': _checksum,
              'items': const <Object?>[],
            },
          ),
        ),
      );
      final gateway = HttpCataloguePayloadGateway(apiClient: client);

      final result = await gateway.fetch(
        CatalogueRevisionRef(
          kind: CatalogueKind.categories,
          revision: 7,
          checksum: _checksum,
        ),
      );

      expect(result, isA<FailureResult<CataloguePayload>>());
      expect(
        (result as FailureResult<CataloguePayload>).failure.code,
        'CATALOGUE_REVISION_MISMATCH',
      );
    },
  );
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
