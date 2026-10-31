import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_sync/content_sync_coordinator.dart';
import '../application/content_sync/content_sync_planner.dart';
import '../application/content_sync/preference_aware_content_sync.dart';
import '../application/ports/sync_journal.dart';
import '../application/ports/sync_plan_executor.dart';
import '../data/local/drift_sync_journal.dart';
import '../data/local/drift_sync_plan_executor.dart';
import 'app_preferences_providers.dart';
import 'content_manifest_providers.dart';
import 'content_payload_providers.dart';
import 'learner_state_providers.dart';
import 'localized_content_payload_providers.dart';

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
    ref.watch(contentPayloadGatewayProvider),
    localizedPayloadGateway: ref.watch(localizedContentPayloadGatewayProvider),
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

final preferenceAwareContentSyncProvider = Provider<PreferenceAwareContentSync>(
  (ref) {
    return PreferenceAwareContentSync(
      preferencesRepository: ref.watch(appPreferencesRepositoryProvider),
      coordinator: ref.watch(contentSyncCoordinatorProvider),
    );
  },
);
