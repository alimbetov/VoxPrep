import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/ports/publication_snapshot_stager.dart';
import 'package:careerspeak_app/application/ports/sync_journal.dart';
import 'package:careerspeak_app/application/ports/sync_plan_executor.dart';
import 'package:careerspeak_app/application/result/result.dart';

const rootA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const rootB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const packHash =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

SyncLocalSnapshot emptySnapshot() => SyncLocalSnapshot(
  currentContentVersion: null,
  currentManifestChecksum: null,
  etag: null,
  currentPacks: const <PackRevisionRef>[],
);

RootContentManifest manifest(
  int version, {
  Iterable<PackRevisionRef> packs = const <PackRevisionRef>[],
  Iterable<PracticeTestRevisionRef> practiceTests =
      const <PracticeTestRevisionRef>[],
  Iterable<CatalogueRevisionRef> catalogues = const <CatalogueRevisionRef>[],
  Iterable<LocaleFallbackRule> localeFallbacks = const <LocaleFallbackRule>[],
}) {
  return RootContentManifest(
    schemaVersion: 1,
    contentVersion: version,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 30, 10),
    checksum: version == 108 ? rootA : rootB,
    packs: packs,
    practiceTests: practiceTests,
    catalogues: catalogues,
    localeFallbacks: localeFallbacks,
    tombstones: const <ContentTombstone>[],
  );
}

PackRevisionRef pack() => PackRevisionRef(
  identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
  revision: 8,
  checksum: packHash,
);

final class FakeJournal implements SyncJournal {
  FakeJournal(this.snapshot);

  final Result<SyncLocalSnapshot> snapshot;
  final states = <SyncRunState>[];
  final plans = <SyncPlan>[];
  final translationLocales = <String>[];
  String? coalescedRunId;
  ApplicationFailure? transitionFailure;

  @override
  Future<Result<SyncLocalSnapshot>> readLocalSnapshot() async => snapshot;

  @override
  Future<Result<SyncRunStart>> startOrCoalesce({
    required String runId,
    required SyncTrigger trigger,
    required String translationLocale,
  }) async {
    translationLocales.add(translationLocale);
    return Success(
      coalescedRunId == null
          ? SyncRunStarted(runId)
          : SyncRunCoalesced(coalescedRunId!),
    );
  }

  @override
  Future<Result<void>> persistPlan({
    required String runId,
    required SyncPlan plan,
  }) async {
    plans.add(plan);
    return const Success(null);
  }

  @override
  Future<Result<void>> transitionRun({
    required String runId,
    required SyncRunState state,
    ApplicationFailure? failure,
  }) async {
    states.add(state);
    final failed = transitionFailure;
    return failed == null ? const Success(null) : FailureResult(failed);
  }
}

final class FakeGateway implements ContentManifestGateway {
  FakeGateway(this.result);

  final Result<RootManifestFetch> result;
  int calls = 0;
  final etags = <String?>[];

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    calls += 1;
    etags.add(etag);
    return result;
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    return const FailureResult(
      ApplicationFailure(
        code: 'NOT_USED',
        message: 'Not used by orchestration tests.',
      ),
    );
  }
}

final class FakeExecutor implements SyncPlanExecutor {
  FakeExecutor([Result<void>? result]) : result = result ?? const Success(null);

  final Result<void> result;
  int calls = 0;

  @override
  Future<Result<void>> execute({
    required String runId,
    required SyncPlan plan,
  }) async {
    calls += 1;
    return result;
  }
}

final class FakeSnapshotStager implements PublicationSnapshotStager {
  FakeSnapshotStager([Result<void>? result])
    : result = result ?? const Success(null);

  final Result<void> result;
  final List<RootContentManifest> targets = <RootContentManifest>[];

  @override
  Future<Result<void>> stage(RootContentManifest target) async {
    targets.add(target);
    return result;
  }
}
