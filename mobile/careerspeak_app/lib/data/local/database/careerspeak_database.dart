import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'careerspeak_content_read_tables.dart';
import 'careerspeak_sync_metadata_tables.dart';
import 'careerspeak_tables.dart';

part 'careerspeak_database.g.dart';

@DriftDatabase(
  tables: [
    AppPreferences,
    InstallationRuntimeStates,
    ContentManifestStates,
    SyncRuns,
    SyncPackUpdates,
    SyncTombstones,
    ContentPackRevisions,
    LocalContentRecords,
    PackContentRefs,
    AssetCatalog,
    ContentAssetRefs,
    PackAssetRefs,
    ContentCatalogReads,
    Favorites,
    ContentLearningStates,
  ],
)
final class CareerSpeakDatabase extends _$CareerSpeakDatabase {
  CareerSpeakDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'careerspeak'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, _) async {
      if (from < 2) {
        await migrator.createTable(syncRuns);
        await migrator.createTable(syncPackUpdates);
        await migrator.createTable(syncTombstones);
      }
      if (from < 3) {
        await migrator.createTable(packContentRefs);
        await migrator.createTable(assetCatalog);
        await migrator.createTable(contentAssetRefs);
        await migrator.createTable(packAssetRefs);
      }
      if (from < 4) {
        await migrator.createTable(contentCatalogReads);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
