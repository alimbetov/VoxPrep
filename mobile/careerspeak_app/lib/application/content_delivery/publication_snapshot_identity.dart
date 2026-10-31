import 'content_manifest.dart';

/// Immutable Flutter-side identity for one backend publication snapshot.
///
/// C4.1 deliberately excludes installation/session security state. A token
/// rotation must never manufacture a different publication identity.
final class PublicationSnapshotIdentity {
  factory PublicationSnapshotIdentity({
    required int schemaVersion,
    required int contentVersion,
    required String checksum,
    String? etag,
  }) {
    if (schemaVersion < 1) {
      throw ArgumentError.value(schemaVersion, 'schemaVersion', 'must be positive');
    }
    if (contentVersion < 1) {
      throw ArgumentError.value(contentVersion, 'contentVersion', 'must be positive');
    }

    return PublicationSnapshotIdentity._(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      checksum: normalizeSha256(checksum, 'checksum'),
      etag: _normalizeOptionalEtag(etag),
    );
  }

  factory PublicationSnapshotIdentity.fromRootManifest(
    RootContentManifest manifest, {
    String? etag,
  }) {
    return PublicationSnapshotIdentity(
      schemaVersion: manifest.schemaVersion,
      contentVersion: manifest.contentVersion,
      checksum: manifest.checksum,
      etag: etag,
    );
  }

  const PublicationSnapshotIdentity._({
    required this.schemaVersion,
    required this.contentVersion,
    required this.checksum,
    required this.etag,
  });

  final int schemaVersion;
  final int contentVersion;
  final String checksum;
  final String? etag;

  /// Fails closed when the backend attempts to reuse one contentVersion for a
  /// different immutable root identity.
  void requireCompatibleWith(PublicationSnapshotIdentity other) {
    if (contentVersion != other.contentVersion) {
      return;
    }

    if (schemaVersion != other.schemaVersion || checksum != other.checksum) {
      throw PublicationSnapshotIdentityConflict(
        existing: this,
        incoming: other,
      );
    }

    if (etag != null && other.etag != null && etag != other.etag) {
      throw PublicationSnapshotIdentityConflict(
        existing: this,
        incoming: other,
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PublicationSnapshotIdentity &&
            other.schemaVersion == schemaVersion &&
            other.contentVersion == contentVersion &&
            other.checksum == checksum &&
            other.etag == etag;
  }

  @override
  int get hashCode => Object.hash(schemaVersion, contentVersion, checksum, etag);

  @override
  String toString() {
    return 'PublicationSnapshotIdentity('
        'schemaVersion: $schemaVersion, '
        'contentVersion: $contentVersion, '
        'checksum: $checksum, '
        'etag: $etag)';
  }
}

final class PublicationSnapshotIdentityConflict implements Exception {
  const PublicationSnapshotIdentityConflict({
    required this.existing,
    required this.incoming,
  });

  final PublicationSnapshotIdentity existing;
  final PublicationSnapshotIdentity incoming;

  @override
  String toString() {
    return 'PublicationSnapshotIdentityConflict('
        'existing: $existing, incoming: $incoming)';
  }
}

String? _normalizeOptionalEtag(String? value) {
  if (value == null) {
    return null;
  }

  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, 'etag', 'must not be blank');
  }
  return normalized;
}
