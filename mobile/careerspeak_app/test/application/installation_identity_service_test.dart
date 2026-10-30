import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/application/services/installation_identity_service.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InstallationIdentityService', () {
    test('creates installation id once and reuses persisted identity', () async {
      final store = _MemoryInstallationCredentialStore();
      var generatedCount = 0;
      final service = InstallationIdentityService(
        store,
        installationIdFactory: () {
          generatedCount += 1;
          return InstallationId('install-generated');
        },
      );

      final ids = await Future.wait(<Future<InstallationId>>[
        service.ensureInstallationId(),
        service.ensureInstallationId(),
      ]);

      expect(ids, everyElement(InstallationId('install-generated')));
      expect(generatedCount, 1);

      final recreated = InstallationIdentityService(
        store,
        installationIdFactory: () => InstallationId('must-not-replace'),
      );
      expect(
        await recreated.ensureInstallationId(),
        InstallationId('install-generated'),
      );
    });

    test('does not expose complete credentials before registration', () async {
      final store = _MemoryInstallationCredentialStore();
      final service = InstallationIdentityService(
        store,
        installationIdFactory: () => InstallationId('install-1'),
      );

      await service.ensureInstallationId();

      expect(await service.readCredentials(), isNull);
    });

    test('rejects token persistence before installation identity exists', () {
      final service = InstallationIdentityService(
        _MemoryInstallationCredentialStore(),
      );

      expect(
        () => service.saveInstallationToken(InstallationToken('token-1')),
        throwsStateError,
      );
    });

    test('projects credentials only after token is persisted', () async {
      final store = _MemoryInstallationCredentialStore();
      final service = InstallationIdentityService(
        store,
        installationIdFactory: () => InstallationId('install-1'),
      );

      await service.ensureInstallationId();
      await service.saveInstallationToken(InstallationToken('token-1'));

      final credentials = await service.readCredentials();
      expect(credentials?.installationId, InstallationId('install-1'));
      expect(credentials?.installationToken, InstallationToken('token-1'));
    });

    test('fails closed when token exists without installation id', () async {
      final store = _MemoryInstallationCredentialStore();
      await store.writeInstallationToken(InstallationToken('orphan-token'));
      final service = InstallationIdentityService(store);

      await expectLater(service.readCredentials(), throwsStateError);
    });

    test('clearing token preserves identity while reset clears both', () async {
      final store = _MemoryInstallationCredentialStore();
      var generation = 0;
      final service = InstallationIdentityService(
        store,
        installationIdFactory: () {
          generation += 1;
          return InstallationId('install-$generation');
        },
      );

      expect(await service.ensureInstallationId(), InstallationId('install-1'));
      await service.saveInstallationToken(InstallationToken('token-1'));

      await service.clearInstallationToken();
      expect(await store.readInstallationId(), InstallationId('install-1'));
      expect(await service.readCredentials(), isNull);

      await service.resetInstallation();
      expect(await store.readInstallationId(), isNull);
      expect(await store.readInstallationToken(), isNull);
      expect(await service.ensureInstallationId(), InstallationId('install-2'));
    });

    test('default identity generator produces RFC 4122 version 4 shape', () async {
      final service = InstallationIdentityService(
        _MemoryInstallationCredentialStore(),
      );

      final installationId = await service.ensureInstallationId();

      expect(
        installationId.value,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });
  });
}

final class _MemoryInstallationCredentialStore
    implements InstallationCredentialStore {
  InstallationId? _installationId;
  InstallationToken? _installationToken;

  @override
  Future<InstallationId?> readInstallationId() async => _installationId;

  @override
  Future<void> writeInstallationId(InstallationId installationId) async {
    _installationId = installationId;
  }

  @override
  Future<InstallationToken?> readInstallationToken() async =>
      _installationToken;

  @override
  Future<void> writeInstallationToken(
    InstallationToken installationToken,
  ) async {
    _installationToken = installationToken;
  }

  @override
  Future<void> clearInstallationToken() async {
    _installationToken = null;
  }

  @override
  Future<void> clear() async {
    _installationToken = null;
    _installationId = null;
  }
}
