import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('installation credential contract', () {
    test('rejects blank installation identity and token values', () {
      expect(() => InstallationId('   '), throwsArgumentError);
      expect(() => InstallationToken('   '), throwsArgumentError);
    });

    test('treats installation id as an opaque value object', () {
      expect(InstallationId('install-1'), InstallationId('install-1'));
      expect(InstallationId('install-1'), isNot(InstallationId('install-2')));
    });

    test('does not expose installation token through toString', () {
      const rawToken = 'secret-token-value';
      final token = InstallationToken(rawToken);
      final credentials = InstallationCredentials(
        installationId: InstallationId('install-1'),
        installationToken: token,
      );

      expect(token.toString(), isNot(contains(rawToken)));
      expect(credentials.toString(), isNot(contains(rawToken)));
      expect(credentials.toString(), contains('<redacted>'));
    });

    test('store port supports independent id and token lifecycle', () async {
      final store = _MemoryInstallationCredentialStore();
      final installationId = InstallationId('install-1');
      final installationToken = InstallationToken('token-1');

      expect(await store.readInstallationId(), isNull);
      expect(await store.readInstallationToken(), isNull);

      await store.writeInstallationId(installationId);
      expect(await store.readInstallationId(), installationId);
      expect(await store.readInstallationToken(), isNull);

      await store.writeInstallationToken(installationToken);
      expect(await store.readInstallationToken(), installationToken);

      await store.clearInstallationToken();
      expect(await store.readInstallationId(), installationId);
      expect(await store.readInstallationToken(), isNull);

      await store.clear();
      expect(await store.readInstallationId(), isNull);
      expect(await store.readInstallationToken(), isNull);
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
