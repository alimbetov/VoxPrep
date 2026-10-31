import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_sync/root_manifest_materializer.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:flutter_test/flutter_test.dart';

const _rootHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _packHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _testHash =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _catalogueHash =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';

void main() {
  test(
    'locale projection preserves exact practice-test and catalogue membership',
    () {
      final practiceTest = PracticeTestRevisionRef(
        practiceTestCode: 'JAVA_TEST_001',
        revision: 4,
        checksum: _testHash,
      );
      final catalogue = CatalogueRevisionRef(
        kind: CatalogueKind.learningCollections,
        revision: 7,
        checksum: _catalogueHash,
      );
      final root = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 120,
        minimumAppContractVersion: 1,
        publishedAt: DateTime.utc(2026, 10, 31, 15),
        checksum: _rootHash,
        packs: <PackRevisionRef>[
          PackRevisionRef(
            identity: PackIdentity(code: 'JAVA', variant: 'canonical'),
            revision: 8,
            checksum: _packHash,
          ),
          PackRevisionRef(
            identity: PackIdentity(code: 'JAVA', variant: 'locale:ru'),
            revision: 3,
            checksum: _packHash,
          ),
          PackRevisionRef(
            identity: PackIdentity(code: 'JAVA', variant: 'locale:de'),
            revision: 2,
            checksum: _packHash,
          ),
        ],
        practiceTests: <PracticeTestRevisionRef>[practiceTest],
        catalogues: <CatalogueRevisionRef>[catalogue],
        localeFallbacks: <LocaleFallbackRule>[
          LocaleFallbackRule(
            locale: 'ru-KZ',
            fallbackLocales: const <String>['ru', 'en'],
          ),
        ],
        tombstones: const <ContentTombstone>[],
      );

      final result = const RootManifestMaterializer().materialize(
        root: root,
        translationLocale: 'ru-KZ',
      );

      expect(result, isA<Success<RootContentManifest>>());
      final projected = (result as Success<RootContentManifest>).value;
      expect(
        projected.packs.map((ref) => ref.identity.variant).toList(),
        <String>['canonical', 'locale:ru'],
      );
      expect(projected.practiceTests, hasLength(1));
      expect(projected.practiceTests.single.identityKey, practiceTest.identityKey);
      expect(projected.practiceTests.single.revision, practiceTest.revision);
      expect(projected.practiceTests.single.checksum, practiceTest.checksum);
      expect(projected.catalogues, hasLength(1));
      expect(projected.catalogues.single.kind, catalogue.kind);
      expect(projected.catalogues.single.revision, catalogue.revision);
      expect(projected.catalogues.single.checksum, catalogue.checksum);
      expect(projected.contentVersion, root.contentVersion);
      expect(projected.checksum, root.checksum);
    },
  );
}
