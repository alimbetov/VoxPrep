import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/publication_snapshot_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const checksumA =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const checksumB =
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  test('derives identity from immutable root manifest fields', () {
    final manifest = RootContentManifest(
      schemaVersion: 1,
      contentVersion: 42,
      minimumAppContractVersion: 1,
      publishedAt: DateTime.utc(2026, 10, 31),
      checksum: checksumA,
      packs: const <PackRevisionRef>[],
      tombstones: const <ContentTombstone>[],
    );

    final identity = PublicationSnapshotIdentity.fromRootManifest(
      manifest,
      etag: 'etag-42',
    );

    expect(identity.schemaVersion, 1);
    expect(identity.contentVersion, 42);
    expect(identity.checksum, checksumA);
    expect(identity.etag, 'etag-42');
  });

  test('same contentVersion and same immutable identity is compatible', () {
    final existing = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
      etag: 'etag-42',
    );
    final incoming = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
      etag: 'etag-42',
    );

    expect(() => existing.requireCompatibleWith(incoming), returnsNormally);
    expect(existing, incoming);
  });

  test('same contentVersion with different checksum fails closed', () {
    final existing = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
      etag: 'etag-42',
    );
    final incoming = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumB,
      etag: 'etag-42',
    );

    expect(
      () => existing.requireCompatibleWith(incoming),
      throwsA(isA<PublicationSnapshotIdentityConflict>()),
    );
  });

  test('same contentVersion with different ETag fails closed when both known', () {
    final existing = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
      etag: 'etag-42-a',
    );
    final incoming = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
      etag: 'etag-42-b',
    );

    expect(
      () => existing.requireCompatibleWith(incoming),
      throwsA(isA<PublicationSnapshotIdentityConflict>()),
    );
  });

  test('different contentVersion is a different publication, not a conflict', () {
    final v42 = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
    );
    final v43 = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 43,
      checksum: checksumB,
    );

    expect(() => v42.requireCompatibleWith(v43), returnsNormally);
    expect(v42, isNot(v43));
  });

  test('security/session material cannot participate in snapshot identity', () {
    final beforeTokenRotation = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
      etag: 'etag-42',
    );
    final afterTokenRotation = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
      etag: 'etag-42',
    );

    expect(beforeTokenRotation, afterTokenRotation);
  });

  test('rejects blank ETag but preserves opaque nonblank values', () {
    expect(
      () => PublicationSnapshotIdentity(
        schemaVersion: 1,
        contentVersion: 42,
        checksum: checksumA,
        etag: '   ',
      ),
      throwsArgumentError,
    );

    final identity = PublicationSnapshotIdentity(
      schemaVersion: 1,
      contentVersion: 42,
      checksum: checksumA,
      etag: '  etag-42  ',
    );
    expect(identity.etag, 'etag-42');
  });
}
