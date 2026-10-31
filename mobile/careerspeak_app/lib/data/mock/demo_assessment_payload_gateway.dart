import '../../application/ports/assessment_payload_gateway.dart';
import '../../application/result/result.dart';
import '../../domain/assessment.dart';
import 'demo_learning_fixture.dart';

final class DemoAssessmentPayloadGateway implements AssessmentPayloadGateway {
  DemoAssessmentPayloadGateway({
    Iterable<PracticeTestRevision>? practiceTests,
    Iterable<AssessmentQuestionRevision>? questions,
    this.latency = const Duration(milliseconds: 120),
  }) : _practiceTests = <String, PracticeTestRevision>{
         for (final test in practiceTests ?? buildDemoPracticeTests())
           _testKey(test.practiceTestCode, test.revision, test.checksum): test,
       },
       _questions = <QuestionRevisionId, AssessmentQuestionRevision>{
         for (final question in questions ?? buildDemoAssessmentQuestions())
           question.id: question,
       };

  final Map<String, PracticeTestRevision> _practiceTests;
  final Map<QuestionRevisionId, AssessmentQuestionRevision> _questions;
  final Duration latency;

  @override
  Future<Result<PracticeTestRevision>> fetchPracticeTestRevision({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final value = _practiceTests[_testKey(practiceTestCode, revision, checksum)];
    if (value == null) {
      return FailureResult<PracticeTestRevision>(
        ApplicationFailure(
          code: 'DEMO_PRACTICE_TEST_NOT_FOUND',
          message: 'Demo backend has no exact practice-test revision.',
          details: <String, Object?>{
            'practiceTestCode': practiceTestCode,
            'revision': revision,
          },
        ),
      );
    }
    return Success<PracticeTestRevision>(value);
  }

  @override
  Future<Result<AssessmentQuestionRevision>> fetchQuestionRevision(
    QuestionRevisionId target,
  ) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final value = _questions[target];
    if (value == null) {
      return FailureResult<AssessmentQuestionRevision>(
        ApplicationFailure(
          code: 'DEMO_QUESTION_NOT_FOUND',
          message: 'Demo backend has no exact assessment-question revision.',
          details: <String, Object?>{
            'questionCode': target.questionCode,
            'revision': target.revision,
          },
        ),
      );
    }
    return Success<AssessmentQuestionRevision>(value);
  }

  static String _testKey(String code, int revision, String checksum) =>
      '$code|$revision|$checksum';
}
