import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/content_payload_gateway.dart';
import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _root108 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _root109 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _pack108 =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _content =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  late CareerSpeakDatabase database;
  final now = DateTime.utc(2026, 10, 31, 15, 30);

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('planned tombstone is not learner-visible before publication commit', () async {
    await _seedCurrentSnapshot(database, now);
    final plan = _retirementPlan();
    final journal = DriftSyncJournal(database, now: () => now);

    await _prepareRun(journal, plan);

    final tombstone = await database.select(database.syncTombstones).getSingle();
    expect(tombstone.state, SyncTombstoneState.planned.storageCode);
    expect(await database.select(database.contentRetirements).get(), isEmpty);

    final visible = (await DriftContentRepository(database)
            .watchContent(const ContentQuery())
            .first)
        .getOrThrow();
    expect(visible.items.map((item) => item.code), <String>['OLD_Q_001']);
  });

  test('repository recreation does not activate a staged tombstone', () async {
    await _seedCurrentSnapshot(database, now);
    final plan = _retirementPlan();
    final journal = DriftSyncJournal(database, now: () => now);
    await _prepareRun(journal, plan);

    final recreatedRepository = DriftContentRepository(database);
    final visible = (await recreatedRepository
            .watchContent(const ContentQuery())
            .first)
        .getOrThrow();

    expect(visible.items, hasLength(1));
    expect(visible.items.single.code, 'OLD_Q_001');
    expect(await database.select(database.contentRetirements).get(), isEmpty);
  });

  test('successful atomic publication makes tombstone effective', () async {
    await _seedCurrentSnapshot(database, now);
    final plan = _retirementPlan();
    final journal = DriftSyncJournal(database, now: () => now);
    await _prepareRun(journal, plan);

    final executor = DriftSyncPlanExecutor(
      database,
      const _UnusedManifestGateway(),
      const _UnusedPayloadGateway(),
      now: () => now,
    );
    final result = await executor.execute(runId: 'run-c4-6', plan: plan);

    expect(result, isA<Success<void>>());

    final root = await database.select(database.contentManifestStates).getSingle();
    expect(root.currentContentVersion, 109);
    expect(root.currentManifestChecksum, _root109);

    final retirement = await database.select(database.contentRetirements).getSingle();
    expect(retirement.contentCode, 'OLD_Q_001');
    expect(retirement.sourceContentVersion, 109);
    expect(retirement.retiredRevision, 1);

    final tombstone = await database.select(database.syncTombstones).getSingle();
    expect(tombstone.state, SyncTombstoneState.applied.storageCode);
    expect(tombstone.appliedAt, isNotNull);

    final content = await database.select(database.localContentRecords).getSingle();
    expect(content.snapshotState, 'TOMBSTONED');

    final visible = (await DriftContentRepository(database)
            .watchContent(const ContentQuery())
            .first)
        .getOrThrow();
    expect(visible.items, isEmpty);
  });

  test('failed publication keeps tombstone staged and CURRENT content intact', () async {
    await _seedCurrentSnapshot(database, now);

    final conflictingTarget = PackRevisionRef(
      identity: PackIdentity(code: 'NEW_PACK', variant: 'canonical'),
      revision: 1,
      checksum: _pack108,
    );
    final tombstone = ContentTombstone(
      identity: const ContentIdentity(
        code: 'OLD_Q_001',
        type: ContentType.interview,
      ),
      revision: 1,
      reason: 'INACTIVE',
    );
    final root = RootContentManifest(
      schemaVersion: 1,
      contentVersion: 109,
      minimumAppContractVersion: 1,
      publishedAt: now,
      checksum: _root109,
      packs: <PackRevisionRef>[conflictingTarget],
      tombstones: <ContentTombstone>[tombstone],
    );
    final plan = const ContentSyncPlanner()
        .plan(
          local: SyncLocalSnapshot(
            currentContentVersion: 108,
            currentManifestChecksum: _root108,
            etag: null,
            currentPacks: <PackRevisionRef>[
              PackRevisionRef(
                identity: PackIdentity(code: 'OLD_PACK', variant: 'canonical'),
                revision: 1,
                checksum: _pack108,
              ),
            ],
          ),
          remote: root,
        )
        .getOrThrow();
    final journal = DriftSyncJournal(database, now: () => now);
    await _prepareRun(journal, plan);

    final executor = DriftSyncPlanExecutor(
      database,
      _ConflictingManifestGateway(conflictingTarget, tombstone),
      const _UnusedPayloadGateway(),
      now: () => now,
    );
    final result = await executor.execute(runId: 'run-c4-6', plan: plan);

    expect(result, isA<FailureResult<void>>());
    expect(await database.select(database.contentRetirements).get(), isEmpty);

    final rootState = await database.select(database.contentManifestStates).getSingle();
    expect(rootState.currentContentVersion, 108);

    final oldContent = await database.select(database.localContentRecords).getSingle();
    expect(oldContent.snapshotState, 'CURRENT');

    final stagedTombstone = await database.select(database.syncTombstones).getSingle();
    expect(stagedTombstone.state, SyncTombstoneState.planned.storageCode);

    final visible = (await DriftContentRepository(database)
            .watchContent(const ContentQuery())
            .first)
        .getOrThrow();
    expect(visible.items.map((item) => item.code), <String>['OLD_Q_001']);
  });
}

