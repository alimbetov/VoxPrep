import '../../domain/content_review_state.dart';

typedef ReviewScheduleDecision = ({
  int reviewStage,
  DateTime nextReviewAt,
  ReviewOutcome lastReviewOutcome,
});

final class ReviewSchedulingPolicy {
  const ReviewSchedulingPolicy();

  ReviewScheduleDecision schedule({
    required int currentStage,
    required ReviewOutcome outcome,
    required DateTime now,
  }) {
    final normalizedStage = currentStage < 0 ? 0 : currentStage;
    final nextStage = switch (outcome) {
      ReviewOutcome.incorrect => 0,
      ReviewOutcome.hard => normalizedStage < 1 ? 1 : normalizedStage,
      ReviewOutcome.correct => normalizedStage + 1,
      ReviewOutcome.known => normalizedStage + 2,
    };
    final interval = switch (outcome) {
      ReviewOutcome.incorrect => const Duration(minutes: 10),
      ReviewOutcome.hard => const Duration(days: 1),
      ReviewOutcome.correct => _correctInterval(nextStage),
      ReviewOutcome.known => _knownInterval(nextStage),
    };

    return (
      reviewStage: nextStage,
      nextReviewAt: now.toUtc().add(interval),
      lastReviewOutcome: outcome,
    );
  }

  static Duration _correctInterval(int stage) => switch (stage) {
    <= 1 => const Duration(days: 2),
    2 => const Duration(days: 4),
    3 => const Duration(days: 7),
    4 => const Duration(days: 14),
    _ => const Duration(days: 30),
  };

  static Duration _knownInterval(int stage) => switch (stage) {
    <= 2 => const Duration(days: 7),
    3 => const Duration(days: 14),
    4 => const Duration(days: 30),
    _ => const Duration(days: 60),
  };
}
