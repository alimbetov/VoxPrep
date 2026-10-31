import 'package:careerspeak_app/application/ports/universal_catalogue_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_universal_catalogue_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  group('DriftUniversalCatalogueRepository', () {
    test('reads only CURRENT typed graph and ignores staged snapshot', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 10, 31, 20);

      await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 2,
          currentContentVersion: 100,
          currentManifestChecksum: _hash,
          updatedAt: now,
        ),
      );
      await _insertGraph(database, 100, 'CURRENT');
      await _insertGraph(database, 101, 'STAGED');

      const repositoryType = DriftUniversalCatalogueRepository;
      expect(repositoryType, isNotNull);
      final repository = DriftUniversalCatalogueRepository(database);

      final first = await repository.readCurrent();
      expect(first, isA<Success<CurrentUniversalCatalogueSnapshot?>>());
      final current = (first as Success<CurrentUniversalCatalogueSnapshot?>).value!;
      expect(current.contentVersion, 100);
      expect(current.graph.verticals.single.code, 'CURRENT_VERTICAL');
      expect(current.graph.collections.single.members, hasLength(2));
      expect(current.graph.collections.single.members[0].position, 0);
      expect(current.graph.collections.single.members[1].position, 1);

      await (database.update(database.contentManifestStates)
            ..where((row) => row.id.equals(1)))
          .write(
        ContentManifestStatesCompanion(
          currentContentVersion: const Value(101),
          updatedAt: Value(now.add(const Duration(minutes: 1))),
        ),
      );

      final second = await DriftUniversalCatalogueRepository(database).readCurrent();
      expect(second, isA<Success<CurrentUniversalCatalogueSnapshot?>>());
      final switched =
          (second as Success<CurrentUniversalCatalogueSnapshot?>).value!;
      expect(switched.contentVersion, 101);
      expect(switched.graph.verticals.single.code, 'STAGED_VERTICAL');
    });

    test('returns null before any CURRENT publication exists', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 10, 31, 20);
      await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 2,
          currentContentVersion: 0,
          currentManifestChecksum: 'bootstrap',
          updatedAt: now,
        ),
      );

      final result = await DriftUniversalCatalogueRepository(database).readCurrent();
      expect(result, isA<Success<CurrentUniversalCatalogueSnapshot?>>());
      expect((result as Success<CurrentUniversalCatalogueSnapshot?>).value, isNull);
    });

    test('fails closed when CURRENT points to missing materialized snapshot', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 10, 31, 20);
      await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 2,
          currentContentVersion: 999,
          currentManifestChecksum: _hash,
          updatedAt: now,
        ),
      );

      final result = await DriftUniversalCatalogueRepository(database).readCurrent();
      expect(result, isA<FailureResult<CurrentUniversalCatalogueSnapshot?>>());
      expect(
        (result as FailureResult<CurrentUniversalCatalogueSnapshot?>).failure.code,
        'UNIVERSAL_CATALOGUE_CURRENT_MISSING',
      );
    });
  });
}

Future<void> _insertGraph(
  CareerSpeakDatabase database,
  int version,
  String prefix,
) async {
  final now = DateTime.utc(2026, 10, 31, 20).millisecondsSinceEpoch;
  final section = '${prefix}_SECTION';
  final vertical = '${prefix}_VERTICAL';
  final goal = '${prefix}_GOAL';
  final track = '${prefix}_TRACK';
  final collection = '${prefix}_COLLECTION';

  await database.customStatement(
    '''INSERT INTO publication_snapshots
       (content_version, schema_version, minimum_app_contract_version,
        published_at, checksum, created_at)
       VALUES (?, 2, 2, ?, ?, ?)''',
    <Object?>[version, now, _hash, now],
  );
  await database.customStatement(
    '''INSERT INTO vertical_section_reads
       (content_version, code, title, description, icon_asset_id, sort_order, active)
       VALUES (?, ?, ?, NULL, NULL, 0, 1)''',
    <Object?>[version, section, section],
  );
  await database.customStatement(
    '''INSERT INTO learning_vertical_reads
       (content_version, code, section_code, title, description, icon_asset_id,
        sort_order, active)
       VALUES (?, ?, ?, ?, ?, ?, 0, 1)''',
    <Object?>[version, vertical, section, vertical, '$vertical description', 'asset-$prefix'],
  );
  await database.customStatement(
    '''INSERT INTO learning_goal_reads
       (content_version, code, vertical_code, title, description, sort_order, active)
       VALUES (?, ?, ?, ?, ?, 0, 1)''',
    <Object?>[version, goal, vertical, goal, '$goal description'],
  );
  await database.customStatement(
    '''INSERT INTO learning_track_reads
       (content_version, code, vertical_code, goal_code, title, description,
        level_code, career_track_code, sort_order, active)
       VALUES (?, ?, ?, ?, ?, ?, 'B2', NULL, 0, 1)''',
    <Object?>[version, track, vertical, goal, track, '$track description'],
  );
  await database.customStatement(
    '''INSERT INTO learning_collection_reads
       (content_version, code, vertical_code, track_code, title, description,
        sort_order, active)
       VALUES (?, ?, ?, ?, ?, ?, 0, 1)''',
    <Object?>[version, collection, vertical, track, collection, '$collection description'],
  );
  await database.customStatement(
    '''INSERT INTO learning_collection_member_reads
       (content_version, collection_code, position, member_type,
        content_code, content_type, content_revision, content_checksum,
        practice_test_code, practice_test_revision, practice_test_checksum)
       VALUES (?, ?, 0, 'CONTENT', ?, 'topic', 1, ?, NULL, NULL, NULL)''',
    <Object?>[version, collection, '${prefix}_CONTENT', _hash],
  );
  await database.customStatement(
    '''INSERT INTO learning_collection_member_reads
       (content_version, collection_code, position, member_type,
        content_code, content_type, content_revision, content_checksum,
        practice_test_code, practice_test_revision, practice_test_checksum)
       VALUES (?, ?, 1, 'PRACTICE_TEST', NULL, NULL, NULL, NULL, ?, 1, ?)''',
    <Object?>[version, collection, '${prefix}_TEST', _hash],
  );
  await database.customStatement(
    '''INSERT INTO vertical_presentation_reads
       (content_version, mode, show_featured, show_see_all, featured_section_code)
       VALUES (?, 'SHELVES', 0, 1, NULL)''',
    <Object?>[version],
  );
}
