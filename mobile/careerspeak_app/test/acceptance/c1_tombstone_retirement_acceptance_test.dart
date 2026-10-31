import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/content_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rev1 to rev2 to tombstone survives reopen and rejects resurrection',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-c1-tombstone-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final file = File('${directory.path}/careerspeak.sqlite');

      var database = CareerSpeakDatabase(NativeDatabase(file));

      final v1 = await _publish(
        database: database,
        runId: 'c1-tombstone-v1',
        root: _root(
          contentVersion: 1,
          checksum: _rootV1,
          pack: _packRef(revision: 1, checksum: _packV1),
        ),
        pack: _packManifest(
          packRevision: 1,
          packChecksum: _packV1,
          contentRevision: 1,
          contentChecksum: _contentV1,
        ),
        payload: _payload(
          revision: 1,
          checksum: _contentV1,
          title: 'Dependency Injection v1',
        ),
      );
      expect(v1, isA<Success<void>>());
      await _expectVisible(database, revision: 1);

      final v2 = await _publish(
        database: database,
        runId: 'c1-tombstone-v2',
        root: _root(
          contentVersion: 2,
          checksum: _rootV2,
          pack: _packRef(revision: 2, checksum: _packV2),
        ),
        pack: _packManifest(
          packRevision: 2,
          packChecksum: _packV2,
          contentRevision: 2,
          contentChecksum: _contentV2,
        ),
        payload: _payload(
          revision: 2,
          checksum: _contentV2,
          title: 'Dependency Injection v2',
        ),
      );
      expect(v2, isA<Success<void>>());
      await _expectVisible(database, revision: 2);

      final retired = await _publish(
        database: database,
        runId: 'c1-tombstone-retire',
        root: _root(
          contentVersion: 3,
          checksum: _rootV3,
          tombstones: <ContentTombstone>[
            ContentTombstone(
              identity: _identity,
              revision: 2,
              reason: 'RETIRED',
            ),
          ],
        ),
      );
      expect(retired, isA<Success<void>>());
      await _expectRetired(database);

      await database.close();
      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);

      await _expectRetired(database);
      final stateAfterReopen = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(stateAfterReopen.currentContentVersion, 3);
      expect(stateAfterReopen.currentManifestChecksum, _rootV3);

      final resurrection = await _publish(
        database: database,
        runId: 'c1-tombstone-resurrection',
        root: _root(
          contentVersion: 4,
          checksum: _rootV4,
          pack: _packRef(revision: 4, checksum: _packV4),
        ),
        pack: _packManifest(
          packRevision: 4,
          packChecksum: _packV4,
          contentRevision: 3,
          contentChecksum: _contentV3,
        ),
        payload: _payload(
          revision: 3,
          checksum: _contentV3,
          title: 'Dependency Injection resurrected',
        ),
      );

      expect(resurrection, isA<FailureResult<void>>());
      expect(
        (resurrection as FailureResult<void>).failure.code,
        'CONTENT_IDENTITY_RETIRED',
      );
      await _expectRetired(database);

      final stateAfterRejectedResurrection = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(stateAfterRejectedResurrection.currentContentVersion, 3);
      expect(stateAfterRejectedResurrection.currentManifestChecksum, _rootV3);

      final revision3Rows = await (database.select(
        database.localContentRecords,
      )..where((row) => row.revision.equals(3))).get();
      expect(revision3Rows, isEmpty);
      final resurrectionPack = await (database.select(
        database.contentPackRevisions,
      )..where((row) => row.revision.equals(4))).get();
      expect(resurrectionPack, isEmpty);
    },
  );
}

Future<Result<void>> _publish({
  required CareerSpeakDatabase database,
  required String runId,
  required RootContentManifest root,
  PackContentManifest? pack,
  ContentPayload? payload,
}) async {
  final journal = DriftSyncJournal(database);
  final localResult = await journal.readLocalSnapshot();
  if (localResult case FailureResult(:final failure)) {
    return FailureResult<void>(failure);
  }

  final planResult = const ContentSyncPlanner().plan(
    local: (localResult as Success).value,
    remote: root,
  );
  if (planResult case FailureResult(:final failure)) {
    return FailureResult<void>(failure);
  }
  final plan = (planResult as Success).value;

  final start = await journal.startOrCoalesce(
    runId: runId,
    trigger: SyncTrigger.recovery,
    translationLocale: 'ru',
  );
  if (start case FailureResult(:final failure)) {
    return FailureResult<void>(failure);
  }

  final persisted = await journal.persistPlan(runId: runId, plan: plan);
  if (persisted case FailureResult<void>(:final failure)) {
    return FailureResult<void>(failure);
  }

  final executor = DriftSyncPlanExecutor(
    database,
    _ManifestGateway(pack),
    _PayloadGateway(payload),
  );
  final result = await executor.execute(runId: runId, plan: plan);
  if (result is Success<void>) {
    final terminal = await journal.transitionRun(
      runId: runId,
      state: SyncRunState.succeeded,
    );
    if (terminal case FailureResult<void>(:final failure)) {
      return FailureResult<void>(failure);
    }
  }
  return result;
}

