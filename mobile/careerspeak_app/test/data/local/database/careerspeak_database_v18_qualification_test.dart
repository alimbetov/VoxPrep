import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../generated_migrations/schema.dart';
import '../../../generated_migrations/schema_v8.dart' as v8;
import '../../../support/test_database_factory.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('runtime migration v8 to v18 matches a fresh production v18 schema', () async {
    final legacySchema = await verifier.schemaAt(8);
    final storedNow =
        DateTime.utc(2026, 11, 2, 7).millisecondsSinceEpoch ~/ 1000;

    final legacy = v8.DatabaseAtV8(legacySchema.newConnection());
    await legacy.into(legacy.favorites).insert(
      v8.FavoritesCompanion.insert(
        contentCode: 'JAVA_DI_001',
        contentType: 'INTERVIEW',
        createdAt: storedNow,
      ),
    );
    await legacy.close();

    final migrated = CareerSpeakDatabase(legacySchema.newConnection());
    await migrated.customSelect('SELECT 1').getSingle();

    final migratedVersion = await migrated
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(migratedVersion.read<int>('user_version'), 18);

    final favorites = await migrated.select(migrated.favorites).get();
    expect(favorites, hasLength(1));
    expect(favorites.single.contentCode, 'JAVA_DI_001');

    final fresh = createTestDatabase();
    await fresh.customSelect('SELECT 1').getSingle();
    final freshVersion = await fresh.customSelect('PRAGMA user_version').getSingle();
    expect(freshVersion.read<int>('user_version'), 18);

    expect(await _schemaShape(migrated), await _schemaShape(fresh));

    final appPreferenceColumns = await _columnNames(migrated, 'app_preferences');
    expect(appPreferenceColumns, contains('country_code'));

    final migratedTables = (await _schemaShape(migrated)).keys.toSet();
    expect(
      migratedTables,
      containsAll(<String>{
        'vertical_sections',
        'learning_verticals',
        'learning_goals',
        'learning_tracks',
        'learning_collections',
        'asset_cache_retention',
        'learner_selection',
        'practice_test_active_attempt',
        'learner_last_opened_content',
        'practice_test_completions',
        'content_review_states',
        'learning_collection_access_reads',
        'learner_access_snapshot',
      }),
    );

    await migrated.close();
    await fresh.close();
  });
}

Future<Map<String, List<String>>> _schemaShape(CareerSpeakDatabase database) async {
  final rows = await database.customSelect('''
    SELECT name
    FROM sqlite_master
    WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
    ORDER BY name
  ''').get();

  final shape = <String, List<String>>{};
  for (final row in rows) {
    final name = row.read<String>('name');
    shape[name] = await _columnNames(database, name);
  }
  return shape;
}

Future<List<String>> _columnNames(
  CareerSpeakDatabase database,
  String tableName,
) async {
  final quoted = tableName.replaceAll('"', '""');
  final rows = await database.customSelect('PRAGMA table_info("$quoted")').get();
  return rows.map((row) => row.read<String>('name')).toList(growable: false);
}
