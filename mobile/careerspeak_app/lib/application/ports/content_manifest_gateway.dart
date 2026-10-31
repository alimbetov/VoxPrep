import '../content_delivery/content_manifest.dart';
import '../result/result.dart';

sealed class RootManifestFetch {
  const RootManifestFetch({required this.etag});

  final String? etag;
}

final class RootManifestChanged extends RootManifestFetch {
  const RootManifestChanged({required this.manifest, required super.etag});

  final RootContentManifest manifest;
}

final class RootManifestNotModified extends RootManifestFetch {
  const RootManifestNotModified({required super.etag});
}

abstract interface class ContentManifestGateway {
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag});

  Future<Result<PackContentManifest>> fetchPackManifest(PackRevisionRef target);
}
