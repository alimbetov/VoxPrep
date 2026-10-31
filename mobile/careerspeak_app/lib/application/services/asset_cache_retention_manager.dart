import '../content_delivery/asset_retention.dart';
import '../ports/asset_cache_eviction_store.dart';
import '../ports/asset_cache_retention_repository.dart';
import '../result/result.dart';

typedef RetentionClock = DateTime Function();

final class AssetCacheRetentionManager {
  factory AssetCacheRetentionManager({
    required AssetCacheRetentionRepository retention,
    required AssetCacheEvictionStore evictionStore,
    Duration audioTtl = const Duration(days: 90),
    int batchSize = 100,
    RetentionClock? now,
  }) {
    if (audioTtl <= Duration.zero) {
      throw ArgumentError.value(audioTtl, 'audioTtl', 'must be positive');
    }
    if (batchSize < 1) {
      throw ArgumentError.value(batchSize, 'batchSize', 'must be positive');
    }
    return AssetCacheRetentionManager._(
      retention,
      evictionStore,
      audioTtl,
      batchSize,
      now ?? (() => DateTime.now().toUtc()),
    );
  }

  AssetCacheRetentionManager._(
    this._retention,
    this._evictionStore,
    this._audioTtl,
    this._batchSize,
    this._now,
  );

  final AssetCacheRetentionRepository _retention;
  final AssetCacheEvictionStore _evictionStore;
  final Duration _audioTtl;
  final int _batchSize;
  final RetentionClock _now;

  Future<Result<AssetRetentionCleanupReport>> cleanupExpiredAudio() async {
    final candidates = await _retention.findExpiredAutoCache(
      accessedBefore: _now().toUtc().subtract(_audioTtl),
      limit: _batchSize,
    );
    if (candidates case FailureResult<List<AssetRetentionEntry>>(:final failure)) {
      return FailureResult<AssetRetentionCleanupReport>(failure);
    }

    var evicted = 0;
    var reclaimedBytes = 0;
    var skippedProtected = 0;
    final entries = (candidates as Success<List<AssetRetentionEntry>>).value;

    for (final entry in entries) {
      if (entry.isProtected || !entry.asset.mediaType.startsWith('audio/')) {
        skippedProtected += 1;
        continue;
      }

      final removal = await _evictionStore.evict(entry.asset);
      if (removal case FailureResult<bool>(:final failure)) {
        return FailureResult<AssetRetentionCleanupReport>(failure);
      }

      final removed = (removal as Success<bool>).value;
      if (removed) {
        evicted += 1;
        reclaimedBytes += entry.asset.sizeBytes;
      }

      final forgotten = await _retention.forget(entry.asset.assetId);
      if (forgotten case FailureResult<void>(:final failure)) {
        return FailureResult<AssetRetentionCleanupReport>(failure);
      }
    }

    return Success<AssetRetentionCleanupReport>(
      AssetRetentionCleanupReport(
        examined: entries.length,
        evicted: evicted,
        reclaimedBytes: reclaimedBytes,
        skippedProtected: skippedProtected,
      ),
    );
  }
}
