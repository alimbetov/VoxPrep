import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../generated_migrations/schema.dart';
import '../../../support/test_database_factory.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('universal catalogue Drift v9', () {
    test('fresh database creates snapshot-scoped universal catalogue tables', () async {
      final database = createTestDatabase();
      addTearDown(database.close);

      await database.customSelect('SELECT 1').getSingle();

      expect(database.schemaVersion, 9);
      final userVersion = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(userVersion.read<int>('user_version'), 9);

      final rows = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ).get();
      final names = rows.map((row) => row.read<String>('name')).toSet();

      expect(
        names,
        containsAll(<String>{
          'publication_snapshots',
          'vertical_section_reads',
          'learning_vertical_reads',
          'learning_goal_reads',
          'learning_track_reads',
          'learning_collection_reads',
          'learning_collection_member_reads',
          'vertical_presentation_reads',
        }),
      );
    });

    test('opening a v1 database migrates through the full chain to v9', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(1);
      final database = CareerSpeakDatabase(schema.newConnection());
      addTearDown(database.close);

      await database.customSelect('SELECT 1').getSingle();

      final userVersion = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(userVersion.read<int>('user_version'), 9);

      final rows = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ).get();
      final names = rows.map((row) => row.read<String>('name')).toSet();
      expect(
        names,
        containsAll(<String>{
          'sync_runs',
          'pack_content_refs',
          'content_catalog_reads',
          'localized_content_reads',
          'content_retirements',
          'typed_content_reads',
          'assessment_question_reads',
          'practice_test_revision_reads',
          'publication_snapshots',
          'learning_vertical_reads',
          'learning_collection_member_reads',
        }),
      );
    });

    test('opening a v8 database migrates it to v9 without generated v9 types', () async {
      final verifier = SchemaVerifier(GeneratedHelper());
      final schema = await verifier.schemaAt(8);
      final database = CareerSpeakDatabase(schema.newConnection());
      addTearDown(database.close);

      await database.customSelect('SELECT 1').getSingle();

      final userVersion = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(userVersion.read<int>('user_version'), 9);

      final table = await database.customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'publication_snapshots'",
      ).getSingleOrNull();
      expect(table, isNotNull);
    });

    test('staged snapshot rows stay invisible until CURRENT pointer switches', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 10, 31, 18);

      await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 2,
          currentContentVersion: 100,
          currentManifestChecksum: _hash,
          updatedAt: now,
        ),
      );

      await _insertSnapshot(database, 100);
      await _insertSnapshot(database, 101);
      await _insertSection(database, 100, 'CURRENT_SECTION');
      await _insertSection(database, 101, 'STAGED_SECTION');

      Future<List<String>> currentSections() async {
        final rows = await database.customSelect('''
          SELECT section.code
          FROM content_manifest_states state
          INNER JOIN vertical_section_reads section
            ON section.content_version = state.current_content_version
          WHERE state.id = 1
          ORDER BY section.sort_order, section.code
        ''').get();
        return rows.map((row) => row.read<String>('code')).toList();
      }

      expect(await currentSections(), <String>['CURRENT_SECTION']);

      await (database.update(database.contentManifestStates)
            ..where((row) => row.id.equals(1)))
          .write(
        ContentManifestStatesCompanion(
          currentContentVersion: const Value(101),
          updatedAt: Value(now.add(const Duration(minutes: 1))),
        ),
      );

      expect(await currentSections(), <String>['STAGED_SECTION']);
    });

    test('cross-snapshot vertical ownership fails closed at foreign key boundary', () async {
      final database = createTestDatabase();
      addTearDown(database.close);

      await database.customSelect('SELECT 1').getSingle();
      await _insertSnapshot(database, 200);
      await _insertSnapshot(database, 201);
      await _insertSection(database, 200, 'ENGINEERING');

      await expectLater(
        database.customStatement(
          '''
          INSERT INTO learning_vertical_reads (
            content_version,
            code,
            section_code,
            title,
            description,
            icon_asset_id,
            sort_order,
            active
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ''',
          <Object?>[
            201,
            'FUTURE_VERTICAL',
            'ENGINEERING',
            'Future vertical',
            'Future vertical description',
            'asset-future',
            0,
            1,
          ],
        ),
        throwsA(anything),
      );
    });
  });
}

Future<void> _insertSnapshot(CareerSpeakDatabase database, int contentVersion) {
  return database.customStatement(
    '''
    INSERT INTO publication_snapshots (
      content_version,
      schema_version,
      minimum_app_contract_version,
      published_at,
      checksum,
      created_at
    ) VALUES (?, ?, ?, ?, ?, ?)
    ''',
    <Object?>[
      contentVersion,
      2,
      2,
      DateTime.utc(2026, 10, 31, 18).millisecondsSinceEpoch,
      _hash,
      DateTime.utc(2026, 10, 31, 18).millisecondsSinceEpoch,
    ],
  );
}

Future<void> _insertSection(
  CareerSpeakDatabase database,
  int contentVersion,
  String code,
) {
  return database.customStatement(
    '''
    INSERT INTO vertical_section_reads (
      content_version,
      code,
      title,
      description,
      icon_asset_id,
      sort_order,
      active
    ) VALUES (?, ?, ?, ?, ?, ?, ?)
    ''',
    <Object?>[
      contentVersion,
      code,
      code,
      null,
      null,
      0,
      1,
    ],
  );
}
