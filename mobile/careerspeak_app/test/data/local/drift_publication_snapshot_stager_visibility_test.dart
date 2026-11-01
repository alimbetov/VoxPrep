import 'dart:convert';

import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/ports/assessment_payload_gateway.dart';
import 'package:careerspeak_app/application/ports/catalogue_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart'
    hide PracticeTestQuestionRef;
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/local/drift_catalogue_snapshot_repository.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_repository.dart';
import 'package:careerspeak_app/data/local/drift_publication_snapshot_stager.dart';
import 'package:careerspeak_app/data/local/publication_snapshot_storage.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:careerspeak_app/domain/assessment_bundle.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  test(
    'C4 staging stays invisible until one CURRENT root switch exposes exact refs',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      await PublicationSnapshotStorage(database).ensureReady();

      final assessmentRepository = DriftAssessmentRevisionRepository(database);
      await assessmentRepository.saveBundle(
        _bundle(
          revision: 1,
          testChecksum: _testV1,
          questionRevision: 1,
          questionChecksum: _questionV1,
          title: 'Publication v1 test',
        ),
      );
      await assessmentRepository.saveBundle(
        _bundle(
          revision: 2,
          testChecksum: _testV2,
          questionRevision: 2,
          questionChecksum: _questionV2,
          title: 'Publication v2 test',
        ),
      );

      final now = DateTime.utc(2026, 11, 1, 10);
      await database.into(database.contentManifestStates).insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 1,
          currentContentVersion: 1,
          currentManifestChecksum: _rootV1,
          updatedAt: now,
        ),
      );
      await database.customStatement(
        '''
        INSERT INTO publication_practice_test_refs
          (content_version, practice_test_code, revision, checksum)
        VALUES (?, ?, ?, ?)
        ''',
        <Object?>[1, 'JAVA_TEST', 1, _testV1],
      );
      await _seedCatalogueV1(database, now);

      final targetCatalogueRef = CatalogueRevisionRef(
        kind: CatalogueKind.categories,
        revision: 2,
        checksum: _catalogueV2,
      );
      final target = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 2,
        minimumAppContractVersion: 1,
        publishedAt: now.add(const Duration(minutes: 1)),
        checksum: _rootV2,
        packs: const <PackRevisionRef>[],
        practiceTests: <PracticeTestRevisionRef>[
          PracticeTestRevisionRef(
            practiceTestCode: 'JAVA_TEST',
            revision: 2,
            checksum: _testV2,
          ),
        ],
        catalogues: <CatalogueRevisionRef>[targetCatalogueRef],
        tombstones: const <ContentTombstone>[],
      );

      final stager = DriftPublicationSnapshotStager(
        database,
        AssessmentRevisionLoader(
          gateway: const _NeverAssessmentGateway(),
          repository: assessmentRepository,
        ),
        _CatalogueGateway(
          CataloguePayload(
            ref: targetCatalogueRef,
            items: const <Object>[
              <String, Object?>{
                'code': 'JAVA_BACKEND',
                'label': 'Java v2',
                'sortOrder': 0,
                'active': true,
              },
            ],
            wireJson: <String, Object?>{
              'kind': CatalogueKind.categories.wireName,
              'revision': 2,
              'checksum': _catalogueV2,
              'items': const <Object>[
                <String, Object?>{
                  'code': 'JAVA_BACKEND',
                  'label': 'Java v2',
                  'sortOrder': 0,
                  'active': true,
                },
              ],
            },
          ),
        ),
        now: () => now.add(const Duration(minutes: 1)),
      );

      expect(await stager.stage(target), isA<Success<void>>());

      final practiceRepository = DriftPracticeTestRepository(
        database,
        assessmentRepository,
      );
      final catalogueRepository = DriftCatalogueSnapshotRepository(database);

      final beforeTest = (await practiceRepository.getByCode('JAVA_TEST'))
          .getOrThrow();
      final beforeCatalogue = (await catalogueRepository.readCurrent(
        CatalogueKind.categories,
      )).getOrThrow();

      expect(beforeTest, isNotNull);
      expect(beforeTest!.title, 'Publication v1 test');
      expect(beforeCatalogue, isNotNull);
      expect(beforeCatalogue!.ref.revision, 1);
      expect(
        (beforeCatalogue.items.single as Map<String, dynamic>)['label'],
        'Java v1',
      );

      final stagedTestRefs = await database.customSelect(
        'SELECT revision FROM publication_practice_test_refs '
        'WHERE content_version = 2 AND practice_test_code = ?',
        variables: <Variable<Object>>[const Variable<String>('JAVA_TEST')],
      ).get();
      final stagedCatalogueRefs = await database.customSelect(
        'SELECT revision FROM publication_catalogue_refs '
        'WHERE content_version = 2 AND catalogue_kind = ?',
        variables: <Variable<Object>>[
          Variable<String>(CatalogueKind.categories.wireName),
        ],
      ).get();
      expect(stagedTestRefs.single.read<int>('revision'), 2);
      expect(stagedCatalogueRefs.single.read<int>('revision'), 2);

      await (database.update(database.contentManifestStates)
            ..where((row) => row.id.equals(1)))
          .write(
        ContentManifestStatesCompanion(
          currentContentVersion: const Value(2),
          currentManifestChecksum: const Value(_rootV2),
          updatedAt: Value(now.add(const Duration(minutes: 2))),
        ),
      );

      final afterTest = (await practiceRepository.getByCode('JAVA_TEST'))
          .getOrThrow();
      final afterCatalogue = (await catalogueRepository.readCurrent(
        CatalogueKind.categories,
      )).getOrThrow();

      expect(afterTest, isNotNull);
      expect(afterTest!.title, 'Publication v2 test');
      expect(afterCatalogue, isNotNull);
      expect(afterCatalogue!.ref.revision, 2);
      expect(
        (afterCatalogue.items.single as Map<String, dynamic>)['label'],
        'Java v2',
      );
    },
  );
}

