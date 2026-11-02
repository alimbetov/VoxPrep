import '../../application/access/store_product.dart';
import '../../application/access/store_purchase_event.dart';
import '../../application/ports/billing_repository.dart';
import '../../application/result/result.dart';

final class UnavailableBillingRepository implements BillingRepository {
  const UnavailableBillingRepository();

  static const _failure = ApplicationFailure(
    code: 'STORE_UNAVAILABLE',
    message: 'Store purchases are not available yet.',
    retryable: true,
  );

  @override
  Future<Result<StoreProduct>> loadFullUnlockProduct() async =>
      const FailureResult<StoreProduct>(_failure);

  @override
  Stream<StorePurchaseEvent> watchPurchaseEvents() =>
      const Stream<StorePurchaseEvent>.empty();

  @override
  Future<Result<void>> purchaseFullUnlock(StoreProduct product) async =>
      const FailureResult<void>(_failure);

  @override
  Future<Result<void>> restorePurchases() async =>
      const FailureResult<void>(_failure);

  @override
  Future<Result<void>> completePurchase(String eventId) async =>
      const FailureResult<void>(_failure);
}
