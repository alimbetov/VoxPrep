import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _root108 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _root109 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _packCanonical =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _packLocale =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _contentHash =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

void main() {
  late CareerSpeakDatabase database;
  late DriftSyncJournal journal;
  final now = DateTime.utc(2026, 10, 30, 10);

  setUp(() {
    database = createTestDatabase();
    journal = DriftSyncJournal(database, now: () => now);
  });

  tearDown(() async {
    await database.close();
  });

  test('reads the CURRENT root and pack snapshot only', () async {
    await database
        .into(database.contentManifestStates)
        .insert(
          ContentManifestStatesCompanion.insert(
            id: const Value(1),
            schemaVersion: 1,
            currentContentVersion: 108,
            currentManifestChecksum: _root108,
            etag: const Value('etag-108'),
            updatedAt: now,
          ),
        );
    await database
        .into(database.contentPackRevisions)
        .insert(
          ContentPackRevisionsCompanion.insert(
            packCode: 'JAVA_SENIOR',
            variantKey: 'canonical',
            revision: 8,
            schemaVersion: 1,
            checksum: _packCanonical,
            state: 'CURRENT',
            sourceContentVersion: 108,
            stagedAt: now,
          ),
        );
    await database
        .into(database.contentPackRevisions)
        .insert(
          ContentPackRevisionsCompanion.insert(
            packCode: 'JAVA_SENIOR',
            variantKey: 'locale:kk',
            revision: 3,
            schemaVersion: 1,
            checksum: _packLocale,
            state: 'SUPERSEDED',
            sourceContentVersion: 107,
            stagedAt: now,
          ),
        );

    final snapshot = (await journal.readLocalSnapshot()).getOrThrow();

    expect(snapshot.currentContentVersion, 108);
    expect(snapshot.currentManifestChecksum, _root108);
    expect(snapshot.etag, 'etag-108');
    expect(snapshot.currentPacks, hasLength(1));
    expect(snapshot.currentPacks.single.identity.variant, 'canonical');
  });

  test(
    'CURRENT canonical pack stays represented while same root repairs payload',
    () async {
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
      await database
          .into(database.contentPackRevisions)
          .insert(
            ContentPackRevisionsCompanion.insert(
              packCode: 'JAVA_SENIOR',
              variantKey: 'canonical',
              revision: 8,
              schemaVersion: 1,
              checksum: _packCanonical,
              state: 'CURRENT',
              sourceContentVersion: 108,
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
              revision: 1,
              checksum: _contentHash,
              snapshotState: 'CURRENT',
              sourceSchemaVersion: 1,
              createdAt: now,
            ),
          );
      await database
          .into(database.packContentRefs)
          .insert(
            PackContentRefsCompanion.insert(
              packCode: 'JAVA_SENIOR',
              variantKey: 'canonical',
              packRevision: 8,
              contentCode: 'JAVA_Q_001',
              contentType: 'INTERVIEW',
              contentRevision: 1,
            ),
          );

      final local = (await journal.readLocalSnapshot()).getOrThrow();
      expect(local.currentContentVersion, 108);
      expect(local.currentPacks, hasLength(1));
      expect(local.contentPayloadRepairPacks, hasLength(1));

      final remote = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 108,
        minimumAppContractVersion: 1,
        publishedAt: now,
        checksum: _root108,
        packs: <PackRevisionRef>[
          PackRevisionRef(
            identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
            revision: 8,
            checksum: _packCanonical,
          ),
        ],
        tombstones: const <ContentTombstone>[],
      );
      final plan = const ContentSyncPlanner()
          .plan(local: local, remote: remote)
          .getOrThrow();

      expect(plan.rootChanged, isFalse);
      expect(plan.changedPacks, hasLength(1));
      expect(plan.changedPacks.single.identity.code, 'JAVA_SENIOR');
    },
  );

  test('coalesces a second trigger into the active durable run', () async {
    final first = await journal.startOrCoalesce(
      runId: 'run-1',
      trigger: SyncTrigger.startup,
      translationLocale: 'kk',
    );
    final second = await journal.startOrCoalesce(
      runId: 'run-2',
      trigger: SyncTrigger.manual,
      translationLocale: 'ru',
    );

    expect(first, isA<Success<SyncRunStart>>());
    expect((first as Success<SyncRunStart>).value, isA<SyncRunStarted>());
    expect(second, isA<Success<SyncRunStart>>());
    final coalesced = (second as Success<SyncRunStart>).value;
    expect(coalesced, isA<SyncRunCoalesced>());
    expect(coalesced.runId, 'run-1');

    final rows = await database.select(database.syncRuns).get();
    expect(rows, hasLength(1));
    expect(rows.single.resyncRequested, isTrue);
  });

  test(
    'terminal run is immutable and a later trigger starts a new run',
    () async {
      await journal.startOrCoalesce(
        runId: 'run-1',
        trigger: SyncTrigger.startup,
        translationLocale: 'kk',
      );
      expect(
        await journal.transitionRun(
          runId: 'run-1',
          state: SyncRunState.succeeded,
        ),
        isA<Success<void>>(),
      );

      final illegal = await journal.transitionRun(
        runId: 'run-1',
        state: SyncRunState.planning,
      );
      expect(illegal, isA<FailureResult<void>>());
      expect(
        (illegal as FailureResult<void>).failure.code,
        'SYNC_RUN_TERMINAL',
      );

      final next = await journal.startOrCoalesce(
        runId: 'run-2',
        trigger: SyncTrigger.manual,
        translationLocale: 'kk',
      );
      expect((next as Success<SyncRunStart>).value, isA<SyncRunStarted>());
      expect(await database.select(database.syncRuns).get(), hasLength(2));
    },
  );

  test('persists a deterministic plan and rejects target mutation', () async {
    await journal.startOrCoalesce(
      runId: 'run-1',
      trigger: SyncTrigger.startup,
      translationLocale: 'kk',
    );

    final planner = const ContentSyncPlanner();
    final plan = planner
        .plan(
          local: SyncLocalSnapshot(
            currentContentVersion: null,
            currentManifestChecksum: null,
            etag: null,
            currentPacks: const <PackRevisionRef>[],
          ),
          remote: _manifest(109),
        )
        .getOrThrow();

    expect(
      await journal.persistPlan(runId: 'run-1', plan: plan),
      isA<Success<void>>(),
    );
    expect(
      await journal.persistPlan(runId: 'run-1', plan: plan),
      isA<Success<void>>(),
    );

    final run = await database.select(database.syncRuns).getSingle();
    expect(run.targetContentVersion, 109);
    expect(run.targetSchemaVersion, 1);
    expect(run.state, 'PLANNING');
    expect(await database.select(database.syncPackUpdates).get(), hasLength(2));
    expect(await database.select(database.syncTombstones).get(), hasLength(1));

    final changedTarget = const ContentSyncPlanner()
        .plan(
          local: SyncLocalSnapshot(
            currentContentVersion: null,
            currentManifestChecksum: null,
            etag: null,
            currentPacks: const <PackRevisionRef>[],
          ),
          remote: _manifest(110),
        )
        .getOrThrow();
    final rejected = await journal.persistPlan(
      runId: 'run-1',
      plan: changedTarget,
    );

    expect(rejected, isA<FailureResult<void>>());
    expect(
      (rejected as FailureResult<void>).failure.code,
      'SYNC_TARGET_IMMUTABLE',
    );
  });
}

RootContentManifest _manifest(int contentVersion) {
  return RootContentManifest(
    schemaVersion: 1,
    contentVersion: contentVersion,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 30, 10),
    checksum: contentVersion == 109 ? _root109 : _root108,
    packs: <PackRevisionRef>[
      PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
        revision: 8,
        checksum: _packCanonical,
      ),
      PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'locale:kk'),
        revision: 4,
        checksum: _packLocale,
      ),
    ],
    tombstones: <ContentTombstone>[
      ContentTombstone(
        identity: ContentIdentity(
          code: 'JAVA_QUESTION_001',
          type: ContentType.interview,
        ),
        revision: 3,
        reason: 'INACTIVE',
      ),
    ],
  );
}
