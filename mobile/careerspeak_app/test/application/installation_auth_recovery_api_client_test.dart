import 'dart:async';

import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/installation_auth_recovery_api_client.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejected token fails closed without anonymous rotation or replay', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('invalid-token'),
    );
    final delegate = _Delegate((request) async => _unauthorized());
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );

    expect(result, isA<FailureResult<ApiResponse>>());
    expect((result as FailureResult<ApiResponse>).failure.code, 'UNAUTHORIZED');
    expect(delegate.calls, 1);
    expect((await store.readInstallationToken())?.value, 'invalid-token');
    expect((await store.readInstallationId())?.value, 'installation-1');
  });

  test('anonymous 401 never attempts installation recovery', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    final delegate = _Delegate((request) async => _unauthorized());
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
    );
    final result = await client.send(
      ApiRequest(
        method: ApiMethod.post,
        path: '/api/v1/installations',
        authentication: ApiAuthentication.none,
      ),
    );

    expect(result, isA<FailureResult<ApiResponse>>());
    expect(delegate.calls, 1);
    expect((await store.readInstallationToken())?.value, 'token-old');
  });

  test('already rotated credential replays at most once', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    var calls = 0;
    final client = InstallationAuthRecoveryApiClient(
      delegate: _Delegate((request) async {
        calls++;
        if (calls == 1) {
          await store.writeInstallationToken(InstallationToken('token-new'));
          return _unauthorized();
        }
        return _ok();
      }),
      credentialStore: store,
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );
    expect(result, isA<Success<ApiResponse>>());
    expect(calls, 2);
    expect((await store.readInstallationToken())?.value, 'token-new');
  });

  test('second 401 after concurrent rotation remains unauthorized', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    var calls = 0;
    final client = InstallationAuthRecoveryApiClient(
      delegate: _Delegate((request) async {
        calls++;
        if (calls == 1) {
          await store.writeInstallationToken(InstallationToken('token-new'));
        }
        return _unauthorized();
      }),
      credentialStore: store,
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );
    expect(result, isA<FailureResult<ApiResponse>>());
    expect(calls, 2);
  });

  test('parallel revoked-token responses never rotate or replay', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-revoked'),
    );
    final delegate = _Delegate((request) async => _unauthorized());
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
    );
    final results = await Future.wait([
      client.send(ApiRequest(method: ApiMethod.get, path: '/api/v1/a')),
      client.send(ApiRequest(method: ApiMethod.get, path: '/api/v1/b')),
    ]);
    expect(results, everyElement(isA<FailureResult<ApiResponse>>()));
    expect(delegate.calls, 2);
    expect((await store.readInstallationToken())?.value, 'token-revoked');
  });

  test('parallel in-flight 401s replay once after independent rotation', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    final gate = Completer<void>();
    final firstTwoStarted = Completer<void>();
    var oldCalls = 0;
    var freshCalls = 0;
    final client = InstallationAuthRecoveryApiClient(
      delegate: _Delegate((request) async {
        final token = await store.readInstallationToken();
        if (token?.value == 'token-old') {
          oldCalls++;
          if (oldCalls == 2) firstTwoStarted.complete();
          await gate.future;
          return _unauthorized();
        }
        freshCalls++;
        return _ok();
      }),
      credentialStore: store,
    );

    final first = client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/a'),
    );
    final second = client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/b'),
    );
    await firstTwoStarted.future;
    await store.writeInstallationToken(InstallationToken('token-new'));
    gate.complete();
    final results = await Future.wait([first, second]);
    expect(results, everyElement(isA<Success<ApiResponse>>()));
    expect(oldCalls, 2);
    expect(freshCalls, 2);
  });

  test('missing local credential never resurrects or re-registers UUID', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: null,
    );
    final delegate = _Delegate((request) async => _unauthorized());
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
    );
    final response = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );
    expect(response, isA<FailureResult<ApiResponse>>());
    expect(delegate.calls, 1);
    expect(await store.readInstallationToken(), isNull);
    expect((await store.readInstallationId())?.value, 'installation-1');
  });
}

Result<ApiResponse> _ok() => Success(
  ApiResponse(statusCode: 200, headers: const {}, jsonBody: const {'ok': true}),
);

Result<ApiResponse> _unauthorized() => const FailureResult<ApiResponse>(
  ApplicationFailure(
    code: 'UNAUTHORIZED',
    message: 'Installation credential was rejected.',
  ),
);

final class _Delegate implements ApiClient {
  _Delegate(this.handler);

  final Future<Result<ApiResponse>> Function(ApiRequest request) handler;
  int calls = 0;

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) {
    calls += 1;
    return handler(request);
  }
}

final class _MemoryCredentialStore implements InstallationCredentialStore {
  _MemoryCredentialStore({required this.installationId, required this.token});

  InstallationId? installationId;
  InstallationToken? token;

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
