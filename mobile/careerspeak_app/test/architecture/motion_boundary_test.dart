import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion dependencies remain presentation-only', () {
    final forbiddenRoots = <String>[
      'lib/application',
      'lib/data',
      'lib/domain',
    ];

    for (final rootPath in forbiddenRoots) {
      final root = Directory(rootPath);
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final source = entity.readAsStringSync();
        expect(
          source.contains('core/motion/') ||
              source.contains("../motion/") ||
              source.contains("../../motion/"),
          isFalse,
          reason: 'Motion dependency leaked into ${entity.path}',
        );
      }
    }
  });
}
