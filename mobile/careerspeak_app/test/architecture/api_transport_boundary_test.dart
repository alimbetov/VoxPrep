import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('domain application and features do not depend on package:http', () {
    final roots = <Directory>[
      Directory('lib/domain'),
      Directory('lib/application'),
      Directory('lib/features'),
    ];
    final violations = <String>[];

    for (final root in roots) {
      expect(root.existsSync(), isTrue, reason: root.path);
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final source = entity.readAsStringSync();
        if (source.contains('package:http/')) {
          violations.add(entity.path);
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'HTTP package types belong in the data/composition layers and must not leak into domain, application contracts, or feature presentation.',
    );
  });
}
