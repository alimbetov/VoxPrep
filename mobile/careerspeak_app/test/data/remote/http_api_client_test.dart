import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_api_client.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpApiClient', () {
    test('does not send an authenticated request without a token', () async {
      var transportCalls = 0;
      final client = HttpApiClient(
        client: MockClient((request) async {
          transportCalls += 1;
          return http.Response('{}', 200);
        }),
        credentialStore: _MemoryCredentialStore(),
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
      );

      expect(transportCalls, 0);
      expect(_failure(result).code, 'UNAUTHORIZED');
    });

    test('owns Authorization and does not allow caller override', () async {
      final store = _MemoryCredentialStore(
        token: InstallationToken('server-token'),
      );
      final client = HttpApiClient(
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer server-token');
          expect(request.headers['x-client-header'], 'value');
          return http.Response(
            '{"ok":true}',
            200,
            headers: const <String, String>{'X-Trace-Id': 'trace-1'},
          );
        }),
        credentialStore: store,
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(
          method: ApiMethod.get,
          path: '/api/v1/content',
          headers: const <String, String>{
            'Authorization': 'Bearer caller-token',
            'X-Client-Header': 'value',
          },
        ),
      );

      final response = _success(result);
      expect(response.traceId, 'trace-1');
    });

    test('owns JSON transport headers for JSON bodies', () async {
      final client = HttpApiClient(
        client: MockClient((request) async {
          expect(request.headers['accept'], 'application/json');
          expect(
            request.headers['content-type'],
            'application/json; charset=utf-8',
          );
          expect(request.headers['authorization'], 'Bearer token-1');
          expect(request.headers['cookie'], isNull);
          return http.Response('{}', 200);
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(
          method: ApiMethod.post,
          path: '/api/v1/items',
          headers: const <String, String>{
            'Accept': 'text/plain',
            'Content-Type': 'text/plain',
            'Cookie': 'caller-cookie=1',
          },
          jsonBody: const <String, Object?>{'value': 1},
        ),
      );

      expect(result, isA<Success<ApiResponse>>());
    });

    test('allows explicitly anonymous requests without caller auth', () async {
      var transportCalls = 0;
      final client = HttpApiClient(
        client: MockClient((request) async {
          transportCalls += 1;
          expect(request.headers['authorization'], isNull);
          return http.Response('{}', 200);
        }),
        credentialStore: _MemoryCredentialStore(),
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(
          method: ApiMethod.post,
          path: '/api/v1/installations',
          authentication: ApiAuthentication.none,
          headers: const <String, String>{
            'Authorization': 'Bearer caller-token',
          },
        ),
      );

      expect(transportCalls, 1);
      expect(result, isA<Success<ApiResponse>>());
    });

    test('resolves base path, query parameters, and JSON body', () async {
      final store = _MemoryCredentialStore(token: InstallationToken('token-1'));
      final client = HttpApiClient(
        client: MockClient((request) async {
          expect(
            request.url.toString(),
            'https://api.example.test/root/api/v1/items?locale=en',
          );
          expect(request.headers['content-type'], contains('application/json'));
          expect(request.body, '{"value":1}');
          return http.Response('{}', 200);
        }),
        credentialStore: store,
        baseUri: Uri.parse('https://api.example.test/root'),
      );

      final result = await client.send(
        ApiRequest(
          method: ApiMethod.post,
          path: '/api/v1/items',
          queryParameters: const <String, String>{'locale': 'en'},
          jsonBody: const <String, Object?>{'value': 1},
        ),
      );

      expect(result, isA<Success<ApiResponse>>());
    });

    test('fails locally when JSON request body cannot be encoded', () async {
      var transportCalls = 0;
      final client = HttpApiClient(
        client: MockClient((request) async {
          transportCalls += 1;
          return http.Response('{}', 200);
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(
          method: ApiMethod.post,
          path: '/api/v1/items',
          jsonBody: _NonJsonValue(),
        ),
      );

      expect(transportCalls, 0);
      expect(_failure(result).code, 'REQUEST_ENCODING_FAILED');
    });

    test('retries retryable GET failures with bounded backoff', () async {
      var transportCalls = 0;
      final delays = <Duration>[];
      final client = HttpApiClient(
        client: MockClient((request) async {
          transportCalls += 1;
          if (transportCalls < 3) {
            return http.Response('{"code":"TEMPORARY"}', 503);
          }
          return http.Response('{"ok":true}', 200);
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
        delay: (duration) async {
          delays.add(duration);
        },
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
      );

      expect(result, isA<Success<ApiResponse>>());
      expect(transportCalls, 3);
      expect(delays, const <Duration>[
        Duration(milliseconds: 200),
        Duration(milliseconds: 400),
      ]);
    });

    test('does not automatically retry mutations', () async {
      var transportCalls = 0;
      final client = HttpApiClient(
        client: MockClient((request) async {
          transportCalls += 1;
          return http.Response('{"code":"TEMPORARY"}', 503);
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
        delay: (_) async {},
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.post, path: '/api/v1/mutate'),
      );

      expect(transportCalls, 1);
      expect(_failure(result).retryable, isTrue);
    });

    test('canonicalizes 401 while preserving backend error context', () async {
      final client = HttpApiClient(
        client: MockClient((request) async {
          return http.Response(
            '{'
            '"code":"INSTALLATION_TOKEN_EXPIRED",'
            '"message":"Token expired",'
            '"traceId":"body-trace",'
            '"details":{"reason":"expired"}'
            '}',
            401,
            headers: const <String, String>{'X-Trace-Id': 'header-trace'},
          );
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
      );
      final failure = _failure(result);

      expect(failure.code, 'UNAUTHORIZED');
      expect(failure.message, 'Token expired');
      expect(failure.traceId, 'header-trace');
      expect(failure.details['reason'], 'expired');
      expect(failure.details['backendCode'], 'INSTALLATION_TOKEN_EXPIRED');
      expect(failure.retryable, isFalse);
    });

    test('maps 403 to a stable forbidden failure code', () async {
      final client = HttpApiClient(
        client: MockClient((request) async {
          return http.Response('{"code":"POLICY_DENIED"}', 403);
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
      );

      expect(_failure(result).code, 'FORBIDDEN');
    });

    test('maps invalid successful JSON to a protocol failure', () async {
      final client = HttpApiClient(
        client: MockClient((request) async {
          return http.Response(
            'not-json',
            200,
            headers: const <String, String>{'X-Trace-Id': 'trace-invalid'},
          );
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
      );
      final failure = _failure(result);

      expect(failure.code, 'API_RESPONSE_INVALID');
      expect(failure.traceId, 'trace-invalid');
    });

    test('maps request timeout without leaking transport exception', () async {
      final client = HttpApiClient(
        client: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{}', 200);
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
        requestTimeout: const Duration(milliseconds: 1),
        maxGetAttempts: 1,
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
      );

      expect(_failure(result).code, 'TIMEOUT');
    });

    test('maps ClientException to an offline failure', () async {
      final client = HttpApiClient(
        client: MockClient((request) async {
          throw http.ClientException('offline');
        }),
        credentialStore: _MemoryCredentialStore(
          token: InstallationToken('token-1'),
        ),
        baseUri: Uri.parse('https://api.example.test'),
        maxGetAttempts: 1,
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
      );

      expect(_failure(result).code, 'OFFLINE');
    });

    test('maps secure credential read failures to typed failure', () async {
      var transportCalls = 0;
      final client = HttpApiClient(
        client: MockClient((request) async {
          transportCalls += 1;
          return http.Response('{}', 200);
        }),
        credentialStore: _MemoryCredentialStore(failTokenRead: true),
        baseUri: Uri.parse('https://api.example.test'),
      );

      final result = await client.send(
        ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
      );

      expect(transportCalls, 0);
      expect(_failure(result).code, 'CREDENTIAL_STORE_ERROR');
    });
  });
}

ApiResponse _success(Result<ApiResponse> result) {
  expect(result, isA<Success<ApiResponse>>());
  return (result as Success<ApiResponse>).value;
}

ApplicationFailure _failure(Result<ApiResponse> result) {
  expect(result, isA<FailureResult<ApiResponse>>());
  return (result as FailureResult<ApiResponse>).failure;
}

final class _NonJsonValue {}

final class _MemoryCredentialStore implements InstallationCredentialStore {
  _MemoryCredentialStore({this.token, this.failTokenRead = false});

  InstallationId? installationId;
  InstallationToken? token;
  final bool failTokenRead;

  @override
  Future<void> clear() async {
    installationId = null;
    token = null;
  }

  @override
  Future<void> clearInstallationToken() async {
    token = null;
  }

  @override
  Future<InstallationId?> readInstallationId() async => installationId;

  @override
  Future<InstallationToken?> readInstallationToken() async {
    if (failTokenRead) {
      throw StateError('secure storage unavailable');
    }
    return token;
  }

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
