import 'package:careerspeak_app/application/content_delivery/catalogue_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = CatalogueSelectionPolicy();

  test('keeps an active selected catalogue code', () {
    final result = policy.resolve(
      selectedCode: 'VOICE_B',
      choices: <CatalogueChoice>[
        CatalogueChoice(code: 'VOICE_A', sortOrder: 0, active: true),
        CatalogueChoice(code: 'VOICE_B', sortOrder: 10, active: true),
      ],
    );

    expect(result, 'VOICE_B');
  });

  test('inactive selection falls back by sort order then stable code', () {
    final result = policy.resolve(
      selectedCode: 'VOICE_OLD',
      choices: <CatalogueChoice>[
        CatalogueChoice(code: 'VOICE_OLD', sortOrder: 0, active: false),
        CatalogueChoice(code: 'VOICE_B', sortOrder: 5, active: true),
        CatalogueChoice(code: 'VOICE_A', sortOrder: 5, active: true),
        CatalogueChoice(code: 'VOICE_C', sortOrder: 20, active: true),
      ],
    );

    expect(result, 'VOICE_A');
  });

  test('missing selection uses the same deterministic active fallback', () {
    final result = policy.resolve(
      selectedCode: 'MISSING',
      choices: <CatalogueChoice>[
        CatalogueChoice(code: 'B2', sortOrder: 20, active: true),
        CatalogueChoice(code: 'B1', sortOrder: 10, active: true),
      ],
    );

    expect(result, 'B1');
  });

  test('returns null when no active catalogue choice exists', () {
    final result = policy.resolve(
      selectedCode: null,
      choices: <CatalogueChoice>[
        CatalogueChoice(code: 'RETIRED', sortOrder: 0, active: false),
      ],
    );

    expect(result, isNull);
  });

  test('duplicate catalogue identities fail closed', () {
    expect(
      () => policy.resolve(
        selectedCode: null,
        choices: <CatalogueChoice>[
          CatalogueChoice(code: 'DUP', sortOrder: 0, active: true),
          CatalogueChoice(code: 'DUP', sortOrder: 1, active: false),
        ],
      ),
      throwsArgumentError,
    );
  });
}
