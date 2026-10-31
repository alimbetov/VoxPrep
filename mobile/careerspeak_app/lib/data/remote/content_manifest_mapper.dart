import '../../application/content_delivery/content_manifest.dart';
import '../../domain/content_identity.dart';
import 'dto/content_manifest_dto.dart';

final class ContentManifestMapper {
  const ContentManifestMapper();

  RootContentManifest mapRoot(RootContentManifestDto dto) {
    return RootContentManifest(
      schemaVersion: dto.schemaVersion,
      contentVersion: dto.contentVersion,
      minimumAppContractVersion: dto.minimumAppContractVersion,
      publishedAt: dto.publishedAt,
      checksum: dto.checksum,
      packs: dto.packs.map(
        (pack) => PackRevisionRef(
          identity: PackIdentity(code: pack.code, variant: pack.variant),
          revision: pack.revision,
          checksum: pack.checksum,
        ),
      ),
      tombstones: dto.tombstones.map(
        (tombstone) => ContentTombstone(
          identity: _identity(tombstone.contentCode, tombstone.contentType),
          revision: tombstone.revision,
          reason: tombstone.reason,
        ),
      ),
    );
  }

  PackContentManifest mapPack(PackContentManifestDto dto) {
    return PackContentManifest(
      schemaVersion: dto.schemaVersion,
      identity: PackIdentity(code: dto.code, variant: dto.variant),
      revision: dto.revision,
      checksum: dto.checksum,
      contents: dto.contents.map(
        (content) => PackContentRef(
          identity: _identity(content.contentCode, content.contentType),
          revision: content.revision,
          checksum: content.checksum,
          sortOrder: content.sortOrder,
          publishedAt: content.publishedAt,
        ),
      ),
      localizations: dto.localizations.map(
        (localization) => LocalizedContentRef(
          identity: _identity(
            localization.contentCode,
            localization.contentType,
          ),
          contentRevision: localization.contentRevision,
          locale: localization.locale,
          localizationRevision: localization.localizationRevision,
          checksum: localization.checksum,
        ),
      ),
      assets: dto.assets.map(
        (asset) => ManifestAssetDescriptor(
          assetId: asset.assetId,
          checksumSha256: asset.checksumSha256,
          deliveryKey: asset.deliveryKey,
          sizeBytes: asset.sizeBytes,
          mediaType: asset.mediaType,
          requiredOffline: asset.requiredOffline,
        ),
      ),
      contentAssets: dto.contentAssets.map(
        (ref) => ContentAssetRef(
          contentIdentity: _identity(ref.contentCode, ref.contentType),
          contentRevision: ref.contentRevision,
          assetId: ref.assetId,
          role: ref.role,
        ),
      ),
    );
  }

  ContentIdentity _identity(String code, String typeName) {
    final type = contentTypeFromWireName(typeName);
    if (type == null) {
      throw ArgumentError.value(
        typeName,
        'contentType',
        'contains an unsupported content type',
      );
    }
    return ContentIdentity(code: code, type: type);
  }
}
