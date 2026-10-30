import '../content_delivery/content_manifest.dart';
import '../result/result.dart';

final class AssetByteStream {
  const AssetByteStream({required this.bytes, required this.contentLength});

  final Stream<List<int>> bytes;
  final int? contentLength;
}

abstract interface class AssetByteSource {
  Future<Result<AssetByteStream>> open(ManifestAssetDescriptor asset);
}
