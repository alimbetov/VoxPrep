import '../content_delivery/product_catalog.dart';

enum AccessSnapshotSource {
  backendVerified('BACKEND_VERIFIED'),
  storeRestore('STORE_RESTORE');

  const AccessSnapshotSource(this.wireName);

  final String wireName;

  static AccessSnapshotSource fromWireName(String value) {
    for (final source in values) {
      if (source.wireName == value) return source;
    }
    throw FormatException('Unsupported access snapshot source: $value');
  }
}

final class AccessSnapshot {
  factory AccessSnapshot({
    required AccessLevel accessLevel,
    required DateTime verifiedAt,
    required AccessSnapshotSource source,
  }) {
    if (!verifiedAt.isUtc) {
      throw ArgumentError.value(
        verifiedAt,
        'verifiedAt',
        'must use UTC semantics',
      );
    }
    return AccessSnapshot._(
      accessLevel: accessLevel,
      verifiedAt: verifiedAt,
      source: source,
    );
  }

  const AccessSnapshot._({
    required this.accessLevel,
    required this.verifiedAt,
    required this.source,
  });

  final AccessLevel accessLevel;
  final DateTime verifiedAt;
  final AccessSnapshotSource source;

  static const AccessLevel defaultAccessLevel = AccessLevel.free;
}
