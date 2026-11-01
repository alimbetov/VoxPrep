import '../../domain/practice_test_attempt.dart';
import '../result/result.dart';

abstract interface class PracticeTestAttemptRepository {
  Future<Result<PracticeTestAttempt?>> getActiveAttempt();

  Future<Result<PracticeTestAttempt>> startActiveAttempt(
    String practiceTestCode,
  );

  Future<Result<PracticeTestAttempt>> saveActiveAttempt(
    PracticeTestAttempt attempt,
  );

  Future<Result<void>> clearActiveAttempt();
}
