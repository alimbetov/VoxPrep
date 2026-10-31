import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/app/content_payload_providers.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_content_payload_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('composition root selects production content payload gateway', () {
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(const _UnusedApiClient()),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(contentPayloadGatewayProvider),
      isA<HttpContentPayloadGateway>(),
    );
  });
}

final class _UnusedApiClient implements ApiClient {
  const _UnusedApiClient();

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) {
    throw StateError('Transport must not be called by composition test.');
  }
}
