import '../../domain/onboarding_state.dart';
import '../result/result.dart';

abstract interface class OnboardingStateRepository {
  Stream<Result<OnboardingState>> watchState();

  Future<Result<OnboardingState>> getState();

  Future<Result<OnboardingState>> compareAndSet({
    required int expectedGeneration,
    required bool completed,
  });
}
