from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing C1 fallback-test v2 anchor in {path}: {old[:220]}')
    file.write_text(text.replace(old, new, 1))


# Sync projection must follow an explicit Backend rule.
projection = Path(
    'mobile/careerspeak_app/test/application/content_sync/content_sync_locale_projection_test.dart'
)
text = projection.read_text()
text = text.replace(
    "test('sync materializes only canonical plus exact and language fallback packs', () async {",
    "test('sync materializes only canonical plus Backend-configured fallback packs', () async {",
)
anchor = '''              german,
            ],
          ),
'''
replacement = '''              german,
            ],
            localeFallbacks: <LocaleFallbackRule>[
              LocaleFallbackRule(
                locale: 'ru-KZ',
                fallbackLocales: const <String>['ru', 'en'],
              ),
            ],
          ),
'''
if replacement not in text:
    if anchor not in text:
        raise SystemExit('missing locale projection Backend rule anchor')
    text = text.replace(anchor, replacement, 1)
projection.write_text(text)

# Resolver tests seed CURRENT root policy in the existing Drift v6 table.
repo_test = Path(
    'mobile/careerspeak_app/test/data/local/drift_localized_content_repository_test.dart'
)
text = repo_test.read_text()
text = text.replace(
    "import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';\n",
    """import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:careerspeak_app/application/content_delivery/localized_content_resolution.dart';
""",
    1,
)
text = text.replace(
    "test('exact locale overlays language fallback field by field', () async {\n    await _seedLocalization(",
    """test('exact locale overlays configured fallback field by field', () async {
    await _seedFallbackRule(
      database,
      locale: 'ru-KZ',
      fallbackLocales: const <String>['ru', 'en'],
    );
    await _seedLocalization(""",
    1,
)
text = text.replace(
    """    'superseded exact locale is ignored and language fallback wins',
    () async {
      await _seedLocalization(""",
    """    'superseded exact locale is ignored and configured fallback wins',
    () async {
      await _seedFallbackRule(
        database,
        locale: 'ru-KZ',
        fallbackLocales: const <String>['ru', 'en'],
      );
      await _seedLocalization(""",
    1,
)
text = text.replace('LocaleFallbackKind.language', 'LocaleFallbackKind.configured')
text = text.replace(
    'isA<FailureResult>()',
    'isA<FailureResult<ResolvedLocalizedContent?>>()',
)
text = text.replace(
    '(result as FailureResult).failure.code',
    '(result as FailureResult<ResolvedLocalizedContent?>).failure.code',
)
helper_anchor = 'Future<void> _seedLocalization(\n'
helper = '''Future<void> _seedFallbackRule(
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
          localePolicyContentVersion: const Value(1),
          updatedAt: now,
        ),
      );
  await (database.delete(database.localeFallbackRules)
        ..where((row) => row.locale.equals(locale)))
      .go();
  for (var order = 0; order < fallbackLocales.length; order += 1) {
    await database
        .into(database.localeFallbackRules)
        .insert(
          LocaleFallbackRulesCompanion.insert(
            locale: locale,
            fallbackOrder: order,
            fallbackLocale: fallbackLocales[order],
            sourceContentVersion: 1,
          ),
        );
  }
}

Future<void> _seedLocalization(
'''
if helper not in text:
    if helper_anchor not in text:
        raise SystemExit('missing localized repository helper anchor')
    text = text.replace(helper_anchor, helper, 1)
checksum_anchor = '''const _canonicalChecksum =
'''
checksum_replacement = '''const _rootChecksum =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const _canonicalChecksum =
'''
if checksum_replacement not in text:
    if checksum_anchor not in text:
        raise SystemExit('missing localized repository checksum anchor')
    text = text.replace(checksum_anchor, checksum_replacement, 1)
repo_test.write_text(text)

# File-backed restart acceptance persists a committed Backend policy before reopen.
restart = Path(
    'mobile/careerspeak_app/test/acceptance/c1_localization_recovery_acceptance_test.dart'
)
text = restart.read_text().replace(
    'LocaleFallbackKind.language',
    'LocaleFallbackKind.configured',
)
text = text.replace(
    '''          currentManifestChecksum: _rootChecksum,
          remoteContentVersionSeen: const Value(42),
''',
    '''          currentManifestChecksum: _rootChecksum,
          localePolicyContentVersion: const Value(42),
          remoteContentVersionSeen: const Value(42),
''',
    1,
)
manifest_seed = '''      );

  await database
      .into(database.localContentRecords)
'''
manifest_seed_replacement = '''      );
  await database
      .into(database.localeFallbackRules)
      .insert(
        LocaleFallbackRulesCompanion.insert(
          locale: 'ru-KZ',
          fallbackOrder: 0,
          fallbackLocale: 'ru',
          sourceContentVersion: 42,
        ),
      );
  await database
      .into(database.localeFallbackRules)
      .insert(
        LocaleFallbackRulesCompanion.insert(
          locale: 'ru-KZ',
          fallbackOrder: 1,
          fallbackLocale: 'en',
          sourceContentVersion: 42,
        ),
      );

  await database
      .into(database.localContentRecords)
'''
if manifest_seed_replacement not in text:
    if manifest_seed not in text:
        raise SystemExit('missing restart fallback seed anchor')
    text = text.replace(manifest_seed, manifest_seed_replacement, 1)
restart.write_text(text)

# Migration tests use the actual v6 table name.
migration = Path(
    'mobile/careerspeak_app/test/data/local/database/careerspeak_database_migration_test.dart'
)
text = migration.read_text().replace(
    'migratedDatabase.rootLocaleFallbacks',
    'migratedDatabase.localeFallbackRules',
)
migration.write_text(text)

# Atomic persistence test uses LocaleFallbackRules and CURRENT-policy semantics.
persistence = Path(
    'mobile/careerspeak_app/test/data/local/drift_root_fallback_persistence_test.dart'
)
text = persistence.read_text()
text = text.replace('database.rootLocaleFallbacks', 'database.localeFallbackRules')
text = text.replace(
    'row.contentVersion.equals(120)',
    'row.sourceContentVersion.equals(120)',
)
text = text.replace('row.position', 'row.fallbackOrder')
persistence.write_text(text)

# Pack manifest v1 now has an explicit immutable localization-ref collection.
# Canonical packs carry the field as an empty array rather than omitting it.
fixture = Path('mobile/careerspeak_app/test/contracts/fixtures/pack_manifest_v1.json')
fixture_text = fixture.read_text()
fixture_old = '''  ],
  "assets": [
'''
fixture_new = '''  ],
  "localizations": [],
  "assets": [
'''
if fixture_new not in fixture_text:
    if fixture_old not in fixture_text:
        raise SystemExit('missing canonical pack fixture localization anchor')
    fixture_text = fixture_text.replace(fixture_old, fixture_new, 1)
fixture.write_text(fixture_text)
