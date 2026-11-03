import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppEnvironment { development, staging, production }

final class AppConfigurationException implements Exception {
  const AppConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'AppConfigurationException: $message';
}

final class ApiHostPolicy {
  factory ApiHostPolicy.fromCsv({
    String stagingHosts = '',
    String productionHosts = '',
  }) {
    final staging = _parseHosts(stagingHosts);
    final production = _parseHosts(productionHosts);
    final overlap = staging.intersection(production);
    if (overlap.isNotEmpty) {
      throw AppConfigurationException(
        'API host classification overlaps across staging and production: '
        '${overlap.join(', ')}',
      );
    }
    return ApiHostPolicy._(staging, production);
  }

  const ApiHostPolicy._(this.stagingHosts, this.productionHosts);

  final Set<String> stagingHosts;
  final Set<String> productionHosts;

  void validate(AppEnvironment environment, Uri uri) {
    final host = uri.host.toLowerCase();
    if (environment == AppEnvironment.development) {
      return;
    }

    if (uri.scheme != 'https') {
      throw const AppConfigurationException(
        'Staging and production API endpoints must use HTTPS.',
      );
    }
    if (_isUnsafeRemoteHost(host)) {
      throw AppConfigurationException(
        'Unsafe or placeholder API host is not allowed outside development: '
        '$host',
      );
    }

    if (environment == AppEnvironment.staging) {
      if (productionHosts.contains(host)) {
        throw AppConfigurationException(
          'Staging configuration points to a production API host: $host',
        );
      }
      if (stagingHosts.isEmpty || !stagingHosts.contains(host)) {
        throw AppConfigurationException(
          'Staging API host is not present in VOXPREP_STAGING_HOSTS: $host',
        );
      }
      return;
    }

    if (stagingHosts.contains(host)) {
      throw AppConfigurationException(
        'Production configuration points to a staging API host: $host',
      );
    }
    if (productionHosts.isEmpty || !productionHosts.contains(host)) {
      throw AppConfigurationException(
        'Production API host is not present in VOXPREP_PROD_HOSTS: $host',
      );
    }
  }

  static Set<String> _parseHosts(String raw) {
    final result = <String>{};
    for (final value in raw.split(',')) {
      final host = value.trim().toLowerCase();
      if (host.isEmpty) continue;
      if (host.contains('://') || host.contains('/') || host.contains(':')) {
        throw AppConfigurationException(
          'API host allowlists accept host names only: $host',
        );
      }
      result.add(host);
    }
    return Set<String>.unmodifiable(result);
  }
}

final class AppConfiguration {
  factory AppConfiguration.fromBuildValues({
    required bool releaseMode,
    String appEnvironment = '',
    String apiBaseUrl = '',
    String mockBilling = '',
    String mockPurchaseVerification = '',
    String stagingApiHosts = '',
    String productionApiHosts = '',
  }) {
    final environment = _parseEnvironment(appEnvironment, releaseMode);
    final hostPolicy = ApiHostPolicy.fromCsv(
      stagingHosts: stagingApiHosts,
      productionHosts: productionApiHosts,
    );
    final normalizedApiBaseUrl = apiBaseUrl.trim();
    final networkEnabled = normalizedApiBaseUrl.isNotEmpty;
    final apiBaseUri = networkEnabled
        ? _parseApiBaseUri(normalizedApiBaseUrl)
        : Uri.parse('https://api.voxprep.invalid');

    if (networkEnabled) {
      hostPolicy.validate(environment, apiBaseUri);
    }

    final developmentMocksDefault =
        environment == AppEnvironment.development && !releaseMode;
    final mockBillingRequested = _parseBoolean(
      'VOXPREP_MOCK_BILLING',
      mockBilling,
      defaultValue: developmentMocksDefault,
    );
    final mockPurchaseVerificationRequested = _parseBoolean(
      'VOXPREP_MOCK_PURCHASE',
      mockPurchaseVerification,
      defaultValue: developmentMocksDefault,
    );

    return AppConfiguration._(
      environment: environment,
      apiBaseUri: apiBaseUri,
      networkEnabled: networkEnabled,
      releaseMode: releaseMode,
      mockBillingRequested: mockBillingRequested,
      mockPurchaseVerificationRequested: mockPurchaseVerificationRequested,
      hostPolicy: hostPolicy,
    );
  }

