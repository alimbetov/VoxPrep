import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/data/remote/http_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composition root selects the production HTTP API adapter', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(apiClientProvider), isA<HttpApiClient>());
  });

  test('default API base URL is deliberately non-routable', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(apiBaseUriProvider).host, 'api.careerspeak.invalid');
  });
}
