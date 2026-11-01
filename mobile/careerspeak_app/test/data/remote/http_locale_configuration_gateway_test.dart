import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/remote/http_locale_configuration_gateway.dart';
import 'package:careerspeak_app/domain/locale_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'loads exact backend locale configuration for selected country',
    () async {
      final api = _RecordingApiClient(
        response: ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{
            'countryCode': 'KZ',
            'defaultLocale': 'kk-KZ',
            'locales': <Object?>[
              <String, Object?>{'code': 'kk-KZ', 'label': 'Қазақша'},
              <String, Object?>{'code': 'ru-KZ', 'label': 'Русский'},
              <String, Object?>{'code': 'en', 'label': 'English'},
            ],
          },
        ),
      );
      final gateway = HttpLocaleConfigurationGateway(apiClient: api);

      final result = await gateway.fetchForCountry('kz');

      expect(result, isA<Success<CountryLocaleConfiguration>>());
      final value = (result as Success<CountryLocaleConfiguration>).value;
      expect(value.countryCode, 'KZ');
      expect(value.defaultLocale.code, 'kk-KZ');
      expect(value.locales.map((item) => item.locale.code), <String>[
        'kk-KZ',
        'ru-KZ',
        'en',
      ]);
      expect(api.lastRequest?.method, ApiMethod.get);
      expect(api.lastRequest?.path, '/api/v1/configuration/locales');
      expect(api.lastRequest?.queryParameters, <String, String>{
        'countryCode': 'KZ',
      });
      expect(api.lastRequest?.authentication, ApiAuthentication.none);
    },
  );

  test('rejects a response for a different country', () async {
    final gateway = HttpLocaleConfigurationGateway(
      apiClient: _RecordingApiClient(
        response: ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{
            'countryCode': 'TR',
            'defaultLocale': 'tr-TR',
            'locales': <Object?>[
              <String, Object?>{'code': 'tr-TR', 'label': 'Türkçe'},
            ],
          },
        ),
      ),
    );

    final result = await gateway.fetchForCountry('KZ');

    expect(result, isA<FailureResult<CountryLocaleConfiguration>>());
    expect(
      (result as FailureResult<CountryLocaleConfiguration>).failure.code,
      'LOCALE_CONFIGURATION_PAYLOAD_INVALID',
    );
  });

  test('rejects mutable or unknown fields in locale configuration', () async {
    final gateway = HttpLocaleConfigurationGateway(
      apiClient: _RecordingApiClient(
        response: ApiResponse(
          statusCode: 200,
          headers: const <String, String>{},
          jsonBody: const <String, Object?>{
            'countryCode': 'KZ',
            'defaultLocale': 'ru-KZ',
            'locales': <Object?>[
              <String, Object?>{'code': 'ru-KZ', 'label': 'Русский'},
            ],
            'updatedAt': '2026-11-01T00:00:00Z',
          },
        ),
      ),
    );

    final result = await gateway.fetchForCountry('KZ');

    expect(result, isA<FailureResult<CountryLocaleConfiguration>>());
  });

  test('rejects invalid country before network', () async {
    final api = _RecordingApiClient(
      response: ApiResponse(
        statusCode: 200,
        headers: const <String, String>{},
        jsonBody: const <String, Object?>{},
      ),
    );
    final gateway = HttpLocaleConfigurationGateway(apiClient: api);

    final result = await gateway.fetchForCountry('KAZ');

    expect(result, isA<FailureResult<CountryLocaleConfiguration>>());
    expect(api.lastRequest, isNull);
  });
}

final class _RecordingApiClient implements ApiClient {
  _RecordingApiClient({required this.response});

  final ApiResponse response;
  ApiRequest? lastRequest;

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) async {
    lastRequest = request;
    return Success<ApiResponse>(response);
  }
}
