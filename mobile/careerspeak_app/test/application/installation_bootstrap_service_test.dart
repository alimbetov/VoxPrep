import 'dart:async';

import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/ports/installation_registration_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/installation_bootstrap_service.dart';
import 'package:careerspeak_app/application/services/installation_identity_service.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('existing credentials bypass registration', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      installationToken: InstallationToken('token-1'),
    );
    final gateway = _RegistrationGateway(
      result: Success(InstallationToken('unused')),
    );
    final service = InstallationBootstrapService(
      identityService: InstallationIdentityService(store),
      registrationGateway: gateway,
    );

    final credentials = (await service.ensureCredentials()).getOrThrow();

    expect(credentials.installationId.value, 'installation-1');
    expect(credentials.installationToken.value, 'token-1');
    expect(gateway.calls, 0);
  });

  test('missing token registers once and persists returned token', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
    );
    final gateway = _RegistrationGateway(
      result: Success(InstallationToken('token-2')),
    );
    final service = InstallationBootstrapService(
      identityService: InstallationIdentityService(store),
      registrationGateway: gateway,
    );

    final credentials = (await service.ensureCredentials()).getOrThrow();

    expect(gateway.calls, 1);
    expect(credentials.installationToken.value, 'token-2');
    expect((await store.readInstallationToken())?.value, 'token-2');
  });

  test('concurrent bootstrap callers share one registration', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
    );
    final gate = Completer<void>();
    final gateway = _RegistrationGateway(
      result: Success(InstallationToken('token-3')),
      gate: gate,
    );
    final service = InstallationBootstrapService(
      identityService: InstallationIdentityService(store),
      registrationGateway: gateway,
    );

    final first = service.ensureCredentials();
    final second = service.ensureCredentials();

    expect(identical(first, second), isTrue);
    gate.complete();
    await Future.wait([first, second]);
    expect(gateway.calls, 1);
  });
}

final class _MemoryCredentialStore implements InstallationCredentialStore {
  _MemoryCredentialStore({this.installationId, this.installationToken});

  InstallationId? installationId;
  InstallationToken? installationToken;

  @override
  Future<void> clear() async {
    installationToken = null;
    installationId = null;
  }

  @override
  Future<void> clearInstallationToken() async {
    installationToken = null;
  }

  @override
  Future<InstallationId?> readInstallationId() async => installationId;

  @override
  Future<InstallationToken?> readInstallationToken() async => installationToken;

  @override
  Future<void> writeInstallationId(InstallationId value) async {
    installationId = value;
  }

  @override
  Future<void> writeInstallationToken(InstallationToken value) async {
    installationToken = value;
  }
}

final class _RegistrationGateway implements InstallationRegistrationGateway {
  _RegistrationGateway({required this.result, this.gate});

  final Result<InstallationToken> result;
  final Completer<void>? gate;
  int calls = 0;

  @override
  Future<Result<InstallationToken>> register(
    InstallationId installationId,
  ) async {
    calls += 1;
    if (gate != null) await gate!.future;
    return result;
  }
}
