import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('content manifest contract', () {
    test('root snapshot keeps pack and tombstone identity immutable', () {
      final manifest = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 108,
        minimumAppContractVersion: 1,
        publishedAt: DateTime.utc(2026, 10, 30, 9, 30),
        checksum: _shaA,
        packs: <PackRevisionRef>[
          PackRevisionRef(
            identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
            revision: 8,
            checksum: _shaB,
          ),
        ],
        tombstones: <ContentTombstone>[
          ContentTombstone(
            identity: const ContentIdentity(
              code: 'JAVA_QUESTION_001',
              type: ContentType.interview,
            ),
            revision: 3,
            reason: 'INACTIVE',
          ),
        ],
      );

      expect(manifest.checksum, _shaA);
      expect(manifest.packs.single.identity.variant, 'canonical');
      expect(manifest.tombstones.single.identity.type, ContentType.interview);
      expect(
        () => manifest.packs.add(manifest.packs.single),
        throwsUnsupportedError,
      );
    });

    test(
      'same business code may be tombstoned independently by content type',
      () {
        final manifest = RootContentManifest(
          schemaVersion: 1,
          contentVersion: 109,
          minimumAppContractVersion: 1,
          publishedAt: DateTime.utc(2026, 10, 30, 10),
          checksum: _shaA,
          packs: const <PackRevisionRef>[],
          tombstones: <ContentTombstone>[
            ContentTombstone(
              identity: const ContentIdentity(
                code: 'SHARED_CODE',
                type: ContentType.vocabulary,
              ),
              revision: 2,
              reason: 'INACTIVE',
            ),
            ContentTombstone(
              identity: const ContentIdentity(
                code: 'SHARED_CODE',
                type: ContentType.topic,
              ),
              revision: 4,
              reason: 'INACTIVE',
            ),
          ],
        );

        expect(manifest.tombstones, hasLength(2));
      },
    );

    test('duplicate pack variant in one root snapshot is rejected', () {
      final identity = PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical');

      expect(
        () => RootContentManifest(
          schemaVersion: 1,
          contentVersion: 108,
          minimumAppContractVersion: 1,
          publishedAt: DateTime.utc(2026, 10, 30, 9, 30),
          checksum: _shaA,
          packs: <PackRevisionRef>[
            PackRevisionRef(identity: identity, revision: 8, checksum: _shaB),
            PackRevisionRef(identity: identity, revision: 9, checksum: _shaC),
          ],
          tombstones: const <ContentTombstone>[],
        ),
        throwsArgumentError,
      );
    });

    test('pack variant and checksum contracts fail closed', () {
      expect(
        () => PackIdentity(code: 'JAVA/SENIOR', variant: 'canonical'),
        throwsArgumentError,
      );
      expect(
        () => PackIdentity(code: 'JAVA_SENIOR', variant: 'locale:'),
        throwsArgumentError,
      );
      expect(
        () => PackRevisionRef(
          identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
          revision: 8,
          checksum: 'not-a-checksum',
        ),
        throwsArgumentError,
      );
    });

    test('pack manifest rejects dangling content asset references', () {
      const contentIdentity = ContentIdentity(
        code: 'JAVA_QUESTION_001',
        type: ContentType.interview,
      );

      expect(
        () => PackContentManifest(
          schemaVersion: 1,
          identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
          revision: 8,
          checksum: _shaA,
          contents: <PackContentRef>[
            PackContentRef(
              identity: contentIdentity,
              revision: 3,
              checksum: _shaB,
            ),
          ],
          assets: <ManifestAssetDescriptor>[
            ManifestAssetDescriptor(
              assetId: 'asset-1',
              checksumSha256: _shaC,
              deliveryKey: 'audio/java/question-001.mp3',
              sizeBytes: 1024,
              mediaType: 'audio/mpeg',
              requiredOffline: true,
            ),
          ],
          contentAssets: <ContentAssetRef>[
            ContentAssetRef(
              contentIdentity: contentIdentity,
              contentRevision: 3,
              assetId: 'missing-asset',
              role: 'audio',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('asset delivery key is relative and traversal-safe', () {
      expect(
        () => ManifestAssetDescriptor(
          assetId: 'asset-1',
          checksumSha256: _shaC,
          deliveryKey: '../audio.mp3',
          sizeBytes: 1,
          mediaType: 'audio/mpeg',
          requiredOffline: false,
        ),
        throwsArgumentError,
      );
      expect(
        () => ManifestAssetDescriptor(
          assetId: 'asset-1',
          checksumSha256: _shaC,
          deliveryKey: 'https://cdn.example/audio.mp3',
          sizeBytes: 1,
          mediaType: 'audio/mpeg',
          requiredOffline: false,
        ),
        throwsArgumentError,
      );
    });
  });
}

const _shaA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _shaB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _shaC =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
