import 'package:careerspeak_app/application/access/store_product.dart';
import 'package:careerspeak_app/application/access/store_purchase_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Full Unlock uses one stable Store product id and localized price', () {
    final product = StoreProduct(
      productId: fullUnlockProductId,
      title: 'Full VoxPrep',
      description: 'Complete catalogue',
      localizedPrice: '₸2,490',
    );

    expect(fullUnlockProductId, 'voxprep_full_unlock');
    expect(product.isFullUnlock, isTrue);
    expect(product.localizedPrice, '₸2,490');
  });

  test('purchase proof is mandatory before backend verification', () {
    expect(
      () => StorePurchaseEvent(
        eventId: 'purchase-1',
        provider: StoreProvider.googlePlay,
        productId: fullUnlockProductId,
        status: StorePurchaseStatus.purchased,
      ),
      throwsArgumentError,
    );

    final event = StorePurchaseEvent(
      eventId: 'purchase-1',
      provider: StoreProvider.googlePlay,
      productId: fullUnlockProductId,
      status: StorePurchaseStatus.purchased,
      serverVerificationData: 'opaque-proof',
    );

    expect(event.requiresVerification, isTrue);
  });

  test('pending and cancelled events never require verification proof', () {
    for (final status in <StorePurchaseStatus>[
      StorePurchaseStatus.pending,
      StorePurchaseStatus.cancelled,
      StorePurchaseStatus.failed,
    ]) {
      final event = StorePurchaseEvent(
        eventId: 'event-${status.name}',
        provider: StoreProvider.appStore,
        productId: fullUnlockProductId,
        status: status,
      );
      expect(event.requiresVerification, isFalse);
    }
  });
}
