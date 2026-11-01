import 'package:careerspeak_app/application/review/review_scheduling_policy.dart';
import 'package:careerspeak_app/domain/content_review_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const policy = ReviewSchedulingPolicy();
  final now = DateTime.utc(2026, 11, 1, 10);

  test('incorrect resets stage and schedules ten minutes', () {
    final decision = policy.schedule(
      currentStage: 5,
      outcome: ReviewOutcome.incorrect,
      now: now,
    );

    expect(decision.reviewStage, 0);
    expect(decision.nextReviewAt, now.add(const Duration(minutes: 10)));
    expect(decision.lastReviewOutcome, ReviewOutcome.incorrect);
  });

  test('hard preserves established stage and schedules one day', () {
    final decision = policy.schedule(
      currentStage: 4,
      outcome: ReviewOutcome.hard,
      now: now,
    );

    expect(decision.reviewStage, 4);
    expect(decision.nextReviewAt, now.add(const Duration(days: 1)));
  });

  test('hard lifts stage zero to one', () {
    final decision = policy.schedule(
      currentStage: 0,
      outcome: ReviewOutcome.hard,
      now: now,
    );

    expect(decision.reviewStage, 1);
  });

  test('correct advances through deterministic interval table', () {
    final cases = <(int, int, Duration)>[
      (0, 1, const Duration(days: 2)),
      (1, 2, const Duration(days: 4)),
      (2, 3, const Duration(days: 7)),
      (3, 4, const Duration(days: 14)),
      (4, 5, const Duration(days: 30)),
      (12, 13, const Duration(days: 30)),
    ];

    for (final entry in cases) {
      final decision = policy.schedule(
        currentStage: entry.$1,
        outcome: ReviewOutcome.correct,
        now: now,
      );
      expect(decision.reviewStage, entry.$2);
      expect(decision.nextReviewAt, now.add(entry.$3));
    }
  });

  test('known advances by two and uses longer interval table', () {
    final cases = <(int, int, Duration)>[
      (0, 2, const Duration(days: 7)),
      (1, 3, const Duration(days: 14)),
      (2, 4, const Duration(days: 30)),
      (3, 5, const Duration(days: 60)),
      (10, 12, const Duration(days: 60)),
    ];

    for (final entry in cases) {
      final decision = policy.schedule(
        currentStage: entry.$1,
        outcome: ReviewOutcome.known,
        now: now,
      );
      expect(decision.reviewStage, entry.$2);
      expect(decision.nextReviewAt, now.add(entry.$3));
    }
  });

  test('same input is deterministic and UTC normalized', () {
    final localNow = DateTime.parse('2026-11-01T15:00:00+05:00');
    final first = policy.schedule(
      currentStage: 2,
      outcome: ReviewOutcome.correct,
      now: localNow,
    );
    final second = policy.schedule(
      currentStage: 2,
      outcome: ReviewOutcome.correct,
      now: localNow,
    );

    expect(first, second);
    expect(first.nextReviewAt.isUtc, isTrue);
  });

  test('negative stage fails closed to zero before transition', () {
    final decision = policy.schedule(
      currentStage: -7,
      outcome: ReviewOutcome.correct,
      now: now,
    );

    expect(decision.reviewStage, 1);
  });
}
