from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if old not in text:
        raise SystemExit(f'missing anchor in {path}: {old[:120]!r}')
    file.write_text(text.replace(old, new, 1))


database_test = 'mobile/careerspeak_app/test/data/local/database/careerspeak_database_test.dart'
replace_once(
    database_test,
    "test('schema version 5 creates the production content foundation', () async {",
    "test('schema version 6 creates the production content foundation', () async {",
)
replace_once(database_test, 'expect(database.schemaVersion, 5);', 'expect(database.schemaVersion, 6);')
replace_once(
    database_test,
    "expect(userVersion.read<int>('user_version'), 5);",
    "expect(userVersion.read<int>('user_version'), 6);",
)
replace_once(
    database_test,
    "        'pack_localization_refs',\n",
    "        'pack_localization_refs',\n        'locale_fallback_rules',\n",
)

migration_test = 'mobile/careerspeak_app/test/data/local/database/careerspeak_database_migration_test.dart'
replace_once(
    migration_test,
    "import '../../../generated_migrations/schema_v4.dart' as v4;\n",
    "import '../../../generated_migrations/schema_v4.dart' as v4;\nimport '../../../generated_migrations/schema_v5.dart' as v5;\nimport '../../../generated_migrations/schema_v6.dart' as v6;\n",
)
file = Path(migration_test)
text = file.read_text()
anchor = '\n}\n'
index = text.rfind(anchor)
if index < 0:
    raise SystemExit('migration test closing brace not found')
addition = r'''

  test('v5 to v6 adds an empty backend locale fallback policy', () async {
    final schema = await verifier.schemaAt(5);
    final storedNow =
        DateTime.utc(2026, 10, 31, 5).millisecondsSinceEpoch ~/ 1000;

    final oldDatabase = v5.DatabaseAtV5(schema.newConnection());
    await oldDatabase
        .into(oldDatabase.contentManifestStates)
        .insert(
          v5.ContentManifestStatesCompanion.insert(
            id: const Value(1),
            schemaVersion: 1,
            currentContentVersion: 77,
            currentManifestChecksum:
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            remoteContentVersionSeen: const Value(77),
            remoteManifestChecksum: const Value(
              'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            ),
            updatedAt: storedNow,
          ),
        );
    await oldDatabase.close();

    final database = CareerSpeakDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 6);
    await database.close();

    final migratedDatabase = v6.DatabaseAtV6(schema.newConnection());
    final manifest = await migratedDatabase
        .select(migratedDatabase.contentManifestStates)
        .getSingle();
    expect(manifest.currentContentVersion, 77);
    expect(
      await migratedDatabase.select(migratedDatabase.localeFallbackRules).get(),
      isEmpty,
    );
    await migratedDatabase.close();
  });
'''
file.write_text(text[:index] + addition + text[index:])

p2_8 = 'mobile/careerspeak_app/test/acceptance/p2_8_asset_resolution_test.dart'
replace_once(p2_8, 'expect(database.schemaVersion, 5);', 'expect(database.schemaVersion, 6);')
