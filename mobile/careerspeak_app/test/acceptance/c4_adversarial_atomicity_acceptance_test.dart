import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/assessment_payload_gateway.dart';
import 'package:careerspeak_app/application/ports/catalogue_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/local/drift_publication_snapshot_stager.dart';
import 'package:careerspeak_app/data/local/publication_snapshot_storage.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:careerspeak_app/domain/practice_test.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_database_factory.dart';

const _rootA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _rootB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _catalogueA =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _catalogueB =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  test('C4.9 failed auxiliary fetch leaves zero partial publication membership', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await PublicationSnapshotStorage(database).ensureReady();

    final first = CatalogueRevisionRef(
      kind: CatalogueKind.categories,
      revision: 1,
      checksum: _catalogueA,
    );
    final second = CatalogueRevisionRef(
      kind: CatalogueKind.levels,
      revision: 1,
      checksum: _catalogueB,
    );
    final stager = _stager(
      database,
      _ScriptedCatalogueGateway(<CatalogueKind, Result<CataloguePayload>>{
        CatalogueKind.categories: Success(_payload(first)),
        CatalogueKind.levels: const FailureResult<CataloguePayload>(
          ApplicationFailure(code: 'SYNTHETIC_FAILURE', message: 'stop'),
        ),
      }),
    );

    final result = await stager.stage(_root(109, <CatalogueRevisionRef>[first, second]));

    expect(result, isA<FailureResult<void>>());
    expect(await _count(database, 'catalogue_revision_reads'), 0);
    expect(await _count(database, 'publication_catalogue_refs'), 0);
    expect(await _count(database, 'publication_practice_test_refs'), 0);
    expect(await _count(database, 'content_manifest_state'), 0);
  });

  test('C4.9 immutable conflict rolls back and preserves CURRENT membership', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await PublicationSnapshotStorage(database).ensureReady();

    final now = DateTime.utc(2026, 10, 31, 19);
    await database.into(database.contentManifestStates).insert(
      ContentManifestStatesCompanion.insert(
        id: const Value(1),
        schemaVersion: 1,
        currentContentVersion: 108,
        currentManifestChecksum: _rootA,
        updatedAt: now,
      ),
    );
    await database.customStatement(
      '''
      INSERT INTO catalogue_revision_reads (
        catalogue_kind, revision, checksum, payload_json, created_at
      ) VALUES (?, ?, ?, ?, ?)
      ''',
      <Object?>[
        CatalogueKind.categories.wireName,
        1,
        _catalogueA,
        '{"revision":1}',
        now.millisecondsSinceEpoch,
      ],
    );
    await database.customStatement(
      '''
      INSERT INTO publication_catalogue_refs (
        content_version, catalogue_kind, revision, checksum
      ) VALUES (?, ?, ?, ?)
      ''',
      <Object?>[108, CatalogueKind.categories.wireName, 1, _catalogueA],
    );

    final conflicting = CatalogueRevisionRef(
      kind: CatalogueKind.categories,
      revision: 1,
      checksum: _catalogueB,
    );
    final result = await _stager(
      database,
      _ScriptedCatalogueGateway(<CatalogueKind, Result<CataloguePayload>>{
        CatalogueKind.categories: Success(_payload(conflicting)),
      }),
    ).stage(_root(108, <CatalogueRevisionRef>[conflicting]));

    expect(result, isA<FailureResult<void>>());
    final rows = await database.customSelect(
      'SELECT revision, checksum FROM publication_catalogue_refs WHERE content_version = 108',
    ).get();
    expect(rows, hasLength(1));
    expect(rows.single.read<int>('revision'), 1);
    expect(rows.single.read<String>('checksum'), _catalogueA);

    final current = await database.select(database.contentManifestStates).getSingle();
    expect(current.currentContentVersion, 108);
    expect(current.currentManifestChecksum, _rootA);
    expect(current.updatedAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
  });

  test('C4.9 repeated identical stage is idempotent and duplicate-free', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await PublicationSnapshotStorage(database).ensureReady();

    final ref = CatalogueRevisionRef(
      kind: CatalogueKind.skills,
      revision: 3,
      checksum: _catalogueA,
    );
    final target = _root(109, <CatalogueRevisionRef>[ref]);
    final stager = _stager(
      database,
      _ScriptedCatalogueGateway(<CatalogueKind, Result<CataloguePayload>>{
        CatalogueKind.skills: Success(_payload(ref)),
      }),
    );

    expect(await stager.stage(target), isA<Success<void>>());
    expect(await stager.stage(target), isA<Success<void>>());

    expect(await _count(database, 'catalogue_revision_reads'), 1);
    expect(await _count(database, 'publication_catalogue_refs'), 1);
    expect(await _count(database, 'content_manifest_state'), 0);
  });
}

DriftPublicationSnapshotStager _stager(
  CareerSpeakDatabase database,
  CataloguePayloadGateway catalogueGateway,
) {
  return DriftPublicationSnapshotStager(
    database,
    AssessmentRevisionLoader(
      gateway: const _UnusedAssessmentGateway(),
      repository: DriftAssessmentRevisionRepository(database),
    ),
    catalogueGateway,
  );
}

RootContentManifest _root(
  int contentVersion,
  List<CatalogueRevisionRef> catalogues,
) {
  return RootContentManifest(
    schemaVersion: 1,
    contentVersion: contentVersion,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 31, 19),
    checksum: contentVersion == 108 ? _rootA : _rootB,
    packs: const <PackRevisionRef>[],
    practiceTests: const <PracticeTestRevisionRef>[],
    catalogues: catalogues,
    tombstones: const <ContentTombstone>[],
  );
}

CataloguePayload _payload(CatalogueRevisionRef ref) {
  return CataloguePayload(
    ref: ref,
    items: const <Object>[],
    wireJson: <String, Object?>{
      'kind': ref.kind.wireName,
      'revision': ref.revision,
      'checksum': ref.checksum,
      'items': const <Object>[],
    },
  );
}

Future<int> _count(CareerSpeakDatabase database, String table) async {
  final row = await database.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
  return row.read<int>('c');
}

final class _ScriptedCatalogueGateway implements CataloguePayloadGateway {
  const _ScriptedCatalogueGateway(this.results);

  final Map<CatalogueKind, Result<CataloguePayload>> results;

  @override
  Future<Result<CataloguePayload>> fetch(CatalogueRevisionRef target) async {
    return results[target.kind] ??
        const FailureResult<CataloguePayload>(
          ApplicationFailure(code: 'UNEXPECTED_FETCH', message: 'unexpected'),
        );
  }
}

final class _UnusedAssessmentGateway implements AssessmentPayloadGateway {
  const _UnusedAssessmentGateway();

  @override
  Future<Result<PracticeTestRevision>> fetchPracticeTestRevision({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) async {
    return const FailureResult<PracticeTestRevision>(
      ApplicationFailure(code: 'NOT_USED', message: 'not used'),
    );
  }

  @override
  Future<Result<AssessmentQuestionRevision>> fetchQuestionRevision(
    QuestionRevisionId target,
  ) async {
    return const FailureResult<AssessmentQuestionRevision>(
      ApplicationFailure(code: 'NOT_USED', message: 'not used'),
    );
  }
}
