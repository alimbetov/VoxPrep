import 'package:careerspeak_app/data/secure/flutter_secure_installation_credential_store.dart';
import 'package:careerspeak_app/domain/installation_credentials.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
  });

  test('secure adapter survives storage-backed adapter recreation', () async {
    final first = FlutterSecureInstallationCredentialStore(
      const FlutterSecureStorage(),
    );

    await first.writeInstallationId(InstallationId('install-1'));
    await first.writeInstallationToken(InstallationToken('token-1'));

    final reopened = FlutterSecureInstallationCredentialStore(
      const FlutterSecureStorage(),
    );

    expect(await reopened.readInstallationId(), InstallationId('install-1'));
    expect(
      await reopened.readInstallationToken(),
      InstallationToken('token-1'),
    );
  });

  test('clearing token does not rotate installation identity', () async {
    final store = FlutterSecureInstallationCredentialStore(
      const FlutterSecureStorage(),
    );

    await store.writeInstallationId(InstallationId('install-1'));
    await store.writeInstallationToken(InstallationToken('token-1'));
    await store.clearInstallationToken();

    expect(await store.readInstallationId(), InstallationId('install-1'));
    expect(await store.readInstallationToken(), isNull);
  });

  test('full clear removes token and installation identity', () async {
    final store = FlutterSecureInstallationCredentialStore(
      const FlutterSecureStorage(),
    );

    await store.writeInstallationId(InstallationId('install-1'));
    await store.writeInstallationToken(InstallationToken('token-1'));
    await store.clear();

    expect(await store.readInstallationId(), isNull);
    expect(await store.readInstallationToken(), isNull);
  });
}
