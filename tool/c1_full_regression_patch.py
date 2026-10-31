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

# Renderer acceptance must not hold an HTTP request open while taking a PNG.
# Render the real empty production UI first, then enable ProductionBootstrapHost
# against the same Drift database and assert that the live query updates.
replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_10_7_production_e2e_test.dart',
    '''      final manifestGate = Completer<void>();
      final backend = _LearnerApiFixture(rootManifestGate: manifestGate);
      final client = MockClient(backend.handle);
      addTearDown(database.close);
      addTearDown(client.close);

      const screenshotKey = Key('production-e2e-screenshot');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            careerSpeakDatabaseProvider.overrideWithValue(database),
            installationCredentialStoreProvider.overrideWithValue(
              credentialStore,
            ),
            httpClientProvider.overrideWithValue(client),
            apiBaseUriProvider.overrideWithValue(
              Uri.parse('https://api.careerspeak.test'),
            ),
          ],
          child: const RepaintBoundary(
            key: screenshotKey,
            child: ProductionBootstrapHost(child: CareerSpeakApp()),
          ),
        ),
      );

      expect(find.byKey(screenshotKey), findsOneWidget);
      expect(find.text('Dependency Injection'), findsNothing);
      await _pumpUntilCondition(
        tester,
        () => backend.rootManifestCalls == 1,
        'root manifest request',
      );
      expect(backend.registrationCalls, 1);
      expect(backend.packManifestCalls, 0);
      expect(backend.contentPayloadCalls, 0);
      await _captureScreenshot(
        tester,
        screenshotKey,
        '01-home-before-sync.png',
      );

      manifestGate.complete();
      await _pumpUntil(tester, find.text('Dependency Injection'));
      expect(backend.packManifestCalls, 1);
      expect(backend.contentPayloadCalls, 1);
''',
    '''      final backend = _LearnerApiFixture();
      final client = MockClient(backend.handle);
      addTearDown(database.close);
      addTearDown(client.close);

      const screenshotKey = Key('production-e2e-screenshot');
      ProviderScope buildApp({required bool bootstrap}) => ProviderScope(
        overrides: [
          careerSpeakDatabaseProvider.overrideWithValue(database),
          installationCredentialStoreProvider.overrideWithValue(
            credentialStore,
          ),
          httpClientProvider.overrideWithValue(client),
          apiBaseUriProvider.overrideWithValue(
            Uri.parse('https://api.careerspeak.test'),
          ),
        ],
        child: RepaintBoundary(
          key: screenshotKey,
          child: bootstrap
              ? const ProductionBootstrapHost(child: CareerSpeakApp())
              : const CareerSpeakApp(),
        ),
      );

      await tester.pumpWidget(buildApp(bootstrap: false));
      expect(find.byKey(screenshotKey), findsOneWidget);
      expect(find.text('Dependency Injection'), findsNothing);
      expect(backend.registrationCalls, 0);
      expect(backend.rootManifestCalls, 0);
      expect(backend.packManifestCalls, 0);
      expect(backend.contentPayloadCalls, 0);
      await _captureScreenshot(
        tester,
        screenshotKey,
        '01-home-before-sync.png',
      );

      await tester.pumpWidget(buildApp(bootstrap: true));
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(screenshotKey)),
      );
      final bootstrapResult = await tester.runAsync(
        () => container.read(applicationBootstrapProvider.future),
      );
      expect(bootstrapResult, isNotNull);
      bootstrapResult!.getOrThrow();
      expect(backend.registrationCalls, 1);
      expect(backend.rootManifestCalls, 1);
      expect(backend.packManifestCalls, 1);
      expect(backend.contentPayloadCalls, 1);
      await tester.pump();
      await _pumpUntil(tester, find.text('Dependency Injection'));
''',
)
replace_once(
    'mobile/careerspeak_app/test/acceptance/p2_10_7_production_e2e_test.dart',
    '''      await _captureScreenshot(
        tester,
        screenshotKey,
        '04-detail-after-sync.png',
      );
''',
    '''      await _captureScreenshot(
        tester,
        screenshotKey,
        '04-detail-after-sync.png',
      );

      // Dispose ProviderScope and its Drift subscriptions before closing the
      // database in tearDown. This also proves the E2E owns no dangling work.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
