import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/content_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart'
    hide ContentAssetRef, PackContentRef;
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
const _packHash =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _contentHash =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _assetHash =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

void main() {
  late CareerSpeakDatabase database;
  final now = DateTime.utc(2026, 10, 30, 12);

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('stages exact payload and atomically activates CURRENT root', () async {
    final target = _targetPack();
    final root = _root(contentVersion: 109, pack: target);
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
    await _prepareRun(journal, plan);

    await database
        .into(database.favorites)
        .insert(
          FavoritesCompanion.insert(
            contentCode: 'JAVA_Q_001',
            contentType: 'INTERVIEW',
            createdAt: now,
          ),
        );

    final executor = DriftSyncPlanExecutor(
      database,
      _PackGateway(_packManifest(target)),
      const _PayloadGateway(),
      now: () => now,
    );
    final result = await executor.execute(runId: 'run-1', plan: plan);

    expect(result, isA<Success<void>>());

    final manifestState = await database
        .select(database.contentManifestStates)
        .getSingle();
    expect(manifestState.currentContentVersion, 109);
    expect(manifestState.currentManifestChecksum, _root109);

    final pack = await database
        .select(database.contentPackRevisions)
        .getSingle();
    expect(pack.state, 'CURRENT');
    expect(pack.revision, 8);

    final content = await database
        .select(database.localContentRecords)
        .getSingle();
    expect(content.snapshotState, 'CURRENT');
    expect(content.contentCode, 'JAVA_Q_001');

    final payload = await database
        .select(database.contentCatalogReads)
        .getSingle();
    expect(payload.contentCode, 'JAVA_Q_001');
    expect(payload.contentType, 'INTERVIEW');
    expect(payload.revision, 1);
    expect(payload.checksum, _contentHash);
    expect(payload.title, 'Dependency Injection');
    expect(payload.minutes, 6);

    final typedPayload = await database
        .select(database.typedContentReads)
        .getSingle();
    expect(typedPayload.contentCode, 'JAVA_Q_001');
    expect(typedPayload.categoryCode, 'JAVA_BACKEND');
    expect(typedPayload.levelCode, 'SENIOR');
    expect(typedPayload.skillCodesJson, '["COMMUNICATION","SYSTEM_DESIGN"]');
    expect(typedPayload.bodyKind, 'interview');
    expect(
      typedPayload.bodyJson,
      contains('"prompt":"What is dependency injection?"'),
    );

    final asset = await database.select(database.assetCatalog).getSingle();
    expect(asset.assetKind, 'AUDIO');
    expect(asset.mimeType, 'audio/mpeg');
    expect(await database.select(database.packContentRefs).get(), hasLength(1));
    expect(
      await database.select(database.contentAssetRefs).get(),
      hasLength(1),
    );
    expect(await database.select(database.packAssetRefs).get(), hasLength(1));

    final update = await database.select(database.syncPackUpdates).getSingle();
    expect(update.state, SyncPackUpdateState.committed.storageCode);
    final run = await database.select(database.syncRuns).getSingle();
    expect(run.state, SyncRunState.cleaning.storageCode);
    expect(await database.select(database.favorites).get(), hasLength(1));
  });

  test(
    'commit conflict keeps staged payload hidden and preserves previous CURRENT',
    () async {
      await _seedCurrentSnapshot(database, now);

      final target = _targetPack();
      final tombstone = ContentTombstone(
        identity: ContentIdentity(
          code: 'JAVA_Q_001',
          type: ContentType.interview,
        ),
        revision: 1,
        reason: 'INACTIVE',
      );
      final root = _root(
        contentVersion: 109,
        pack: target,
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
                  identity: PackIdentity(
                    code: 'OLD_PACK',
                    variant: 'canonical',
                  ),
                  revision: 1,
                  checksum: _root108,
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
        _PackGateway(_packManifest(target)),
        const _PayloadGateway(),
        now: () => now,
      );
      final result = await executor.execute(runId: 'run-1', plan: plan);

      expect(result, isA<FailureResult<void>>());
      expect(
        (result as FailureResult<void>).failure.code,
        'TOMBSTONE_TARGET_CONFLICT',
      );

      final manifestState = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(manifestState.currentContentVersion, 108);
      final oldPack = await (database.select(
        database.contentPackRevisions,
      )..where((row) => row.packCode.equals('OLD_PACK'))).getSingle();
      expect(oldPack.state, 'CURRENT');
      final oldContent = await (database.select(
        database.localContentRecords,
      )..where((row) => row.contentCode.equals('OLD_Q_001'))).getSingle();
      expect(oldContent.snapshotState, 'CURRENT');

      final stagedContent = await (database.select(
        database.localContentRecords,
      )..where((row) => row.contentCode.equals('JAVA_Q_001'))).getSingle();
      expect(stagedContent.snapshotState, 'STAGED');
      expect(
        await (database.select(
          database.contentCatalogReads,
        )..where((row) => row.contentCode.equals('JAVA_Q_001'))).get(),
        hasLength(1),
      );

      final visible = await database.customSelect('''
        SELECT r.content_code
        FROM content_catalog_reads r
        INNER JOIN local_content_records l
          ON l.content_code = r.content_code
         AND l.content_type = r.content_type
         AND l.revision = r.revision
        WHERE l.snapshot_state = 'CURRENT'
        ORDER BY r.content_code
      ''').get();
      expect(
        visible.map((row) => row.read<String>('content_code')).toList(),
        <String>['OLD_Q_001'],
      );
    },
  );

  test('payload mismatch fails before any local pack staging', () async {
    final target = _targetPack();
    final root = _root(contentVersion: 109, pack: target);
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
    await _prepareRun(journal, plan);

    final executor = DriftSyncPlanExecutor(
      database,
      _PackGateway(_packManifest(target)),
      const _PayloadGateway(mismatched: true),
      now: () => now,
    );
    final result = await executor.execute(runId: 'run-1', plan: plan);

    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure.code,
      'CONTENT_PAYLOAD_MISMATCH',
    );
    expect(await database.select(database.contentPackRevisions).get(), isEmpty);
    expect(await database.select(database.localContentRecords).get(), isEmpty);
    expect(await database.select(database.contentCatalogReads).get(), isEmpty);
  });
}

