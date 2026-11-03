import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_installation_registration_gateway.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'registers installation anonymously using frozen learner API contract',
    () async {
      final apiClient = _FakeApiClient(
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: const <String, Object?>{'installationToken': 'token-123'},
          ),
        ),
      );
      final gateway = HttpInstallationRegistrationGateway(apiClient: apiClient);

      final result = await gateway.register(InstallationId('installation-123'));

      expect(result.getOrThrow().value, 'token-123');
      expect(apiClient.requests, hasLength(1));
      final request = apiClient.requests.single;
      expect(request.method, ApiMethod.post);
      expect(request.path, '/api/v1/installations');
      expect(request.authentication, ApiAuthentication.none);
      expect(request.jsonBody, const <String, Object?>{
        'installationId': 'installation-123',
      });
    },
  );

  test('propagates transport failure without rewriting it', () async {
    final apiClient = _FakeApiClient(
      const FailureResult<ApiResponse>(
        ApplicationFailure(
          code: 'OFFLINE',
          message: 'offline',
          retryable: true,
        ),
      ),
    );
    final gateway = HttpInstallationRegistrationGateway(apiClient: apiClient);

    final result = await gateway.register(InstallationId('installation-123'));

    expect(result, isA<FailureResult<InstallationToken>>());
    expect(
      (result as FailureResult<InstallationToken>).failure.code,
      'OFFLINE',
    );
  });

  test(
    'rejects successful HTTP status outside registration contract',
    () async {
      final apiClient = _FakeApiClient(
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 201,
            headers: const <String, String>{},
            jsonBody: const <String, Object?>{'installationToken': 'token-123'},
          ),
        ),
      );
      final gateway = HttpInstallationRegistrationGateway(apiClient: apiClient);

      final result = await gateway.register(InstallationId('installation-123'));

      expect(result, isA<FailureResult<InstallationToken>>());
      expect(
        (result as FailureResult<InstallationToken>).failure.code,
        'INSTALLATION_REGISTRATION_STATUS_INVALID',
      );
    },
  );

  test('rejects malformed registration response', () async {
    final apiClient = _FakeApiClient(
      Success<ApiResponse>(
        ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{},
        ),
      ),
    );
    final gateway = HttpInstallationRegistrationGateway(apiClient: apiClient);

    final result = await gateway.register(InstallationId('installation-123'));

    expect(result, isA<FailureResult<InstallationToken>>());
    expect(
      (result as FailureResult<InstallationToken>).failure.code,
      'INSTALLATION_REGISTRATION_RESPONSE_INVALID',
    );
  });

  test(
    'uses installation authentication when rotating an existing token',
    () async {
      final store = _TestCredentialStore();
      await store.writeInstallationToken(InstallationToken('previous-token'));
      final apiClient = _FakeApiClient(
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: const <String, Object?>{'installationToken': 'new-token'},
          ),
        ),
      );
      final gateway = HttpInstallationRegistrationGateway(
        apiClient: apiClient,
        credentialStore: store,
      );

      final result = await gateway.register(InstallationId('installation-123'));

      expect(result.getOrThrow().value, 'new-token');
      expect(
        apiClient.requests.single.authentication,
        ApiAuthentication.installation,
      );
    },
  );

  test(
    'uses anonymous authentication on first registration with empty store',
    () async {
      final store = _TestCredentialStore();
      final apiClient = _FakeApiClient(
        Success<ApiResponse>(
          ApiResponse(
            statusCode: 200,
            headers: const <String, String>{},
            jsonBody: const <String, Object?>{'installationToken': 'new-token'},
          ),
        ),
      );
      final gateway = HttpInstallationRegistrationGateway(
        apiClient: apiClient,
        credentialStore: store,
      );

      await gateway.register(InstallationId('installation-123'));

      expect(apiClient.requests.single.authentication, ApiAuthentication.none);
    },
  );
}

final class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.result);

  final Result<ApiResponse> result;
  final List<ApiRequest> requests = <ApiRequest>[];

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    requests.add(request);
    return result;
  }
}

final class _TestCredentialStore implements InstallationCredentialStore {
  InstallationId? _id;
  InstallationToken? _token;

  @override
  Future<InstallationId?> readInstallationId() async => _id;

  @override
  Future<InstallationToken?> readInstallationToken() async => _token;

  @override
  Future<void> writeInstallationId(InstallationId id) async {
    _id = id;
  }

  @override
  Future<void> writeInstallationToken(InstallationToken token) async {
    _token = token;
  }

  @override
  Future<void> clearInstallationToken() async {
    _token = null;
  }

  @override
  Future<void> clear() async {
    _id = null;
    _token = null;
  }
}
