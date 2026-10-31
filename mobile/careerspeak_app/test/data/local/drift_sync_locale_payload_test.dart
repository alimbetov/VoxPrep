import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/content_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _root =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _pack =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _content =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  test(
    'locale pack metadata does not fetch or duplicate canonical payload',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 10, 30, 12);
      final target = PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'locale:kk'),
        revision: 4,
        checksum: _pack,
      );
      final root = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 108,
        minimumAppContractVersion: 1,
        publishedAt: now,
        checksum: _root,
        packs: <PackRevisionRef>[target],
        tombstones: const <ContentTombstone>[],
      );
      final plan = const ContentSyncPlanner()
          .plan(
            local: SyncLocalSnapshot(
              currentContentVersion: null,
              currentManifestChecksum: null,
              etag: null,
              currentPacks: const <PackRevisionRef>[],
            ),
            remote: root,
          )
          .getOrThrow();
      final journal = DriftSyncJournal(database, now: () => now);
      await journal.startOrCoalesce(
        runId: 'run-locale',
        trigger: SyncTrigger.localeChange,
        translationLocale: 'kk',
      );
      await journal.persistPlan(runId: 'run-locale', plan: plan);

      final payloadGateway = _RejectingPayloadGateway();
      final executor = DriftSyncPlanExecutor(
        database,
        _ManifestGateway(_localePack(target, now)),
        payloadGateway,
        now: () => now,
      );

      final result = await executor.execute(runId: 'run-locale', plan: plan);

      expect(result, isA<Success<void>>());
      expect(payloadGateway.calls, 0);
      expect(
        await database.select(database.contentCatalogReads).get(),
        isEmpty,
      );
      final content = await database
          .select(database.localContentRecords)
          .getSingle();
      expect(content.snapshotState, 'CURRENT');
    },
  );
}

PackContentManifest _localePack(PackRevisionRef target, DateTime now) {
  return PackContentManifest(
    schemaVersion: 1,
    identity: target.identity,
    revision: target.revision,
    checksum: target.checksum,
    contents: <PackContentRef>[
      PackContentRef(
        identity: const ContentIdentity(
          code: 'JAVA_Q_001',
          type: ContentType.interview,
        ),
        revision: 3,
        checksum: _content,
        sortOrder: 1,
        publishedAt: now,
      ),
    ],
    assets: const <ManifestAssetDescriptor>[],
    contentAssets: const <ContentAssetRef>[],
  );
}

final class _ManifestGateway implements ContentManifestGateway {
  const _ManifestGateway(this.pack);

  final PackContentManifest pack;

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async => Success(pack);

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    return const FailureResult(
      ApplicationFailure(code: 'NOT_USED', message: 'Not used.'),
    );
  }
}

final class _RejectingPayloadGateway implements ContentPayloadGateway {
  int calls = 0;

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async {
    calls += 1;
    return const FailureResult(
      ApplicationFailure(
        code: 'UNEXPECTED_PAYLOAD_FETCH',
        message: 'Locale packs must not fetch canonical payload.',
      ),
    );
  }
}
