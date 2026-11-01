import 'content_manifest.dart';

enum AssetRetentionClass {
  autoCache('AUTO_CACHE'),
  explicitDownload('EXPLICIT_DOWNLOAD'),
  pinned('PINNED');

  const AssetRetentionClass(this.storageCode);

  final String storageCode;

  static AssetRetentionClass? fromStorageCode(String value) {
    for (final item in values) {
      if (item.storageCode == value) return item;
    }
    return null;
  }
}

final class AssetRetentionEntry {
  const AssetRetentionEntry({
    required this.asset,
    required this.retentionClass,
    required this.cachedAt,
    required this.lastAccessedAt,
  });

  final ManifestAssetDescriptor asset;
  final AssetRetentionClass retentionClass;
  final DateTime cachedAt;
  final DateTime lastAccessedAt;

  bool get isAutoCache => retentionClass == AssetRetentionClass.autoCache;
  bool get isProtected =>
      retentionClass != AssetRetentionClass.autoCache || asset.requiredOffline;
}

final class AssetRetentionCleanupReport {
  const AssetRetentionCleanupReport({
    required this.examined,
    required this.evicted,
    required this.reclaimedBytes,
    required this.skippedProtected,
  });

  final int examined;
  final int evicted;
  final int reclaimedBytes;
  final int skippedProtected;
}
