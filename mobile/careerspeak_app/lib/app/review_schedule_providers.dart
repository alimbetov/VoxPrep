import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/review_schedule_repository.dart';
import '../data/local/drift_review_schedule_repository.dart';
import '../domain/content_identity.dart';
import '../domain/content_review_state.dart';
import 'learner_state_providers.dart';

final reviewScheduleRepositoryProvider = Provider<ReviewScheduleRepository>((ref) {
  return DriftReviewScheduleRepository(ref.watch(careerSpeakDatabaseProvider));
});

final reviewSchedulesProvider =
    StreamProvider<Map<ContentIdentity, ContentReviewState>>((ref) {
      final repository = ref.watch(reviewScheduleRepositoryProvider);
      return repository.watchSchedules().map((result) => result.getOrThrow());
    });

final reviewClockProvider = Provider<DateTime Function()>((ref) {
  return () => DateTime.now().toUtc();
});

final reviewDueTimerFactoryProvider = Provider<ReviewDueTimerFactory>((ref) {
  return (delay, callback) => Timer(delay, callback);
});

typedef ReviewDueTimerFactory = Timer Function(
  Duration delay,
  void Function() callback,
);

final dueReviewIdentitiesProvider = Provider<AsyncValue<Set<ContentIdentity>>>((ref) {
  final schedules = ref.watch(reviewSchedulesProvider);
  final now = ref.watch(reviewClockProvider)().toUtc();
  Timer? timer;

  final value = schedules.whenData((values) {
    DateTime? nextBoundary;
    final due = <ContentIdentity>{};
    for (final entry in values.entries) {
      final nextReviewAt = entry.value.nextReviewAt.toUtc();
      if (!nextReviewAt.isAfter(now)) {
        due.add(entry.key);
        continue;
      }
      if (nextBoundary == null || nextReviewAt.isBefore(nextBoundary)) {
        nextBoundary = nextReviewAt;
      }
    }

    if (nextBoundary != null) {
      var delay = nextBoundary.difference(now);
      if (delay <= Duration.zero) {
        delay = const Duration(microseconds: 1);
      }
      timer = ref.read(reviewDueTimerFactoryProvider)(delay, ref.invalidateSelf);
    }

    return Set<ContentIdentity>.unmodifiable(due);
  });

  ref.onDispose(() => timer?.cancel());
  return value;
});
