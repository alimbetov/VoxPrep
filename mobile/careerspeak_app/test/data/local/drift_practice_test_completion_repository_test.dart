import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_attempt_repository.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:careerspeak_app/domain/practice_test_completion_key.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  group('PracticeTest completion persistence', () {
    test('schema v15 atomically completes and clears active attempt', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      expect(database.schemaVersion, greaterThanOrEqualTo(15));
      final completedAt = DateTime.utc(2026, 11, 1, 12);
      final repository = DriftPracticeTestAttemptRepository(
        database,
        now: () => completedAt,
      );
      final attempt = PracticeTestAttempt(
        practiceTestCode: 'TEST_A',
        practiceTestRevision: 5,
        currentIndex: 2,
        answers: const <int, int>{0: 1, 1: 2},
        startedAt: completedAt.subtract(const Duration(minutes: 5)),
        updatedAt: completedAt.subtract(const Duration(minutes: 1)),
      );

      expect(
        await repository.saveActiveAttempt(attempt),
        isA<Success<PracticeTestAttempt>>(),
      );
      expect(await repository.completeActiveAttempt(), isA<Success<void>>());

      final active = await repository.getActiveAttempt();
      expect((active as Success<PracticeTestAttempt?>).value, isNull);
      final completed = await repository.getCompletedPracticeTests();
      expect(
        (completed as Success<Set<PracticeTestCompletionKey>>).value,
        contains(
          const PracticeTestCompletionKey(
            practiceTestCode: 'TEST_A',
            revision: 5,
          ),
        ),
      );
    });

    test(
      'completion is exact-revision and survives retake start state',
      () async {
        final database = createTestDatabase();
        addTearDown(database.close);
        final now = DateTime.utc(2026, 11, 1, 13);
        final repository = DriftPracticeTestAttemptRepository(
          database,
          now: () => now,
        );

        await repository.saveActiveAttempt(
          PracticeTestAttempt(
            practiceTestCode: 'TEST_A',
            practiceTestRevision: 5,
            currentIndex: 0,
            answers: const <int, int>{},
            startedAt: now.subtract(const Duration(minutes: 2)),
            updatedAt: now.subtract(const Duration(minutes: 1)),
          ),
        );
        await repository.completeActiveAttempt();
        await repository.saveActiveAttempt(
          PracticeTestAttempt(
            practiceTestCode: 'TEST_A',
            practiceTestRevision: 6,
            currentIndex: 0,
            answers: const <int, int>{},
            startedAt: now,
            updatedAt: now,
          ),
        );

        final completed =
            (await repository.getCompletedPracticeTests()
                    as Success<Set<PracticeTestCompletionKey>>)
                .value;
        expect(
          completed,
          contains(
            const PracticeTestCompletionKey(
              practiceTestCode: 'TEST_A',
              revision: 5,
            ),
          ),
        );
        expect(
          completed,
          isNot(
            contains(
              const PracticeTestCompletionKey(
                practiceTestCode: 'TEST_A',
                revision: 6,
              ),
            ),
          ),
        );
        expect(
          (await repository.getActiveAttempt() as Success<PracticeTestAttempt?>)
              .value
              ?.practiceTestRevision,
          6,
        );
      },
    );
  });
}
