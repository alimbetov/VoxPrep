import '../content_delivery/product_catalog.dart';

final class PurchaseVerification {
  factory PurchaseVerification({
    required bool verified,
    required AccessLevel accessLevel,
    DateTime? verifiedAt,
  }) {
    if (verified && accessLevel == AccessLevel.full && verifiedAt == null) {
      throw ArgumentError(
        'A verified Full Unlock decision requires verifiedAt.',
      );
    }
    if (verifiedAt != null && !verifiedAt.isUtc) {
      throw ArgumentError.value(
        verifiedAt,
        'verifiedAt',
        'must use UTC semantics',
      );
    }
    return PurchaseVerification._(
      verified: verified,
      accessLevel: accessLevel,
      verifiedAt: verifiedAt,
    );
  }

  const PurchaseVerification._({
    required this.verified,
    required this.accessLevel,
    required this.verifiedAt,
  });

  factory PurchaseVerification.rejected() {
    return PurchaseVerification(
      verified: false,
      accessLevel: AccessLevel.free,
    );
  }

  factory PurchaseVerification.full({required DateTime verifiedAt}) {
    return PurchaseVerification(
      verified: true,
      accessLevel: AccessLevel.full,
      verifiedAt: verifiedAt,
    );
  }

  final bool verified;
  final AccessLevel accessLevel;
  final DateTime? verifiedAt;

  bool get grantsFullAccess => verified && accessLevel == AccessLevel.full;
}
