from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing full-regression anchor in {path}: {old[:220]}')
    file.write_text(text.replace(old, new, 1))


# Motion: assert the transition returned by CareerSpeakMotion directly instead
# of counting unrelated Material route SlideTransitions in the widget tree.
replace_once(
    'mobile/careerspeak_app/test/core/motion/careerspeak_motion_test.dart',
    '''    expect(find.byType(SlideTransition), findsOneWidget);
''',
    '''    expect(transition, isA<FadeTransition>());
    final fade = transition as FadeTransition;
    expect(fade.child, isA<SlideTransition>());
    final slide = fade.child! as SlideTransition;
    expect(slide.position.value.dx, closeTo(-0.04, 0.000001));
''',
)

# A missing pack in the device-local projection is metadata drift on the same
# immutable root and therefore requires a commit, even though contentVersion
# and root checksum do not change.
replace_once(
    'mobile/careerspeak_app/test/application/content_sync/content_sync_planner_test.dart',
    '''    expect(plan.rootChanged, isFalse);
    expect(plan.isNoOp, isFalse);
    expect(plan.changedPacks, hasLength(1));
''',
    '''    expect(plan.rootChanged, isTrue);
    expect(plan.isNoOp, isFalse);
    expect(plan.changedPacks, hasLength(1));
''',
)

# P2.8 predates localization/retirement persistence. The production database is
# now schema v6; asset resolution behavior itself is unchanged.
replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_8_asset_resolution_test.dart',
    '      expect(database.schemaVersion, 4);\n',
    '      expect(database.schemaVersion, 6);\n',
)

# C1.1 makes the root manifest locale-independent. Translation locale is used
# after the immutable root is fetched, never as a root query parameter.
replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_10_7_production_e2e_test.dart',
    '''      if (request.url.queryParameters['locale'] != 'ru') {
        throw StateError('Startup sync must use persisted translation locale.');
      }
''',
    '''      if (request.url.queryParameters.isNotEmpty) {
        throw StateError('Root manifest request must stay locale-independent.');
      }
''',
)
replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_10_7_production_e2e_test.dart',
    '''  ],
  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};
''',
    '''  ],
  'localizations': <Object?>[],
  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};
''',
)

# Recovery fixtures use canonical packs. Canonical packs explicitly carry an
# empty localization-ref collection under the hardened pack contract.
replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_11_recovery_acceptance_test.dart',
    '''  ],
  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};
''',
    '''  ],
  'localizations': <Object?>[],
  'assets': <Object?>[],
  'contentAssets': <Object?>[],
};
''',
)

# Remote gateway/decoder fixtures must reach identity/checksum validation rather
# than failing earlier because canonical pack localization refs are omitted.
replace_once(
    'mobile/careerspeak_app/test/data/remote/http_content_manifest_gateway_test.dart',
    '''    'contents': const <Object?>[],
    'assets': const <Object?>[],
''',
    '''    'contents': const <Object?>[],
    'localizations': const <Object?>[],
    'assets': const <Object?>[],
''',
)
replace_once(
    'mobile/careerspeak_app/test/data/remote/content_manifest_decoder_test.dart',
    '''    ],
    'assets': <Object?>[
''',
    '''    ],
    'localizations': <Object?>[],
    'assets': <Object?>[
''',
)

# This journal test isolates canonical payload repair. Seed a healthy v6 locale
# policy marker so the planner does not also request an unrelated policy repair.
replace_once(
    'mobile/careerspeak_app/test/data/local/drift_sync_journal_test.dart',
    '''              currentManifestChecksum: _root108,
              updatedAt: now,
''',
    '''              currentManifestChecksum: _root108,
              localePolicyContentVersion: const Value(108),
              updatedAt: now,
''',
)
