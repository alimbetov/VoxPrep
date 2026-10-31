import 'dart:convert';

import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_catalogue_snapshot_repository.dart';
import 'package:careerspeak_app/data/local/publication_snapshot_storage.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _checksumV1 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _checksumV2 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _root108 =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _root109 =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  late CareerSpeakDatabase database;
  late DriftCatalogueSnapshotRepository repository;

  setUp(() async {
    database = createTestDatabase();
    await PublicationSnapshotStorage(database).ensureReady();
    repository = DriftCatalogueSnapshotRepository(database);
    final now = DateTime.utc(2026, 10, 31, 16);

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

    await _seedCatalogue(
      database,
      contentVersion: 108,
      revision: 1,
      checksum: _checksumV1,
      label: 'Java v1',
    );
    await _seedCatalogue(
      database,
      contentVersion: 109,
      revision: 2,
      checksum: _checksumV2,
      label: 'Java v2',
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('newer cached catalogue stays hidden outside CURRENT root', () async {
    final payload = (await repository.readCurrent(
      CatalogueKind.categories,
    )).getOrThrow();

    expect(payload, isNotNull);
    expect(payload!.ref.revision, 1);
    expect((payload.items.single as Map<String, dynamic>)['label'], 'Java v1');
  });

  test(
    'root pointer switch exposes the next exact catalogue revision',
    () async {
      await (database.update(
        database.contentManifestStates,
      )..where((row) => row.id.equals(1))).write(
        ContentManifestStatesCompanion(
          currentContentVersion: const Value(109),
          currentManifestChecksum: const Value(_root109),
          updatedAt: Value(DateTime.utc(2026, 10, 31, 16, 1)),
        ),
      );

      final payload = (await repository.readCurrent(
        CatalogueKind.categories,
      )).getOrThrow();

      expect(payload, isNotNull);
      expect(payload!.ref.revision, 2);
      expect(
        (payload.items.single as Map<String, dynamic>)['label'],
        'Java v2',
      );
    },
  );
}

Future<void> _seedCatalogue(
  CareerSpeakDatabase database, {
  required int contentVersion,
  required int revision,
  required String checksum,
  required String label,
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
      DateTime.utc(2026, 10, 31, 16).millisecondsSinceEpoch,
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
