import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_learner_selection_repository.dart';
import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  group('DriftLearnerSelectionRepository', () {
    test('starts with empty singleton selection', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftLearnerSelectionRepository(database);

      final result = await repository.getSelection();
      final selection = (result as Success<LearnerSelection>).value;

      expect(selection, LearnerSelection.empty);
    });

    test('persists goal track and explicit level decision', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftLearnerSelectionRepository(database);

      final write = await repository.compareAndSet(
        expectedGeneration: 0,
        next: LearnerSelection(
          selectedGoalCode: 'JOB_INTERVIEW',
          selectedTrackCode: 'JAVA_SENIOR',
          selfAssessedLevelCode: 'B2',
          levelDecisionMade: true,
        ),
      );
      final persisted = (write as Success<LearnerSelection>).value;

      expect(persisted.generation, 1);

      final reopenedRepository = DriftLearnerSelectionRepository(database);
      final read = await reopenedRepository.getSelection();
      expect((read as Success<LearnerSelection>).value, persisted);
    });

    test('persists Not sure separately from unanswered level', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftLearnerSelectionRepository(database);

      final write = await repository.compareAndSet(
        expectedGeneration: 0,
        next: LearnerSelection(levelDecisionMade: true),
      );
      final persisted = (write as Success<LearnerSelection>).value;

      expect(persisted.levelDecisionMade, isTrue);
      expect(persisted.selfAssessedLevelCode, isNull);

      final read = await repository.getSelection();
      final restored = (read as Success<LearnerSelection>).value;
      expect(restored.levelDecisionMade, isTrue);
      expect(restored.selfAssessedLevelCode, isNull);
    });

    test('stale generation cannot overwrite newer user selection', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftLearnerSelectionRepository(database);

      final first = await repository.compareAndSet(
        expectedGeneration: 0,
        next: LearnerSelection(selectedGoalCode: 'JOB_INTERVIEW'),
      );
      expect(first, isA<Success<LearnerSelection>>());

      final stale = await repository.compareAndSet(
        expectedGeneration: 0,
        next: LearnerSelection(selectedGoalCode: 'MEDICAL_ENGLISH'),
      );

      expect(stale, isA<FailureResult<LearnerSelection>>());
      final failure = (stale as FailureResult<LearnerSelection>).failure;
      expect(failure.code, 'LEARNER_SELECTION_CONFLICT');

      final current = await repository.getSelection();
      expect(
        (current as Success<LearnerSelection>).value.selectedGoalCode,
        'JOB_INTERVIEW',
      );
    });

    test('watch emits initial state and successful CAS update', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftLearnerSelectionRepository(database);
      final events = <LearnerSelection>[];
      final subscription = repository.watchSelection().listen((result) {
        if (result case Success<LearnerSelection>(:final value)) {
          events.add(value);
        }
      });
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      await repository.compareAndSet(
        expectedGeneration: 0,
        next: LearnerSelection(selectedGoalCode: 'JOB_INTERVIEW'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(2));
      expect(events.first, LearnerSelection.empty);
      expect(events.last.selectedGoalCode, 'JOB_INTERVIEW');
      expect(events.last.generation, 1);
    });
  });
}
