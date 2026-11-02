import '../access/purchase_verification.dart';
import '../access/store_purchase_event.dart';
import '../result/result.dart';

abstract interface class PurchaseVerificationRepository {
  Future<Result<PurchaseVerification>> verify(StorePurchaseEvent event);
}
