enum StoreProvider {
  googlePlay('GOOGLE_PLAY'),
  appStore('APP_STORE');

  const StoreProvider(this.wireName);

  final String wireName;
}

enum StorePurchaseStatus {
  pending,
  purchased,
  restored,
  cancelled,
  failed,
}

final class StorePurchaseEvent {
  factory StorePurchaseEvent({
    required String eventId,
    required StoreProvider provider,
    required String productId,
    required StorePurchaseStatus status,
    String? serverVerificationData,
  }) {
    final normalizedEventId = eventId.trim();
    final normalizedProductId = productId.trim();
    final normalizedProof = serverVerificationData?.trim();
    if (normalizedEventId.isEmpty || normalizedProductId.isEmpty) {
      throw ArgumentError('Store purchase event identity is required.');
    }
    if ((status == StorePurchaseStatus.purchased ||
            status == StorePurchaseStatus.restored) &&
        (normalizedProof == null || normalizedProof.isEmpty)) {
      throw ArgumentError(
        'Purchased/restored events require server verification data.',
      );
    }
    return StorePurchaseEvent._(
      eventId: normalizedEventId,
      provider: provider,
      productId: normalizedProductId,
      status: status,
      serverVerificationData: normalizedProof,
    );
  }

  const StorePurchaseEvent._({
    required this.eventId,
    required this.provider,
    required this.productId,
    required this.status,
    required this.serverVerificationData,
  });

  final String eventId;
  final StoreProvider provider;
  final String productId;
  final StorePurchaseStatus status;

  /// Sensitive proof for backend verification. Never render this in learner UI.
  final String? serverVerificationData;

  bool get requiresVerification =>
      status == StorePurchaseStatus.purchased ||
      status == StorePurchaseStatus.restored;
}
