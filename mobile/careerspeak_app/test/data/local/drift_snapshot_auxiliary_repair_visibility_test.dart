import 'dart:async';

import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/ports/assessment_payload_gateway.dart';
import 'package:careerspeak_app/application/ports/catalogue_payload_gateway.dart';
import 'package:careerspeak_app/application/query/page.dart';
import 'package:careerspeak_app/application/query/practice_test_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart'
    hide PracticeTestQuestionRef;
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_repository.dart';
import 'package:careerspeak_app/data/local/drift_publication_snapshot_stager.dart';
import 'package:careerspeak_app/data/local/publication_snapshot_storage.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:careerspeak_app/domain/assessment_bundle.dart';
import 'package:careerspeak_app/domain/practice_test.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _root =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _test =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _question =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  test(
    'same-version auxiliary repair invalidates an active learner stream',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      await PublicationSnapshotStorage(database).ensureReady();

      final now = DateTime.utc(2026, 10, 31, 18);
      await database
          .into(database.contentManifestStates)
          .insert(
            ContentManifestStatesCompanion.insert(
              id: const Value(1),
              schemaVersion: 1,
              currentContentVersion: 108,
              currentManifestChecksum: _root,
              updatedAt: now,
            ),
          );

      final assessmentRepository = DriftAssessmentRevisionRepository(database);
      await assessmentRepository.saveBundle(_bundle());

      final learnerRepository = DriftPracticeTestRepository(
        database,
        assessmentRepository,
      );
      final iterator = StreamIterator<Result<Page<PracticeTestSummary>>>(
        learnerRepository.watchTests(const PracticeTestQuery()),
      );
      addTearDown(iterator.cancel);

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current.getOrThrow().items, isEmpty);

      final loader = AssessmentRevisionLoader(
        gateway: const _UnusedAssessmentGateway(),
        repository: assessmentRepository,
      );
      final stager = DriftPublicationSnapshotStager(
        database,
        loader,
        const _UnusedCatalogueGateway(),
        now: () => now.add(const Duration(minutes: 1)),
      );
      final target = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 108,
        minimumAppContractVersion: 1,
        publishedAt: now,
        checksum: _root,
        packs: const <PackRevisionRef>[],
        practiceTests: <PracticeTestRevisionRef>[
          PracticeTestRevisionRef(
            practiceTestCode: 'JAVA_TEST',
            revision: 1,
            checksum: _test,
          ),
        ],
        catalogues: const <CatalogueRevisionRef>[],
        tombstones: const <ContentTombstone>[],
      );

      final staged = await stager.stage(target);
      expect(staged, isA<Success<void>>());

      expect(await iterator.moveNext(), isTrue);
      final page = iterator.current.getOrThrow();
      expect(page.items, hasLength(1));
      expect(page.items.single.code, 'JAVA_TEST');
      expect(page.items.single.title, 'CURRENT repaired test');

      final root = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(root.currentContentVersion, 108);
      expect(root.currentManifestChecksum, _root);
      expect(
        root.updatedAt.millisecondsSinceEpoch,
        now.add(const Duration(minutes: 1)).millisecondsSinceEpoch,
      );
    },
  );
}

AssessmentRevisionBundle _bundle() {
  final questionId = QuestionRevisionId(
    questionCode: 'JAVA_Q',
    revision: 1,
    checksum: _question,
  );
  return AssessmentRevisionBundle(
    test: PracticeTestRevision(
      practiceTestCode: 'JAVA_TEST',
      revision: 1,
      checksum: _test,
      title: 'CURRENT repaired test',
      subtitle: 'C4.7 repair',
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
          prompt: 'What is DI?',
          options: const <String>['A', 'B'],
          correctOptionIndex: 0,
          skillCode: 'JAVA',
          explanation: 'A',
        ),
      ),
    ],
  );
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

final class _UnusedCatalogueGateway implements CataloguePayloadGateway {
  const _UnusedCatalogueGateway();

  @override
  Future<Result<CataloguePayload>> fetch(CatalogueRevisionRef target) async {
    return const FailureResult<CataloguePayload>(
      ApplicationFailure(code: 'NOT_USED', message: 'not used'),
    );
  }
}
