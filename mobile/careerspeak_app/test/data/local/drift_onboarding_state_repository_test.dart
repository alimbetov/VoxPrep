import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_onboarding_state_repository.dart';
import 'package:careerspeak_app/domain/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  group('DriftOnboardingStateRepository', () {
    test('starts incomplete and persists completion with generation', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftOnboardingStateRepository(database);

      final initial = (await repository.getState() as Success<OnboardingState>)
          .value;
      expect(initial.completed, isFalse);
      expect(initial.generation, 0);

      final completed = await repository.compareAndSet(
        expectedGeneration: initial.generation,
        completed: true,
      );
      final state = (completed as Success<OnboardingState>).value;
      expect(state.completed, isTrue);
      expect(state.generation, 1);

      final reopened = DriftOnboardingStateRepository(database);
      final persisted = (await reopened.getState() as Success<OnboardingState>)
          .value;
      expect(persisted.completed, isTrue);
      expect(persisted.generation, 1);
    });

    test('stale compare-and-set cannot overwrite completion', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftOnboardingStateRepository(database);

      await repository.compareAndSet(
        expectedGeneration: 0,
        completed: true,
      );
      final stale = await repository.compareAndSet(
        expectedGeneration: 0,
        completed: false,
      );

      expect(stale, isA<FailureResult<OnboardingState>>());
      expect(
        (stale as FailureResult<OnboardingState>).failure.code,
        'ONBOARDING_STATE_CONFLICT',
      );
      final current = (await repository.getState() as Success<OnboardingState>)
          .value;
      expect(current.completed, isTrue);
    });
  });
}
