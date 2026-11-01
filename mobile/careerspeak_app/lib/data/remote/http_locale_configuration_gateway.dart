import '../../application/ports/api_client.dart';
import '../../application/ports/locale_configuration_gateway.dart';
import '../../application/result/result.dart';
import '../../domain/locale_configuration.dart';

final class HttpLocaleConfigurationGateway implements LocaleConfigurationGateway {
  const HttpLocaleConfigurationGateway({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<Result<CountryLocaleConfiguration>> fetchForCountry(
    String countryCode,
  ) async {
    final country = countryCode.trim().toUpperCase();
    if (!_countryCodePattern.hasMatch(country)) {
      return const FailureResult<CountryLocaleConfiguration>(
        ApplicationFailure(
          code: 'COUNTRY_CODE_INVALID',
          message: 'Country code must be an ISO-3166 alpha-2 code.',
        ),
      );
    }

    final response = await _apiClient.send(
      ApiRequest(
        method: ApiMethod.get,
        path: '/api/v1/configuration/locales',
        queryParameters: <String, String>{'countryCode': country},
      ),
    );
    if (response case FailureResult<ApiResponse>(:final failure)) {
      return FailureResult<CountryLocaleConfiguration>(failure);
    }

    final apiResponse = (response as Success<ApiResponse>).value;
    if (apiResponse.statusCode != 200) {
      return FailureResult<CountryLocaleConfiguration>(
        ApplicationFailure(
          code: 'LOCALE_CONFIGURATION_RESPONSE_INVALID',
          message: 'Locale configuration endpoint returned an invalid status.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{'statusCode': apiResponse.statusCode},
        ),
      );
    }

    try {
      final body = _object(apiResponse.jsonBody, r'$');
      _requireExactKeys(
        body,
        const <String>{'countryCode', 'defaultLocale', 'locales'},
        r'$',
      );
      final items = body['locales'];
      if (items is! List) {
        throw const FormatException(r'$.locales must be an array');
      }
      final locales = <SupportedLocaleOption>[];
      for (var index = 0; index < items.length; index++) {
        final item = _object(items[index], r'$.locales[]');
        _requireExactKeys(
          item,
          const <String>{'code', 'label'},
          r'$.locales[]',
        );
        locales.add(
          SupportedLocaleOption(
            code: _string(item, 'code'),
            label: _string(item, 'label'),
          ),
        );
      }
      final configuration = CountryLocaleConfiguration(
        countryCode: _string(body, 'countryCode'),
        defaultLocale: _string(body, 'defaultLocale'),
        locales: locales,
      );
      if (configuration.countryCode != country) {
        throw const FormatException('countryCode does not match the request');
      }
      return Success<CountryLocaleConfiguration>(configuration);
    } on Object catch (error) {
      return FailureResult<CountryLocaleConfiguration>(
        ApplicationFailure(
          code: 'LOCALE_CONFIGURATION_PAYLOAD_INVALID',
          message: 'Backend returned an invalid locale configuration payload.',
          traceId: apiResponse.traceId,
          details: <String, Object?>{'cause': error.runtimeType.toString()},
        ),
      );
    }
  }
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path must be an object');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) throw FormatException('$path has invalid key');
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _string(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException(r'$.' '$key must be a non-blank string');
  }
  return value.trim();
}

void _requireExactKeys(
  Map<String, Object?> object,
  Set<String> expected,
  String path,
) {
  final actual = object.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw FormatException('$path contains unexpected or missing fields');
  }
}

final _countryCodePattern = RegExp(r'^[A-Z]{2}$');
