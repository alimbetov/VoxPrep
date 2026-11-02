import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/app/app_configuration.dart';
import 'package:careerspeak_app/app/billing_providers.dart';
import 'package:careerspeak_app/app/purchase_providers.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/billing/unavailable_billing_repository.dart';
import 'package:careerspeak_app/data/remote/http_purchase_verification_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('H3.1 AppConfiguration', () {
    test('E01 development + http localhost is allowed', () {
      final configuration = _configuration(
        environment: 'development',
        apiBaseUrl: 'http://localhost:8080',
      );

      expect(configuration.environment, AppEnvironment.development);
      expect(configuration.requireApiBaseUri().scheme, 'http');
    });

    test('E02 staging + classified https staging host is allowed', () {
      final configuration = _configuration(
        environment: 'staging',
        apiBaseUrl: 'https://staging.api.example.org',
        stagingHosts: 'staging.api.example.org',
      );

      expect(configuration.environment, AppEnvironment.staging);
      expect(configuration.requireApiBaseUri().host, 'staging.api.example.org');
    });

    test('E03 production + classified https production host is allowed', () {
      final configuration = _configuration(
        environment: 'production',
        apiBaseUrl: 'https://api.example.org',
        productionHosts: 'api.example.org',
        releaseMode: true,
      );

      expect(configuration.environment, AppEnvironment.production);
      expect(configuration.requireApiBaseUri().host, 'api.example.org');
    });

    test('E04 production + http is rejected', () {
      expect(
        () => _configuration(
          environment: 'production',
          apiBaseUrl: 'http://api.example.org',
          productionHosts: 'api.example.org',
          releaseMode: true,
        ),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('E05 production + localhost is rejected', () {
      expect(
        () => _configuration(
          environment: 'production',
          apiBaseUrl: 'https://localhost',
          productionHosts: 'localhost',
          releaseMode: true,
        ),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('E06 production + private IP is rejected', () {
      expect(
        () => _configuration(
          environment: 'production',
          apiBaseUrl: 'https://10.0.0.4',
          productionHosts: '10.0.0.4',
          releaseMode: true,
        ),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('E07 production + classified staging host is rejected', () {
      expect(
        () => _configuration(
          environment: 'production',
          apiBaseUrl: 'https://staging.api.example.org',
          stagingHosts: 'staging.api.example.org',
          productionHosts: 'api.example.org',
          releaseMode: true,
        ),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('E08 staging + classified production host is rejected', () {
      expect(
        () => _configuration(
          environment: 'staging',
          apiBaseUrl: 'https://api.example.org',
          stagingHosts: 'staging.api.example.org',
          productionHosts: 'api.example.org',
        ),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('E09 invalid CAREERSPEAK_APP_ENV is rejected', () {
      expect(
        () => _configuration(
          environment: 'preview',
          apiBaseUrl: 'https://api.example.org',
        ),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('E10 release mock billing cannot compose an accepting mock', () {
      final configuration = _configuration(
        environment: 'production',
        apiBaseUrl: 'https://api.example.org',
        productionHosts: 'api.example.org',
        releaseMode: true,
        mockBilling: 'true',
      );
      final container = ProviderContainer(
        overrides: [appConfigurationProvider.overrideWithValue(configuration)],
      );
      addTearDown(container.dispose);

      expect(
        container.read(billingRepositoryProvider),
        isA<UnavailableBillingRepository>(),
      );
    });

    test('E11 release mock purchase verification still composes HTTP', () {
      final configuration = _configuration(
        environment: 'production',
        apiBaseUrl: 'https://api.example.org',
        productionHosts: 'api.example.org',
        releaseMode: true,
        mockPurchaseVerification: 'true',
      );
      final container = ProviderContainer(
        overrides: [
          appConfigurationProvider.overrideWithValue(configuration),
          apiClientProvider.overrideWithValue(const _FakeApiClient()),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(purchaseVerificationRepositoryProvider),
        isA<HttpPurchaseVerificationRepository>(),
      );
    });

    test('E12 default environment policy is deterministic', () {
      final debugConfiguration = AppConfiguration.fromBuildValues(
        releaseMode: false,
      );
      final releaseConfiguration = AppConfiguration.fromBuildValues(
        releaseMode: true,
      );

      expect(debugConfiguration.environment, AppEnvironment.development);
      expect(releaseConfiguration.environment, AppEnvironment.production);
    });

    test('E13 invalid API URI is rejected', () {
      expect(
        () =>
            _configuration(environment: 'development', apiBaseUrl: 'not a uri'),
        throwsA(isA<AppConfigurationException>()),
      );
    });

    test('E14 missing API URL is network-disabled and fails closed', () {
      final configuration = AppConfiguration.fromBuildValues(
        releaseMode: false,
        appEnvironment: 'development',
      );

      expect(configuration.networkEnabled, isFalse);
      expect(
        configuration.requireApiBaseUri,
        throwsA(isA<AppConfigurationException>()),
      );
    });
  });
}

AppConfiguration _configuration({
  required String environment,
  required String apiBaseUrl,
  String stagingHosts = '',
  String productionHosts = '',
  bool releaseMode = false,
  String mockBilling = '',
  String mockPurchaseVerification = '',
}) {
  return AppConfiguration.fromBuildValues(
    releaseMode: releaseMode,
    appEnvironment: environment,
    apiBaseUrl: apiBaseUrl,
    stagingApiHosts: stagingHosts,
    productionApiHosts: productionHosts,
    mockBilling: mockBilling,
    mockPurchaseVerification: mockPurchaseVerification,
  );
}

final class _FakeApiClient implements ApiClient {
  const _FakeApiClient();

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    throw UnsupportedError('No HTTP call is expected in composition tests.');
  }
}
