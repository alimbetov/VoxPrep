from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing fallback-test anchor in {path}: {old[:220]}')
    p.write_text(text.replace(old, new, 1))


projection = 'mobile/careerspeak_app/test/application/content_sync/content_sync_locale_projection_test.dart'
replace_once(
    projection,
    "test('sync materializes only canonical plus exact and language fallback packs', () async {",
    "test('sync materializes only canonical plus Backend-configured fallback packs', () async {",
)
replace_once(
    projection,
    '''              german,
            ],
          ),
''',
    '''              german,
            ],
            localeFallbacks: <LocaleFallbackRule>[
              LocaleFallbackRule(
                locale: 'ru-KZ',
                fallbackLocales: const <String>['ru', 'en'],
              ),
            ],
          ),
''',
)

repo_test = 'mobile/careerspeak_app/test/data/local/drift_localized_content_repository_test.dart'
replace_once(
    repo_test,
    """  test('exact locale overlays language fallback field by field', () async {
    await _seedLocalization(
""",
    """  test('exact locale overlays configured fallback field by field', () async {
    await _seedFallbackRule(
      database,
      locale: 'ru-KZ',
      fallbackLocales: const <String>['ru', 'en'],
    );
    await _seedLocalization(
""",
)
replace_once(
    repo_test,
    """    'superseded exact locale is ignored and language fallback wins',
    () async {
      await _seedLocalization(
""",
    """    'superseded exact locale is ignored and configured fallback wins',
    () async {
      await _seedFallbackRule(
        database,
        locale: 'ru-KZ',
        fallbackLocales: const <String>['ru', 'en'],
      );
      await _seedLocalization(
""",
)
replace_once(
    repo_test,
    'LocaleFallbackKind.language',
    'LocaleFallbackKind.configured',
)
replace_once(
    repo_test,
    '''Future<void> _seedLocalization(
''',
    '''Future<void> _seedFallbackRule(
  CareerSpeakDatabase database, {
  required String locale,
  required List<String> fallbackLocales,
}) async {
  final now = DateTime.utc(2026, 10, 31, 4);
  await database
      .into(database.contentManifestStates)
      .insertOnConflictUpdate(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 1,
          currentContentVersion: 1,
          currentManifestChecksum: _rootChecksum,
          updatedAt: now,
        ),
      );
  await (database.delete(database.rootLocaleFallbacks)..where(
        (row) => row.contentVersion.equals(1) & row.locale.equals(locale),
      ))
      .go();
  for (var position = 0; position < fallbackLocales.length; position += 1) {
    await database
        .into(database.rootLocaleFallbacks)
        .insert(
          RootLocaleFallbacksCompanion.insert(
            contentVersion: 1,
            locale: locale,
            position: position,
            fallbackLocale: fallbackLocales[position],
          ),
        );
  }
}

Future<void> _seedLocalization(
''',
)
replace_once(
    repo_test,
    '''const _canonicalChecksum =
''',
    '''const _rootChecksum =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const _canonicalChecksum =
''',
)

restart = 'mobile/careerspeak_app/test/acceptance/c1_localization_recovery_acceptance_test.dart'
replace_once(
    restart,
    'LocaleFallbackKind.language',
    'LocaleFallbackKind.configured',
)
replace_once(
    restart,
    '''      );

  await database
      .into(database.localContentRecords)
''',
    '''      );
  await database
      .into(database.rootLocaleFallbacks)
      .insert(
        RootLocaleFallbacksCompanion.insert(
          contentVersion: 42,
          locale: 'ru-KZ',
          position: 0,
          fallbackLocale: 'ru',
        ),
      );
  await database
      .into(database.rootLocaleFallbacks)
      .insert(
        RootLocaleFallbacksCompanion.insert(
          contentVersion: 42,
          locale: 'ru-KZ',
          position: 1,
          fallbackLocale: 'en',
        ),
      );

  await database
      .into(database.localContentRecords)
''',
)
