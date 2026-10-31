import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/sync_orchestration_fakes.dart';

void main() {
  test('sync materializes only canonical plus exact and language fallback packs', () async {
    final canonical = _pack('canonical', revision: 8);
    final russian = _pack('locale:ru', revision: 5);
    final regional = _pack('locale:ru-KZ', revision: 2);
    final kazakh = _pack('locale:kk', revision: 4);
    final german = _pack('locale:de', revision: 3);
    final journal = FakeJournal(Success(emptySnapshot()));
    final executor = FakeExecutor();
    final gateway = FakeGateway(
      Success(
        RootManifestChanged(
          manifest: manifest(
            109,
            packs: <PackRevisionRef>[
              canonical,
              russian,
              regional,
              kazakh,
              german,
            ],
          ),
          etag: 'root-109',
        ),
      ),
    );

    final result = await _coordinator(journal, gateway, executor).synchronize(
      runId: 'locale-projection-fresh',
      trigger: SyncTrigger.startup,
      translationLocale: 'ru-kz',
    );

    expect(result, isA<Success<ContentSyncOutcome>>());
    expect(executor.calls, 1);
    final plan = journal.plans.single;
    expect(
      plan.target.packs.map((pack) => pack.identity.variant).toList(),
      <String>['canonical', 'locale:ru', 'locale:ru-KZ'],
    );
    expect(plan.changedPacks, hasLength(3));
    expect(plan.target.contentVersion, 109);
    expect(plan.target.checksum, rootB);
  });

  test('same-root locale change commits removal-only pack projection', () async {
    final canonical = _pack('canonical', revision: 8);
    final russian = _pack('locale:ru', revision: 5);
    final journal = FakeJournal(
      Success(
        SyncLocalSnapshot(
          currentContentVersion: 108,
          currentManifestChecksum: rootA,
          etag: 'root-108',
          currentPacks: <PackRevisionRef>[canonical, russian],
        ),
      ),
    );
    final executor = FakeExecutor();
    final gateway = FakeGateway(
      Success(
        RootManifestChanged(
          manifest: manifest(
            108,
            packs: <PackRevisionRef>[canonical, russian],
          ),
          etag: 'root-108',
        ),
      ),
    );

    final result = await _coordinator(journal, gateway, executor).synchronize(
      runId: 'locale-projection-remove',
      trigger: SyncTrigger.localeChange,
      translationLocale: 'kk',
    );

    expect(result, isA<Success<ContentSyncOutcome>>());
    expect(executor.calls, 1);
    final plan = journal.plans.single;
    expect(plan.target.packs, hasLength(1));
    expect(plan.target.packs.single.identity.variant, 'canonical');
    expect(plan.changedPacks, isEmpty);
    expect(plan.rootChanged, isTrue);
    expect(plan.tombstones, isEmpty);
    expect(plan.target.contentVersion, 108);
    expect(plan.target.checksum, rootA);
  });

  test('same-root local pack outside immutable backend root still fails closed', () async {
    final canonical = _pack('canonical', revision: 8);
    final staleGerman = _pack('locale:de', revision: 3);
    final journal = FakeJournal(
      Success(
        SyncLocalSnapshot(
          currentContentVersion: 108,
          currentManifestChecksum: rootA,
          etag: 'root-108',
          currentPacks: <PackRevisionRef>[canonical, staleGerman],
        ),
      ),
    );
    final executor = FakeExecutor();
    final gateway = FakeGateway(
      Success(
        RootManifestChanged(
          manifest: manifest(108, packs: <PackRevisionRef>[canonical]),
          etag: 'root-108',
        ),
      ),
    );

    final result = await _coordinator(journal, gateway, executor).synchronize(
      runId: 'locale-projection-corrupt',
      trigger: SyncTrigger.startup,
      translationLocale: 'kk',
    );

    expect(result, isA<FailureResult<ContentSyncOutcome>>());
    expect(
      (result as FailureResult<ContentSyncOutcome>).failure.code,
      'LOCAL_ROOT_PACK_SET_MISMATCH',
    );
    expect(executor.calls, 0);
  });

  test('invalid requested locale fails before planning or execution', () async {
    final journal = FakeJournal(Success(emptySnapshot()));
    final executor = FakeExecutor();
    final gateway = FakeGateway(
      Success(
        RootManifestChanged(
          manifest: manifest(109, packs: <PackRevisionRef>[_pack('canonical')]),
          etag: 'root-109',
        ),
      ),
    );

    final result = await _coordinator(journal, gateway, executor).synchronize(
      runId: 'locale-projection-invalid',
      trigger: SyncTrigger.startup,
      translationLocale: 'ru_KZ',
    );

    expect(result, isA<FailureResult<ContentSyncOutcome>>());
    expect(
      (result as FailureResult<ContentSyncOutcome>).failure.code,
      'LOCALE_INVALID',
    );
    expect(journal.plans, isEmpty);
    expect(executor.calls, 0);
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

PackRevisionRef _pack(String variant, {int revision = 1}) {
  return PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: variant),
    revision: revision,
    checksum: packHash,
  );
}
