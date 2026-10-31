import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _root108 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _root109 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _packCanonical =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _packLocale =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  const planner = ContentSyncPlanner();

  test('first install plans every remote pack and tombstone', () {
    final remote = _manifest(
      contentVersion: 108,
      checksum: _root108,
      packs: <PackRevisionRef>[
        _pack('JAVA_SENIOR', 'canonical', 8, _packCanonical),
        _pack('JAVA_SENIOR', 'locale:kk', 4, _packLocale),
      ],
      tombstones: <ContentTombstone>[_tombstone()],
    );

    final result = planner.plan(
      local: SyncLocalSnapshot(
        currentContentVersion: null,
        currentManifestChecksum: null,
        etag: null,
        currentPacks: const <PackRevisionRef>[],
      ),
      remote: remote,
    );

    final plan = (result as Success<SyncPlan>).value;
    expect(plan.rootChanged, isTrue);
    expect(plan.changedPacks, hasLength(2));
    expect(plan.tombstones, hasLength(1));
  });

  test('same immutable root is a deterministic no-op', () {
    final canonical = _pack('JAVA_SENIOR', 'canonical', 8, _packCanonical);
    final remote = _manifest(
      contentVersion: 108,
      checksum: _root108,
      packs: <PackRevisionRef>[canonical],
    );

    final result = planner.plan(
      local: SyncLocalSnapshot(
        currentContentVersion: 108,
        currentManifestChecksum: _root108,
        etag: 'etag-108',
        currentPacks: <PackRevisionRef>[canonical],
      ),
      remote: remote,
      remoteEtag: 'etag-108',
    );

    final plan = (result as Success<SyncPlan>).value;
    expect(plan.isNoOp, isTrue);
    expect(plan.changedPacks, isEmpty);
    expect(plan.tombstones, isEmpty);
  });

  test('same immutable root plans repair for a missing current pack', () {
    final canonical = _pack('JAVA_SENIOR', 'canonical', 8, _packCanonical);
    final locale = _pack('JAVA_SENIOR', 'locale:kk', 4, _packLocale);
    final remote = _manifest(
      contentVersion: 108,
      checksum: _root108,
      packs: <PackRevisionRef>[canonical, locale],
    );

    final result = planner.plan(
      local: SyncLocalSnapshot(
        currentContentVersion: 108,
        currentManifestChecksum: _root108,
        etag: 'etag-108',
        currentPacks: <PackRevisionRef>[canonical],
      ),
      remote: remote,
      remoteEtag: 'etag-108',
    );

    final plan = (result as Success<SyncPlan>).value;
    expect(plan.rootChanged, isTrue);
    expect(plan.isNoOp, isFalse);
    expect(plan.changedPacks, hasLength(1));
    expect(plan.changedPacks.single.identity, locale.identity);
    expect(plan.tombstones, isEmpty);
  });

  test('same immutable root rejects an unexpected current pack', () {
    final canonical = _pack('JAVA_SENIOR', 'canonical', 8, _packCanonical);
    final unexpected = _pack('LEGACY_PACK', 'canonical', 1, _packLocale);
    final remote = _manifest(
      contentVersion: 108,
      checksum: _root108,
      packs: <PackRevisionRef>[canonical],
    );

    final result = planner.plan(
      local: SyncLocalSnapshot(
        currentContentVersion: 108,
        currentManifestChecksum: _root108,
        etag: 'etag-108',
        currentPacks: <PackRevisionRef>[canonical, unexpected],
      ),
      remote: remote,
      remoteEtag: 'etag-108',
    );

    expect(result, isA<FailureResult<SyncPlan>>());
    expect(
      (result as FailureResult<SyncPlan>).failure.code,
      'LOCAL_ROOT_PACK_SET_MISMATCH',
    );
  });

  test('new root plans only missing or changed pack variants', () {
    final canonical = _pack('JAVA_SENIOR', 'canonical', 8, _packCanonical);
    final locale = _pack('JAVA_SENIOR', 'locale:kk', 4, _packLocale);
    final remote = _manifest(
      contentVersion: 109,
      checksum: _root109,
      packs: <PackRevisionRef>[canonical, locale],
    );

    final result = planner.plan(
      local: SyncLocalSnapshot(
        currentContentVersion: 108,
        currentManifestChecksum: _root108,
        etag: 'etag-108',
        currentPacks: <PackRevisionRef>[canonical],
      ),
      remote: remote,
      remoteEtag: 'etag-109',
    );

    final plan = (result as Success<SyncPlan>).value;
    expect(plan.rootChanged, isTrue);
    expect(plan.changedPacks, hasLength(1));
    expect(plan.changedPacks.single.identity, locale.identity);
  });

  test('rejects a remote content version rollback', () {
    final remote = _manifest(contentVersion: 107, checksum: _root109);

    final result = planner.plan(
      local: SyncLocalSnapshot(
        currentContentVersion: 108,
        currentManifestChecksum: _root108,
        etag: 'etag-108',
        currentPacks: const <PackRevisionRef>[],
      ),
      remote: remote,
      remoteEtag: 'etag-107',
    );

    expect(result, isA<FailureResult<SyncPlan>>());
    expect(
      (result as FailureResult<SyncPlan>).failure.code,
      'REMOTE_CONTENT_VERSION_ROLLBACK',
    );
  });

  test('rejects checksum drift inside the same content version', () {
    final remote = _manifest(contentVersion: 108, checksum: _root109);

    final result = planner.plan(
      local: SyncLocalSnapshot(
        currentContentVersion: 108,
        currentManifestChecksum: _root108,
        etag: 'etag-108',
        currentPacks: const <PackRevisionRef>[],
      ),
      remote: remote,
      remoteEtag: 'etag-108',
    );

    expect(result, isA<FailureResult<SyncPlan>>());
    expect(
      (result as FailureResult<SyncPlan>).failure.code,
      'PUBLICATION_SNAPSHOT_IDENTITY_CONFLICT',
    );
  });

  test('rejects ETag drift inside the same content version', () {
    final remote = _manifest(contentVersion: 108, checksum: _root108);

    final result = planner.plan(
      local: SyncLocalSnapshot(
        currentContentVersion: 108,
        currentManifestChecksum: _root108,
        etag: 'etag-108-a',
        currentPacks: const <PackRevisionRef>[],
      ),
      remote: remote,
      remoteEtag: 'etag-108-b',
    );

    expect(result, isA<FailureResult<SyncPlan>>());
    expect(
      (result as FailureResult<SyncPlan>).failure.code,
      'PUBLICATION_SNAPSHOT_IDENTITY_CONFLICT',
    );
  });
}

RootContentManifest _manifest({
  required int contentVersion,
  required String checksum,
  Iterable<PackRevisionRef> packs = const <PackRevisionRef>[],
  Iterable<ContentTombstone> tombstones = const <ContentTombstone>[],
}) {
  return RootContentManifest(
    schemaVersion: 1,
    contentVersion: contentVersion,
    minimumAppContractVersion: 1,
    publishedAt: DateTime.utc(2026, 10, 30, 10),
    checksum: checksum,
    packs: packs,
    tombstones: tombstones,
  );
}

PackRevisionRef _pack(
  String code,
  String variant,
  int revision,
  String checksum,
) {
  return PackRevisionRef(
    identity: PackIdentity(code: code, variant: variant),
    revision: revision,
    checksum: checksum,
  );
}

ContentTombstone _tombstone() {
  return ContentTombstone(
    identity: ContentIdentity(
      code: 'JAVA_QUESTION_001',
      type: ContentType.interview,
    ),
    revision: 3,
    reason: 'INACTIVE',
  );
}