Future<void> _expectVisible(
  CareerSpeakDatabase database, {
  required int revision,
}) async {
  final content = (await DriftContentRepository(
    database,
  ).getByIdentity(_identity)).getOrThrow();
  expect(content, isNotNull);
  expect(content!.revision, revision);
}

Future<void> _expectRetired(CareerSpeakDatabase database) async {
  final content = (await DriftContentRepository(
    database,
  ).getByIdentity(_identity)).getOrThrow();
  expect(content, isNull);

  final rows = await (database.select(database.localContentRecords)..where(
        (row) =>
            row.contentCode.equals(_identity.code) &
            row.contentType.equals('INTERVIEW'),
      ))
      .get();
  expect(rows.map((row) => row.revision).toSet(), <int>{1, 2});
  expect(rows.every((row) => row.snapshotState == 'TOMBSTONED'), isTrue);
}

RootContentManifest _root({
  required int contentVersion,
  required String checksum,
  PackRevisionRef? pack,
  Iterable<ContentTombstone> tombstones = const <ContentTombstone>[],
}) {
  return RootContentManifest(
    schemaVersion: 1,
    contentVersion: contentVersion,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 31, 5, contentVersion),
    checksum: checksum,
    packs: pack == null ? const <PackRevisionRef>[] : <PackRevisionRef>[pack],
    tombstones: tombstones,
  );
}

PackRevisionRef _packRef({required int revision, required String checksum}) {
  return PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: revision,
    checksum: checksum,
  );
}

PackContentManifest _packManifest({
  required int packRevision,
  required String packChecksum,
  required int contentRevision,
  required String contentChecksum,
}) {
  return PackContentManifest(
    schemaVersion: 1,
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: packRevision,
    checksum: packChecksum,
    contents: <PackContentRef>[
      PackContentRef(
        identity: _identity,
        revision: contentRevision,
        checksum: contentChecksum,
        sortOrder: 10,
        publishedAt: DateTime.utc(2026, 10, 31, 5, contentRevision),
      ),
    ],
    assets: const <ManifestAssetDescriptor>[],
    contentAssets: const <ContentAssetRef>[],
  );
}

ContentPayload _payload({
  required int revision,
  required String checksum,
  required String title,
}) {
  return ContentPayload(
    ref: ContentPayloadRef(
      identity: _identity,
      revision: revision,
      checksum: checksum,
    ),
    title: title,
    subtitle: 'Java Backend · Senior interview',
    description: 'Explain constructor injection and its tradeoffs.',
    categoryCode: 'JAVA_BACKEND',
    category: 'Java Backend',
    levelCode: 'SENIOR',
    level: 'Senior',
    minutes: 8,
    hasAudio: false,
  );
}

final class _ManifestGateway implements ContentManifestGateway {
  const _ManifestGateway(this.pack);

  final PackContentManifest? pack;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    return const FailureResult<RootManifestFetch>(
      ApplicationFailure(code: 'NOT_USED', message: 'Root fetch is not used.'),
    );
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    final value = pack;
    if (value == null) {
      return const FailureResult<PackContentManifest>(
        ApplicationFailure(
          code: 'UNEXPECTED_PACK_FETCH',
          message: 'No pack should be fetched for this publication.',
        ),
      );
    }
    return Success<PackContentManifest>(value);
  }
}

final class _PayloadGateway implements ContentPayloadGateway {
  const _PayloadGateway(this.payload);

  final ContentPayload? payload;

  @override
  Future<Result<ContentPayload>> fetch(ContentPayloadRef target) async {
    final value = payload;
    if (value == null) {
      return const FailureResult<ContentPayload>(
        ApplicationFailure(
          code: 'UNEXPECTED_PAYLOAD_FETCH',
          message: 'No content payload should be fetched for this publication.',
        ),
      );
    }
    return Success<ContentPayload>(value);
  }
}

const _identity = ContentIdentity(
  code: 'JAVA_DI_001',
  type: ContentType.interview,
);

const _rootV1 =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _rootV2 =
    '2222222222222222222222222222222222222222222222222222222222222222';
const _rootV3 =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _rootV4 =
    '4444444444444444444444444444444444444444444444444444444444444444';
const _packV1 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _packV2 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _packV4 =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _contentV1 =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _contentV2 =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const _contentV3 =
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
