import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/publication_revision_membership.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _packChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _contentChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _assetChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _testChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
const _catalogueChecksum =
    'eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee';

void main() {
  test('materializes exact immutable membership across resource categories', () {
    final pack = _packRef();
    final manifest = _packManifest();

    final membership = PublicationRevisionMembership(
      packs: <PackRevisionRef>[pack],
      packManifests: <PackContentManifest>[manifest],
      practiceTests: <PracticeTestRevisionRef>[
        PracticeTestRevisionRef(
          practiceTestCode: 'JAVA_INTERVIEW_TEST_01',
          revision: 3,
          checksum: _testChecksum,
        ),
      ],
      catalogues: <CatalogueRevisionRef>[
        CatalogueRevisionRef(
          kind: CatalogueKind.learningCollections,
          revision: 7,
          checksum: _catalogueChecksum,
        ),
      ],
    );

    expect(membership.packs, hasLength(1));
    expect(membership.canonicalContents, hasLength(1));
    expect(membership.assets, hasLength(1));
    expect(membership.practiceTests.single.revision, 3);
    expect(membership.catalogues.single.revision, 7);
  });

  test('rejects dangling pack revision membership', () {
    final pack = _packRef(revision: 8);
    final manifest = _packManifest(revision: 9);

    expect(
      () => PublicationRevisionMembership(
        packs: <PackRevisionRef>[pack],
        packManifests: <PackContentManifest>[manifest],
      ),
      throwsArgumentError,
    );
  });

  test('rejects same exact content revision with conflicting checksum', () {
    final identity = PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical');
    final contentIdentity = ContentIdentity(
      code: 'JAVA_Q_001',
      type: ContentType.interview,
    );
    final packA = PackRevisionRef(
      identity: identity,
      revision: 8,
      checksum: _packChecksum,
    );
    final secondIdentity = PackIdentity(code: 'JAVA_CORE', variant: 'canonical');
    final packB = PackRevisionRef(
      identity: secondIdentity,
      revision: 2,
      checksum: _assetChecksum,
    );
    final manifestA = PackContentManifest(
      schemaVersion: 1,
      identity: identity,
      revision: 8,
      checksum: _packChecksum,
      contents: <PackContentRef>[
        PackContentRef(
          identity: contentIdentity,
          revision: 4,
          checksum: _contentChecksum,
        ),
      ],
      assets: const <ManifestAssetDescriptor>[],
      contentAssets: const <ContentAssetRef>[],
    );
    final manifestB = PackContentManifest(
      schemaVersion: 1,
      identity: secondIdentity,
      revision: 2,
      checksum: _assetChecksum,
      contents: <PackContentRef>[
        PackContentRef(
          identity: contentIdentity,
          revision: 4,
          checksum: _testChecksum,
        ),
      ],
      assets: const <ManifestAssetDescriptor>[],
      contentAssets: const <ContentAssetRef>[],
    );

    expect(
      () => PublicationRevisionMembership(
        packs: <PackRevisionRef>[packA, packB],
        packManifests: <PackContentManifest>[manifestA, manifestB],
      ),
      throwsArgumentError,
    );
  });

  test('rejects duplicate catalogue kind membership', () {
    final pack = _packRef();
    final manifest = _packManifest();

    expect(
      () => PublicationRevisionMembership(
        packs: <PackRevisionRef>[pack],
        packManifests: <PackContentManifest>[manifest],
        catalogues: <CatalogueRevisionRef>[
          CatalogueRevisionRef(
            kind: CatalogueKind.learningCollections,
            revision: 7,
            checksum: _catalogueChecksum,
          ),
          CatalogueRevisionRef(
            kind: CatalogueKind.learningCollections,
            revision: 8,
            checksum: _testChecksum,
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}

PackRevisionRef _packRef({int revision = 8}) {
  return PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: revision,
    checksum: _packChecksum,
  );
}

PackContentManifest _packManifest({int revision = 8}) {
  final contentIdentity = ContentIdentity(
    code: 'JAVA_Q_001',
    type: ContentType.interview,
  );
  return PackContentManifest(
    schemaVersion: 1,
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: revision,
    checksum: _packChecksum,
    contents: <PackContentRef>[
      PackContentRef(
        identity: contentIdentity,
        revision: 4,
        checksum: _contentChecksum,
      ),
    ],
    assets: <ManifestAssetDescriptor>[
      ManifestAssetDescriptor(
        assetId: 'asset-java-q-001',
        checksumSha256: _assetChecksum,
        deliveryKey: 'audio/java-q-001-r4.mp3',
        sizeBytes: 1024,
        mediaType: 'audio/mpeg',
        requiredOffline: false,
      ),
    ],
    contentAssets: <ContentAssetRef>[
      ContentAssetRef(
        contentIdentity: contentIdentity,
        contentRevision: 4,
        assetId: 'asset-java-q-001',
        role: 'audio',
      ),
    ],
  );
}
