import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_api_client.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('sends selected locale and country as managed Backend headers', () async {
    final client = HttpApiClient(
      client: MockClient((request) async {
        expect(request.headers['accept-language'], 'ru-KZ');
        expect(request.headers['x-country-code'], 'KZ');
        expect(request.headers['authorization'], 'Bearer token-1');
        return http.Response('{}', 200);
      }),
      credentialStore: _MemoryCredentialStore(InstallationToken('token-1')),
      baseUri: Uri.parse('https://api.example.test'),
      contextHeadersProvider: () async => const <String, String>{
        'accept-language': 'ru-KZ',
        'x-country-code': 'KZ',
      },
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content/manifest'),
    );

    expect(result, isA<Success<ApiResponse>>());
  });

  test('caller cannot override managed locale context headers', () async {
    final client = HttpApiClient(
      client: MockClient((request) async {
        expect(request.headers['accept-language'], 'kk-KZ');
        expect(request.headers['x-country-code'], 'KZ');
        return http.Response('{}', 200);
      }),
      credentialStore: _MemoryCredentialStore(InstallationToken('token-1')),
      baseUri: Uri.parse('https://api.example.test'),
      contextHeadersProvider: () async => const <String, String>{
        'accept-language': 'kk-KZ',
        'x-country-code': 'KZ',
      },
    );

    final result = await client.send(
      ApiRequest(
        method: ApiMethod.get,
        path: '/api/v1/content/manifest',
        headers: const <String, String>{
          'Accept-Language': 'ru-KZ',
          'X-Country-Code': 'RU',
        },
      ),
    );

    expect(result, isA<Success<ApiResponse>>());
  });

  test('pre-onboarding request may send neutral language without country', () async {
    final client = HttpApiClient(
      client: MockClient((request) async {
        expect(request.headers['accept-language'], 'en');
        expect(request.headers['x-country-code'], isNull);
        expect(request.headers['authorization'], isNull);
        return http.Response('{}', 200);
      }),
      credentialStore: _MemoryCredentialStore(null),
      baseUri: Uri.parse('https://api.example.test'),
      contextHeadersProvider: () async => const <String, String>{
        'accept-language': 'en',
      },
    );

    final result = await client.send(
      ApiRequest(
        method: ApiMethod.get,
        path: '/api/v1/configuration/locales',
        authentication: ApiAuthentication.none,
      ),
    );

    expect(result, isA<Success<ApiResponse>>());
  });

  test('rejects unsafe locale context before network transport', () async {
    var calls = 0;
    final client = HttpApiClient(
      client: MockClient((request) async {
        calls += 1;
        return http.Response('{}', 200);
      }),
      credentialStore: _MemoryCredentialStore(InstallationToken('token-1')),
      baseUri: Uri.parse('https://api.example.test'),
      contextHeadersProvider: () async => const <String, String>{
        'accept-language': 'ru-KZ\r\nX-Evil: 1',
      },
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content/manifest'),
    );

    expect(calls, 0);
    expect(result, isA<FailureResult<ApiResponse>>());
    expect(
      (result as FailureResult<ApiResponse>).failure.code,
      'REQUEST_CONTEXT_UNAVAILABLE',
    );
  });
}

final class _MemoryCredentialStore implements InstallationCredentialStore {
  _MemoryCredentialStore(this.token);

  InstallationToken? token;
  InstallationId? installationId;

  @override
  Future<void> clear() async {
    installationId = null;
    token = null;
  }

  @override
  Future<void> clearInstallationToken() async => token = null;

  @override
  Future<InstallationId?> readInstallationId() async => installationId;

  @override
  Future<InstallationToken?> readInstallationToken() async => token;

  @override
  Future<void> writeInstallationId(InstallationId installationId) async {
    this.installationId = installationId;
  }

  @override
  Future<void> writeInstallationToken(
    InstallationToken installationToken,
  ) async {
    token = installationToken;
  }
}
