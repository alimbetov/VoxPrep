import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_sync/content_sync_coordinator.dart';
import '../application/content_sync/content_sync_planner.dart';
import '../application/ports/sync_journal.dart';
import '../application/ports/sync_plan_executor.dart';
import '../data/local/drift_sync_journal.dart';
import '../data/local/drift_sync_plan_executor.dart';
import 'content_manifest_providers.dart';
import 'learner_state_providers.dart';

final contentSyncPlannerProvider = Provider<ContentSyncPlanner>((ref) {
  return const ContentSyncPlanner();
});

final syncJournalProvider = Provider<SyncJournal>((ref) {
  return DriftSyncJournal(ref.watch(careerSpeakDatabaseProvider));
});

final syncPlanExecutorProvider = Provider<SyncPlanExecutor>((ref) {
  return DriftSyncPlanExecutor(
    ref.watch(careerSpeakDatabaseProvider),
    ref.watch(contentManifestGatewayProvider),
  );
});

final contentSyncCoordinatorProvider = Provider<ContentSyncCoordinator>((ref) {
  return ContentSyncCoordinator(
    journal: ref.watch(syncJournalProvider),
    manifestGateway: ref.watch(contentManifestGatewayProvider),
    planner: ref.watch(contentSyncPlannerProvider),
    executor: ref.watch(syncPlanExecutorProvider),
  );
});
