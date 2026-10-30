import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../generated_migrations/schema.dart';
import '../../../generated_migrations/schema_v1.dart' as v1;
import '../../../generated_migrations/schema_v2.dart' as v2;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v1 to v2 migration preserves durable learner state', () async {
    final schema = await verifier.schemaAt(1);
    final storedNow =
        DateTime.utc(2026, 10, 30, 10).millisecondsSinceEpoch ~/ 1000;

    final oldDatabase = v1.DatabaseAtV1(schema.newConnection());
    await oldDatabase
        .into(oldDatabase.favorites)
        .insert(
          v1.FavoritesCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            createdAt: storedNow,
          ),
        );
    await oldDatabase
        .into(oldDatabase.contentLearningStates)
        .insert(
          v1.ContentLearningStatesCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            listenCount: const Value(3),
            lastRevisionSeen: const Value(7),
            updatedAt: storedNow,
          ),
        );
    await oldDatabase.close();

    final database = CareerSpeakDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 2);
    await database.close();

    final migratedDatabase = v2.DatabaseAtV2(schema.newConnection());
    final favorites = await migratedDatabase
        .select(migratedDatabase.favorites)
        .get();
    final learningStates = await migratedDatabase
        .select(migratedDatabase.contentLearningStates)
        .get();

    expect(favorites, hasLength(1));
    expect(favorites.single.contentCode, 'JAVA_DI_001');
    expect(learningStates, hasLength(1));
    expect(learningStates.single.listenCount, 3);
    expect(learningStates.single.lastRevisionSeen, 7);
    expect(
      await migratedDatabase.select(migratedDatabase.syncRuns).get(),
      isEmpty,
    );

    await migratedDatabase.close();
  });
}
