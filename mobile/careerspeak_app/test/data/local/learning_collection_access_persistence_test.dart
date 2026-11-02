import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/ports/universal_catalogue_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_universal_catalogue_repository.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test(
    'schema v18 keeps bounded FREE/FULL collection access read model',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);

      expect(database.schemaVersion, 18);
      final table = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'learning_collection_access_reads'",
          )
          .getSingleOrNull();
      expect(table, isNotNull);
    },
  );

  test('CURRENT snapshot restores explicit FREE collection access', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await _insertCurrentPointer(database, 100);
    await _insertGraph(database, 100, accessLevel: 'FREE');

    final result = await DriftUniversalCatalogueRepository(database)
        .readCurrent();
    expect(result, isA<Success<CurrentUniversalCatalogueSnapshot?>>());
    final snapshot =
        (result as Success<CurrentUniversalCatalogueSnapshot?>).value!;

    expect(snapshot.graph.collections.single.accessLevel, AccessLevel.free);
    expect(snapshot.graph.collections.single.requiresFullAccess, isFalse);
  });

  test('legacy snapshot without access row fails closed to FULL', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await _insertCurrentPointer(database, 101);
    await _insertGraph(database, 101);

    final result = await DriftUniversalCatalogueRepository(database)
        .readCurrent();
    expect(result, isA<Success<CurrentUniversalCatalogueSnapshot?>>());
    final snapshot =
        (result as Success<CurrentUniversalCatalogueSnapshot?>).value!;

    expect(snapshot.graph.collections.single.accessLevel, AccessLevel.full);
    expect(snapshot.graph.collections.single.requiresFullAccess, isTrue);
  });

  test('schema rejects unknown persisted access level', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await _insertGraph(database, 102);

    await expectLater(
      database.customStatement(
        '''INSERT INTO learning_collection_access_reads
           (content_version, collection_code, access_level)
           VALUES (?, ?, 'TRIAL')''',
        <Object?>[102, 'COLLECTION'],
      ),
      throwsA(anything),
    );
  });
}

Future<void> _insertCurrentPointer(
  CareerSpeakDatabase database,
  int version,
) async {
  await database
      .into(database.contentManifestStates)
      .insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 2,
          currentContentVersion: version,
          currentManifestChecksum: _hash,
          updatedAt: DateTime.utc(2026, 11, 2),
        ),
      );
}

Future<void> _insertGraph(
  CareerSpeakDatabase database,
  int version, {
  String? accessLevel,
}) async {
  final now = DateTime.utc(2026, 11, 2).millisecondsSinceEpoch;
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
       VALUES (?, 'SECTION', 'Section', NULL, NULL, 0, 1)''',
    <Object?>[version],
  );
  await database.customStatement(
    '''INSERT INTO learning_vertical_reads
       (content_version, code, section_code, title, description, icon_asset_id,
        sort_order, active)
       VALUES (?, 'VERTICAL', 'SECTION', 'Vertical', 'Description', 'icon', 0, 1)''',
    <Object?>[version],
  );
  await database.customStatement(
    '''INSERT INTO learning_goal_reads
       (content_version, code, vertical_code, title, description, sort_order, active)
       VALUES (?, 'GOAL', 'VERTICAL', 'Goal', 'Description', 0, 1)''',
    <Object?>[version],
  );
  await database.customStatement(
    '''INSERT INTO learning_track_reads
       (content_version, code, vertical_code, goal_code, title, description,
        level_code, career_track_code, sort_order, active)
       VALUES (?, 'TRACK', 'VERTICAL', 'GOAL', 'Track', 'Description',
        'B2', NULL, 0, 1)''',
    <Object?>[version],
  );
  await database.customStatement(
    '''INSERT INTO learning_collection_reads
       (content_version, code, vertical_code, track_code, title, description,
        sort_order, active)
       VALUES (?, 'COLLECTION', 'VERTICAL', 'TRACK', 'Collection',
        'Description', 0, 1)''',
    <Object?>[version],
  );
  if (accessLevel != null) {
    await database.customStatement(
      '''INSERT INTO learning_collection_access_reads
         (content_version, collection_code, access_level)
         VALUES (?, 'COLLECTION', ?)''',
      <Object?>[version, accessLevel],
    );
  }
  await database.customStatement(
    '''INSERT INTO learning_collection_member_reads
       (content_version, collection_code, position, member_type,
        content_code, content_type, content_revision, content_checksum,
        practice_test_code, practice_test_revision, practice_test_checksum)
       VALUES (?, 'COLLECTION', 0, 'CONTENT', 'CONTENT', 'topic', 1, ?,
        NULL, NULL, NULL)''',
    <Object?>[version, _hash],
  );
  await database.customStatement(
    '''INSERT INTO vertical_presentation_reads
       (content_version, mode, show_featured, show_see_all, featured_section_code)
       VALUES (?, 'SHELVES', 0, 1, NULL)''',
    <Object?>[version],
  );
}
