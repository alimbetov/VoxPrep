import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _root108 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _root109 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _content108 =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _content109 =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  late CareerSpeakDatabase database;
  final now = DateTime.utc(2026, 10, 31, 15);

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'root pointer is the authoritative learner visibility fence',
    () async {
      await _seedRevision(
        database,
        contentVersion: 108,
        packCode: 'JAVA_OLD',
        packRevision: 1,
        contentRevision: 1,
        checksum: _content108,
        title: 'Published v108',
        now: now,
      );
      await _seedRevision(
        database,
        contentVersion: 109,
        packCode: 'JAVA_NEW',
        packRevision: 1,
        contentRevision: 2,
        checksum: _content109,
        title: 'Prepared v109',
        now: now,
      );
      await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 1,
          currentContentVersion: 108,
          currentManifestChecksum: _root108,
          updatedAt: now,
        ),
      );

      final beforeSwitch = DriftContentRepository(database);
      final oldPage =
          (await beforeSwitch.watchContent(const ContentQuery()).first)
              .getOrThrow();

      expect(oldPage.items, hasLength(1));
      expect(oldPage.items.single.revision, 1);
      expect(oldPage.items.single.title, 'Published v108');

      // Recreating the repository simulates a process-level reader restart:
      // prepared rows must still not become visible without a root switch.
      final restartedReader = DriftContentRepository(database);
      final afterReaderRestart =
          (await restartedReader.watchContent(const ContentQuery()).first)
              .getOrThrow();
      expect(afterReaderRestart.items.single.revision, 1);

      await database.transaction(() async {
        await (database.update(database.contentPackRevisions)..where(
              (row) =>
                  row.packCode.equals('JAVA_OLD') &
                  row.variantKey.equals('canonical') &
                  row.revision.equals(1),
            ))
            .write(
              ContentPackRevisionsCompanion(
                state: const Value('SUPERSEDED'),
                supersededAt: Value(now),
              ),
            );
        await (database.update(database.contentManifestStates)..where(
              (row) => row.id.equals(1),
            ))
            .write(
              ContentManifestStatesCompanion(
                currentContentVersion: const Value(109),
                currentManifestChecksum: const Value(_root109),
                updatedAt: Value(now),
              ),
            );
      });

      final newPage =
          (await restartedReader.watchContent(const ContentQuery()).first)
              .getOrThrow();
      expect(newPage.items, hasLength(1));
      expect(newPage.items.single.revision, 2);
      expect(newPage.items.single.title, 'Prepared v109');
    },
  );

  test('prepared CURRENT-looking rows are invisible behind older root', () async {
    await _seedRevision(
      database,
      contentVersion: 109,
      packCode: 'JAVA_NEW',
      packRevision: 1,
      contentRevision: 2,
      checksum: _content109,
      title: 'Prepared v109',
      now: now,
    );

    await database.into(database.contentManifestStates).insert(
      ContentManifestStatesCompanion.insert(
        id: const Value(1),
        schemaVersion: 1,
        currentContentVersion: 108,
        currentManifestChecksum: _root108,
        updatedAt: now,
      ),
    );

    final repository = DriftContentRepository(database);
    final page =
        (await repository.watchContent(const ContentQuery()).first).getOrThrow();

    expect(page.items, isEmpty);
  });
}

Future<void> _seedRevision(
  CareerSpeakDatabase database, {
  required int contentVersion,
  required String packCode,
  required int packRevision,
  required int contentRevision,
  required String checksum,
  required String title,
  required DateTime now,
}) async {
  await database.into(database.contentPackRevisions).insert(
    ContentPackRevisionsCompanion.insert(
      packCode: packCode,
      variantKey: 'canonical',
      revision: packRevision,
      schemaVersion: 1,
      checksum: checksum,
      state: 'CURRENT',
      sourceContentVersion: contentVersion,
      stagedAt: now,
      currentAt: Value(now),
    ),
  );
  await database.into(database.localContentRecords).insert(
    LocalContentRecordsCompanion.insert(
      contentCode: 'JAVA_Q_001',
      contentType: 'INTERVIEW',
      revision: contentRevision,
      checksum: checksum,
      sortOrder: const Value(1),
      snapshotState: 'CURRENT',
      sourceSchemaVersion: 1,
      createdAt: now,
    ),
  );
  await database.into(database.contentCatalogReads).insert(
    ContentCatalogReadsCompanion.insert(
      contentCode: 'JAVA_Q_001',
      contentType: 'INTERVIEW',
      revision: contentRevision,
      checksum: checksum,
      title: title,
      subtitle: 'Atomic publication',
      description: 'C4.3 visibility qualification.',
      category: 'Java Backend',
      level: 'Senior',
      minutes: 5,
      hasAudio: false,
      createdAt: now,
    ),
  );
  await database.into(database.packContentRefs).insert(
    PackContentRefsCompanion.insert(
      packCode: packCode,
      variantKey: 'canonical',
      packRevision: packRevision,
      contentCode: 'JAVA_Q_001',
      contentType: 'INTERVIEW',
      contentRevision: contentRevision,
    ),
  );
}
