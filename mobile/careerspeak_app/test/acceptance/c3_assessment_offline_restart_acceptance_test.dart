import 'dart:io';

import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/ports/assessment_payload_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart'
    hide PracticeTestQuestionRef;
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:careerspeak_app/domain/assessment_bundle.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _testChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _q1Checksum =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _q2Checksum =
    '2222222222222222222222222222222222222222222222222222222222222222';

void main() {
  test('online exact assessment survives restart and resolves offline', () async {
    final directory = await Directory.systemTemp.createTemp(
      'careerspeak-c3-assessment-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/assessment.sqlite');
    final source = _sourceBundle();

    var database = CareerSpeakDatabase(NativeDatabase(file));
    var repository = DriftAssessmentRevisionRepository(database);
    final onlineGateway = _FakeAssessmentGateway(bundle: source);
    var loader = AssessmentRevisionLoader(
      gateway: onlineGateway,
      repository: repository,
    );

    final online = await loader.load(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 4,
      checksum: _testChecksum,
    );
    final onlineBundle = (online as Success<AssessmentRevisionBundle>).value;
    final onlineScore = _score(onlineBundle);
    expect(onlineScore.scoreBasisPoints, 6666);
    expect(onlineGateway.practiceTestCalls, 1);
    expect(onlineGateway.questionCalls, 2);

    await database.close();

    database = CareerSpeakDatabase(NativeDatabase(file));
    addTearDown(database.close);
    repository = DriftAssessmentRevisionRepository(database);
    final offlineGateway = _OfflineAssessmentGateway();
    loader = AssessmentRevisionLoader(
      gateway: offlineGateway,
      repository: repository,
    );

    final offline = await loader.load(
      practiceTestCode: 'INTERVIEW_CORE',
      revision: 4,
      checksum: _testChecksum,
    );
    final offlineBundle = (offline as Success<AssessmentRevisionBundle>).value;
    final offlineScore = _score(offlineBundle);

    expect(offlineScore.earnedPoints, onlineScore.earnedPoints);
    expect(offlineScore.totalPoints, onlineScore.totalPoints);
    expect(offlineScore.scoreBasisPoints, onlineScore.scoreBasisPoints);
    expect(offlineScore.passed, onlineScore.passed);
    expect(offlineGateway.calls, 0);
  });
}

AssessmentScore _score(AssessmentRevisionBundle bundle) {
  return const AssessmentScorer().score(
    test: bundle.test,
    questions: bundle.questions,
    answersByOrder: const {0: 0, 1: 1},
  );
}

AssessmentRevisionBundle _sourceBundle() {
  final q1 = QuestionRevisionId(
    questionCode: 'Q1',
    revision: 1,
    checksum: _q1Checksum,
  );
  final q2 = QuestionRevisionId(
    questionCode: 'Q2',
    revision: 2,
    checksum: _q2Checksum,
  );
  final test = PracticeTestRevision(
    practiceTestCode: 'INTERVIEW_CORE',
    revision: 4,
    checksum: _testChecksum,
    title: 'Core interview',
    subtitle: 'Qualification',
    mode: AssessmentMode.exam,
    passingScoreBasisPoints: 6000,
    questionRefs: [
      PracticeTestQuestionRef(order: 0, question: q1, points: 1),
      PracticeTestQuestionRef(order: 1, question: q2, points: 2),
    ],
  );
  return AssessmentRevisionBundle(
    test: test,
    questions: [
      AssessmentQuestionRevision(
        id: q1,
        body: SingleChoiceQuestionBody(
          prompt: 'What does idempotent mean?',
          options: ['Safe retry', 'Always asynchronous'],
          correctOptionIndex: 0,
          skillCode: 'BACKEND_RELIABILITY',
          explanation: 'Repeating the same operation preserves the result.',
        ),
      ),
      AssessmentQuestionRevision(
        id: q2,
        body: SingleChoiceQuestionBody(
          prompt: 'Which boundary owns transaction atomicity?',
          options: ['Repository transaction', 'Widget tree'],
          correctOptionIndex: 0,
          skillCode: 'BACKEND_TRANSACTIONS',
          explanation: 'Atomicity belongs to the persistence transaction.',
        ),
      ),
    ],
  );
}

final class _FakeAssessmentGateway implements AssessmentPayloadGateway {
  _FakeAssessmentGateway({required this.bundle});

  final AssessmentRevisionBundle bundle;
  var practiceTestCalls = 0;
  var questionCalls = 0;

  @override
  Future<Result<PracticeTestRevision>> fetchPracticeTestRevision({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) async {
    practiceTestCalls++;
    return Success<PracticeTestRevision>(bundle.test);
  }

  @override
  Future<Result<AssessmentQuestionRevision>> fetchQuestionRevision(
    QuestionRevisionId target,
  ) async {
    questionCalls++;
    return Success<AssessmentQuestionRevision>(
      bundle.questions.singleWhere((question) => question.id == target),
    );
  }
}

final class _OfflineAssessmentGateway implements AssessmentPayloadGateway {
  var calls = 0;

  @override
  Future<Result<PracticeTestRevision>> fetchPracticeTestRevision({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) async {
    calls++;
    return const FailureResult<PracticeTestRevision>(
      ApplicationFailure(
        code: 'OFFLINE',
        message: 'Network must not be used for a cached exact revision.',
      ),
    );
  }

  @override
  Future<Result<AssessmentQuestionRevision>> fetchQuestionRevision(
    QuestionRevisionId target,
  ) async {
    calls++;
    return const FailureResult<AssessmentQuestionRevision>(
      ApplicationFailure(
        code: 'OFFLINE',
        message: 'Network must not be used for a cached exact revision.',
      ),
    );
  }
}
