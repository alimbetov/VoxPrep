import 'package:careerspeak_app/application/ports/installation_credential_store.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('installation credential contract', () {
    test('rejects blank installation identity and token values', () {
      expect(() => InstallationId('   '), throwsArgumentError);

      expect(
        () => InstallationCredentials(
          installationId: InstallationId('install-1'),
          installationToken: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('treats installation id as an opaque value object', () {
      expect(InstallationId('install-1'), InstallationId('install-1'));
      expect(InstallationId('install-1'), isNot(InstallationId('install-2')));
    });

    test('does not expose installation token through toString', () {
      const token = 'secret-token-value';
      final credentials = InstallationCredentials(
        installationId: InstallationId('install-1'),
        installationToken: token,
      );

      expect(credentials.toString(), isNot(contains(token)));
      expect(credentials.toString(), contains('<redacted>'));
    });

    test('store port supports read write and clear lifecycle', () async {
      final store = _MemoryInstallationCredentialStore();
      final credentials = InstallationCredentials(
        installationId: InstallationId('install-1'),
        installationToken: 'token-1',
      );

      expect(await store.read(), isNull);

      await store.write(credentials);
      final stored = await store.read();

      expect(stored?.installationId, InstallationId('install-1'));
      expect(stored?.installationToken, 'token-1');

      await store.clear();
      expect(await store.read(), isNull);
    });
  });
}

final class _MemoryInstallationCredentialStore
    implements InstallationCredentialStore {
  InstallationCredentials? _credentials;

  @override
  Future<void> clear() async {
    _credentials = null;
  }

  @override
  Future<InstallationCredentials?> read() async => _credentials;

  @override
  Future<void> write(InstallationCredentials credentials) async {
    _credentials = credentials;
  }
}
