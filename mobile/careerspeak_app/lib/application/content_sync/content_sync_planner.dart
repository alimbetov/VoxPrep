import '../content_delivery/content_manifest.dart';
import '../result/result.dart';
import 'sync_models.dart';

final class ContentSyncPlanner {
  const ContentSyncPlanner();

  Result<SyncPlan> plan({
    required SyncLocalSnapshot local,
    required RootContentManifest remote,
    Iterable<PackIdentity>? immutableRootPackIdentities,
  }) {
    final currentVersion = local.currentContentVersion;

    if (currentVersion != null && remote.contentVersion < currentVersion) {
      return FailureResult(
        ApplicationFailure(
          code: 'REMOTE_CONTENT_VERSION_ROLLBACK',
          message:
              'Remote content version is older than the installed CURRENT snapshot.',
          details: <String, Object?>{
            'currentContentVersion': currentVersion,
            'remoteContentVersion': remote.contentVersion,
          },
        ),
      );
    }

    if (currentVersion == remote.contentVersion &&
        local.currentManifestChecksum != remote.checksum) {
      return FailureResult(
        ApplicationFailure(
          code: 'CONTENT_VERSION_CHECKSUM_CONFLICT',
          message:
              'The same content version was observed with a different manifest checksum.',
          details: <String, Object?>{'contentVersion': remote.contentVersion},
        ),
      );
    }

    final currentByIdentity = <PackIdentity, PackRevisionRef>{
      for (final pack in local.currentPacks) pack.identity: pack,
    };
    final immutableIdentities = Set<PackIdentity>.unmodifiable(
      immutableRootPackIdentities ?? remote.packs.map((pack) => pack.identity),
    );

    if (currentVersion == remote.contentVersion) {
      PackRevisionRef? unexpectedCurrentPack;
      for (final pack in local.currentPacks) {
        if (!immutableIdentities.contains(pack.identity)) {
          unexpectedCurrentPack = pack;
          break;
        }
      }
      if (unexpectedCurrentPack != null) {
        return FailureResult(
          ApplicationFailure(
            code: 'LOCAL_ROOT_PACK_SET_MISMATCH',
            message:
                'The local CURRENT pack set contains a pack outside the immutable root snapshot.',
            details: <String, Object?>{
              'packCode': unexpectedCurrentPack.identity.code,
              'variant': unexpectedCurrentPack.identity.variant,
            },
          ),
        );
      }
    }

    final changedPacks = <PackRevisionRef>[];
    for (final target in remote.packs) {
      final current = currentByIdentity[target.identity];
      final requiresPayloadRepair = local.contentPayloadRepairPacks.contains(
        target.identity,
      );
      if (current == null ||
          current.revision != target.revision ||
          current.checksum != target.checksum ||
          requiresPayloadRepair) {
        changedPacks.add(target);
      }
    }

    final publicationRootChanged = currentVersion != remote.contentVersion;
    final projectionChanged =
        currentVersion == remote.contentVersion &&
        !_samePackProjection(local.currentPacks, remote.packs);
    return Success(
      SyncPlan(
        target: remote,
        rootChanged: publicationRootChanged || projectionChanged,
        changedPacks: changedPacks,
        tombstones: publicationRootChanged
            ? remote.tombstones
            : const <ContentTombstone>[],
      ),
    );
  }
}

bool _samePackProjection(
  Iterable<PackRevisionRef> current,
  Iterable<PackRevisionRef> target,
) {
  final currentByIdentity = <PackIdentity, PackRevisionRef>{
    for (final pack in current) pack.identity: pack,
  };
  final targetList = target.toList(growable: false);
  if (currentByIdentity.length != targetList.length) return false;

  for (final pack in targetList) {
    final installed = currentByIdentity[pack.identity];
    if (installed == null ||
        installed.revision != pack.revision ||
        installed.checksum != pack.checksum) {
      return false;
    }
  }
  return true;
}
