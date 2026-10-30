import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../application/ports/installation_credential_store.dart';
import '../application/services/installation_identity_service.dart';
import '../data/secure/flutter_secure_installation_credential_store.dart';
import '../domain/installation_credentials.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final installationCredentialStoreProvider =
    Provider<InstallationCredentialStore>((ref) {
      return FlutterSecureInstallationCredentialStore(
        ref.watch(secureStorageProvider),
      );
    });

final installationIdentityServiceProvider =
    Provider<InstallationIdentityService>((ref) {
      return InstallationIdentityService(
        ref.watch(installationCredentialStoreProvider),
      );
    });

final installationIdProvider = FutureProvider<InstallationId>((ref) {
  return ref.watch(installationIdentityServiceProvider).ensureInstallationId();
});