Future<void> _seedCatalogueV1(
  CareerSpeakDatabase database,
  DateTime now,
) async {
  final payload = <String, Object?>{
    'kind': CatalogueKind.categories.wireName,
    'revision': 1,
    'checksum': _catalogueV1,
    'items': const <Object>[
      <String, Object?>{
        'code': 'JAVA_BACKEND',
        'label': 'Java v1',
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
      1,
      _catalogueV1,
      jsonEncode(payload),
      now.millisecondsSinceEpoch,
    ],
  );
  await database.customStatement(
    '''
    INSERT INTO publication_catalogue_refs
      (content_version, catalogue_kind, revision, checksum)
    VALUES (?, ?, ?, ?)
    ''',
    <Object?>[1, CatalogueKind.categories.wireName, 1, _catalogueV1],
  );
}

AssessmentRevisionBundle _bundle({
  required int revision,
  required String testChecksum,
  required int questionRevision,
  required String questionChecksum,
  required String title,
}) {
  final questionId = QuestionRevisionId(
    questionCode: 'JAVA_Q',
    revision: questionRevision,
    checksum: questionChecksum,
  );
  return AssessmentRevisionBundle(
    test: PracticeTestRevision(
      practiceTestCode: 'JAVA_TEST',
      revision: revision,
      checksum: testChecksum,
      title: title,
      subtitle: 'Exact publication assessment',
      mode: AssessmentMode.exam,
      passingScoreBasisPoints: 7000,
      questionRefs: <PracticeTestQuestionRef>[
        PracticeTestQuestionRef(order: 0, question: questionId, points: 1),
      ],
    ),
    questions: <AssessmentQuestionRevision>[
      AssessmentQuestionRevision(
        id: questionId,
        body: SingleChoiceQuestionBody(
          prompt: 'Question revision $questionRevision',
          options: const <String>['A', 'B'],
          correctOptionIndex: 0,
          skillCode: 'JAVA',
          explanation: 'Because A is correct.',
        ),
      ),
    ],
  );
}

final class _CatalogueGateway implements CataloguePayloadGateway {
  const _CatalogueGateway(this.payload);

  final CataloguePayload payload;

  @override
  Future<Result<CataloguePayload>> fetch(CatalogueRevisionRef target) async {
    expect(target.kind, payload.ref.kind);
    expect(target.revision, payload.ref.revision);
    expect(target.checksum, payload.ref.checksum);
    return Success<CataloguePayload>(payload);
  }
}

final class _NeverAssessmentGateway implements AssessmentPayloadGateway {
  const _NeverAssessmentGateway();

  @override
  Future<Result<PracticeTestRevision>> fetchPracticeTestRevision({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) {
    throw StateError('exact assessment revision must already be cached');
  }

  @override
  Future<Result<AssessmentQuestionRevision>> fetchQuestionRevision(
    QuestionRevisionId target,
  ) {
    throw StateError('exact assessment question must already be cached');
  }
}

const _rootV1 =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _rootV2 =
    '2222222222222222222222222222222222222222222222222222222222222222';
const _testV1 =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _testV2 =
    '4444444444444444444444444444444444444444444444444444444444444444';
const _questionV1 =
    '5555555555555555555555555555555555555555555555555555555555555555';
const _questionV2 =
    '6666666666666666666666666666666666666666666666666666666666666666';
const _catalogueV1 =
    '7777777777777777777777777777777777777777777777777777777777777777';
const _catalogueV2 =
    '8888888888888888888888888888888888888888888888888888888888888888';
