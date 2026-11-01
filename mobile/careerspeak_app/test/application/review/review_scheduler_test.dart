import 'package:careerspeak_app/application/ports/review_schedule_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/review/review_scheduler.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_review_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recordOutcome persists deterministic policy result', () async {
    final repository = _Repository();
    final scheduler = ReviewScheduler(
      repository: repository,
      now: () => DateTime.utc(2026, 11, 1, 10),
    );
    const identity = ContentIdentity(code: 'JAVA_REVIEW', type: ContentType.topic);

    final result = await scheduler.recordOutcome(
      identity: identity,
      currentStage: 2,
      outcome: ReviewOutcome.correct,
    );

    final state = result.getOrThrow();
    expect(state.identity, identity);
    expect(state.reviewStage, 3);
    expect(state.nextReviewAt, DateTime.utc(2026, 11, 8, 10));
    expect(state.lastReviewOutcome, ReviewOutcome.correct);
    expect(repository.lastState, state);
  });
}

final class _Repository implements ReviewScheduleRepository {
  ContentReviewState? lastState;

  @override
  Future<Result<Map<ContentIdentity, ContentReviewState>>> getSchedules() async =>
      Success<Map<ContentIdentity, ContentReviewState>>(
        lastState == null
            ? const <ContentIdentity, ContentReviewState>{}
            : <ContentIdentity, ContentReviewState>{lastState!.identity: lastState!},
      );

  @override
  Stream<Result<Map<ContentIdentity, ContentReviewState>>> watchSchedules() async* {
    yield await getSchedules();
  }

  @override
  Future<Result<ContentReviewState>> upsertSchedule({
    required ContentIdentity identity,
    required DateTime nextReviewAt,
    required int reviewStage,
    ReviewOutcome? lastReviewOutcome,
  }) async {
    final state = ContentReviewState(
      identity: identity,
      nextReviewAt: nextReviewAt,
      reviewStage: reviewStage,
      lastReviewOutcome: lastReviewOutcome,
    );
    lastState = state;
    return Success<ContentReviewState>(state);
  }

  @override
  Future<Result<void>> clearSchedule(ContentIdentity identity) async {
    lastState = null;
    return const Success<void>(null);
  }
}
