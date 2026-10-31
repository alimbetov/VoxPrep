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

  test('v5 APPLIED tombstone migrates into permanent retirement ledger', () async {
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
    final retirements = await migrated.select(migrated.contentRetirements).get();
    expect(retirements, hasLength(1));
    expect(retirements.single.contentCode, 'JAVA_DI_001');
    expect(retirements.single.contentType, 'INTERVIEW');
    expect(retirements.single.retiredRevision, 2);
    expect(retirements.single.reason, 'RETIRED');
    expect(retirements.single.sourceContentVersion, 55);

    await migrated.close();
  });
}
