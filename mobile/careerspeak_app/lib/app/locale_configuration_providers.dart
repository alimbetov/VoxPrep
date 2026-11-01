import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/locale_configuration_gateway.dart';
import '../application/result/result.dart';
import '../data/remote/http_locale_configuration_gateway.dart';
import '../domain/locale_configuration.dart';
import 'api_client_providers.dart';

final localeConfigurationGatewayProvider = Provider<LocaleConfigurationGateway>((
  ref,
) {
  return HttpLocaleConfigurationGateway(apiClient: ref.watch(apiClientProvider));
});

final countryLocaleConfigurationProvider =
    FutureProvider.family<CountryLocaleConfiguration, String>((
      ref,
      countryCode,
    ) async {
      final result = await ref
          .watch(localeConfigurationGatewayProvider)
          .fetchForCountry(countryCode);
      return switch (result) {
        Success<CountryLocaleConfiguration>(:final value) => value,
        FailureResult<CountryLocaleConfiguration>(:final failure) =>
          throw StateError('${failure.code}: ${failure.message}'),
      };
    });
