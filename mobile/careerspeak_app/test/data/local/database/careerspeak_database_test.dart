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
    'schema version 10 creates the production foundation and retention schema',
    () async {
      await database.customSelect('SELECT 1').getSingle();

      expect(database.schemaVersion, 10);

      final userVersion = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(userVersion.read<int>('user_version'), 10);

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

      final retentionTable = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'asset_cache_retention'",
      ).getSingleOrNull();
      expect(retentionTable, isNotNull);
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
            contentCode: 'JAVA_Q_001',
            contentType: 'INTERVIEW',
            reason: 'INACTIVE',
            state: 'PLANNED',
          ),
        );

    expect(await database.select(database.syncPackUpdates).get(), hasLength(1));
    expect(await database.select(database.syncTombstones).get(), hasLength(1));

    await (database.delete(database.syncRuns)
          ..where((row) => row.runId.equals('sync-1')))
        .go();

    expect(await database.select(database.syncPackUpdates).get(), isEmpty);
    expect(await database.select(database.syncTombstones).get(), isEmpty);
  });

  test('asset references cascade only when their owner is removed', () async {
    final now = DateTime.utc(2026, 10, 30, 10);
    const checksum =
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

    await database
        .into(database.contentPackRevisions)
        .insert(
          ContentPackRevisionsCompanion.insert(
            packCode: 'JAVA_SENIOR',
            variantKey: 'canonical',
            revision: 8,
            schemaVersion: 1,
            checksum: checksum,
            state: 'CURRENT',
            sourceContentVersion: 108,
            stagedAt: now,
          ),
        );

    await database
        .into(database.localContentRecords)
        .insert(
          LocalContentRecordsCompanion.insert(
            contentCode: 'JAVA_Q_001',
            contentType: 'INTERVIEW',
            revision: 3,
            checksum: checksum,
            snapshotState: 'CURRENT',
            sourceSchemaVersion: 1,
            createdAt: now,
          ),
        );

    await database
        .into(database.assetCatalog)
        .insert(
          AssetCatalogCompanion.insert(
            assetId: 'audio-1',
            checksumSha256: checksum,
            deliveryKey: 'audio/java-q-001.mp3',
            sizeBytes: 100,
            mimeType: 'audio/mpeg',
          ),
        );

    await database
        .into(database.contentAssetRefs)
        .insert(
          ContentAssetRefsCompanion.insert(
            contentCode: 'JAVA_Q_001',
            contentType: 'INTERVIEW',
            contentRevision: 3,
            assetId: 'audio-1',
            assetRole: 'promptAudio',
            requiredOffline: false,
          ),
        );

    await database
        .into(database.packAssetRefs)
        .insert(
          PackAssetRefsCompanion.insert(
            packCode: 'JAVA_SENIOR',
            variantKey: 'canonical',
            packRevision: 8,
            assetId: 'audio-1',
            requiredOffline: false,
          ),
        );

    await (database.delete(database.localContentRecords)
          ..where((row) => row.contentCode.equals('JAVA_Q_001')))
        .go();

    expect(await database.select(database.contentAssetRefs).get(), isEmpty);
    expect(await database.select(database.assetCatalog).get(), hasLength(1));
    expect(await database.select(database.packAssetRefs).get(), hasLength(1));
  });
}
