import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/root_manifest_materializer.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('schema v2 locale materialization preserves all universal catalogues', () {
    final catalogues = <CatalogueRevisionRef>[
      _ref(CatalogueKind.verticalSections, 1),
      _ref(CatalogueKind.verticals, 2),
      _ref(CatalogueKind.verticalPresentation, 3),
      _ref(CatalogueKind.learningGoals, 4),
      _ref(CatalogueKind.learningTracks, 5),
      _ref(CatalogueKind.learningCollections, 6),
    ];
    final root = RootContentManifest(
      schemaVersion: 2,
      contentVersion: 200,
      minimumAppContractVersion: 2,
      publishedAt: DateTime.utc(2026, 10, 31, 16),
      checksum: _hash,
      packs: const <PackRevisionRef>[],
      catalogues: catalogues,
      tombstones: const <ContentTombstone>[],
    );

    final result = const RootManifestMaterializer().materialize(
      root: root,
      translationLocale: 'en',
    );

    expect(result, isA<Success<RootContentManifest>>());
    final projected = (result as Success<RootContentManifest>).value;
    expect(projected.schemaVersion, 2);
    expect(projected.catalogues, hasLength(catalogues.length));
    for (var index = 0; index < catalogues.length; index++) {
      expect(projected.catalogues[index].kind, catalogues[index].kind);
      expect(projected.catalogues[index].revision, catalogues[index].revision);
      expect(projected.catalogues[index].checksum, catalogues[index].checksum);
    }
  });
}

CatalogueRevisionRef _ref(CatalogueKind kind, int revision) {
  return CatalogueRevisionRef(
    kind: kind,
    revision: revision,
    checksum: _hash,
  );
}
