import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/app/app_configuration.dart';
import 'package:careerspeak_app/app/billing_providers.dart';
import 'package:careerspeak_app/app/purchase_providers.dart';
import 'package:careerspeak_app/app/release_switch.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/billing/unavailable_billing_repository.dart';
import 'package:careerspeak_app/data/remote/http_purchase_verification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('commercial release switch', () {
    test('defaults to development when compiler and flag are both off', () {
      expect(
        AppRunModePolicy.resolve(
          compilerReleaseMode: false,
          releaseFlagEnabled: false,
        ),
        AppRunMode.development,
      );
    });

    test('flag can enable release behavior in a debug build', () {
      expect(
        AppRunModePolicy.resolve(
          compilerReleaseMode: false,
          releaseFlagEnabled: true,
        ),
        AppRunMode.release,
      );
    });

    test('compiler release mode always enables release behavior', () {
      expect(
        AppRunModePolicy.resolve(
          compilerReleaseMode: true,
          releaseFlagEnabled: false,
        ),
        AppRunMode.release,
      );
    });

    test('release behavior disables accepting billing mock', () {
      final configuration = AppConfiguration.fromBuildValues(
        releaseMode: false,
        appEnvironment: 'development',
        mockBilling: 'true',
      );
      final container = ProviderContainer(
        overrides: [
          appConfigurationProvider.overrideWithValue(configuration),
          appRunModeProvider.overrideWithValue(AppRunMode.release),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(billingRepositoryProvider),
        isA<UnavailableBillingRepository>(),
      );
    });

    test('release behavior uses real purchase verification boundary', () {
      final configuration = AppConfiguration.fromBuildValues(
        releaseMode: false,
        appEnvironment: 'development',
        apiBaseUrl: 'http://localhost:8080',
        mockPurchaseVerification: 'true',
      );
      final container = ProviderContainer(
        overrides: [
          appConfigurationProvider.overrideWithValue(configuration),
          appRunModeProvider.overrideWithValue(AppRunMode.release),
          apiClientProvider.overrideWithValue(const _FakeApiClient()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(purchaseVerificationRepositoryProvider),
        isA<HttpPurchaseVerificationRepository>(),
      );
    });
  });
}

final class _FakeApiClient implements ApiClient {
  const _FakeApiClient();

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    throw UnsupportedError('No HTTP call is expected in composition tests.');
  }
}
