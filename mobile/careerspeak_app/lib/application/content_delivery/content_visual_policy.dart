import 'content_manifest.dart';

enum ContentVisualRole {
  coverImage('coverImage');

  const ContentVisualRole(this.wireName);

  final String wireName;

  static ContentVisualRole? fromWireName(String value) {
    for (final role in values) {
      if (role.wireName == value) return role;
    }
    return null;
  }
}

final class ContentCoverAsset {
  const ContentCoverAsset({required this.ref, required this.asset});

  final ContentAssetRef ref;
  final ManifestAssetDescriptor asset;
}

final class ContentVisualPolicy {
  const ContentVisualPolicy._();

  static bool isPreviewSafe(ContentVisualRole role) =>
      role == ContentVisualRole.coverImage;

  static bool isSupportedCoverMediaType(String mediaType) {
    final normalized = mediaType.trim().toLowerCase();
    return normalized == 'image/webp' ||
        normalized == 'image/jpeg' ||
        normalized == 'image/png';
  }

  static ContentCoverAsset? resolveCover({
    required Iterable<ContentAssetRef> refs,
    required Iterable<ManifestAssetDescriptor> assets,
  }) {
    final coverRefs = refs
        .where(
          (ref) =>
              ContentVisualRole.fromWireName(ref.role) ==
              ContentVisualRole.coverImage,
        )
        .toList(growable: false);

    if (coverRefs.isEmpty) return null;
    if (coverRefs.length != 1) {
      throw const FormatException(
        'An exact content revision may reference at most one cover image.',
      );
    }

    final ref = coverRefs.single;
    final matchingAssets = assets
        .where((asset) => asset.assetId == ref.assetId)
        .toList(growable: false);
    if (matchingAssets.length != 1) {
      throw FormatException(
        'Cover image asset ${ref.assetId} must resolve exactly once.',
      );
    }

    final asset = matchingAssets.single;
    if (!isSupportedCoverMediaType(asset.mediaType)) {
      throw FormatException(
        'Cover image ${ref.assetId} uses unsupported media type.',
      );
    }

    return ContentCoverAsset(ref: ref, asset: asset);
  }
}
