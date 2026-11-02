import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/application/services/installation_auth_recovery_api_client.dart';
import 'package:careerspeak_app/data/remote/http_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('raw API composition selects the production HTTP transport', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(rawApiClientProvider), isA<HttpApiClient>());
  });

  test('learner API composition wraps raw transport with auth recovery', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(apiClientProvider),
      isA<InstallationAuthRecoveryApiClient>(),
    );
  });

  test('default API base URL is deliberately non-routable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(apiBaseUriProvider).host, 'api.careerspeak.invalid');
  });
}
