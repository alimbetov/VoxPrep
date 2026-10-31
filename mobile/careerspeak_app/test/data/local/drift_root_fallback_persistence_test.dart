import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/content_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  test(
    'sync commit persists Backend-owned fallback order with root identity',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 10, 31, 6);
      final target = PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
        revision: 8,
        checksum: _packChecksum,
      );
      final root = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 120,
        minimumAppContractVersion: 1,
        publishedAt: now,
        checksum: _rootChecksum,
        packs: <PackRevisionRef>[target],
        localeFallbacks: <LocaleFallbackRule>[
          LocaleFallbackRule(
            locale: 'ru-kz',
            fallbackLocales: const <String>['kk', 'en'],
          ),
        ],
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
        runId: 'fallback-persistence',
        trigger: SyncTrigger.startup,
        translationLocale: 'ru-KZ',
      );
      await journal.persistPlan(runId: 'fallback-persistence', plan: plan);

      final result = await DriftSyncPlanExecutor(
        database,
        _ManifestGateway(_emptyPack(target)),
        const _RejectingPayloadGateway(),
        now: () => now,
      ).execute(runId: 'fallback-persistence', plan: plan);

      expect(result, isA<Success<void>>());
      final fallbackRows =
          await (database.select(database.localeFallbackRules)
                ..where((row) => row.sourceContentVersion.equals(120))
                ..orderBy([(row) => OrderingTerm.asc(row.fallbackOrder)]))
              .get();
      expect(fallbackRows, hasLength(2));
      expect(fallbackRows.map((row) => row.locale).toSet(), <String>{'ru-KZ'});
      expect(fallbackRows.map((row) => row.fallbackLocale).toList(), <String>[
        'kk',
        'en',
      ]);

      final manifest = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(manifest.currentContentVersion, 120);
      expect(manifest.currentManifestChecksum, _rootChecksum);
    },
  );
}

PackContentManifest _emptyPack(PackRevisionRef target) => PackContentManifest(
  schemaVersion: 1,
  identity: target.identity,
  revision: target.revision,
  checksum: target.checksum,
  contents: const <PackContentRef>[],
  assets: const <ManifestAssetDescriptor>[],
  contentAssets: const <ContentAssetRef>[],
);

final class _ManifestGateway implements ContentManifestGateway {
  const _ManifestGateway(this.pack);

  final PackContentManifest pack;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async =>
      const FailureResult<RootManifestFetch>(
        ApplicationFailure(code: 'NOT_USED', message: 'Not used.'),
      );

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async => Success<PackContentManifest>(pack);
}

final class _RejectingPayloadGateway implements ContentPayloadGateway {
  const _RejectingPayloadGateway();

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async =>
      const FailureResult<ContentPayload>(
        ApplicationFailure(
          code: 'UNEXPECTED_PAYLOAD_FETCH',
          message: 'Empty canonical pack must not fetch content.',
        ),
      );
}

const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _packChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
