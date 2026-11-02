import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LearnerSelection', () {
    test('starts empty with generation zero', () {
      final selection = LearnerSelection.empty;

      expect(selection.selectedGoalCode, isNull);
      expect(selection.selectedTrackCode, isNull);
      expect(selection.selfAssessedLevelCode, isNull);
      expect(selection.levelDecisionMade, isFalse);
      expect(selection.generation, 0);
    });

    test('track requires goal', () {
      expect(
        () => LearnerSelection(selectedTrackCode: 'JAVA_TRACK'),
        throwsArgumentError,
      );
    });

    test('level code requires explicit level decision', () {
      expect(
        () => LearnerSelection(selfAssessedLevelCode: 'B2'),
        throwsArgumentError,
      );
    });

    test('Not sure is represented by decision made with null level', () {
      final selection = LearnerSelection(levelDecisionMade: true);

      expect(selection.levelDecisionMade, isTrue);
      expect(selection.selfAssessedLevelCode, isNull);
    });

    test('clearing goal also clears track', () {
      final selection = LearnerSelection(
        selectedGoalCode: 'JOB_INTERVIEW',
        selectedTrackCode: 'JAVA_SENIOR',
      );

      final cleared = selection.copyWith(clearSelectedGoal: true);

      expect(cleared.selectedGoalCode, isNull);
      expect(cleared.selectedTrackCode, isNull);
    });

    test('generation cannot be negative', () {
      expect(() => LearnerSelection(generation: -1), throwsArgumentError);
    });
  });
}
