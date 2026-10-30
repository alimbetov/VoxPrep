import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('learner api v1 keeps the Flutter wire contract baseline', () {
    final contract = File('../../contracts/learner-api-v1.yaml');
    expect(contract.existsSync(), isTrue);

    final source = contract.readAsStringSync();
    for (final requiredFragment in <String>[
      '/api/v1/installations:',
      '/api/v1/content/manifest:',
      '/api/v1/content/packs/{packCode}/manifest:',
      '/api/v1/content/{contentType}/{contentCode}/revisions/{revision}:',
      'installationBearer:',
      'RootContentManifest:',
      'PackContentManifest:',
      'ContentPayload:',
      'ApiError:',
      '- categoryCode',
      '- categoryLabel',
      '- levelCode',
      '- levelLabel',
      "pattern: '^[A-Z0-9][A-Z0-9._-]*$'",
    ]) {
      expect(
        source,
        contains(requiredFragment),
        reason: 'Missing learner API contract fragment: $requiredFragment',
      );
    }
  });
}
