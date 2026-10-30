import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API client contract', () {
    test('request path must stay inside the configured API origin', () {
      for (final path in <String>[
        'api/v1/manifest',
        '//other.example/api',
        '/api/v1/../admin',
        '/api/v1/%2e%2e/admin',
        '/api/v1/value%2Fadmin',
        '/api/v1/value\\admin',
        '/api/v1/content?locale=en',
        '/api/v1/content#fragment',
      ]) {
        expect(
          () => ApiRequest(method: ApiMethod.get, path: path),
          throwsArgumentError,
          reason: path,
        );
      }
    });

    test('GET requests reject JSON bodies', () {
      expect(
        () => ApiRequest(
          method: ApiMethod.get,
          path: '/api/v1/content',
          jsonBody: const <String, Object?>{'unexpected': true},
        ),
        throwsArgumentError,
      );
    });

    test('request collections are immutable normalized snapshots', () {
      final query = <String, String>{'locale': 'en'};
      final headers = <String, String>{'If-None-Match': 'etag-1'};
      final request = ApiRequest(
        method: ApiMethod.get,
        path: '/api/v1/content',
        queryParameters: query,
        headers: headers,
      );

      query['locale'] = 'ru';
      headers['If-None-Match'] = 'etag-2';

      expect(request.queryParameters['locale'], 'en');
      expect(request.headers['if-none-match'], 'etag-1');
      expect(
        () => request.queryParameters['locale'] = 'kk',
        throwsUnsupportedError,
      );
    });

    test('only GET is classified as a replay-safe read', () {
      expect(
        ApiRequest(method: ApiMethod.get, path: '/read').isSafeRead,
        isTrue,
      );
      for (final method in <ApiMethod>[
        ApiMethod.post,
        ApiMethod.put,
        ApiMethod.patch,
        ApiMethod.delete,
      ]) {
        expect(ApiRequest(method: method, path: '/mutate').isSafeRead, isFalse);
      }
    });

    test('response headers are immutable and case-insensitive', () {
      final sourceHeaders = <String, String>{'ETag': 'abc'};
      final response = ApiResponse(
        statusCode: 200,
        headers: sourceHeaders,
        jsonBody: null,
      );

      sourceHeaders['ETag'] = 'changed';

      expect(response.header('ETag'), 'abc');
      expect(response.header('etag'), 'abc');
      expect(
        () => response.headers['etag'] = 'changed',
        throwsUnsupportedError,
      );
    });
  });
}
