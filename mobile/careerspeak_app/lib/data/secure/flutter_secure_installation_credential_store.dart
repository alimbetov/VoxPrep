import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../application/ports/installation_credential_store.dart';
import '../../domain/installation_credentials.dart';

final class FlutterSecureInstallationCredentialStore
    implements InstallationCredentialStore {
  FlutterSecureInstallationCredentialStore(this._storage);

  static const _installationIdKey = 'careerspeak.installation.id.v1';
  static const _installationTokenKey = 'careerspeak.installation.token.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<InstallationId?> readInstallationId() async {
    final value = await _storage.read(key: _installationIdKey);
    return value == null ? null : InstallationId(value);
  }

  @override
  Future<void> writeInstallationId(InstallationId installationId) {
    return _storage.write(key: _installationIdKey, value: installationId.value);
  }

  @override
  Future<InstallationToken?> readInstallationToken() async {
    final value = await _storage.read(key: _installationTokenKey);
    return value == null ? null : InstallationToken(value);
  }

  @override
  Future<void> writeInstallationToken(InstallationToken installationToken) {
    return _storage.write(
      key: _installationTokenKey,
      value: installationToken.value,
    );
  }

  @override
  Future<void> clearInstallationToken() {
    return _storage.delete(key: _installationTokenKey);
  }

  @override
  Future<void> clear() async {
    await clearInstallationToken();
    await _storage.delete(key: _installationIdKey);
  }
}
