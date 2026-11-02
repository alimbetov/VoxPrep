import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/required_offline_asset_prefetcher.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
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
            packs: <PackRevisionRef>[pack()],
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

  test('C4 required-offline asset failure blocks activation', () async {
    final targetPack = pack();
    final root = manifest(109, packs: <PackRevisionRef>[targetPack]);
    final gateway = _PackGateway(
      root: root,
      packManifest: _packManifest(
        targetPack,
        assets: <ManifestAssetDescriptor>[
          ManifestAssetDescriptor(
            assetId: 'audio.required.1',
            checksumSha256: _assetChecksum,
            deliveryKey: 'audio/required-1.mp3',
            sizeBytes: 128,
            mediaType: 'audio/mpeg',
            requiredOffline: true,
          ),
        ],
      ),
    );
    final executor = FakeExecutor();
    final journal = FakeJournal(Success(emptySnapshot()));
    final prefetcher = RequiredOfflineAssetPrefetcher(
      manifestGateway: gateway,
      ensureLocal: (asset) async => const FailureResult<AssetDownloadOutcome>(
        ApplicationFailure(
          code: 'OFFLINE',
          message: 'required asset is unavailable',
          retryable: true,
        ),
      ),
    );
    final coordinator = ContentSyncCoordinator(
      journal: journal,
      manifestGateway: gateway,
      planner: const ContentSyncPlanner(),
      executor: executor,
      requiredOfflinePrefetcher: prefetcher,
    );

    final result = await coordinator.synchronize(
      runId: 'c4-required-asset-failure',
      trigger: SyncTrigger.startup,
      translationLocale: 'ru',
    );

    expect(result, isA<FailureResult<ContentSyncOutcome>>());
    final failure = (result as FailureResult<ContentSyncOutcome>).failure;
    expect(failure.code, 'REQUIRED_OFFLINE_ASSET_UNAVAILABLE');
    expect(failure.retryable, isTrue);
    expect(executor.calls, 0);
    expect(gateway.packCalls, 1);
    expect(journal.states.last, SyncRunState.failedRetryable);
  });

  test('C4 exact target rejects a newer pack returned mid-sync', () async {
    final targetPack = pack();
    final root = manifest(109, packs: <PackRevisionRef>[targetPack]);
    final advancedPack = PackRevisionRef(
      identity: targetPack.identity,
      revision: targetPack.revision + 1,
      checksum: _advancedPackChecksum,
    );
    final gateway = _PackGateway(
      root: root,
      packManifest: _packManifest(advancedPack),
    );
    final executor = FakeExecutor();
    final journal = FakeJournal(Success(emptySnapshot()));
    final prefetcher = RequiredOfflineAssetPrefetcher(
      manifestGateway: gateway,
      ensureLocal: (asset) async => Success<AssetDownloadOutcome>(
        AssetDownloadOutcome(
          localPath: '/verified/${asset.assetId}',
          reused: true,
        ),
      ),
    );
    final coordinator = ContentSyncCoordinator(
      journal: journal,
      manifestGateway: gateway,
      planner: const ContentSyncPlanner(),
      executor: executor,
      requiredOfflinePrefetcher: prefetcher,
    );

    final result = await coordinator.synchronize(
      runId: 'c4-advanced-pack-mid-sync',
      trigger: SyncTrigger.startup,
      translationLocale: 'ru',
    );

    expect(result, isA<FailureResult<ContentSyncOutcome>>());
    final failure = (result as FailureResult<ContentSyncOutcome>).failure;
    expect(failure.code, 'REQUIRED_OFFLINE_PACK_MISMATCH');
    expect(executor.calls, 0);
    expect(gateway.packCalls, 1);
    expect(journal.states.last, SyncRunState.failedFatal);
  });
}

PackContentManifest _packManifest(
  PackRevisionRef target, {
  Iterable<ManifestAssetDescriptor> assets = const <ManifestAssetDescriptor>[],
}) {
  return PackContentManifest(
    schemaVersion: 1,
    identity: target.identity,
    revision: target.revision,
    checksum: target.checksum,
    contents: const <PackContentRef>[],
    assets: assets,
    contentAssets: const <ContentAssetRef>[],
  );
}

final class _PackGateway implements ContentManifestGateway {
  _PackGateway({required this.root, required this.packManifest});

  final RootContentManifest root;
  final PackContentManifest packManifest;
  int packCalls = 0;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    return Success<RootManifestFetch>(
      RootManifestChanged(manifest: root, etag: 'root-${root.contentVersion}'),
    );
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    packCalls += 1;
    return Success<PackContentManifest>(packManifest);
  }
}

const _testChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _assetChecksum =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';
const _advancedPackChecksum =
    'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
