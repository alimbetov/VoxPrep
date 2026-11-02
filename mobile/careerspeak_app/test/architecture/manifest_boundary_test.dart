import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('content delivery transport stays behind application boundary', () {
    final roots = <Directory>[
      Directory('lib/domain'),
      Directory('lib/application'),
      Directory('lib/features'),
    ];
    final violations = <String>[];

    for (final root in roots) {
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        final source = entity.readAsStringSync();
        if (source.contains('data/remote/content_manifest_decoder.dart') ||
            source.contains('data/remote/http_content_manifest_gateway.dart') ||
            source.contains('data/remote/content_payload_decoder.dart') ||
            source.contains('data/remote/http_content_payload_gateway.dart')) {
          violations.add(entity.path);
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: 'Domain, application, and features must depend on content delivery contracts, not remote adapters.',
    );
  });
}
