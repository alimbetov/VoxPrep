import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('remote wire types do not leak into inner application layers', () {
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
        if (source.contains('data/remote/')) {
          violations.add(entity.path);
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Remote DTOs, decoders and HTTP adapters must remain outside domain, application and feature presentation.',
    );
  });
}
