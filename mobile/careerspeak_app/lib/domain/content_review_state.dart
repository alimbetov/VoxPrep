import 'content_identity.dart';

enum ReviewOutcome { incorrect, hard, correct, known }

class ContentReviewState {
  const ContentReviewState({
    required this.identity,
    required this.nextReviewAt,
    required this.reviewStage,
    this.lastReviewOutcome,
  });

  final ContentIdentity identity;
  final DateTime nextReviewAt;
  final int reviewStage;
  final ReviewOutcome? lastReviewOutcome;

  bool isDueAt(DateTime now) => !nextReviewAt.toUtc().isAfter(now.toUtc());

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ContentReviewState &&
            other.identity == identity &&
            other.nextReviewAt == nextReviewAt &&
            other.reviewStage == reviewStage &&
            other.lastReviewOutcome == lastReviewOutcome;
  }

  @override
  int get hashCode =>
      Object.hash(identity, nextReviewAt, reviewStage, lastReviewOutcome);
}
