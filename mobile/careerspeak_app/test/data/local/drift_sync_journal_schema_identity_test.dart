import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test(
    'CURRENT root preserves persisted schema identity across app upgrades',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 11, 2, 9);

      await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 1,
          currentContentVersion: 108,
          currentManifestChecksum: _rootChecksum,
          etag: const Value('root-v1-108'),
          updatedAt: now,
        ),
      );

      final local = (await DriftSyncJournal(database).readLocalSnapshot())
          .getOrThrow();
      expect(local.currentSchemaVersion, 1);

      final remoteV1 = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 108,
        minimumAppContractVersion: 1,
        publishedAt: now,
        checksum: _rootChecksum,
        packs: const <PackRevisionRef>[],
        tombstones: const <ContentTombstone>[],
      );
      final compatible = const ContentSyncPlanner().plan(
        local: local,
        remote: remoteV1,
        remoteEtag: 'root-v1-108',
      );
      expect(compatible, isA<Success<SyncPlan>>());
      expect((compatible as Success<SyncPlan>).value.isNoOp, isTrue);

      final remoteV2 = RootContentManifest(
        schemaVersion: supportedContentManifestSchemaVersion,
        contentVersion: 108,
        minimumAppContractVersion: 2,
        publishedAt: now,
        checksum: _rootChecksum,
        packs: const <PackRevisionRef>[],
        tombstones: const <ContentTombstone>[],
      );
      final conflict = const ContentSyncPlanner().plan(
        local: local,
        remote: remoteV2,
        remoteEtag: 'root-v1-108',
      );
      expect(conflict, isA<FailureResult<SyncPlan>>());
      expect(
        (conflict as FailureResult<SyncPlan>).failure.code,
        'PUBLICATION_SNAPSHOT_IDENTITY_CONFLICT',
      );
    },
  );
}
