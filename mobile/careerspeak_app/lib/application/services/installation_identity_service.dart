import 'dart:math';

import '../../domain/installation_credentials.dart';
import '../ports/installation_credential_store.dart';

typedef InstallationIdFactory = InstallationId Function();

final class InstallationIdentityService {
  InstallationIdentityService(
    this._store, {
    InstallationIdFactory? installationIdFactory,
  }) : _installationIdFactory =
           installationIdFactory ?? _generateSecureInstallationId;

  final InstallationCredentialStore _store;
  final InstallationIdFactory _installationIdFactory;

  Future<InstallationId>? _installationIdFuture;

  Future<InstallationId> ensureInstallationId() {
    return _installationIdFuture ??= _loadOrCreateInstallationId();
  }

  Future<InstallationCredentials?> readCredentials() async {
    final installationId = await _store.readInstallationId();
    final installationToken = await _store.readInstallationToken();

    if (installationId == null && installationToken != null) {
      throw StateError(
        'Secure storage contains an installation token without an installation id.',
      );
    }

    if (installationId == null || installationToken == null) {
      return null;
    }

    return InstallationCredentials(
      installationId: installationId,
      installationToken: installationToken,
    );
  }

  Future<void> saveInstallationToken(InstallationToken installationToken) async {
    final installationId = await _store.readInstallationId();
    if (installationId == null) {
      throw StateError(
        'Cannot persist an installation token before installation identity exists.',
      );
    }

    await _store.writeInstallationToken(installationToken);
  }

  Future<void> clearInstallationToken() {
    return _store.clearInstallationToken();
  }

  Future<void> resetInstallation() async {
    await _store.clear();
    _installationIdFuture = null;
  }

  Future<InstallationId> _loadOrCreateInstallationId() async {
    try {
      final existing = await _store.readInstallationId();
      if (existing != null) {
        return existing;
      }

      final generated = _installationIdFactory();
      await _store.writeInstallationId(generated);
      return generated;
    } catch (_) {
      _installationIdFuture = null;
      rethrow;
    }
  }
}

InstallationId _generateSecureInstallationId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));

  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  final hex = bytes
      .map((value) => value.toRadixString(16).padLeft(2, '0'))
      .join();

  return InstallationId(
    '${hex.substring(0, 8)}-'
    '${hex.substring(8, 12)}-'
    '${hex.substring(12, 16)}-'
    '${hex.substring(16, 20)}-'
    '${hex.substring(20)}',
  );
}
