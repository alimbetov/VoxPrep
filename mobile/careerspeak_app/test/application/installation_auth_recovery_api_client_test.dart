import 'dart:async';

import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/installation_auth_recovery_api_client.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one 401 renews credential and replays request once', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    var delegateCalls = 0;
    var renewCalls = 0;
    final client = InstallationAuthRecoveryApiClient(
      delegate: _Delegate((request) async {
        delegateCalls += 1;
        if (delegateCalls == 1) return _unauthorized();
        return _ok();
      }),
      credentialStore: store,
      renewCredentials: () async {
        renewCalls += 1;
        final token = InstallationToken('token-new');
        await store.writeInstallationToken(token);
        return Success(
          InstallationCredentials(
            installationId: store.installationId!,
            installationToken: token,
          ),
        );
      },
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );

    expect(result, isA<Success<ApiResponse>>());
    expect(delegateCalls, 2);
    expect(renewCalls, 1);
    expect((await store.readInstallationToken())?.value, 'token-new');
  });

  test('second 401 fails closed without another renewal', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    var delegateCalls = 0;
    var renewCalls = 0;
    final client = InstallationAuthRecoveryApiClient(
      delegate: _Delegate((request) async {
        delegateCalls += 1;
        return _unauthorized();
      }),
      credentialStore: store,
      renewCredentials: () async {
        renewCalls += 1;
        final token = InstallationToken('token-new');
        await store.writeInstallationToken(token);
        return Success(
          InstallationCredentials(
            installationId: store.installationId!,
            installationToken: token,
          ),
        );
      },
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );

    expect(result, isA<FailureResult<ApiResponse>>());
    expect((result as FailureResult<ApiResponse>).failure.code, 'UNAUTHORIZED');
    expect(delegateCalls, 2);
    expect(renewCalls, 1);
  });

  test('anonymous 401 never triggers installation recovery', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    var renewCalls = 0;
    final delegate = _Delegate((request) async => _unauthorized());
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
      renewCredentials: () async {
        renewCalls += 1;
        throw StateError('must not renew anonymous requests');
      },
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
    expect(renewCalls, 0);
  });

  test('already rotated token replays without a second rotation', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    var delegateCalls = 0;
    var renewCalls = 0;
    final client = InstallationAuthRecoveryApiClient(
      delegate: _Delegate((request) async {
        delegateCalls += 1;
        if (delegateCalls == 1) {
          await store.writeInstallationToken(InstallationToken('token-new'));
          return _unauthorized();
        }
        return _ok();
      }),
      credentialStore: store,
      renewCredentials: () async {
        renewCalls += 1;
        throw StateError('token already rotated');
      },
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );

    expect(result, isA<Success<ApiResponse>>());
    expect(delegateCalls, 2);
    expect(renewCalls, 0);
  });

  test('parallel 401 responses share one credential renewal', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    final renewalGate = Completer<void>();
    var renewCalls = 0;
    var oldTokenCalls = 0;
    var newTokenCalls = 0;
    final client = InstallationAuthRecoveryApiClient(
      delegate: _Delegate((request) async {
        final token = await store.readInstallationToken();
        if (token?.value == 'token-old') {
          oldTokenCalls += 1;
          return _unauthorized();
        }
        newTokenCalls += 1;
        return _ok();
      }),
      credentialStore: store,
      renewCredentials: () async {
        renewCalls += 1;
        await renewalGate.future;
        final token = InstallationToken('token-new');
        await store.writeInstallationToken(token);
        return Success(
          InstallationCredentials(
            installationId: store.installationId!,
            installationToken: token,
          ),
        );
      },
    );

    final first = client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content/1'),
    );
    final second = client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content/2'),
    );

    await Future<void>.delayed(Duration.zero);
    expect(renewCalls, 1);
    renewalGate.complete();

    final results = await Future.wait([first, second]);

    expect(results, everyElement(isA<Success<ApiResponse>>()));
    expect(renewCalls, 1);
    expect(oldTokenCalls, 2);
    expect(newTokenCalls, 2);
  });

  test('renewal failure is returned without replaying request', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    final delegate = _Delegate((request) async => _unauthorized());
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
      renewCredentials: () async => const FailureResult<InstallationCredentials>(
        ApplicationFailure(
          code: 'INSTALLATION_REVOKED',
          message: 'installation revoked',
        ),
      ),
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );

    expect(result, isA<FailureResult<ApiResponse>>());
    expect(
      (result as FailureResult<ApiResponse>).failure.code,
      'INSTALLATION_REVOKED',
    );
    expect(delegate.calls, 1);
  });

  test('credential-store read failure fails locally before transport', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
      failTokenReads: true,
    );
    final delegate = _Delegate((request) async => _ok());
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
      renewCredentials: () async => throw StateError('must not renew'),
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );

    expect(result, isA<FailureResult<ApiResponse>>());
    expect(
      (result as FailureResult<ApiResponse>).failure.code,
      'CREDENTIAL_STORE_ERROR',
    );
    expect(delegate.calls, 0);
  });

  test('token cleared after first 401 fails closed without renewal or replay', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    var renewCalls = 0;
    final delegate = _Delegate((request) async {
      await store.clearInstallationToken();
      return _unauthorized();
    });
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
      renewCredentials: () async {
        renewCalls += 1;
        throw StateError('must not renew after local clear');
      },
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );

    expect(result, isA<FailureResult<ApiResponse>>());
    expect((result as FailureResult<ApiResponse>).failure.code, 'UNAUTHORIZED');
    expect(delegate.calls, 1);
    expect(renewCalls, 0);
  });

  test('thrown renewal exception is converted to fail-closed result', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      token: InstallationToken('token-old'),
    );
    final delegate = _Delegate((request) async => _unauthorized());
    final client = InstallationAuthRecoveryApiClient(
      delegate: delegate,
      credentialStore: store,
      renewCredentials: () async {
        throw StateError('registration transport exploded');
      },
    );

    final result = await client.send(
      ApiRequest(method: ApiMethod.get, path: '/api/v1/content'),
    );

    expect(result, isA<FailureResult<ApiResponse>>());
    expect(
      (result as FailureResult<ApiResponse>).failure.code,
      'CREDENTIAL_RENEWAL_ERROR',
    );
    expect(delegate.calls, 1);
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
  _MemoryCredentialStore({
    required this.installationId,
    required this.token,
    this.failTokenReads = false,
  });

  InstallationId? installationId;
  InstallationToken? token;
  final bool failTokenReads;

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
    if (failTokenReads) {
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
