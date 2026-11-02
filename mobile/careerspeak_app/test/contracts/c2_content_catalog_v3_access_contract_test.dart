import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('C2 v3 freezes explicit FREE/FULL collection access', () {
    final contract = File('../../contracts/c2-content-catalog-v3.yaml');
    expect(contract.existsSync(), isTrue);

    final source = contract.readAsStringSync();
    for (final fragment in <String>[
      'version: 3.0.0',
      'AccessLevel:',
      '- FREE',
      '- FULL',
      '- accessLevel',
      "accessLevel:\n          \$ref: '#/components/schemas/AccessLevel'",
      'Legacy v2 collection bytes without accessLevel MAY remain readable',
      'MUST be interpreted fail-closed as FULL',
      'Access MUST NOT be inferred from sortOrder',
    ]) {
      expect(
        source,
        contains(fragment),
        reason: 'Missing C2 v3 access contract fragment: $fragment',
      );
    }
  });

  test('C2 v2 remains immutable and has no monetization field', () {
    final contract = File('../../contracts/c2-content-catalog-v2.yaml');
    expect(contract.existsSync(), isTrue);

    final source = contract.readAsStringSync();
    expect(source, contains('version: 2.0.0'));
    expect(source, isNot(contains('accessLevel:')));
  });
}
