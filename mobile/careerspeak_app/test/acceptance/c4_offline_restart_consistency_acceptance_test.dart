import 'dart:convert';
import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_catalogue_snapshot_repository.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:careerspeak_app/data/local/publication_snapshot_storage.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _root108 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _content108 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _content109 =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _catalogue108 =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _catalogue109 =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

void main() {
  test(
    'C4.8 committed CURRENT survives real database reopen while staged next snapshot stays hidden',
    () async {
      final directory = await Directory.systemTemp.createTemp('c4_restart_');
      final file = File('${directory.path}/careerspeak.sqlite');
      final now = DateTime.utc(2026, 10, 31, 17);

      CareerSpeakDatabase? database;
      try {
        database = CareerSpeakDatabase(NativeDatabase(file));
        await PublicationSnapshotStorage(database).ensureReady();

        await _seedContent(
          database,
          contentVersion: 108,
          packCode: 'JAVA_CURRENT',
          contentRevision: 1,
          checksum: _content108,
          title: 'Committed v108',
          now: now,
        );
        await _seedContent(
          database,
          contentVersion: 109,
          packCode: 'JAVA_STAGED',
          contentRevision: 2,
          checksum: _content109,
          title: 'Staged v109',
          now: now,
        );
        await _seedCatalogue(
          database,
          contentVersion: 108,
          revision: 1,
          checksum: _catalogue108,
          label: 'Published catalogue v108',
          now: now,
        );
        await _seedCatalogue(
          database,
          contentVersion: 109,
          revision: 2,
          checksum: _catalogue109,
          label: 'Staged catalogue v109',
          now: now,
        );

        await database
            .into(database.contentManifestStates)
            .insert(
              ContentManifestStatesCompanion.insert(
                id: const Value(1),
                schemaVersion: 1,
                currentContentVersion: 108,
                currentManifestChecksum: _root108,
                updatedAt: now,
              ),
            );

        final beforeRestart = DriftContentRepository(database);
        final beforePage =
            (await beforeRestart.watchContent(const ContentQuery()).first)
                .getOrThrow();
        expect(beforePage.items, hasLength(1));
        expect(beforePage.items.single.revision, 1);
        expect(beforePage.items.single.title, 'Committed v108');

        await database.close();
        database = null;

        final reopened = CareerSpeakDatabase(NativeDatabase(file));
        database = reopened;
        await PublicationSnapshotStorage(reopened).ensureReady();

        final contentRepository = DriftContentRepository(reopened);
        final reopenedPage =
            (await contentRepository.watchContent(const ContentQuery()).first)
                .getOrThrow();

        expect(reopenedPage.items, hasLength(1));
        expect(reopenedPage.items.single.revision, 1);
        expect(reopenedPage.items.single.title, 'Committed v108');
        expect(
          reopenedPage.items.where((item) => item.revision == 2),
          isEmpty,
          reason:
              'staged v109 must not become visible merely because the app restarted',
        );

        final catalogueRepository = DriftCatalogueSnapshotRepository(reopened);
        final catalogue = (await catalogueRepository.readCurrent(
          CatalogueKind.categories,
        )).getOrThrow();

        expect(catalogue, isNotNull);
        expect(catalogue!.ref.revision, 1);
        expect(catalogue.ref.checksum, _catalogue108);
        expect(
          (catalogue.items.single as Map<String, dynamic>)['label'],
          'Published catalogue v108',
        );
      } finally {
        await database?.close();
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );

  test(
    'C4.8 offline reopen keeps last committed snapshot authoritative until an explicit CURRENT switch',
    () async {
      final directory = await Directory.systemTemp.createTemp('c4_offline_');
      final file = File('${directory.path}/careerspeak.sqlite');
      final now = DateTime.utc(2026, 10, 31, 17, 30);

      CareerSpeakDatabase? database;
      try {
        database = CareerSpeakDatabase(NativeDatabase(file));
        await _seedContent(
          database,
          contentVersion: 108,
          packCode: 'JAVA_CURRENT',
          contentRevision: 1,
          checksum: _content108,
          title: 'Offline committed v108',
          now: now,
        );
        await _seedContent(
          database,
          contentVersion: 109,
          packCode: 'JAVA_STAGED',
          contentRevision: 2,
          checksum: _content109,
          title: 'Backend advanced v109',
          now: now,
        );
        await database
            .into(database.contentManifestStates)
            .insert(
              ContentManifestStatesCompanion.insert(
                id: const Value(1),
                schemaVersion: 1,
                currentContentVersion: 108,
                currentManifestChecksum: _root108,
                updatedAt: now,
              ),
            );

        await database.close();
        database = null;

        final reopened = CareerSpeakDatabase(NativeDatabase(file));
        database = reopened;
        final repository = DriftContentRepository(reopened);
        final page = (await repository.watchContent(const ContentQuery()).first)
            .getOrThrow();

        expect(page.items, hasLength(1));
        expect(page.items.single.revision, 1);
        expect(page.items.single.title, 'Offline committed v108');
      } finally {
        await database?.close();
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}

Future<void> _seedContent(
  CareerSpeakDatabase database, {
  required int contentVersion,
  required String packCode,
  required int contentRevision,
  required String checksum,
  required String title,
  required DateTime now,
}) async {
  await database
      .into(database.contentPackRevisions)
      .insert(
        ContentPackRevisionsCompanion.insert(
          packCode: packCode,
          variantKey: 'canonical',
          revision: 1,
          schemaVersion: 1,
          checksum: checksum,
          state: 'CURRENT',
          sourceContentVersion: contentVersion,
          stagedAt: now,
          currentAt: Value(now),
        ),
      );
  await database
      .into(database.localContentRecords)
      .insert(
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
  await database
      .into(database.contentCatalogReads)
      .insert(
        ContentCatalogReadsCompanion.insert(
          contentCode: 'JAVA_Q_001',
          contentType: 'INTERVIEW',
          revision: contentRevision,
          checksum: checksum,
          title: title,
          subtitle: 'C4 offline/restart',
          description: 'Exact snapshot restart qualification.',
          category: 'Java Backend',
          level: 'Senior',
          minutes: 5,
          hasAudio: false,
          createdAt: now,
        ),
      );
  await database
      .into(database.packContentRefs)
      .insert(
        PackContentRefsCompanion.insert(
          packCode: packCode,
          variantKey: 'canonical',
          packRevision: 1,
          contentCode: 'JAVA_Q_001',
          contentType: 'INTERVIEW',
          contentRevision: contentRevision,
        ),
      );
}

Future<void> _seedCatalogue(
  CareerSpeakDatabase database, {
  required int contentVersion,
  required int revision,
  required String checksum,
  required String label,
  required DateTime now,
}) async {
  final payload = <String, Object?>{
    'kind': CatalogueKind.categories.wireName,
    'revision': revision,
    'checksum': checksum,
    'items': <Object?>[
      <String, Object?>{
        'code': 'JAVA_BACKEND',
        'label': label,
        'sortOrder': 0,
        'active': true,
      },
    ],
  };

  await database.customStatement(
    '''
    INSERT INTO catalogue_revision_reads
      (catalogue_kind, revision, checksum, payload_json, created_at)
    VALUES (?, ?, ?, ?, ?)
    ''',
    <Object?>[
      CatalogueKind.categories.wireName,
      revision,
      checksum,
      jsonEncode(payload),
      now.millisecondsSinceEpoch,
    ],
  );
  await database.customStatement(
    '''
    INSERT INTO publication_catalogue_refs
      (content_version, catalogue_kind, revision, checksum)
    VALUES (?, ?, ?, ?)
    ''',
    <Object?>[
      contentVersion,
      CatalogueKind.categories.wireName,
      revision,
      checksum,
    ],
  );
}
