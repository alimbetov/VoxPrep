import '../../domain/installation_credentials.dart';

abstract interface class InstallationCredentialStore {
  Future<InstallationCredentials?> read();

  Future<void> write(InstallationCredentials credentials);

  Future<void> clear();
}
