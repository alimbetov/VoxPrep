import 'learner_selection.dart';

enum OnboardingStep {
  learningDirection,
  englishLevel,
  supportLanguage,
  complete,
}

final class OnboardingState {
  const OnboardingState({required this.completed, required this.generation})
    : assert(generation >= 0);

  static const initial = OnboardingState(completed: false, generation: 0);

  final bool completed;
  final int generation;

  OnboardingStep nextStep(LearnerSelection selection) {
    if (completed) return OnboardingStep.complete;
    if (selection.selectedGoalCode == null) {
      return OnboardingStep.learningDirection;
    }
    if (!selection.levelDecisionMade) {
      return OnboardingStep.englishLevel;
    }
    return OnboardingStep.supportLanguage;
  }

  OnboardingState copyWith({bool? completed, int? generation}) {
    return OnboardingState(
      completed: completed ?? this.completed,
      generation: generation ?? this.generation,
    );
  }
}
