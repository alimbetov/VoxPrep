from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    if old not in text:
        raise SystemExit(f'missing full-suite fix anchor in {path}: {old[:240]}')
    p.write_text(text.replace(old, new, 1))


replace_once(
    'mobile/careerspeak_app/test/core/motion/careerspeak_motion_test.dart',
    '    expect(find.byType(SlideTransition), findsOneWidget);',
    '    expect(transition, isA<SlideTransition>());',
)

replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_8_asset_resolution_test.dart',
    '      expect(database.schemaVersion, 4);',
    '      expect(database.schemaVersion, 5);',
)

replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_10_7_production_e2e_test.dart',
    """      if (request.url.queryParameters['locale'] != 'ru') {
        throw StateError('Startup sync must use persisted translation locale.');
      }
""",
    """      if (request.url.queryParameters.containsKey('locale')) {
        throw StateError('Root manifest request must remain locale-independent.');
      }
""",
)
replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_10_7_production_e2e_test.dart',
    """  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};
""",
    """  'localizations': <Object?>[],
  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};
""",
)

replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_11_recovery_acceptance_test.dart',
    """  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};
""",
    """  'localizations': <Object?>[],
  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};
""",
)

replace_once(
    'mobile/careerspeak_app/test/data/remote/http_content_manifest_gateway_test.dart',
    """    'contents': const <Object?>[],
    'assets': const <Object?>[],
""",
    """    'contents': const <Object?>[],
    'localizations': const <Object?>[],
    'assets': const <Object?>[],
""",
)

replace_once(
    'mobile/careerspeak_app/test/data/remote/content_manifest_decoder_test.dart',
    """    'assets': <Object?>[
""",
    """    'localizations': <Object?>[],
    'assets': <Object?>[
""",
)

p = Path('mobile/careerspeak_app/test/contracts/fixtures/pack_manifest_v1.json')
text = p.read_text()
anchor = '  ],\n  "assets": ['
if anchor not in text:
    raise SystemExit('missing JSON pack fixture localization anchor')
text = text.replace(anchor, '  ],\n  "localizations": [],\n  "assets": [', 1)
p.write_text(text)
