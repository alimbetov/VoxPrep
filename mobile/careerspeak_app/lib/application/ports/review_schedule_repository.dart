import '../../domain/content_identity.dart';
import '../../domain/content_review_state.dart';
import '../result/result.dart';

abstract interface class ReviewScheduleRepository {
  Stream<Result<Map<ContentIdentity, ContentReviewState>>> watchSchedules();

  Future<Result<Map<ContentIdentity, ContentReviewState>>> getSchedules();

  Future<Result<ContentReviewState>> upsertSchedule({
    required ContentIdentity identity,
    required DateTime nextReviewAt,
    required int reviewStage,
    ReviewOutcome? lastReviewOutcome,
  });

  Future<Result<void>> clearSchedule(ContentIdentity identity);
}
