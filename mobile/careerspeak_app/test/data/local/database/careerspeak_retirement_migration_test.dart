import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../generated_migrations/schema.dart';
import '../../../generated_migrations/schema_v5.dart' as v5;
import '../../../generated_migrations/schema_v6.dart' as v6;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test(
    'v5 APPLIED tombstone migrates into permanent retirement ledger',
    () async {
      final schema = await verifier.schemaAt(5);
      final storedNow =
          DateTime.utc(2026, 10, 31, 7, 30).millisecondsSinceEpoch ~/ 1000;

      final oldDatabase = v5.DatabaseAtV5(schema.newConnection());
      await oldDatabase
          .into(oldDatabase.syncRuns)
          .insert(
            v5.SyncRunsCompanion.insert(
              runId: 'legacy-retirement',
              trigger: 'RECOVERY',
              translationLocale: 'ru',
              targetContentVersion: const Value(55),
              state: 'SUCCEEDED',
              startedAt: storedNow,
              updatedAt: storedNow,
              finishedAt: Value(storedNow),
            ),
          );
      await oldDatabase
          .into(oldDatabase.syncTombstones)
          .insert(
            v5.SyncTombstonesCompanion.insert(
              runId: 'legacy-retirement',
              contentCode: 'JAVA_DI_001',
              contentType: 'INTERVIEW',
              revision: const Value(2),
              reason: 'RETIRED',
              state: 'APPLIED',
              appliedAt: Value(storedNow),
            ),
          );
      await oldDatabase.close();

      final database = CareerSpeakDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 6);
      await database.close();

      final migrated = v6.DatabaseAtV6(schema.newConnection());
      final retirements = await migrated
          .select(migrated.contentRetirements)
          .get();
      expect(retirements, hasLength(1));
      expect(retirements.single.contentCode, 'JAVA_DI_001');
      expect(retirements.single.contentType, 'INTERVIEW');
      expect(retirements.single.retiredRevision, 2);
      expect(retirements.single.reason, 'RETIRED');
      expect(retirements.single.sourceContentVersion, 55);

      await migrated.close();
    },
  );

  test(
    'v5 TOMBSTONED local rows survive migration after journal pruning',
    () async {
      final schema = await verifier.schemaAt(5);
      final storedNow =
          DateTime.utc(2026, 10, 31, 7, 45).millisecondsSinceEpoch ~/ 1000;
      const checksum =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      final oldDatabase = v5.DatabaseAtV5(schema.newConnection());
      await oldDatabase
          .into(oldDatabase.contentManifestStates)
          .insert(
            v5.ContentManifestStatesCompanion.insert(
              id: const Value(1),
              schemaVersion: 1,
              currentContentVersion: 55,
              currentManifestChecksum: checksum,
              updatedAt: storedNow,
            ),
          );
      for (final revision in <int>[1, 3]) {
        await oldDatabase
            .into(oldDatabase.localContentRecords)
            .insert(
              v5.LocalContentRecordsCompanion.insert(
                contentCode: 'JAVA_LEGACY_001',
                contentType: 'INTERVIEW',
                revision: revision,
                checksum: checksum,
                snapshotState: 'TOMBSTONED',
                sourceSchemaVersion: 1,
                createdAt: storedNow + revision,
              ),
            );
      }
      expect(
        await oldDatabase.select(oldDatabase.syncTombstones).get(),
        isEmpty,
      );
      await oldDatabase.close();

      final database = CareerSpeakDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 6);
      await database.close();

      final migrated = v6.DatabaseAtV6(schema.newConnection());
      final retirements = await migrated
          .select(migrated.contentRetirements)
          .get();
      expect(retirements, hasLength(1));
      expect(retirements.single.contentCode, 'JAVA_LEGACY_001');
      expect(retirements.single.contentType, 'INTERVIEW');
      expect(retirements.single.retiredRevision, 3);
      expect(retirements.single.reason, 'LEGACY_TOMBSTONE');
      expect(retirements.single.sourceContentVersion, 55);

      await migrated.close();
    },
  );

  test(
    'v5 journal metadata wins when retirement evidence has the same revision',
    () async {
      final schema = await verifier.schemaAt(5);
      final storedNow =
          DateTime.utc(2026, 10, 31, 7, 50).millisecondsSinceEpoch ~/ 1000;
      const checksum =
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

      final oldDatabase = v5.DatabaseAtV5(schema.newConnection());
      await oldDatabase
          .into(oldDatabase.contentManifestStates)
          .insert(
            v5.ContentManifestStatesCompanion.insert(
              id: const Value(1),
              schemaVersion: 1,
              currentContentVersion: 55,
              currentManifestChecksum: checksum,
              updatedAt: storedNow,
            ),
          );
      await oldDatabase
          .into(oldDatabase.localContentRecords)
          .insert(
            v5.LocalContentRecordsCompanion.insert(
              contentCode: 'JAVA_SHARED_001',
              contentType: 'INTERVIEW',
              revision: 3,
              checksum: checksum,
              snapshotState: 'TOMBSTONED',
              sourceSchemaVersion: 1,
              createdAt: storedNow,
            ),
          );
      await oldDatabase
          .into(oldDatabase.syncRuns)
          .insert(
            v5.SyncRunsCompanion.insert(
              runId: 'retirement-evidence',
              trigger: 'RECOVERY',
              translationLocale: 'ru',
              targetContentVersion: const Value(55),
              state: 'SUCCEEDED',
              startedAt: storedNow,
              updatedAt: storedNow + 1,
              finishedAt: Value(storedNow + 1),
            ),
          );
      await oldDatabase
          .into(oldDatabase.syncTombstones)
          .insert(
            v5.SyncTombstonesCompanion.insert(
              runId: 'retirement-evidence',
              contentCode: 'JAVA_SHARED_001',
              contentType: 'INTERVIEW',
              revision: const Value(3),
              reason: 'BACKEND_RETIRED',
              state: 'APPLIED',
              appliedAt: Value(storedNow + 1),
            ),
          );
      await oldDatabase.close();

      final database = CareerSpeakDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 6);
      await database.close();

      final migrated = v6.DatabaseAtV6(schema.newConnection());
      final retirements = await migrated
          .select(migrated.contentRetirements)
          .get();
      expect(retirements, hasLength(1));
      expect(retirements.single.contentCode, 'JAVA_SHARED_001');
      expect(retirements.single.retiredRevision, 3);
      expect(retirements.single.reason, 'BACKEND_RETIRED');
      expect(retirements.single.sourceContentVersion, 55);

      await migrated.close();
    },
  );
}
