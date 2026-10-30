import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../application/ports/api_client.dart';
import '../data/remote/http_api_client.dart';
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
  return HttpApiClient(
    client: ref.watch(httpClientProvider),
    credentialStore: ref.watch(installationCredentialStoreProvider),
    baseUri: ref.watch(apiBaseUriProvider),
  );
});
