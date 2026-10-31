from pathlib import Path

path = Path(
    'mobile/careerspeak_app/test/data/local/database/careerspeak_retirement_migration_test.dart'
)
text = path.read_text()
marker = "test('v5 TOMBSTONED local row survives migration after journal pruning'"
if marker in text:
    raise SystemExit(0)

closing = '\n}\n'
if not text.endswith(closing):
    raise SystemExit('unexpected retirement migration test footer')

case = r'''

  test(
    'v5 TOMBSTONED local row survives migration after journal pruning',
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
      await oldDatabase
          .into(oldDatabase.localContentRecords)
          .insert(
            v5.LocalContentRecordsCompanion.insert(
              contentCode: 'JAVA_LEGACY_001',
              contentType: 'INTERVIEW',
              revision: 3,
              checksum: checksum,
              snapshotState: 'TOMBSTONED',
              sourceSchemaVersion: 1,
              createdAt: storedNow,
            ),
          );
      expect(await oldDatabase.select(oldDatabase.syncTombstones).get(), isEmpty);
      await oldDatabase.close();

      final database = CareerSpeakDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 6);
      await database.close();

      final migrated = v6.DatabaseAtV6(schema.newConnection());
      final retirements = await migrated.select(migrated.contentRetirements).get();
      expect(retirements, hasLength(1));
      expect(retirements.single.contentCode, 'JAVA_LEGACY_001');
      expect(retirements.single.contentType, 'INTERVIEW');
      expect(retirements.single.retiredRevision, 3);
      expect(retirements.single.reason, 'LEGACY_TOMBSTONE');
      expect(retirements.single.sourceContentVersion, 55);

      await migrated.close();
    },
  );
'''

path.write_text(text[:-len(closing)] + case + closing)
