import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/review/review_scheduler.dart';
import 'review_schedule_providers.dart';

final reviewSchedulerProvider = Provider<ReviewScheduler>((ref) {
  return ReviewScheduler(
    repository: ref.watch(reviewScheduleRepositoryProvider),
    now: ref.watch(reviewClockProvider),
  );
});
