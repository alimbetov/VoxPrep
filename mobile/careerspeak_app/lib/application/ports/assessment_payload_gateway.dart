import '../../domain/assessment.dart';
import '../result/result.dart';

abstract interface class AssessmentPayloadGateway {
  Future<Result<PracticeTestRevision>> fetchPracticeTestRevision({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  });

  Future<Result<AssessmentQuestionRevision>> fetchQuestionRevision(
    QuestionRevisionId target,
  );
}
