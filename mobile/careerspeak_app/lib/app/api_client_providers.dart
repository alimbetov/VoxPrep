import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../application/ports/api_client.dart';
import '../application/result/result.dart';
import '../data/remote/http_api_client.dart';
import '../domain/application_preferences.dart';
import 'app_preferences_providers.dart';
import 'installation_identity_providers.dart';

const _apiBaseUrl = String.fromEnvironment(
  'CAREERSPEAK_API_BASE_URL',
  defaultValue: 'https://api.careerspeak.invalid',
);

final apiBaseUriProvider = Provider<Uri>((ref) {
  return Uri.parse(_apiBaseUrl);
});

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final preferencesRepository = ref.watch(appPreferencesRepositoryProvider);
  return HttpApiClient(
    client: ref.watch(httpClientProvider),
    credentialStore: ref.watch(installationCredentialStoreProvider),
    baseUri: ref.watch(apiBaseUriProvider),
    contextHeadersProvider: () async {
      final result = await preferencesRepository.getPreferences();
      final preferences = switch (result) {
        Success<ApplicationPreferences>(:final value) => value,
        FailureResult<ApplicationPreferences>() => ApplicationPreferences.defaults,
      };
      return <String, String>{
        'accept-language': preferences.selectedLocale.code,
        if (preferences.countryCode case final countryCode?)
          'x-country-code': countryCode,
      };
    },
  );
});
