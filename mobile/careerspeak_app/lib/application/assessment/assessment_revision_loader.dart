import '../../domain/assessment.dart';
import '../../domain/assessment_bundle.dart';
import '../ports/assessment_payload_gateway.dart';
import '../ports/assessment_revision_repository.dart';
import '../result/result.dart';

final class AssessmentRevisionLoader {
  factory AssessmentRevisionLoader({
    required AssessmentPayloadGateway gateway,
    required AssessmentRevisionRepository repository,
  }) {
    return AssessmentRevisionLoader._(gateway, repository);
  }

  const AssessmentRevisionLoader._(this._gateway, this._repository);

  final AssessmentPayloadGateway _gateway;
  final AssessmentRevisionRepository _repository;

  Future<Result<AssessmentRevisionBundle>> load({
    required String practiceTestCode,
    required int revision,
    required String checksum,
  }) async {
    final local = await _repository.readBundle(
      practiceTestCode: practiceTestCode,
      revision: revision,
      checksum: checksum,
    );
    if (local case FailureResult<AssessmentRevisionBundle?>(:final failure)) {
      return FailureResult<AssessmentRevisionBundle>(failure);
    }
    final cached = (local as Success<AssessmentRevisionBundle?>).value;
    if (cached != null) {
      return Success<AssessmentRevisionBundle>(cached);
    }

    final testResult = await _gateway.fetchPracticeTestRevision(
      practiceTestCode: practiceTestCode,
      revision: revision,
      checksum: checksum,
    );
    if (testResult case FailureResult<PracticeTestRevision>(:final failure)) {
      return FailureResult<AssessmentRevisionBundle>(failure);
    }
    final test = (testResult as Success<PracticeTestRevision>).value;

    final questions = <AssessmentQuestionRevision>[];
    for (final ref in test.questionRefs) {
      final questionResult = await _gateway.fetchQuestionRevision(ref.question);
      if (questionResult case FailureResult<AssessmentQuestionRevision>(
        :final failure,
      )) {
        return FailureResult<AssessmentRevisionBundle>(failure);
      }
      questions.add(
        (questionResult as Success<AssessmentQuestionRevision>).value,
      );
    }

    final AssessmentRevisionBundle bundle;
    try {
      bundle = AssessmentRevisionBundle(test: test, questions: questions);
    } on ArgumentError catch (error) {
      return FailureResult<AssessmentRevisionBundle>(
        ApplicationFailure(
          code: 'ASSESSMENT_BUNDLE_INVALID',
          message: 'The exact assessment payload set is internally inconsistent.',
          details: <String, Object?>{'error': error.toString()},
        ),
      );
    }

    return _repository.saveBundle(bundle);
  }
}
