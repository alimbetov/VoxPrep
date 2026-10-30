import '../content_delivery/content_manifest.dart';
import '../result/result.dart';
import 'sync_models.dart';

final class ContentSyncPlanner {
  const ContentSyncPlanner();

  Result<SyncPlan> plan({
    required SyncLocalSnapshot local,
    required RootContentManifest remote,
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

    if (currentVersion == remote.contentVersion) {
      final remoteIdentities = remote.packs
          .map((pack) => pack.identity)
          .toSet();
      PackRevisionRef? unexpectedCurrentPack;
      for (final pack in local.currentPacks) {
        if (!remoteIdentities.contains(pack.identity)) {
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
      if (current == null ||
          current.revision != target.revision ||
          current.checksum != target.checksum) {
        changedPacks.add(target);
      }
    }

    final rootChanged = currentVersion != remote.contentVersion;
    return Success(
      SyncPlan(
        target: remote,
        rootChanged: rootChanged,
        changedPacks: changedPacks,
        tombstones: rootChanged
            ? remote.tombstones
            : const <ContentTombstone>[],
      ),
    );
  }
}
