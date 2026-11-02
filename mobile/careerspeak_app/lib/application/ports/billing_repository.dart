import '../access/store_product.dart';
import '../access/store_purchase_event.dart';
import '../result/result.dart';

abstract interface class BillingRepository {
  Future<Result<StoreProduct>> loadFullUnlockProduct();

  Stream<StorePurchaseEvent> watchPurchaseEvents();

  Future<Result<void>> purchaseFullUnlock(StoreProduct product);

  Future<Result<void>> restorePurchases();

  /// Completes/acknowledges the underlying store transaction only after
  /// authoritative backend verification and entitlement delivery succeeded.
  Future<Result<void>> completePurchase(String eventId);
}
