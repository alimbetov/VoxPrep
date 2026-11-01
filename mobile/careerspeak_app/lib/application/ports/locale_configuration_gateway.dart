import '../../domain/locale_configuration.dart';
import '../result/result.dart';

abstract interface class LocaleConfigurationGateway {
  Future<Result<CountryLocaleConfiguration>> fetchForCountry(
    String countryCode,
  );
}
