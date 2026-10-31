import '../content_delivery/content_manifest.dart';
import '../ports/content_manifest_gateway.dart';
import '../ports/sync_journal.dart';
import '../ports/sync_plan_executor.dart';
import '../result/result.dart';
import 'content_sync_planner.dart';
import 'root_manifest_materializer.dart';
import 'sync_models.dart';

sealed class ContentSyncOutcome {
  const ContentSyncOutcome(this.runId);
  final String runId;
}

final class ContentSyncCoalesced extends ContentSyncOutcome {
  const ContentSyncCoalesced(super.runId);
}

final class ContentSyncNoOp extends ContentSyncOutcome {
  const ContentSyncNoOp(super.runId);
}

final class ContentSyncExecuted extends ContentSyncOutcome {
  const ContentSyncExecuted(super.runId);
}

final class ContentSyncCoordinator {
  factory ContentSyncCoordinator({
    required SyncJournal journal,
    required ContentManifestGateway manifestGateway,
    required ContentSyncPlanner planner,
    required SyncPlanExecutor executor,
  }) {
    return ContentSyncCoordinator._(
      journal,
      manifestGateway,
      planner,
      executor,
    );
  }

  const ContentSyncCoordinator._(
    this._journal,
    this._manifestGateway,
    this._planner,
    this._executor,
  );

  final SyncJournal _journal;
  final ContentManifestGateway _manifestGateway;
  final ContentSyncPlanner _planner;
  final SyncPlanExecutor _executor;

  Future<Result<ContentSyncOutcome>> synchronize({
    required String runId,
    required SyncTrigger trigger,
    required String translationLocale,
  }) async {
    final startResult = await _journal.startOrCoalesce(
      runId: runId,
      trigger: trigger,
      translationLocale: translationLocale,
    );
    if (startResult is FailureResult<SyncRunStart>) {
      return FailureResult(startResult.failure);
    }
    final start = (startResult as Success<SyncRunStart>).value;
    if (start is SyncRunCoalesced) {
      return Success(ContentSyncCoalesced(start.runId));
    }

    final activeRunId = start.runId;
    final localTransition = await _transition(
      activeRunId,
      SyncRunState.checkingLocal,
    );
    if (localTransition != null) return FailureResult(localTransition);

    final localResult = await _journal.readLocalSnapshot();
    if (localResult is FailureResult<SyncLocalSnapshot>) {
      return _finishFailure(activeRunId, localResult.failure);
    }
    final local = (localResult as Success<SyncLocalSnapshot>).value;

    final remoteTransition = await _transition(
      activeRunId,
      SyncRunState.checkingRemote,
    );
    if (remoteTransition != null) return FailureResult(remoteTransition);

    // Root identity is deliberately locale-independent. Locale selection only
    // materializes a device-local pack projection from that immutable root.
    final remoteResult = await _manifestGateway.fetchRootManifest(etag: null);
    if (remoteResult is FailureResult<RootManifestFetch>) {
      return _finishFailure(activeRunId, remoteResult.failure);
    }
    final remoteFetch = (remoteResult as Success<RootManifestFetch>).value;
    if (remoteFetch is! RootManifestChanged) {
      return _finishFailure(
        activeRunId,
        const ApplicationFailure(
          code: 'SYNC_REMOTE_RESPONSE_INVALID',
          message:
              'An unconditional root manifest request returned no manifest payload.',
        ),
      );
    }

    final fullRoot = remoteFetch.manifest;
    final materializedResult = const RootManifestMaterializer().materialize(
      root: fullRoot,
      translationLocale: translationLocale,
    );
    if (materializedResult is FailureResult<RootContentManifest>) {
      return _finishFailure(activeRunId, materializedResult.failure);
    }
    final targetRoot =
        (materializedResult as Success<RootContentManifest>).value;

    final planningTransition = await _transition(
      activeRunId,
      SyncRunState.planning,
    );
    if (planningTransition != null) return FailureResult(planningTransition);

    final planResult = _planner.plan(
      local: local,
      remote: targetRoot,
      remoteEtag: remoteFetch.etag,
      immutableRootPackIdentities: fullRoot.packs.map((pack) => pack.identity),
    );
    if (planResult is FailureResult<SyncPlan>) {
      return _finishFailure(activeRunId, planResult.failure);
    }
    final plan = (planResult as Success<SyncPlan>).value;
    final persistResult = await _journal.persistPlan(
      runId: activeRunId,
      plan: plan,
    );
    if (persistResult is FailureResult<void>) {
      return _finishFailure(activeRunId, persistResult.failure);
    }

    if (plan.isNoOp) {
      final successTransition = await _transition(
        activeRunId,
        SyncRunState.succeeded,
      );
      if (successTransition != null) return FailureResult(successTransition);
      return Success(ContentSyncNoOp(activeRunId));
    }

    final stagingTransition = await _transition(
      activeRunId,
      SyncRunState.staging,
    );
    if (stagingTransition != null) return FailureResult(stagingTransition);

    final executionResult = await _executor.execute(
      runId: activeRunId,
      plan: plan,
    );
    if (executionResult is FailureResult<void>) {
      return _finishFailure(activeRunId, executionResult.failure);
    }

    final successTransition = await _transition(
      activeRunId,
      SyncRunState.succeeded,
    );
    if (successTransition != null) return FailureResult(successTransition);
    return Success(ContentSyncExecuted(activeRunId));
  }

  Future<ApplicationFailure?> _transition(
    String runId,
    SyncRunState state,
  ) async {
    final result = await _journal.transitionRun(runId: runId, state: state);
    return switch (result) {
      Success<void>() => null,
      FailureResult<void>(:final failure) => failure,
    };
  }

  Future<Result<ContentSyncOutcome>> _finishFailure(
    String runId,
    ApplicationFailure failure,
  ) async {
    final persisted = await _journal.transitionRun(
      runId: runId,
      state: _terminalStateFor(failure),
      failure: failure,
    );
    if (persisted is FailureResult<void>) {
      return FailureResult(
        ApplicationFailure(
          code: 'SYNC_TERMINAL_WRITE_FAILED',
          message: 'The sync failure could not be persisted to the journal.',
          retryable: true,
          traceId: failure.traceId,
          details: <String, Object?>{
            'causeCode': failure.code,
            'journalCode': persisted.failure.code,
          },
        ),
      );
    }
    return FailureResult(failure);
  }

  static SyncRunState _terminalStateFor(ApplicationFailure failure) {
    return switch (failure.code) {
      'OFFLINE' => SyncRunState.deferredOffline,
      'SCHEMA_UNSUPPORTED' ||
      'APP_UPDATE_REQUIRED' => SyncRunState.blockedSchema,
      'UNAUTHORIZED' => SyncRunState.failedRetryable,
      _ when failure.retryable => SyncRunState.failedRetryable,
      _ => SyncRunState.failedFatal,
    };
  }
}