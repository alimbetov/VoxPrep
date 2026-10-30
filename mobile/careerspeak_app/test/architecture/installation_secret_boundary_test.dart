import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Drift and local persistence source contain no installation secrets', () {
    final localRoot = Directory('lib/data/local');
    expect(localRoot.existsSync(), isTrue);

    final violations = <String>[];
    const forbidden = <String>{
      'installationToken',
      'InstallationToken',
      'installation_token',
      'installation_id',
    };

    for (final entity in localRoot.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;

      final source = entity.readAsStringSync();
      if (forbidden.any(source.contains)) {
        violations.add(entity.path);
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Installation identity and token belong to platform Secure Storage, never Drift/local persistence.',
    );
  });
}
