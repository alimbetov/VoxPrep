import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/review_schedule_repository.dart';
import '../data/local/drift_review_schedule_repository.dart';
import '../domain/content_identity.dart';
import '../domain/content_item.dart';
import '../domain/content_review_state.dart';
import 'learner_state_providers.dart';
import 'repository_providers.dart';

final reviewScheduleRepositoryProvider = Provider<ReviewScheduleRepository>((
  ref,
) {
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

typedef ReviewDueTimerFactory =
    Timer Function(Duration delay, void Function() callback);

final dueReviewIdentitiesProvider = Provider<AsyncValue<Set<ContentIdentity>>>((
  ref,
) {
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
      timer = ref.read(reviewDueTimerFactoryProvider)(
        delay,
        ref.invalidateSelf,
      );
    }

    return Set<ContentIdentity>.unmodifiable(due);
  });

  ref.onDispose(() => timer?.cancel());
  return value;
});

/// Resolves every due identity back through the CURRENT content repository.
///
/// This deliberately does not depend on the first catalogue page: Home counts
/// all CURRENT due items, and Review cannot surface stale/retired identities
/// that only remain in learner-owned schedule state.
final dueReviewItemsProvider = FutureProvider<List<ContentItem>>((ref) async {
  final dueAsync = ref.watch(dueReviewIdentitiesProvider);
  final due = switch (dueAsync) {
    AsyncData<Set<ContentIdentity>>(:final value) => value,
    AsyncError<Set<ContentIdentity>>(:final error, :final stackTrace) =>
      Error.throwWithStackTrace(error, stackTrace),
    _ => <ContentIdentity>{},
  };

  if (due.isEmpty) return const <ContentItem>[];

  final identities = due.toList(growable: false)
    ..sort((left, right) {
      final type = left.type.name.compareTo(right.type.name);
      return type != 0 ? type : left.code.compareTo(right.code);
    });
  final repository = ref.watch(contentRepositoryProvider);
  final items = <ContentItem>[];
  for (final identity in identities) {
    final item = (await repository.getByIdentity(identity)).getOrThrow();
    if (item != null) items.add(item);
  }
  return List<ContentItem>.unmodifiable(items);
});