Future<void> _prepareRun(DriftSyncJournal journal, SyncPlan plan) async {
  final started = await journal.startOrCoalesce(
    runId: 'run-1',
    trigger: SyncTrigger.startup,
    translationLocale: 'kk',
  );
  expect(started, isA<Success<SyncRunStart>>());
  final persisted = await journal.persistPlan(runId: 'run-1', plan: plan);
  expect(persisted, isA<Success<void>>());
}

PackRevisionRef _targetPack() {
  return PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: 8,
    checksum: _packHash,
  );
}

RootContentManifest _root({
  required int contentVersion,
  required PackRevisionRef pack,
  Iterable<ContentTombstone> tombstones = const <ContentTombstone>[],
}) {
  return RootContentManifest(
    schemaVersion: 1,
    contentVersion: contentVersion,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 30, 12),
    checksum: contentVersion == 108 ? _root108 : _root109,
    packs: <PackRevisionRef>[pack],
    tombstones: tombstones,
  );
}

PackContentManifest _packManifest(PackRevisionRef target) {
  final identity = ContentIdentity(
    code: 'JAVA_Q_001',
    type: ContentType.interview,
  );
  return PackContentManifest(
    schemaVersion: 1,
    identity: target.identity,
    revision: target.revision,
    checksum: target.checksum,
    contents: <PackContentRef>[
      PackContentRef(
        identity: identity,
        revision: 1,
        checksum: _contentHash,
        sortOrder: 1,
        publishedAt: DateTime.utc(2026, 10, 30, 12),
      ),
    ],
    assets: <ManifestAssetDescriptor>[
      ManifestAssetDescriptor(
        assetId: 'audio-1',
        checksumSha256: _assetHash,
        deliveryKey: 'audio/java_q_001.mp3',
        sizeBytes: 128,
        mediaType: 'audio/mpeg',
        requiredOffline: true,
      ),
    ],
    contentAssets: <ContentAssetRef>[
      ContentAssetRef(
        contentIdentity: identity,
        contentRevision: 1,
        assetId: 'audio-1',
        role: 'promptAudio',
      ),
    ],
  );
}

Future<void> _seedCurrentSnapshot(
  CareerSpeakDatabase database,
  DateTime now,
) async {
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
          packCode: 'OLD_PACK',
          variantKey: 'canonical',
          revision: 1,
          schemaVersion: 1,
          checksum: _root108,
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
          contentCode: 'OLD_Q_001',
          contentType: 'INTERVIEW',
          revision: 1,
          checksum: _contentHash,
          snapshotState: 'CURRENT',
          sourceSchemaVersion: 1,
          createdAt: now,
        ),
      );
  await database
      .into(database.contentCatalogReads)
      .insert(
        ContentCatalogReadsCompanion.insert(
          contentCode: 'OLD_Q_001',
          contentType: 'INTERVIEW',
          revision: 1,
          checksum: _contentHash,
          title: 'Old question',
          subtitle: 'Previous revision',
          description: 'Last-known-good learner payload',
          category: 'Java Backend',
          level: 'Senior',
          minutes: 5,
          hasAudio: true,
          createdAt: now,
        ),
      );
  await database
      .into(database.packContentRefs)
      .insert(
        PackContentRefsCompanion.insert(
          packCode: 'OLD_PACK',
          variantKey: 'canonical',
          packRevision: 1,
          contentCode: 'OLD_Q_001',
          contentType: 'INTERVIEW',
          contentRevision: 1,
        ),
      );
}

final class _PackGateway implements ContentManifestGateway {
  const _PackGateway(this.pack);

  final PackContentManifest pack;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    return const FailureResult(
      ApplicationFailure(code: 'NOT_USED', message: 'Root fetch is not used.'),
    );
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    return Success(pack);
  }
}

final class _PayloadGateway implements ContentPayloadGateway {
  const _PayloadGateway({this.mismatched = false});

  final bool mismatched;

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async {
    final ref = ContentPayloadRef(
      identity: target.identity,
      revision: target.revision,
      checksum: mismatched ? _root108 : target.checksum,
    );
    return Success<ContentPayload>(
      ContentPayload.typed(
        ref: ref,
        title: 'Dependency Injection',
        subtitle: 'Java Backend',
        description: 'Explain constructor injection and its tradeoffs.',
        categoryCode: 'JAVA_BACKEND',
        category: 'Java Backend',
        levelCode: 'SENIOR',
        level: 'Senior',
        minutes: 6,
        hasAudio: true,
        skillCodes: const <String>['COMMUNICATION', 'SYSTEM_DESIGN'],
        body: InterviewBody(
          prompt: 'What is dependency injection?',
          modelAnswer: 'Dependencies are supplied externally.',
          keyPoints: const <String>['loose coupling', 'testability'],
        ),
      ),
    );
  }
}
