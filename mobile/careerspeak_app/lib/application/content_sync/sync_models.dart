import '../content_delivery/content_manifest.dart';

enum SyncTrigger {
  startup('STARTUP'),
  manual('MANUAL'),
  localeChange('LOCALE_CHANGE'),
  packDownload('PACK_DOWNLOAD'),
  periodicFreshness('PERIODIC_FRESHNESS'),
  recovery('RECOVERY');

  const SyncTrigger(this.storageCode);

  final String storageCode;

  static SyncTrigger fromStorage(String value) {
    for (final trigger in values) {
      if (trigger.storageCode == value) return trigger;
    }
    throw FormatException('Unsupported sync trigger: $value');
  }
}

enum SyncRunState {
  created('CREATED', terminal: false),
  checkingLocal('CHECKING_LOCAL', terminal: false),
  checkingRemote('CHECKING_REMOTE', terminal: false),
  planning('PLANNING', terminal: false),
  staging('STAGING', terminal: false),
  verifying('VERIFYING', terminal: false),
  committing('COMMITTING', terminal: false),
  cleaning('CLEANING', terminal: false),
  succeeded('SUCCEEDED', terminal: true),
  deferredOffline('DEFERRED_OFFLINE', terminal: true),
  blockedSchema('BLOCKED_SCHEMA', terminal: true),
  failedRetryable('FAILED_RETRYABLE', terminal: true),
  failedFatal('FAILED_FATAL', terminal: true),
  cancelled('CANCELLED', terminal: true);

  const SyncRunState(this.storageCode, {required this.terminal});

  final String storageCode;
  final bool terminal;

  static SyncRunState fromStorage(String value) {
    for (final state in values) {
      if (state.storageCode == value) return state;
    }
    throw FormatException('Unsupported sync run state: $value');
  }
}

enum SyncPackUpdateState {
  planned('PLANNED'),
  fetchingManifest('FETCHING_MANIFEST'),
  stagingMetadata('STAGING_METADATA'),
  verifying('VERIFYING'),
  readyToCommit('READY_TO_COMMIT'),
  committed('COMMITTED'),
  failed('FAILED'),
  superseded('SUPERSEDED');

  const SyncPackUpdateState(this.storageCode);

  final String storageCode;
}

enum SyncTombstoneState {
  planned('PLANNED'),
  applied('APPLIED');

  const SyncTombstoneState(this.storageCode);

  final String storageCode;
}

final class SyncLocalSnapshot {
  factory SyncLocalSnapshot({
    required int? currentContentVersion,
    required String? currentManifestChecksum,
    required String? etag,
    required Iterable<PackRevisionRef> currentPacks,
    Iterable<PackIdentity> contentPayloadRepairPacks = const <PackIdentity>[],
    Iterable<LocaleFallbackRule> currentLocaleFallbacks =
        const <LocaleFallbackRule>[],
    bool localePolicyRepairRequired = false,
  }) {
    final packs = List<PackRevisionRef>.unmodifiable(currentPacks);
    final identities = <PackIdentity>{};
    for (final pack in packs) {
      if (!identities.add(pack.identity)) {
        throw ArgumentError.value(
          pack.identity,
          'currentPacks',
          'contains duplicate CURRENT pack identity',
        );
      }
    }

    final repairPacks = Set<PackIdentity>.unmodifiable(
      contentPayloadRepairPacks,
    );
    final fallbackRules = List<LocaleFallbackRule>.unmodifiable(
      currentLocaleFallbacks,
    );
    final fallbackRuleLocales = <String>{};
    for (final rule in fallbackRules) {
      if (!fallbackRuleLocales.add(rule.locale)) {
        throw ArgumentError.value(
          rule.locale,
          'currentLocaleFallbacks',
          'contains duplicate requested locale policy',
        );
      }
    }
    for (final identity in repairPacks) {
      if (!identities.contains(identity)) {
        throw ArgumentError.value(
          identity,
          'contentPayloadRepairPacks',
          'must reference a CURRENT pack',
        );
      }
    }

    if (currentContentVersion == null) {
      if (currentManifestChecksum != null ||
          etag != null ||
          packs.isNotEmpty ||
          repairPacks.isNotEmpty ||
          fallbackRules.isNotEmpty ||
          localePolicyRepairRequired) {
        throw ArgumentError(
          'A missing CURRENT root cannot carry checksum, ETag, CURRENT packs, fallback policy, or repair work.',
        );
      }
    } else {
      if (currentContentVersion <= 0) {
        throw ArgumentError.value(
          currentContentVersion,
          'currentContentVersion',
          'must be positive',
        );
      }
      if (currentManifestChecksum == null || currentManifestChecksum.isEmpty) {
        throw ArgumentError('A CURRENT root requires a manifest checksum.');
      }
    }

    return SyncLocalSnapshot._(
      currentContentVersion: currentContentVersion,
      currentManifestChecksum: currentManifestChecksum,
      etag: etag,
      currentPacks: packs,
      contentPayloadRepairPacks: repairPacks,
      currentLocaleFallbacks: fallbackRules,
      localePolicyRepairRequired: localePolicyRepairRequired,
    );
  }

  const SyncLocalSnapshot._({
    required this.currentContentVersion,
    required this.currentManifestChecksum,
    required this.etag,
    required this.currentPacks,
    required this.contentPayloadRepairPacks,
    required this.currentLocaleFallbacks,
    required this.localePolicyRepairRequired,
  });

  final int? currentContentVersion;
  final String? currentManifestChecksum;
  final String? etag;
  final List<PackRevisionRef> currentPacks;

  /// CURRENT pack identities whose immutable learner payload graph is missing
  /// or inconsistent and therefore must be re-fetched even when the root and
  /// pack revision/checksum are unchanged. Applies to canonical and locale
  /// packs alike.
  final Set<PackIdentity> contentPayloadRepairPacks;

  /// Persisted Backend-owned policy for the CURRENT immutable root. This is
  /// compared with the freshly fetched root so deleted/tampered rows trigger a
  /// same-root repair instead of silently changing fallback behavior.
  final List<LocaleFallbackRule> currentLocaleFallbacks;

  /// True when the CURRENT root predates persisted Backend-owned fallback
  /// policy, the policy marker belongs to another contentVersion, or the local
  /// row ordering/version metadata is internally inconsistent.
  final bool localePolicyRepairRequired;
}

final class SyncPlan {
  SyncPlan({
    required this.target,
    required this.rootChanged,
    required Iterable<PackRevisionRef> changedPacks,
    required Iterable<ContentTombstone> tombstones,
  }) : changedPacks = List<PackRevisionRef>.unmodifiable(changedPacks),
       tombstones = List<ContentTombstone>.unmodifiable(tombstones);

  final RootContentManifest target;

  /// True when committing is required because either the immutable publication
  /// changed or the device-local pack projection changed for the same root.
  final bool rootChanged;
  final List<PackRevisionRef> changedPacks;
  final List<ContentTombstone> tombstones;

  bool get isNoOp => !rootChanged && changedPacks.isEmpty && tombstones.isEmpty;
}

sealed class SyncRunStart {
  const SyncRunStart(this.runId);

  final String runId;
}

final class SyncRunStarted extends SyncRunStart {
  const SyncRunStarted(super.runId);
}

final class SyncRunCoalesced extends SyncRunStart {
  const SyncRunCoalesced(super.runId);
}
