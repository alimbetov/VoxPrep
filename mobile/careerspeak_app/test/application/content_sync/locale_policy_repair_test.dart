import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same immutable root still commits when locale policy needs repair', () {
    final pack = PackRevisionRef(
      identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
      revision: 8,
      checksum: _packChecksum,
    );
    final remote = RootContentManifest(
      schemaVersion: 1,
      contentVersion: 108,
      minimumAppContractVersion: 1,
      publishedAt: DateTime.utc(2026, 10, 31, 7),
      checksum: _rootChecksum,
      packs: <PackRevisionRef>[pack],
      localeFallbacks: <LocaleFallbackRule>[
        LocaleFallbackRule(
          locale: 'ru-KZ',
          fallbackLocales: const <String>['ru', 'en'],
        ),
      ],
      tombstones: const <ContentTombstone>[],
    );
    final local = SyncLocalSnapshot(
      currentContentVersion: 108,
      currentManifestChecksum: _rootChecksum,
      etag: 'root-108',
      currentPacks: <PackRevisionRef>[pack],
      localePolicyRepairRequired: true,
    );

    final plan = const ContentSyncPlanner()
        .plan(local: local, remote: remote)
        .getOrThrow();

    expect(plan.rootChanged, isTrue);
    expect(plan.changedPacks, isEmpty);
    expect(plan.tombstones, isEmpty);
    expect(plan.isNoOp, isFalse);
  });

  test('same root is no-op after policy marker reaches current version', () {
    final pack = PackRevisionRef(
      identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
      revision: 8,
      checksum: _packChecksum,
    );
    final remote = RootContentManifest(
      schemaVersion: 1,
      contentVersion: 108,
      minimumAppContractVersion: 1,
      publishedAt: DateTime.utc(2026, 10, 31, 7),
      checksum: _rootChecksum,
      packs: <PackRevisionRef>[pack],
      tombstones: const <ContentTombstone>[],
    );
    final local = SyncLocalSnapshot(
      currentContentVersion: 108,
      currentManifestChecksum: _rootChecksum,
      etag: 'root-108',
      currentPacks: <PackRevisionRef>[pack],
    );

    final plan = const ContentSyncPlanner()
        .plan(local: local, remote: remote)
        .getOrThrow();

    expect(plan.isNoOp, isTrue);
  });
}

const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _packChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
