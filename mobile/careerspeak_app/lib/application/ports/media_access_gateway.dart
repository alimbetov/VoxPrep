import '../result/result.dart';

final class MediaAccessGrant {
  factory MediaAccessGrant({
    required String assetId,
    required Uri url,
    required DateTime expiresAt,
  }) {
    final normalizedAssetId = assetId.trim();
    if (normalizedAssetId.isEmpty) {
      throw ArgumentError.value(assetId, 'assetId', 'must be non-blank');
    }
    if (!url.isAbsolute ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasFragment) {
      throw ArgumentError.value(
        url,
        'url',
        'must be an absolute HTTPS URL without credentials or fragment',
      );
    }
    return MediaAccessGrant._(
      assetId: normalizedAssetId,
      url: url,
      expiresAt: expiresAt.toUtc(),
    );
  }

  const MediaAccessGrant._({
    required this.assetId,
    required this.url,
    required this.expiresAt,
  });

  final String assetId;
  final Uri url;
  final DateTime expiresAt;
}

abstract interface class MediaAccessGateway {
  Future<Result<MediaAccessGrant>> resolve(String assetId);
}
