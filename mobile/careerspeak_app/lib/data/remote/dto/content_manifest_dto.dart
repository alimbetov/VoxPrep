final class PackRevisionDto {
  const PackRevisionDto({
    required this.code,
    required this.variant,
    required this.revision,
    required this.checksum,
  });

  final String code;
  final String variant;
  final int revision;
  final String checksum;
}

final class ContentTombstoneDto {
  const ContentTombstoneDto({
    required this.contentCode,
    required this.contentType,
    required this.revision,
    required this.reason,
  });

  final String contentCode;
  final String contentType;
  final int revision;
  final String reason;
}

final class RootContentManifestDto {
  const RootContentManifestDto({
    required this.schemaVersion,
    required this.contentVersion,
    required this.minimumAppContractVersion,
    required this.publishedAt,
    required this.checksum,
    required this.packs,
    required this.tombstones,
  });

  final int schemaVersion;
  final int contentVersion;
  final int minimumAppContractVersion;
  final DateTime publishedAt;
  final String checksum;
  final List<PackRevisionDto> packs;
  final List<ContentTombstoneDto> tombstones;
}

final class PackContentRefDto {
  const PackContentRefDto({
    required this.contentCode,
    required this.contentType,
    required this.revision,
    required this.checksum,
    required this.sortOrder,
    required this.publishedAt,
  });

  final String contentCode;
  final String contentType;
  final int revision;
  final String checksum;
  final int? sortOrder;
  final DateTime? publishedAt;
}

final class ManifestAssetDescriptorDto {
  const ManifestAssetDescriptorDto({
    required this.assetId,
    required this.checksumSha256,
    required this.deliveryKey,
    required this.sizeBytes,
    required this.mediaType,
    required this.requiredOffline,
  });

  final String assetId;
  final String checksumSha256;
  final String deliveryKey;
  final int sizeBytes;
  final String mediaType;
  final bool requiredOffline;
}

final class ContentAssetRefDto {
  const ContentAssetRefDto({
    required this.contentCode,
    required this.contentType,
    required this.contentRevision,
    required this.assetId,
    required this.role,
  });

  final String contentCode;
  final String contentType;
  final int contentRevision;
  final String assetId;
  final String role;
}

final class PackContentManifestDto {
  const PackContentManifestDto({
    required this.schemaVersion,
    required this.code,
    required this.variant,
    required this.revision,
    required this.checksum,
    required this.contents,
    required this.assets,
    required this.contentAssets,
  });

  final int schemaVersion;
  final String code;
  final String variant;
  final int revision;
  final String checksum;
  final List<PackContentRefDto> contents;
  final List<ManifestAssetDescriptorDto> assets;
  final List<ContentAssetRefDto> contentAssets;
}
