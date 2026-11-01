import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sync_orchestration_fakes.dart';

void main() {
  test('C4 staging failure never reaches publication executor', () async {
    final journal = FakeJournal(Success(emptySnapshot()));
    final exactTest = PracticeTestRevisionRef(
      practiceTestCode: 'JAVA_TEST_001',
      revision: 2,
      checksum: _testChecksum,
    );
    final gateway = FakeGateway(
      Success<RootManifestFetch>(
        RootManifestChanged(
          manifest: manifest(
            109,
            packs: <dynamic>[pack()].cast(),
            practiceTests: <PracticeTestRevisionRef>[exactTest],
          ),
          etag: 'root-109',
        ),
      ),
    );
    final executor = FakeExecutor();
    final stager = FakeSnapshotStager(
      const FailureResult<void>(
        ApplicationFailure(
          code: 'PUBLICATION_SNAPSHOT_STAGING_FAILED',
          message: 'staging failed',
          retryable: true,
        ),
      ),
    );
    final coordinator = ContentSyncCoordinator(
      journal: journal,
      manifestGateway: gateway,
      planner: const ContentSyncPlanner(),
      executor: executor,
      snapshotStager: stager,
    );

    final result = await coordinator.synchronize(
      runId: 'c4-staging-failure',
      trigger: SyncTrigger.startup,
      translationLocale: 'ru',
    );

    expect(result, isA<FailureResult<ContentSyncOutcome>>());
    expect(
      (result as FailureResult<ContentSyncOutcome>).failure.code,
      'PUBLICATION_SNAPSHOT_STAGING_FAILED',
    );
    expect(stager.targets, hasLength(1));
    expect(executor.calls, 0);
    expect(journal.states.last, SyncRunState.failedRetryable);
  });
}

const _testChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
