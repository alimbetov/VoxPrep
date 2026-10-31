import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database_factory.dart';

void main() {
  late CareerSpeakDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'schema version 8 creates the production assessment foundation',
    () async {
      await database.customSelect('SELECT 1').getSingle();

      expect(database.schemaVersion, 8);

      final userVersion = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(userVersion.read<int>('user_version'), 8);

      final foreignKeys = await database
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      expect(foreignKeys.read<int>('foreign_keys'), 1);

      final tableNames = database.allTables
          .map((table) => table.actualTableName)
          .toSet();

      expect(
        tableNames,
        containsAll(<String>{
          'app_preferences',
          'installation_runtime_states',
          'content_manifest_states',
          'sync_runs',
          'sync_pack_updates',
          'sync_tombstones',
          'content_pack_revisions',
          'local_content_records',
          'pack_content_refs',
          'pack_localization_refs',
          'locale_fallback_rules',
          'content_retirements',
          'asset_catalog',
          'content_asset_refs',
          'pack_asset_refs',
          'content_catalog_reads',
          'localized_content_reads',
          'favorites',
          'content_learning_states',
        }),
      );
    },
  );

  test('all singleton foundation tables enforce id equals one', () async {
    final now = DateTime.utc(2026, 10, 30, 10);

    await database
        .into(database.appPreferences)
        .insert(
          AppPreferencesCompanion.insert(
            id: const Value(1),
            uiLocale: 'en',
            translationLocale: 'ru',
            themeCode: 'SYSTEM',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await expectLater(
      database
          .into(database.appPreferences)
          .insert(
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

    await database
        .into(database.installationRuntimeStates)
        .insert(
          InstallationRuntimeStatesCompanion.insert(
            id: const Value(1),
            registrationState: 'UNREGISTERED',
            updatedAt: now,
          ),
        );

    await expectLater(
      database
          .into(database.installationRuntimeStates)
          .insert(
            InstallationRuntimeStatesCompanion.insert(
              id: const Value(2),
              registrationState: 'UNREGISTERED',
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );

    await database
        .into(database.contentManifestStates)
        .insert(
          ContentManifestStatesCompanion.insert(
            id: const Value(1),
            schemaVersion: 1,
            currentContentVersion: 0,
            currentManifestChecksum: 'bootstrap',
            updatedAt: now,
          ),
        );

    await expectLater(
      database
          .into(database.contentManifestStates)
          .insert(
            ContentManifestStatesCompanion.insert(
              id: const Value(2),
              schemaVersion: 1,
              currentContentVersion: 0,
              currentManifestChecksum: 'bootstrap',
              updatedAt: now,
            ),
          ),
      throwsA(anything),
    );
  });

  test('sync journal children are owned by the durable run', () async {
    final now = DateTime.utc(2026, 10, 30, 10);

    await database
        .into(database.syncRuns)
        .insert(
          SyncRunsCompanion.insert(
            runId: 'sync-1',
            trigger: 'STARTUP',
            translationLocale: 'kk',
            state: 'PLANNING',
            startedAt: now,
            updatedAt: now,
          ),
        );

    await database
        .into(database.syncPackUpdates)
        .insert(
          SyncPackUpdatesCompanion.insert(
            runId: 'sync-1',
            packCode: 'JAVA_SENIOR',
            variantKey: 'canonical',
            targetRevision: 8,
            targetChecksum:
                'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
            state: 'PLANNED',
            updatedAt: now,
          ),
        );

    await database
        .into(database.syncTombstones)
        .insert(
          SyncTombstonesCompanion.insert(
            runId: 'sync-1',
            contentCode: 'JAVA_QUESTION_001',
            contentType: 'interview',
            revision: const Value(3),
            reason: 'INACTIVE',
            state: 'PLANNED',
          ),
        );

    expect(await database.select(database.syncPackUpdates).get(), hasLength(1));
    expect(await database.select(database.syncTombstones).get(), hasLength(1));

    await (database.delete(
      database.syncRuns,
    )..where((row) => row.runId.equals('sync-1'))).go();

    expect(await database.select(database.syncPackUpdates).get(), isEmpty);
    expect(await database.select(database.syncTombstones).get(), isEmpty);
  });

  test('sync pack identity is scoped by run and pack variant', () async {
    final now = DateTime.utc(2026, 10, 30, 10);

    await database
        .into(database.syncRuns)
        .insert(
          SyncRunsCompanion.insert(
            runId: 'sync-1',
            trigger: 'MANUAL',
            translationLocale: 'ru',
            state: 'PLANNING',
            startedAt: now,
            updatedAt: now,
          ),
        );

    final update = SyncPackUpdatesCompanion.insert(
      runId: 'sync-1',
      packCode: 'JAVA_SENIOR',
      variantKey: 'canonical',
      targetRevision: 8,
      targetChecksum:
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      state: 'PLANNED',
      updatedAt: now,
    );

    await database.into(database.syncPackUpdates).insert(update);
    await expectLater(
      database.into(database.syncPackUpdates).insert(update),
      throwsA(anything),
    );
  });

  test(
    'content pack revision identity is composite and deterministic',
    () async {
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

      await expectLater(
        database.into(database.contentPackRevisions).insert(row),
        throwsA(anything),
      );
    },
  );

  test('local content identity includes revision', () async {
    final now = DateTime.utc(2026, 10, 30, 10);

    LocalContentRecordsCompanion row(int revision) =>
        LocalContentRecordsCompanion.insert(
          contentCode: 'JAVA_DI_001',
          contentType: 'INTERVIEW',
          revision: revision,
          checksum: 'sha256:content-$revision',
          snapshotState: 'CURRENT',
          sourceSchemaVersion: 1,
          createdAt: now,
        );

    await database.into(database.localContentRecords).insert(row(1));
    await database.into(database.localContentRecords).insert(row(2));

    expect(
      await database.select(database.localContentRecords).get(),
      hasLength(2),
    );

    await expectLater(
      database.into(database.localContentRecords).insert(row(1)),
      throwsA(anything),
    );
  });

  test('learner identities reject duplicate business keys', () async {
    final now = DateTime.utc(2026, 10, 30, 10);

    final favorite = FavoritesCompanion.insert(
      contentCode: 'JAVA_DI_001',
      contentType: 'INTERVIEW',
      createdAt: now,
    );
    await database.into(database.favorites).insert(favorite);
    await expectLater(
      database.into(database.favorites).insert(favorite),
      throwsA(anything),
    );

    final learningState = ContentLearningStatesCompanion.insert(
      contentCode: 'JAVA_DI_001',
      contentType: 'INTERVIEW',
      updatedAt: now,
    );
    await database.into(database.contentLearningStates).insert(learningState);
    await expectLater(
      database.into(database.contentLearningStates).insert(learningState),
      throwsA(anything),
    );
  });

  test('learner state remains after disposable content is deleted', () async {
    final now = DateTime.utc(2026, 10, 30, 10);

    await database
        .into(database.localContentRecords)
        .insert(
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

    await database
        .into(database.favorites)
        .insert(
          FavoritesCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            createdAt: now,
          ),
        );

    await database
        .into(database.contentLearningStates)
        .insert(
          ContentLearningStatesCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            updatedAt: now,
          ),
        );

    await (database.delete(
      database.localContentRecords,
    )..where((row) => row.contentCode.equals('JAVA_DI_001'))).go();

    expect(await database.select(database.localContentRecords).get(), isEmpty);
    expect(await database.select(database.favorites).get(), hasLength(1));
    expect(
      await database.select(database.contentLearningStates).get(),
      hasLength(1),
    );
  });

  test(
    'installation runtime table contains no installation credential',
    () async {
      final columns = database.installationRuntimeStates.$columns
          .map((column) => column.$name)
          .toSet();

      expect(columns, isNot(contains('installation_id')));
      expect(columns, isNot(contains('installation_token')));
      expect(columns, isNot(contains('token')));
    },
  );
}
