import '../../domain/practice_test_attempt.dart';
import '../../domain/practice_test_completion_key.dart';
import '../result/result.dart';

abstract interface class PracticeTestAttemptRepository {
  Future<Result<PracticeTestAttempt?>> getActiveAttempt();

  Future<Result<PracticeTestAttempt>> startActiveAttempt(
    String practiceTestCode,
  );

  Future<Result<PracticeTestAttempt>> saveActiveAttempt(
    PracticeTestAttempt attempt,
  );

  Future<Result<Set<PracticeTestCompletionKey>>> getCompletedPracticeTests();

  Future<Result<void>> completeActiveAttempt();

  Future<Result<void>> clearActiveAttempt();
}
