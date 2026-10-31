import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../generated_migrations/schema.dart';
import '../../../generated_migrations/schema_v1.dart' as v1;
import '../../../generated_migrations/schema_v2.dart' as v2;
import '../../../generated_migrations/schema_v3.dart' as v3;
import '../../../generated_migrations/schema_v5.dart' as v5;
import '../../../generated_migrations/schema_v6.dart' as v6;
import '../../../generated_migrations/schema_v7.dart' as v7;
import '../../../generated_migrations/schema_v8.dart' as v8;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v1 to v8 preserves durable learner state', () async {
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
    await verifier.migrateAndValidate(database, 8);
    await database.close();

    final migratedDatabase = v8.DatabaseAtV8(schema.newConnection());
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
    expect(
      await migratedDatabase.select(migratedDatabase.localeFallbackRules).get(),
      isEmpty,
    );
    expect(
      await migratedDatabase.select(migratedDatabase.contentRetirements).get(),
      isEmpty,
    );
    expect(
      await migratedDatabase
          .select(migratedDatabase.assessmentQuestionReads)
          .get(),
      isEmpty,
    );
    expect(
      await migratedDatabase
          .select(migratedDatabase.practiceTestRevisionReads)
          .get(),
      isEmpty,
    );

    await migratedDatabase.close();
  });

  test('v2 to v8 preserves durable sync journal', () async {
    final schema = await verifier.schemaAt(2);
    final storedNow =
        DateTime.utc(2026, 10, 30, 11).millisecondsSinceEpoch ~/ 1000;

    final oldDatabase = v2.DatabaseAtV2(schema.newConnection());
    await oldDatabase
        .into(oldDatabase.syncRuns)
        .insert(
          v2.SyncRunsCompanion.insert(
            runId: 'sync-v2',
            trigger: 'RECOVERY',
            translationLocale: 'kk',
            state: 'PLANNING',
            startedAt: storedNow,
            updatedAt: storedNow,
          ),
        );
    await oldDatabase.close();

    final database = CareerSpeakDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 8);
    await database.close();

    final migratedDatabase = v8.DatabaseAtV8(schema.newConnection());
    final runs = await migratedDatabase.select(migratedDatabase.syncRuns).get();

    expect(runs, hasLength(1));
    expect(runs.single.runId, 'sync-v2');
    expect(runs.single.state, 'PLANNING');
    expect(
      await migratedDatabase.select(migratedDatabase.localeFallbackRules).get(),
      isEmpty,
    );
    expect(
      await migratedDatabase.select(migratedDatabase.contentRetirements).get(),
      isEmpty,
    );

    await migratedDatabase.close();
  });

  test('v3 to v8 adds immutable read and assessment models empty', () async {
    final schema = await verifier.schemaAt(3);
    final storedNow =
        DateTime.utc(2026, 10, 30, 12).millisecondsSinceEpoch ~/ 1000;

    final oldDatabase = v3.DatabaseAtV3(schema.newConnection());
    await oldDatabase
        .into(oldDatabase.favorites)
        .insert(
          v3.FavoritesCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            createdAt: storedNow,
          ),
        );
    await oldDatabase.close();

    final database = CareerSpeakDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 8);
    await database.close();

    final migratedDatabase = v8.DatabaseAtV8(schema.newConnection());
    expect(
      await migratedDatabase.select(migratedDatabase.favorites).get(),
      hasLength(1),
    );
    expect(
      await migratedDatabase.select(migratedDatabase.contentCatalogReads).get(),
      isEmpty,
    );
    expect(
      await migratedDatabase
          .select(migratedDatabase.localizedContentReads)
          .get(),
      isEmpty,
    );
    expect(
      await migratedDatabase.select(migratedDatabase.localeFallbackRules).get(),
      isEmpty,
    );
    expect(
      await migratedDatabase.select(migratedDatabase.contentRetirements).get(),
      isEmpty,
    );
    expect(
      await migratedDatabase
          .select(migratedDatabase.assessmentQuestionReads)
          .get(),
      isEmpty,
    );

    await migratedDatabase.close();
  });

  test(
    'v5 to v8 preserves localization data and adds no invented fallback',
    () async {
      final schema = await verifier.schemaAt(5);
      final storedNow =
          DateTime.utc(2026, 10, 31, 6).millisecondsSinceEpoch ~/ 1000;
      const localizedChecksum =
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

      final oldDatabase = v5.DatabaseAtV5(schema.newConnection());
      await oldDatabase
          .into(oldDatabase.localizedContentReads)
          .insert(
            v5.LocalizedContentReadsCompanion.insert(
              contentCode: 'JAVA_DI_001',
              contentType: 'INTERVIEW',
              contentRevision: 1,
              locale: 'ru',
              localizationRevision: 2,
              checksum: localizedChecksum,
              title: const Value('Русский заголовок'),
              createdAt: storedNow,
            ),
          );
      await oldDatabase.close();

      final database = CareerSpeakDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 8);
      await database.close();

      final migratedDatabase = v8.DatabaseAtV8(schema.newConnection());
      final localized = await migratedDatabase
          .select(migratedDatabase.localizedContentReads)
          .get();
      expect(localized, hasLength(1));
      expect(localized.single.locale, 'ru');
      expect(localized.single.localizationRevision, 2);
      expect(
        await migratedDatabase
            .select(migratedDatabase.localeFallbackRules)
            .get(),
        isEmpty,
      );
      expect(
        await migratedDatabase
            .select(migratedDatabase.contentRetirements)
            .get(),
        isEmpty,
      );

      await migratedDatabase.close();
    },
  );

  test(
    'v6 to v8 preserves C1 reads and adds typed plus assessment projections',
    () async {
      final schema = await verifier.schemaAt(6);
      final storedNow =
          DateTime.utc(2026, 10, 31, 8).millisecondsSinceEpoch ~/ 1000;

      final oldDatabase = v6.DatabaseAtV6(schema.newConnection());
      await oldDatabase
          .into(oldDatabase.contentCatalogReads)
          .insert(
            v6.ContentCatalogReadsCompanion.insert(
              contentCode: 'JAVA_DI_001',
              contentType: 'INTERVIEW',
              revision: 3,
              checksum: 'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
              title: 'Dependency Injection',
              subtitle: 'Java Backend',
              description: 'Explain constructor injection and its tradeoffs.',
              category: 'Java Backend',
              level: 'Senior',
              minutes: 6,
              hasAudio: 1,
              createdAt: storedNow,
            ),
          );
      await oldDatabase.close();

      final database = CareerSpeakDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 8);
      await database.close();

      final migratedDatabase = v8.DatabaseAtV8(schema.newConnection());
      final common = await migratedDatabase
          .select(migratedDatabase.contentCatalogReads)
          .get();
      expect(common, hasLength(1));
      expect(common.single.contentCode, 'JAVA_DI_001');
      expect(
        await migratedDatabase.select(migratedDatabase.typedContentReads).get(),
        isEmpty,
      );
      expect(
        await migratedDatabase
            .select(migratedDatabase.assessmentQuestionReads)
            .get(),
        isEmpty,
      );
      await migratedDatabase.close();
    },
  );

  test(
    'v7 to v8 preserves typed content and adds assessment tables empty',
    () async {
      final schema = await verifier.schemaAt(7);
      final storedNow =
          DateTime.utc(2026, 10, 31, 12).millisecondsSinceEpoch ~/ 1000;

      final oldDatabase = v7.DatabaseAtV7(schema.newConnection());
      await oldDatabase
          .into(oldDatabase.typedContentReads)
          .insert(
            v7.TypedContentReadsCompanion.insert(
              contentCode: 'JAVA_DI_001',
              contentType: 'interview',
              revision: 3,
              checksum: 'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee',
              categoryCode: 'JAVA',
              levelCode: 'SENIOR',
              skillCodesJson: '["DEPENDENCY_INJECTION"]',
              bodyKind: 'interview',
              bodyJson: '{"kind":"interview"}',
              createdAt: storedNow,
            ),
          );
      await oldDatabase.close();

      final database = CareerSpeakDatabase(schema.newConnection());
      await verifier.migrateAndValidate(database, 8);
      await database.close();

      final migratedDatabase = v8.DatabaseAtV8(schema.newConnection());
      final typed = await migratedDatabase
          .select(migratedDatabase.typedContentReads)
          .get();
      expect(typed, hasLength(1));
      expect(typed.single.contentCode, 'JAVA_DI_001');
      expect(
        await migratedDatabase
            .select(migratedDatabase.assessmentQuestionReads)
            .get(),
        isEmpty,
      );
      expect(
        await migratedDatabase
            .select(migratedDatabase.practiceTestRevisionReads)
            .get(),
        isEmpty,
      );
      expect(
        await migratedDatabase
            .select(migratedDatabase.practiceTestQuestionRefs)
            .get(),
        isEmpty,
      );
      await migratedDatabase.close();
    },
  );
}
