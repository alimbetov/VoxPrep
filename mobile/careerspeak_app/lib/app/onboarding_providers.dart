import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/onboarding_state_repository.dart';
import '../application/result/result.dart';
import '../data/local/drift_onboarding_state_repository.dart';
import '../domain/learner_selection.dart';
import '../domain/onboarding_state.dart';
import 'learner_selection_providers.dart';
import 'learner_state_providers.dart';

final onboardingStateRepositoryProvider = Provider<OnboardingStateRepository>((
  ref,
) {
  return DriftOnboardingStateRepository(ref.watch(careerSpeakDatabaseProvider));
});

final onboardingStateProvider = StreamProvider<OnboardingState>((ref) {
  return ref
      .watch(onboardingStateRepositoryProvider)
      .watchState()
      .map((result) => result.getOrThrow());
});

final onboardingStepProvider = Provider<AsyncValue<OnboardingStep>>((ref) {
  final state = ref.watch(onboardingStateProvider);
  final selection = ref.watch(learnerSelectionProvider);
  return state.when(
    data: (onboarding) => selection.whenData(onboarding.nextStep),
    loading: () => const AsyncLoading<OnboardingStep>(),
    error: (error, stack) => AsyncError<OnboardingStep>(error, stack),
  );
});

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref.watch(onboardingStateRepositoryProvider));
});

final class OnboardingController {
  const OnboardingController(this._repository);

  final OnboardingStateRepository _repository;

  Future<Result<OnboardingState>> complete() => _setCompleted(true);

  Future<Result<OnboardingState>> skip() => _setCompleted(true);

  Future<Result<OnboardingState>> _setCompleted(bool completed) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final currentResult = await _repository.getState();
      if (currentResult case FailureResult<OnboardingState>()) {
        return currentResult;
      }
      final current = (currentResult as Success<OnboardingState>).value;
      if (current.completed == completed) {
        return Success<OnboardingState>(current);
      }
      final write = await _repository.compareAndSet(
        expectedGeneration: current.generation,
        completed: completed,
      );
      if (write case Success<OnboardingState>()) return write;
      if (write is! FailureResult<OnboardingState> ||
          write.failure.code != 'ONBOARDING_STATE_CONFLICT') {
        return write;
      }
    }
    return const FailureResult<OnboardingState>(
      ApplicationFailure(
        code: 'ONBOARDING_STATE_CONFLICT',
        message: 'Onboarding state changed repeatedly.',
        retryable: true,
      ),
    );
  }
}

OnboardingStep deriveOnboardingStep({
  required OnboardingState onboarding,
  required LearnerSelection selection,
}) {
  return onboarding.nextStep(selection);
}
