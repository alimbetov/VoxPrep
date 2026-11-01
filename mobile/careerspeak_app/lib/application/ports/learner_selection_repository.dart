import '../../domain/learner_selection.dart';
import '../result/result.dart';

abstract interface class LearnerSelectionRepository {
  Stream<Result<LearnerSelection>> watchSelection();

  Future<Result<LearnerSelection>> getSelection();

  Future<Result<LearnerSelection>> compareAndSet({
    required int expectedGeneration,
    required LearnerSelection next,
  });
}
