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

final dueReviewIdentitiesProvider = Provider<AsyncValue<Set<ContentIdentity>>>((ref) {
  final schedules = ref.watch(reviewSchedulesProvider);
  final now = ref.watch(reviewClockProvider)().toUtc();
  return schedules.whenData(
    (values) => <ContentIdentity>{
      for (final entry in values.entries)
        if (entry.value.isDueAt(now)) entry.key,
    },
  );
});
