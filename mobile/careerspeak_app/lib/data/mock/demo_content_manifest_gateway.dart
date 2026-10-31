import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/content_manifest_gateway.dart';
import '../../application/result/result.dart';

const _demoRootChecksum =
    '7777777777777777777777777777777777777777777777777777777777777777';
const _demoRootEtag = 'demo-root-v2';

final class DemoContentManifestGateway implements ContentManifestGateway {
  DemoContentManifestGateway({
    required Iterable<CataloguePayload> cataloguePayloads,
    this.latency = const Duration(milliseconds: 250),
  }) : _manifest = RootContentManifest(
         schemaVersion: 2,
         contentVersion: 1,
         minimumAppContractVersion: 2,
         publishedAt: DateTime.utc(2026, 10, 31),
         checksum: _demoRootChecksum,
         packs: const <PackRevisionRef>[],
         catalogues: [for (final payload in cataloguePayloads) payload.ref],
         tombstones: const <ContentTombstone>[],
       );

  final RootContentManifest _manifest;
  final Duration latency;

  @override
  Future<Result<RootManifestFetch>> fetchRootManifest({String? etag}) async {
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    if (etag == _demoRootEtag) {
      return const Success<RootManifestFetch>(
        RootManifestNotModified(etag: _demoRootEtag),
      );
    }
    return Success<RootManifestFetch>(
      RootManifestChanged(manifest: _manifest, etag: _demoRootEtag),
    );
  }

  @override
  Future<Result<PackContentManifest>> fetchPackManifest(
    PackRevisionRef target,
  ) async {
    return FailureResult<PackContentManifest>(
      ApplicationFailure(
        code: 'DEMO_PACK_NOT_FOUND',
        message: 'Demo root manifest does not publish content packs yet.',
        details: <String, Object?>{
          'packCode': target.packCode,
          'revision': target.revision,
        },
      ),
    );
  }
}
