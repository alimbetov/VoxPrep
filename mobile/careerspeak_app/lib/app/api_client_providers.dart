import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../application/ports/api_client.dart';
import '../application/ports/installation_registration_gateway.dart';
import '../application/result/result.dart';
import '../application/services/installation_auth_recovery_api_client.dart';
import '../application/services/installation_bootstrap_service.dart';
import '../data/remote/http_api_client.dart';
import '../data/remote/http_installation_registration_gateway.dart';
import '../domain/application_preferences.dart';
import 'app_preferences_providers.dart';
import 'installation_identity_providers.dart';

const _apiBaseUrl = String.fromEnvironment(
  'CAREERSPEAK_API_BASE_URL',
  defaultValue: 'https://api.careerspeak.invalid',
);

final apiBaseUriProvider = Provider<Uri>((ref) {
  return validateApiBaseUriForEnvironment(Uri.parse(_apiBaseUrl));
});

/// Release builds must never send installation credentials over cleartext HTTP.
///
/// Local HTTP remains available to debug/profile tests by explicitly setting
/// [releaseMode] to false. The transport layer still validates the URI shape.
Uri validateApiBaseUriForEnvironment(
  Uri uri, {
  bool releaseMode = kReleaseMode,
}) {
  if (releaseMode && uri.scheme.toLowerCase() != 'https') {
    throw StateError(
      'CAREERSPEAK_API_BASE_URL must use HTTPS in release builds.',
    );
  }
  return uri;
}

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Raw transport boundary used by installation issuance and as the delegate for
/// the authenticated recovery client. It never performs credential renewal by
/// itself, which keeps POST /api/v1/installations outside the recovery loop.
final rawApiClientProvider = Provider<ApiClient>((ref) {
  final preferencesRepository = ref.watch(appPreferencesRepositoryProvider);
  return HttpApiClient(
    client: ref.watch(httpClientProvider),
    credentialStore: ref.watch(installationCredentialStoreProvider),
    baseUri: ref.watch(apiBaseUriProvider),
    contextHeadersProvider: () async {
      final result = await preferencesRepository.getPreferences();
      if (result case FailureResult<ApplicationPreferences>(:final failure)) {
        throw StateError('${failure.code}: ${failure.message}');
      }
      final preferences = (result as Success<ApplicationPreferences>).value;
      return <String, String>{
        'accept-language': preferences.selectedLocale.code,
      };
    },
  );
});

final installationRegistrationGatewayProvider =
    Provider<InstallationRegistrationGateway>((ref) {
      return HttpInstallationRegistrationGateway(
        apiClient: ref.watch(rawApiClientProvider),
      );
    });

final installationBootstrapServiceProvider =
    Provider<InstallationBootstrapService>((ref) {
      return InstallationBootstrapService(
        identityService: ref.watch(installationIdentityServiceProvider),
        registrationGateway: ref.watch(installationRegistrationGatewayProvider),
      );
    });

/// Learner-facing API client. One installation-authentication 401 may renew the
/// credential and replay the exact logical request once. A second 401 is
/// returned fail-closed by the raw delegate.
final apiClientProvider = Provider<ApiClient>((ref) {
  return InstallationAuthRecoveryApiClient(
    delegate: ref.watch(rawApiClientProvider),
    credentialStore: ref.watch(installationCredentialStoreProvider),
    renewCredentials: ref
        .watch(installationBootstrapServiceProvider)
        .ensureCredentials,
  );
});
