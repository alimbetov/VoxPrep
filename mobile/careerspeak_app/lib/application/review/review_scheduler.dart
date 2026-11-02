// ignore_for_file: prefer_initializing_formals

import '../../application/ports/review_schedule_repository.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_review_state.dart';
import '../result/result.dart';
import 'review_scheduling_policy.dart';

final class ReviewScheduler {
  const ReviewScheduler({
    required ReviewScheduleRepository repository,
    ReviewSchedulingPolicy policy = const ReviewSchedulingPolicy(),
    DateTime Function()? now,
  }) : _repository = repository,
       _policy = policy,
       _now = now;

  final ReviewScheduleRepository _repository;
  final ReviewSchedulingPolicy _policy;
  final DateTime Function()? _now;

  Future<Result<ContentReviewState>> recordOutcome({
    required ContentIdentity identity,
    required int currentStage,
    required ReviewOutcome outcome,
  }) {
    final decision = _policy.schedule(
      currentStage: currentStage,
      outcome: outcome,
      now: (_now ?? DateTime.now)().toUtc(),
    );

    return _repository.upsertSchedule(
      identity: identity,
      nextReviewAt: decision.nextReviewAt,
      reviewStage: decision.reviewStage,
      lastReviewOutcome: decision.lastReviewOutcome,
    );
  }
}
