import 'dart:async';

import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/ports/installation_registration_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/application_bootstrap_service.dart';
import 'package:careerspeak_app/application/services/installation_bootstrap_service.dart';
import 'package:careerspeak_app/application/services/installation_identity_service.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('existing credentials are reused before startup sync', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      installationToken: InstallationToken('token-1'),
    );
    final registration = _RegistrationGateway(
      const FailureResult<InstallationToken>(
        ApplicationFailure(code: 'UNEXPECTED', message: 'must not be called'),
      ),
    );
    var syncCalls = 0;
    final service = _service(
      store: store,
      registration: registration,
      synchronize: ({required runId, required trigger}) async {
        syncCalls += 1;
        expect(runId, 'startup-test');
        expect(trigger, SyncTrigger.startup);
        expect((await store.readInstallationToken())?.value, 'token-1');
        return Success<ContentSyncOutcome>(ContentSyncNoOp(runId));
      },
    );

    final outcome = (await service.bootstrap()).getOrThrow();

    expect(outcome.credentials.installationId.value, 'installation-1');
    expect(outcome.credentials.installationToken.value, 'token-1');
    expect(outcome.contentSyncOutcome, isA<ContentSyncNoOp>());
    expect(registration.calls, 0);
    expect(syncCalls, 1);
  });

  test('missing token registers and persists before startup sync', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
    );
    final registration = _RegistrationGateway(
      Success<InstallationToken>(InstallationToken('token-2')),
    );
    var syncCalls = 0;
    final service = _service(
      store: store,
      registration: registration,
      synchronize: ({required runId, required trigger}) async {
        syncCalls += 1;
        expect((await store.readInstallationToken())?.value, 'token-2');
        return Success<ContentSyncOutcome>(ContentSyncExecuted(runId));
      },
    );

    final result = await service.bootstrap();

    expect(result, isA<Success<ApplicationBootstrapOutcome>>());
    expect(registration.calls, 1);
    expect(syncCalls, 1);
    expect((await store.readInstallationToken())?.value, 'token-2');
  });

  test('registration failure prevents authenticated startup sync', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
    );
    final registration = _RegistrationGateway(
      const FailureResult<InstallationToken>(
        ApplicationFailure(
          code: 'OFFLINE',
          message: 'offline',
          retryable: true,
        ),
      ),
    );
    var syncCalls = 0;
    final service = _service(
      store: store,
      registration: registration,
      synchronize: ({required runId, required trigger}) async {
        syncCalls += 1;
        return Success<ContentSyncOutcome>(ContentSyncNoOp(runId));
      },
    );

    final result = await service.bootstrap();

    expect(result, isA<FailureResult<ApplicationBootstrapOutcome>>());
    expect(
      (result as FailureResult<ApplicationBootstrapOutcome>).failure.code,
      'OFFLINE',
    );
    expect(syncCalls, 0);
    expect(await store.readInstallationToken(), isNull);
  });

  test('sync failure preserves valid credentials for later retry', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
    );
    final registration = _RegistrationGateway(
      Success<InstallationToken>(InstallationToken('token-3')),
    );
    final service = _service(
      store: store,
      registration: registration,
      synchronize: ({required runId, required trigger}) async {
        return const FailureResult<ContentSyncOutcome>(
          ApplicationFailure(
            code: 'OFFLINE',
            message: 'offline',
            retryable: true,
          ),
        );
      },
    );

    final result = await service.bootstrap();

    expect(result, isA<FailureResult<ApplicationBootstrapOutcome>>());
    expect((await store.readInstallationId())?.value, 'installation-1');
    expect((await store.readInstallationToken())?.value, 'token-3');
    expect(registration.calls, 1);
  });

  test('concurrent callers share one complete startup pipeline', () async {
    final store = _MemoryCredentialStore(
      installationId: InstallationId('installation-1'),
      installationToken: InstallationToken('token-1'),
    );
    final registration = _RegistrationGateway(
      Success<InstallationToken>(InstallationToken('unused')),
    );
    final gate = Completer<void>();
    var syncCalls = 0;
    final service = _service(
      store: store,
      registration: registration,
      synchronize: ({required runId, required trigger}) async {
        syncCalls += 1;
        await gate.future;
        return Success<ContentSyncOutcome>(ContentSyncNoOp(runId));
      },
    );

    final first = service.bootstrap();
    final second = service.bootstrap();

    expect(identical(first, second), isTrue);
    gate.complete();
    await Future.wait(<Future<Result<ApplicationBootstrapOutcome>>>[
      first,
      second,
    ]);
    expect(syncCalls, 1);
  });
}

ApplicationBootstrapService _service({
  required _MemoryCredentialStore store,
  required _RegistrationGateway registration,
  required StartupContentSynchronizer synchronize,
}) {
  return ApplicationBootstrapService(
    installationBootstrapService: InstallationBootstrapService(
      identityService: InstallationIdentityService(store),
      registrationGateway: registration,
    ),
    synchronizeContent: synchronize,
    runIdFactory: () => 'startup-test',
  );
}

final class _MemoryCredentialStore implements InstallationCredentialStore {
  _MemoryCredentialStore({this.installationId, this.installationToken});

  InstallationId? installationId;
  InstallationToken? installationToken;

  @override
  Future<void> clear() async {
    installationId = null;
    installationToken = null;
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
  _RegistrationGateway(this.result);

  final Result<InstallationToken> result;
  int calls = 0;

  @override
  Future<Result<InstallationToken>> register(
    InstallationId installationId,
  ) async {
    calls += 1;
    return result;
  }
}
