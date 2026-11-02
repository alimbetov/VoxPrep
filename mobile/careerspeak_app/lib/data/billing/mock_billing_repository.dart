import 'dart:async';

import '../../application/access/store_product.dart';
import '../../application/access/store_purchase_event.dart';
import '../../application/ports/billing_repository.dart';
import '../../application/result/result.dart';

/// Deterministic development Store adapter. It exercises the same asynchronous
/// purchase-event and completion contract as the real Store implementation.
final class MockBillingRepository implements BillingRepository {
  MockBillingRepository({this.provider = StoreProvider.googlePlay});

  final StoreProvider provider;
  final StreamController<StorePurchaseEvent> _events =
      StreamController<StorePurchaseEvent>.broadcast(sync: true);
  final Set<String> _completableEventIds = <String>{};
  int _sequence = 0;

  @override
  Future<Result<StoreProduct>> loadFullUnlockProduct() async {
    return Success<StoreProduct>(
      StoreProduct(
        productId: fullUnlockProductId,
        title: 'VoxPrep Full Unlock',
        description: 'Unlock all VoxPrep learning content.',
        localizedPrice: r'$4.99',
      ),
    );
  }

  @override
  Stream<StorePurchaseEvent> watchPurchaseEvents() => _events.stream;

  @override
  Future<Result<void>> purchaseFullUnlock(StoreProduct product) async {
    if (!product.isFullUnlock) {
      return const FailureResult<void>(
        ApplicationFailure(
          code: 'STORE_PRODUCT_INVALID',
          message: 'This Store product cannot unlock VoxPrep.',
        ),
      );
    }

    final transactionId = 'mock-purchase-${++_sequence}';
    _events.add(
      StorePurchaseEvent(
        eventId: '$transactionId-pending',
        provider: provider,
        productId: fullUnlockProductId,
        status: StorePurchaseStatus.pending,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    final eventId = '$transactionId-purchased';
    _completableEventIds.add(eventId);
    _events.add(
      StorePurchaseEvent(
        eventId: eventId,
        provider: provider,
        productId: fullUnlockProductId,
        status: StorePurchaseStatus.purchased,
        serverVerificationData: 'mock-proof-$transactionId',
      ),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> restorePurchases() async {
    final transactionId = 'mock-restore-${++_sequence}';
    final eventId = '$transactionId-restored';
    _completableEventIds.add(eventId);
    _events.add(
      StorePurchaseEvent(
        eventId: eventId,
        provider: provider,
        productId: fullUnlockProductId,
        status: StorePurchaseStatus.restored,
        serverVerificationData: 'mock-proof-$transactionId',
      ),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> completePurchase(String eventId) async {
    if (!_completableEventIds.remove(eventId)) {
      return const FailureResult<void>(
        ApplicationFailure(
          code: 'PURCHASE_EVENT_UNKNOWN',
          message: 'Purchase completion is unavailable.',
        ),
      );
    }
    return const Success<void>(null);
  }

  Future<void> dispose() => _events.close();
}
