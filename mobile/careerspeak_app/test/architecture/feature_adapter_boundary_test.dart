import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature presentation does not import concrete adapters', () {
    final featureRoot = Directory('lib/features');
    expect(featureRoot.existsSync(), isTrue);

    final violations = <String>[];

    for (final entity in featureRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final source = entity.readAsStringSync();
      if (source.contains('data/mock/') ||
          source.contains('data/local/') ||
          source.contains('data/secure/') ||
          source.contains('data/remote/') ||
          source.contains('mock_content_repository.dart') ||
          source.contains('mock_test_repository.dart') ||
          source.contains('drift_learner_state_repository.dart') ||
          source.contains(
            'flutter_secure_installation_credential_store.dart',
          ) ||
          source.contains('http_api_client.dart')) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Feature presentation must depend on domain/application contracts and composition providers, not concrete adapters.',
    );
  });
}
