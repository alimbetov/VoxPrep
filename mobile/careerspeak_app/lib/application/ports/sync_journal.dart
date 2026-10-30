import '../result/result.dart';
import '../content_sync/sync_models.dart';

abstract interface class SyncJournal {
  Future<Result<SyncLocalSnapshot>> readLocalSnapshot();

  Future<Result<SyncRunStart>> startOrCoalesce({
    required String runId,
    required SyncTrigger trigger,
    required String translationLocale,
  });

  Future<Result<void>> persistPlan({
    required String runId,
    required SyncPlan plan,
  });

  Future<Result<void>> transitionRun({
    required String runId,
    required SyncRunState state,
    ApplicationFailure? failure,
  });
}
