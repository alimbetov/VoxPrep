from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected exactly one patch anchor, found {count}')
    file.write_text(text.replace(old, new, 1))


replace_once(
    'mobile/careerspeak_app/test/core/motion/careerspeak_motion_test.dart',
    """    expect(find.byType(SlideTransition), findsOneWidget);\n""",
    """    expect(transition, isA<FadeTransition>());\n    final slide = (transition as FadeTransition).child as SlideTransition;\n    expect(slide.position.value.dx, lessThan(0));\n""",
)

replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_8_asset_resolution_test.dart',
    '      expect(database.schemaVersion, 4);\n',
    '      expect(database.schemaVersion, 5);\n',
)

replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_10_7_production_e2e_test.dart',
    """      if (request.url.queryParameters['locale'] != 'ru') {\n        throw StateError('Startup sync must use persisted translation locale.');\n      }\n""",
    """      if (request.url.queryParameters.containsKey('locale')) {\n        throw StateError(\n          'Root manifest identity must remain locale-independent.',\n        );\n      }\n""",
)

replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_10_7_production_e2e_test.dart',
    """  ],\n  'assets': <Object?>[],\n  'contentAssets': <Object?>[],\n};\n\nconst _contentPayload""",
    """  ],\n  'localizations': <Object?>[],\n  'assets': <Object?>[],\n  'contentAssets': <Object?>[],\n};\n\nconst _contentPayload""",
)

replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_11_recovery_acceptance_test.dart',
    """  ],\n  'assets': <Object?>[],\n  'contentAssets': <Object?>[],\n};\n\nMap<String, Object?> _contentPayload""",
    """  ],\n  'localizations': <Object?>[],\n  'assets': <Object?>[],\n  'contentAssets': <Object?>[],\n};\n\nMap<String, Object?> _contentPayload""",
)

replace_once(
    'mobile/careerspeak_app/test/contracts/fixtures/pack_manifest_v1.json',
    """  ],\n  \"assets\": [\n""",
    """  ],\n  \"localizations\": [],\n  \"assets\": [\n""",
)

replace_once(
    'mobile/careerspeak_app/test/data/remote/http_content_manifest_gateway_test.dart',
    """    'contents': const <Object?>[],\n    'assets': const <Object?>[],\n""",
    """    'contents': const <Object?>[],\n    'localizations': const <Object?>[],\n    'assets': const <Object?>[],\n""",
)

replace_once(
    'mobile/careerspeak_app/test/data/remote/content_manifest_decoder_test.dart',
    """    ],\n    'assets': <Object?>[\n""",
    """    ],\n    'localizations': const <Object?>[],\n    'assets': <Object?>[\n""",
)
