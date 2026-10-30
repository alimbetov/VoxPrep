import '../../domain/installation_credentials.dart';

abstract interface class InstallationCredentialStore {
  Future<InstallationId?> readInstallationId();

  Future<void> writeInstallationId(InstallationId installationId);

  Future<InstallationToken?> readInstallationToken();

  Future<void> writeInstallationToken(InstallationToken installationToken);

  Future<void> clearInstallationToken();

  Future<void> clear();
}
