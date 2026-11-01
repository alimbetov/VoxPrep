import 'package:careerspeak_app/application/ports/installation_registration_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/installation_bootstrap_service.dart';
import 'package:careerspeak_app/application/services/installation_identity_service.dart';
import 'package:careerspeak_app/data/secure/flutter_secure_installation_credential_store.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test(
    'restart preserves installation id and rotates bootstrap token',
    () async {
      final firstStore = FlutterSecureInstallationCredentialStore(
        const FlutterSecureStorage(),
      );
      final firstGateway = _RegistrationGateway('token-1');
      final firstBootstrap = InstallationBootstrapService(
        identityService: InstallationIdentityService(
          firstStore,
          installationIdFactory: () => InstallationId('installation-1'),
        ),
        registrationGateway: firstGateway,
      );

      final first = (await firstBootstrap.ensureCredentials()).getOrThrow();
      expect(first.installationId.value, 'installation-1');
      expect(first.installationToken.value, 'token-1');

      // Simulate process recreation: new adapter + services over the same
      // platform secure storage.
      final reopenedStore = FlutterSecureInstallationCredentialStore(
        const FlutterSecureStorage(),
      );
      var regeneratedIdentity = false;
      final secondGateway = _RegistrationGateway('token-2');
      final secondBootstrap = InstallationBootstrapService(
        identityService: InstallationIdentityService(
          reopenedStore,
          installationIdFactory: () {
            regeneratedIdentity = true;
            return InstallationId('must-not-regenerate');
          },
        ),
        registrationGateway: secondGateway,
      );

      final second = (await secondBootstrap.ensureCredentials()).getOrThrow();

      expect(regeneratedIdentity, isFalse);
      expect(second.installationId.value, 'installation-1');
      expect(second.installationToken.value, 'token-2');
      expect(secondGateway.installationIds.single.value, 'installation-1');
      expect(
        await reopenedStore.readInstallationToken(),
        InstallationToken('token-2'),
      );
    },
  );
}

final class _RegistrationGateway implements InstallationRegistrationGateway {
  _RegistrationGateway(this.token);

  final String token;
  final List<InstallationId> installationIds = <InstallationId>[];

  @override
  Future<Result<InstallationToken>> register(
    InstallationId installationId,
  ) async {
    installationIds.add(installationId);
    return Success(InstallationToken(token));
  }
}
