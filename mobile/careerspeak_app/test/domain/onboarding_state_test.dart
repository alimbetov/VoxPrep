import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:careerspeak_app/domain/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OnboardingState', () {
    test('fresh install starts at learning direction', () {
      expect(
        OnboardingState.initial.nextStep(LearnerSelection.empty),
        OnboardingStep.learningDirection,
      );
    });

    test('selected goal resumes at English level', () {
      expect(
        OnboardingState.initial.nextStep(
          LearnerSelection(selectedGoalCode: 'GOAL_A'),
        ),
        OnboardingStep.englishLevel,
      );
    });

    test('explicit Not sure resumes at support language', () {
      expect(
        OnboardingState.initial.nextStep(
          LearnerSelection(
            selectedGoalCode: 'GOAL_A',
            levelDecisionMade: true,
          ),
        ),
        OnboardingStep.supportLanguage,
      );
    });

    test('completed onboarding never reopens regardless of selection', () {
      const completed = OnboardingState(completed: true, generation: 4);
      expect(
        completed.nextStep(LearnerSelection.empty),
        OnboardingStep.complete,
      );
    });
  });
}
