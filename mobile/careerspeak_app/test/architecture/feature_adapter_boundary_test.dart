import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature presentation does not import concrete mock adapters', () {
    final featureRoot = Directory('lib/features');
    expect(featureRoot.existsSync(), isTrue);

    final violations = <String>[];

    for (final entity in featureRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final source = entity.readAsStringSync();
      if (source.contains('data/mock/') ||
          source.contains('mock_content_repository.dart') ||
          source.contains('mock_test_repository.dart')) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Feature presentation must depend on application ports/providers, not concrete adapters.',
    );
  });
}
