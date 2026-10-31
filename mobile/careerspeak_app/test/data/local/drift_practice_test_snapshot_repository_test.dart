import 'package:careerspeak_app/application/query/practice_test_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart'
    hide PracticeTestQuestionRef;
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_repository.dart';
import 'package:careerspeak_app/data/local/publication_snapshot_storage.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:careerspeak_app/domain/assessment_bundle.dart';
import 'package:careerspeak_app/domain/practice_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _testV1 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _testV2 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _questionV1 =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _questionV2 =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _root108 =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const _root109 =
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

void main() {
  late CareerSpeakDatabase database;
  late DriftAssessmentRevisionRepository assessmentRepository;
  late DriftPracticeTestRepository repository;

  setUp(() async {
    database = createTestDatabase();
    await PublicationSnapshotStorage(database).ensureReady();
    assessmentRepository = DriftAssessmentRevisionRepository(database);
    repository = DriftPracticeTestRepository(database, assessmentRepository);

    await assessmentRepository.saveBundle(
      _bundle(
        revision: 1,
        testChecksum: _testV1,
        questionRevision: 1,
        questionChecksum: _questionV1,
        title: 'Snapshot 108 test',
      ),
    );
    await assessmentRepository.saveBundle(
      _bundle(
        revision: 2,
        testChecksum: _testV2,
        questionRevision: 2,
        questionChecksum: _questionV2,
        title: 'Snapshot 109 test',
      ),
    );

    final now = DateTime.utc(2026, 10, 31, 16);
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
    await database.customStatement(
      '''
      INSERT INTO publication_practice_test_refs
        (content_version, practice_test_code, revision, checksum)
      VALUES (?, ?, ?, ?), (?, ?, ?, ?)
      ''',
      <Object?>[108, 'JAVA_TEST', 1, _testV1, 109, 'JAVA_TEST', 2, _testV2],
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'does not select a newer cached revision outside CURRENT snapshot',
    () async {
      final current = (await repository.getByCode('JAVA_TEST')).getOrThrow();

      expect(current, isNotNull);
      expect(current!.title, 'Snapshot 108 test');
      expect(current.questions.single.prompt, contains('revision 1'));

      final page =
          (await repository.watchTests(const PracticeTestQuery()).first)
              .getOrThrow();
      expect(page.items, hasLength(1));
      expect(page.items.single.title, 'Snapshot 108 test');
    },
  );

  test(
    'one root pointer switch exposes the next exact test revision',
    () async {
      await (database.update(
        database.contentManifestStates,
      )..where((row) => row.id.equals(1))).write(
        ContentManifestStatesCompanion(
          currentContentVersion: const Value(109),
          currentManifestChecksum: const Value(_root109),
          updatedAt: Value(DateTime.utc(2026, 10, 31, 16, 1)),
        ),
      );

      final current = (await repository.getByCode('JAVA_TEST')).getOrThrow();

      expect(current, isNotNull);
      expect(current!.title, 'Snapshot 109 test');
      expect(current.questions.single.prompt, contains('revision 2'));
    },
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
  final question = AssessmentQuestionRevision(
    id: questionId,
    body: SingleChoiceQuestionBody(
      prompt: 'Question revision $questionRevision',
      options: const <String>['A', 'B'],
      correctOptionIndex: 0,
      skillCode: 'JAVA',
      explanation: 'Because A is correct.',
    ),
  );
  final test = PracticeTestRevision(
    practiceTestCode: 'JAVA_TEST',
    revision: revision,
    checksum: testChecksum,
    title: title,
    subtitle: 'Exact snapshot assessment',
    mode: AssessmentMode.exam,
    passingScoreBasisPoints: 7000,
    questionRefs: <PracticeTestQuestionRef>[
      PracticeTestQuestionRef(order: 0, question: questionId, points: 1),
    ],
  );
  return AssessmentRevisionBundle(
    test: test,
    questions: <AssessmentQuestionRevision>[question],
  );
}
