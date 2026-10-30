import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CareerSpeakDatabase database;

  setUp(() {
    database = CareerSpeakDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('schema version 1 creates the foundation tables', () async {
    await database.customSelect('SELECT 1').getSingle();

    expect(database.schemaVersion, 1);

    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(userVersion.read<int>('user_version'), 1);

    final tableNames = database.allTables
        .map((table) => table.actualTableName)
        .toSet();

    expect(
      tableNames,
      containsAll(<String>{
        'app_preferences',
        'installation_runtime_states',
        'content_manifest_states',
        'content_pack_revisions',
        'local_content_records',
        'favorites',
        'content_learning_states',
      }),
    );
  });

  test('singleton system tables reject ids other than one', () async {
    final now = DateTime.utc(2026, 10, 30, 10);

    await database.into(database.appPreferences).insert(
          AppPreferencesCompanion.insert(
            id: const Value(1),
            uiLocale: 'en',
            translationLocale: 'ru',
            themeCode: 'SYSTEM',
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(
      () => database.into(database.appPreferences).insert(
            AppPreferencesCompanion.insert(
              id: const Value(2),
              uiLocale: 'en',
              translationLocale: 'kk',
              themeCode: 'SYSTEM',
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('content pack revision identity is composite and deterministic', () async {
    final now = DateTime.utc(2026, 10, 30, 10);
    final row = ContentPackRevisionsCompanion.insert(
      packCode: 'JAVA_SENIOR',
      variantKey: 'canonical',
      revision: 8,
      schemaVersion: 1,
      checksum: 'sha256:pack-8',
      state: 'CURRENT',
      sourceContentVersion: 108,
      stagedAt: now,
    );

    await database.into(database.contentPackRevisions).insert(row);

    expect(
      () => database.into(database.contentPackRevisions).insert(row),
      throwsA(anything),
    );
  });

  test('learner state remains after disposable content is deleted', () async {
    final now = DateTime.utc(2026, 10, 30, 10);

    await database.into(database.localContentRecords).insert(
          LocalContentRecordsCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            revision: 1,
            checksum: 'sha256:content',
            snapshotState: 'CURRENT',
            sourceSchemaVersion: 1,
            createdAt: now,
          ),
        );

    await database.into(database.favorites).insert(
          FavoritesCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            createdAt: now,
          ),
        );

    await database.into(database.contentLearningStates).insert(
          ContentLearningStatesCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            updatedAt: now,
          ),
        );

    await (database.delete(database.localContentRecords)
          ..where((row) => row.contentCode.equals('JAVA_DI_001')))
        .go();

    expect(await database.select(database.localContentRecords).get(), isEmpty);
    expect(await database.select(database.favorites).get(), hasLength(1));
    expect(
      await database.select(database.contentLearningStates).get(),
      hasLength(1),
    );
  });

  test('installation runtime table contains no installation credential', () async {
    final columns = database.installationRuntimeStates.$columns
        .map((column) => column.$name)
        .toSet();

    expect(columns, isNot(contains('installation_id')));
    expect(columns, isNot(contains('installation_token')));
    expect(columns, isNot(contains('token')));
  });
}
