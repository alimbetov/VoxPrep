import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/required_offline_asset_prefetcher.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/sync_journal.dart';
import 'package:careerspeak_app/application/ports/sync_plan_executor.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/asset_download_manager.dart';
import 'package:flutter_test/flutter_test.dart';

const _sha = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('required-offline failure stops sync before commit executor', () async {
    final pack = PackRevisionRef(
      identity: PackIdentity(code: 'PACK_A', variant: 'canonical'),
      revision: 1,
      checksum: _sha,
    );
    // Schema v1 keeps this test focused on commit ordering. Universal-v2 graph
    // membership is qualified independently by the publication/materializer
    // acceptance suite.
    final root = RootContentManifest(
      schemaVersion: 1,
      contentVersion: 2,
      minimumAppContractVersion: 1,
      publishedAt: DateTime.utc(2026, 11, 1),
      checksum: _sha,
      packs: <PackRevisionRef>[pack],
      tombstones: const <ContentTombstone>[],
    );
    final gateway = _Gateway(root: root, pack: _packManifest(pack));
    final journal = _Journal();
    final executor = _Executor();
    final coordinator = ContentSyncCoordinator(
      journal: journal,
      manifestGateway: gateway,
      planner: const ContentSyncPlanner(),
      executor: executor,
      requiredOfflinePrefetcher: RequiredOfflineAssetPrefetcher(
        manifestGateway: gateway,
        ensureLocal: (asset) async => const FailureResult<AssetDownloadOutcome>(
          ApplicationFailure(
            code: 'ASSET_CHECKSUM_MISMATCH',
            message: 'corrupt bytes',
          ),
        ),
      ),
    );

    final result = await coordinator.synchronize(
      runId: 'run-required-offline',
      trigger: SyncTrigger.startup,
      translationLocale: 'en',
    );

    expect(result, isA<FailureResult<ContentSyncOutcome>>());
    expect(executor.calls, 0);
    expect(journal.persistedPlans, 1);
    expect(journal.states, contains(SyncRunState.staging));
    expect(journal.states.last, SyncRunState.failedFatal);
    expect(journal.failures.last?.code, 'REQUIRED_OFFLINE_ASSET_UNAVAILABLE');
  });
}

PackContentManifest _packManifest(PackRevisionRef pack) {
  return PackContentManifest(
    schemaVersion: 2,
    identity: pack.identity,
    revision: pack.revision,
    checksum: pack.checksum,
    contents: const <PackContentRef>[],
    assets: <ManifestAssetDescriptor>[
      ManifestAssetDescriptor(
        assetId: 'required-a',
        checksumSha256: _sha,
        deliveryKey: 'offline/required-a.bin',
        sizeBytes: 5,
        mediaType: 'application/octet-stream',
        requiredOffline: true,
      ),
    ],
    contentAssets: const <ContentAssetRef>[],
  );
}

final class _Gateway implements ContentManifestGateway {
  const _Gateway({required this.root, required this.pack});

  final RootContentManifest root;
  final PackContentManifest pack;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    return Success<RootManifestFetch>(
      RootManifestChanged(manifest: root, etag: 'etag-2'),
    );
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    return Success<PackContentManifest>(pack);
  }
}

final class _Journal implements SyncJournal {
  final states = <SyncRunState>[];
  final failures = <ApplicationFailure?>[];
  int persistedPlans = 0;

  @override
  Future<Result<SyncRunStart>> startOrCoalesce({
    required String runId,
    required SyncTrigger trigger,
    required String translationLocale,
  }) async {
    return Success<SyncRunStart>(SyncRunStarted(runId));
  }

  @override
  Future<Result<SyncLocalSnapshot>> readLocalSnapshot() async {
    return Success<SyncLocalSnapshot>(
      SyncLocalSnapshot(
        currentContentVersion: 1,
        currentManifestChecksum: _sha,
        etag: 'etag-1',
        currentPacks: const <PackRevisionRef>[],
      ),
    );
  }

  @override
  Future<Result<void>> persistPlan({
    required String runId,
    required SyncPlan plan,
  }) async {
    persistedPlans += 1;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> transitionRun({
    required String runId,
    required SyncRunState state,
    ApplicationFailure? failure,
  }) async {
    states.add(state);
    failures.add(failure);
    return const Success<void>(null);
  }
}

final class _Executor implements SyncPlanExecutor {
  int calls = 0;

  @override
  Future<Result<void>> execute({
    required String runId,
    required SyncPlan plan,
  }) async {
    calls += 1;
    return const Success<void>(null);
  }
}
