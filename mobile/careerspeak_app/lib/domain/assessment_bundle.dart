import 'assessment.dart';

final class AssessmentRevisionBundle {
  factory AssessmentRevisionBundle({
    required PracticeTestRevision test,
    required Iterable<AssessmentQuestionRevision> questions,
  }) {
    final byIdentity = <QuestionRevisionId, AssessmentQuestionRevision>{};
    final revisionKeys = <String>{};
    for (final question in questions) {
      final revisionKey =
          '${question.id.questionCode}\u0000${question.id.revision}';
      if (!revisionKeys.add(revisionKey)) {
        throw ArgumentError.value(
          question.id,
          'questions',
          'contains duplicate question code and revision',
        );
      }
      byIdentity[question.id] = question;
    }

    if (byIdentity.length != test.questionRefs.length) {
      throw ArgumentError.value(
        questions,
        'questions',
        'must contain exactly the test revision question set',
      );
    }

    final orderedQuestions = <AssessmentQuestionRevision>[];
    for (final ref in test.questionRefs) {
      final question = byIdentity[ref.question];
      if (question == null) {
        throw ArgumentError.value(
          ref.question,
          'questions',
          'is missing an exact referenced question revision',
        );
      }
      orderedQuestions.add(question);
    }

    return AssessmentRevisionBundle._(
      test: test,
      questions: List<AssessmentQuestionRevision>.unmodifiable(
        orderedQuestions,
      ),
    );
  }

  const AssessmentRevisionBundle._({
    required this.test,
    required this.questions,
  });

  final PracticeTestRevision test;
  final List<AssessmentQuestionRevision> questions;
}
