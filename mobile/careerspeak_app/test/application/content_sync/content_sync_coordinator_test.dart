import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sync_orchestration_fakes.dart';

void main() {
  test('coalesces without reading remote state', () async {
    final journal = FakeJournal(Success(emptySnapshot()))
      ..coalescedRunId = 'run-1';
    final gateway = FakeGateway(
      Success(RootManifestChanged(manifest: manifest(108), etag: 'e')),
    );
    final executor = FakeExecutor();
    final result = await _coordinator(journal, gateway, executor).synchronize(
      runId: 'run-2',
      trigger: SyncTrigger.manual,
      translationLocale: 'kk',
    );

    expect(
      (result as Success<ContentSyncOutcome>).value,
      isA<ContentSyncCoalesced>(),
    );
    expect(gateway.calls, 0);
    expect(executor.calls, 0);
  });

  test('same root finishes as no-op without executor', () async {
    final p = pack();
    final journal = FakeJournal(
      Success(
        SyncLocalSnapshot(
          currentContentVersion: 108,
          currentManifestChecksum: rootA,
          etag: 'etag-108',
          currentPacks: <PackRevisionRef>[p],
        ),
      ),
    );
    final gateway = FakeGateway(
      Success(
        RootManifestChanged(
          manifest: manifest(108, packs: <PackRevisionRef>[p]),
          etag: 'e',
        ),
      ),
    );
    final executor = FakeExecutor();
    final result = await _coordinator(journal, gateway, executor).synchronize(
      runId: 'run-1',
      trigger: SyncTrigger.startup,
      translationLocale: 'kk',
    );

    expect(
      (result as Success<ContentSyncOutcome>).value,
      isA<ContentSyncNoOp>(),
    );
    expect(gateway.etags.single, isNull);
    expect(executor.calls, 0);
    expect(journal.states, <SyncRunState>[
      SyncRunState.checkingLocal,
      SyncRunState.checkingRemote,
      SyncRunState.planning,
      SyncRunState.succeeded,
    ]);
  });

  test('changed root persists plan and executes once', () async {
    final journal = FakeJournal(Success(emptySnapshot()));
    final gateway = FakeGateway(
      Success(
        RootManifestChanged(
          manifest: manifest(109, packs: <PackRevisionRef>[pack()]),
          etag: 'e',
        ),
      ),
    );
    final executor = FakeExecutor();
    final result = await _coordinator(journal, gateway, executor).synchronize(
      runId: 'run-1',
      trigger: SyncTrigger.startup,
      translationLocale: 'kk',
    );

    expect(
      (result as Success<ContentSyncOutcome>).value,
      isA<ContentSyncExecuted>(),
    );
    expect(journal.plans, hasLength(1));
    expect(executor.calls, 1);
    expect(journal.states.last, SyncRunState.succeeded);
  });

  test('offline remote check becomes deferred offline', () async {
    final journal = FakeJournal(Success(emptySnapshot()));
    final gateway = FakeGateway(
      const FailureResult(
        ApplicationFailure(
          code: 'OFFLINE',
          message: 'offline',
          retryable: true,
        ),
      ),
    );
    final result = await _coordinator(journal, gateway, FakeExecutor())
        .synchronize(
          runId: 'run-1',
          trigger: SyncTrigger.startup,
          translationLocale: 'kk',
        );

    expect(
      (result as FailureResult<ContentSyncOutcome>).failure.code,
      'OFFLINE',
    );
    expect(journal.states.last, SyncRunState.deferredOffline);
  });

  test('retryable executor failure becomes retryable terminal state', () async {
    final journal = FakeJournal(Success(emptySnapshot()));
    final gateway = FakeGateway(
      Success(
        RootManifestChanged(
          manifest: manifest(109, packs: <PackRevisionRef>[pack()]),
          etag: 'e',
        ),
      ),
    );
    final executor = FakeExecutor(
      const FailureResult(
        ApplicationFailure(
          code: 'STAGING_BUSY',
          message: 'busy',
          retryable: true,
        ),
      ),
    );
    final result = await _coordinator(journal, gateway, executor).synchronize(
      runId: 'run-1',
      trigger: SyncTrigger.startup,
      translationLocale: 'kk',
    );

    expect(
      (result as FailureResult<ContentSyncOutcome>).failure.code,
      'STAGING_BUSY',
    );
    expect(journal.states.last, SyncRunState.failedRetryable);
  });
}

ContentSyncCoordinator _coordinator(
  FakeJournal journal,
  FakeGateway gateway,
  FakeExecutor executor,
) {
  return ContentSyncCoordinator(
    journal: journal,
    manifestGateway: gateway,
    planner: const ContentSyncPlanner(),
    executor: executor,
  );
}
