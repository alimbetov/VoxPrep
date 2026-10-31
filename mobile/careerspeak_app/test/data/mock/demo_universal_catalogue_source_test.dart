import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/mock/demo_catalogue_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_content_manifest_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_vertical_catalogue_fixture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo source publishes exact six-core schema v2 catalogue graph', () async {
    final payloads = buildDemoVerticalCataloguePayloads();
    final manifestGateway = DemoContentManifestGateway(
      cataloguePayloads: payloads.values,
      latency: Duration.zero,
    );
    final catalogueGateway = DemoCataloguePayloadGateway(
      payloads: payloads,
      latency: Duration.zero,
    );

    final fetched = await manifestGateway.fetchRootManifest();
    expect(fetched, isA<Success<RootManifestFetch>>());
    final changed = (fetched as Success<RootManifestFetch>).value;
    expect(changed, isA<RootManifestChanged>());
    final root = (changed as RootManifestChanged).manifest;

    expect(root.schemaVersion, 2);
    expect(root.minimumAppContractVersion, 2);
    expect(root.catalogues.map((ref) => ref.kind).toSet(), <CatalogueKind>{
      CatalogueKind.verticalSections,
      CatalogueKind.verticals,
      CatalogueKind.verticalPresentation,
      CatalogueKind.learningGoals,
      CatalogueKind.learningTracks,
      CatalogueKind.learningCollections,
    });

    for (final ref in root.catalogues) {
      final payload = await catalogueGateway.fetch(ref);
      expect(payload, isA<Success>());
    }
  });

  test('demo root honors etag not-modified semantics', () async {
    final gateway = DemoContentManifestGateway(
      cataloguePayloads: buildDemoVerticalCataloguePayloads().values,
      latency: Duration.zero,
    );
    final first = await gateway.fetchRootManifest();
    final etag = ((first as Success<RootManifestFetch>).value).etag;
    final second = await gateway.fetchRootManifest(etag: etag);
    expect((second as Success<RootManifestFetch>).value, isA<RootManifestNotModified>());
  });
}
