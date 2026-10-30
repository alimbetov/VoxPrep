import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_sync/content_sync_planner.dart';
import '../application/ports/sync_journal.dart';
import '../data/local/drift_sync_journal.dart';
import 'learner_state_providers.dart';

final contentSyncPlannerProvider = Provider<ContentSyncPlanner>((ref) {
  return const ContentSyncPlanner();
});

final syncJournalProvider = Provider<SyncJournal>((ref) {
  return DriftSyncJournal(ref.watch(careerSpeakDatabaseProvider));
});
