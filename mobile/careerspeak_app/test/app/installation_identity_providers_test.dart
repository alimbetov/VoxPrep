import 'package:careerspeak_app/app/installation_identity_providers.dart';
import 'package:careerspeak_app/data/secure/flutter_secure_installation_credential_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composition root selects Flutter secure credential adapter', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(installationCredentialStoreProvider),
      isA<FlutterSecureInstallationCredentialStore>(),
    );
  });
}