  const AppConfiguration._({
    required this.environment,
    required this.apiBaseUri,
    required this.networkEnabled,
    required this.releaseMode,
    required this.mockBillingRequested,
    required this.mockPurchaseVerificationRequested,
    required this.hostPolicy,
  });

  final AppEnvironment environment;
  final Uri apiBaseUri;
  final bool networkEnabled;
  final bool releaseMode;
  final bool mockBillingRequested;
  final bool mockPurchaseVerificationRequested;
  final ApiHostPolicy hostPolicy;

  bool get developmentMocksAllowed =>
      environment == AppEnvironment.development && !releaseMode;

  Uri requireApiBaseUri() {
    if (!networkEnabled) {
      throw const AppConfigurationException(
        'VOXPREP_API_URL is required before Backend networking can be composed.',
      );
    }
    return apiBaseUri;
  }

  static AppEnvironment _parseEnvironment(String raw, bool releaseMode) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) {
      return releaseMode
          ? AppEnvironment.production
          : AppEnvironment.development;
    }
    return switch (normalized) {
      'development' => AppEnvironment.development,
      'staging' => AppEnvironment.staging,
      'production' => AppEnvironment.production,
      _ => throw AppConfigurationException('Unknown VOXPREP_ENV value: $raw'),
    };
  }

  static bool _parseBoolean(
    String name,
    String raw, {
    required bool defaultValue,
  }) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return defaultValue;
    return switch (normalized) {
      'true' => true,
      'false' => false,
      _ => throw AppConfigurationException('$name must be true or false.'),
    };
  }

  static Uri _parseApiBaseUri(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.isAbsolute ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw AppConfigurationException(
        'VOXPREP_API_URL must be an absolute HTTP(S) URI without '
        'credentials, query, or fragment.',
      );
    }
    return uri;
  }
}

const _appEnvironmentValue = String.fromEnvironment('VOXPREP_ENV');
const _apiBaseUrlValue = String.fromEnvironment('VOXPREP_API_URL');
const _mockBillingValue = String.fromEnvironment('VOXPREP_MOCK_BILLING');
const _mockPurchaseVerificationValue = String.fromEnvironment(
  'VOXPREP_MOCK_PURCHASE',
);
const _stagingApiHostsValue = String.fromEnvironment('VOXPREP_STAGING_HOSTS');
const _productionApiHostsValue = String.fromEnvironment('VOXPREP_PROD_HOSTS');

final appConfigurationProvider = Provider<AppConfiguration>((ref) {
  return AppConfiguration.fromBuildValues(
    releaseMode: kReleaseMode,
    appEnvironment: _appEnvironmentValue,
    apiBaseUrl: _apiBaseUrlValue,
    mockBilling: _mockBillingValue,
    mockPurchaseVerification: _mockPurchaseVerificationValue,
    stagingApiHosts: _stagingApiHostsValue,
    productionApiHosts: _productionApiHostsValue,
  );
});

bool _isUnsafeRemoteHost(String host) {
  if (host == 'localhost' ||
      host.endsWith('.local') ||
      host.endsWith('.invalid') ||
      host.endsWith('.test') ||
      host.endsWith('.example')) {
    return true;
  }

  if (host == '::1' ||
      host.startsWith('fc') ||
      host.startsWith('fd') ||
      host.startsWith('fe80:')) {
    return true;
  }

  final parts = host.split('.');
  if (parts.length != 4) return false;
  final octets = parts.map(int.tryParse).toList(growable: false);
  if (octets.any((value) => value == null || value < 0 || value > 255)) {
    return false;
  }
  final a = octets[0]!;
  final b = octets[1]!;
  return a == 10 ||
      a == 127 ||
      (a == 169 && b == 254) ||
      (a == 172 && b >= 16 && b <= 31) ||
      (a == 192 && b == 168);
}
