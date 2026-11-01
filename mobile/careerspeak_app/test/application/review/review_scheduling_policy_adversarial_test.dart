import 'package:careerspeak_app/application/review/review_scheduling_policy.dart';
import 'package:careerspeak_app/domain/content_review_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = ReviewSchedulingPolicy();

  test('very large stage remains bounded by terminal interval buckets', () {
    final now = DateTime.utc(2026, 11, 1);

    final correct = policy.schedule(
      currentStage: 1000000,
      outcome: ReviewOutcome.correct,
      now: now,
    );
    final known = policy.schedule(
      currentStage: 1000000,
      outcome: ReviewOutcome.known,
      now: now,
    );

    expect(correct.reviewStage, 1000001);
    expect(correct.nextReviewAt, now.add(const Duration(days: 30)));
    expect(known.reviewStage, 1000002);
    expect(known.nextReviewAt, now.add(const Duration(days: 60)));
  });

  test('incorrect always resets regardless of prior stage', () {
    final now = DateTime.utc(2026, 11, 1);
    for (final stage in <int>[-100, 0, 1, 10, 999]) {
      final decision = policy.schedule(
        currentStage: stage,
        outcome: ReviewOutcome.incorrect,
        now: now,
      );
      expect(decision.reviewStage, 0);
      expect(decision.nextReviewAt, now.add(const Duration(minutes: 10)));
    }
  });
}
