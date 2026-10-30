import '../content_sync/sync_models.dart';
import '../result/result.dart';

abstract interface class SyncPlanExecutor {
  Future<Result<void>> execute({required String runId, required SyncPlan plan});
}
