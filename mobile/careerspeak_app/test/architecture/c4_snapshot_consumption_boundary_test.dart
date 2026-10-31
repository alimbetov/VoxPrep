import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production repository composition uses Drift snapshot adapters', () {
    final source = File('lib/app/repository_providers.dart').readAsStringSync();

    expect(source, contains('DriftContentRepository'));
    expect(source, contains('DriftPracticeTestRepository'));
    expect(source, isNot(contains('UnavailablePracticeTestRepository')));
    expect(source, isNot(contains('data/mock/')));
  });

  test('production remote adapters do not use latest/current revision endpoints', () {
    final remoteRoot = Directory('lib/data/remote');
    expect(remoteRoot.existsSync(), isTrue);

    final violations = <String>[];
    for (final entity in remoteRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync().toLowerCase();
      if (source.contains('/latest') ||
          source.contains('revision=latest') ||
          source.contains("'latest'") ||
          source.contains('"latest"')) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'C4 publication consumption must resolve exact revisions from immutable snapshot membership, never latest/current remote aliases.',
    );
  });
}