SyncPlan _retirementPlan() {
  final tombstone = ContentTombstone(
    identity: const ContentIdentity(
      code: 'OLD_Q_001',
      type: ContentType.interview,
    ),
    revision: 1,
    reason: 'INACTIVE',
  );
  final root = RootContentManifest(
    schemaVersion: 1,
    contentVersion: 109,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 31, 15, 30),
    checksum: _root109,
    packs: const <PackRevisionRef>[],
    tombstones: <ContentTombstone>[tombstone],
  );
  return const ContentSyncPlanner()
      .plan(
        local: SyncLocalSnapshot(
          currentContentVersion: 108,
          currentManifestChecksum: _root108,
          etag: null,
          currentPacks: <PackRevisionRef>[
            PackRevisionRef._unsafeForTest(),
          ],
        ),
        remote: root,
      )
      .getOrThrow();
}

Future<void> _prepareRun(DriftSyncJournal journal, SyncPlan plan) async {
  final started = await journal.startOrCoalesce(
    runId: 'run-c4-6',
    trigger: SyncTrigger.startup,
    translationLocale: 'kk',
  );
  expect(started, isA<Success<SyncRunStart>>());
  expect(
    await journal.persistPlan(runId: 'run-c4-6', plan: plan),
    isA<Success<void>>(),
  );
}

Future<void> _seedCurrentSnapshot(
  CareerSpeakDatabase database,
  DateTime now,
) async {
  await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 1,
          currentContentVersion: 108,
          currentManifestChecksum: _root108,
          updatedAt: now,
        ),
      );
  await database.into(database.contentPackRevisions).insert(
        ContentPackRevisionsCompanion.insert(
          packCode: 'OLD_PACK',
          variantKey: 'canonical',
          revision: 1,
          schemaVersion: 1,
          checksum: _pack108,
          state: 'CURRENT',
          sourceContentVersion: 108,
          stagedAt: now,
          currentAt: Value(now),
        ),
      );
  await database.into(database.packContentRefs).insert(
        PackContentRefsCompanion.insert(
          packCode: 'OLD_PACK',
          variantKey: 'canonical',
          packRevision: 1,
          contentCode: 'OLD_Q_001',
          contentType: 'INTERVIEW',
          contentRevision: 1,
        ),
      );
  await database.into(database.localContentRecords).insert(
        LocalContentRecordsCompanion.insert(
          contentCode: 'OLD_Q_001',
          contentType: 'INTERVIEW',
          revision: 1,
          checksum: _content,
          snapshotState: 'CURRENT',
          sourceSchemaVersion: 1,
          createdAt: now,
        ),
      );
  await database.into(database.contentCatalogReads).insert(
        ContentCatalogReadsCompanion.insert(
          contentCode: 'OLD_Q_001',
          contentType: 'INTERVIEW',
          revision: 1,
          checksum: _content,
          title: 'Old question',
          subtitle: 'Previous publication',
          description: 'Last-known-good content.',
          category: 'Java Backend',
          level: 'Senior',
          minutes: 5,
          hasAudio: false,
          createdAt: now,
        ),
      );
}

final class _UnusedManifestGateway implements ContentManifestGateway {
  const _UnusedManifestGateway();

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async =>
      const FailureResult(
        ApplicationFailure(code: 'NOT_USED', message: 'not used'),
      );

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async => const FailureResult(
        ApplicationFailure(code: 'NOT_USED', message: 'not used'),
      );
}

final class _ConflictingManifestGateway implements ContentManifestGateway {
  const _ConflictingManifestGateway(this.target, this.tombstone);

  final PackRevisionRef target;
  final ContentTombstone tombstone;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async =>
      const FailureResult(
        ApplicationFailure(code: 'NOT_USED', message: 'not used'),
      );

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef requested,
  ) async {
    return Success(
      PackContentManifest(
        schemaVersion: 1,
        identity: target.identity,
        revision: target.revision,
        checksum: target.checksum,
        contents: <PackContentRef>[
          PackContentRef(
            identity: tombstone.identity,
            revision: tombstone.revision,
            checksum: _content,
          ),
        ],
        assets: const <ManifestAssetDescriptor>[],
        contentAssets: const <ContentAssetRef>[],
      ),
    );
  }
}

final class _UnusedPayloadGateway implements ContentPayloadGateway {
  const _UnusedPayloadGateway();

  @override
  Future<Result<dynamic>> fetch(dynamic target) async => const FailureResult(
        ApplicationFailure(code: 'NOT_USED', message: 'not used'),
      );
}
