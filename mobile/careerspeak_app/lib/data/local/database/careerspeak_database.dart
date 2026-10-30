import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
    Favorites,
    ContentLearningStates,
  ],
)
final class CareerSpeakDatabase extends _$CareerSpeakDatabase {
  CareerSpeakDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'careerspeak'));

  @override
  int get schemaVersion => 2;

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
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
