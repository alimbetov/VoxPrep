import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateApiBaseUriForEnvironment', () {
    test('accepts HTTPS in release mode', () {
      final uri = Uri.parse('https://api.example.com');

      expect(
        validateApiBaseUriForEnvironment(uri, releaseMode: true),
        same(uri),
      );
    });

    test('rejects cleartext HTTP in release mode', () {
      expect(
        () => validateApiBaseUriForEnvironment(
          Uri.parse('http://api.example.com'),
          releaseMode: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('permits local HTTP outside release mode', () {
      final uri = Uri.parse('http://127.0.0.1:8080');

      expect(
        validateApiBaseUriForEnvironment(uri, releaseMode: false),
        same(uri),
      );
    });
  });
}
