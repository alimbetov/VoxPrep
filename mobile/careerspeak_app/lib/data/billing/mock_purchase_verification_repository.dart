import '../../application/access/purchase_verification.dart';
import '../../application/access/store_product.dart';
import '../../application/access/store_purchase_event.dart';
import '../../application/ports/purchase_verification_repository.dart';
import '../../application/result/result.dart';

/// Development substitute for POST /api/v1/purchases/verify.
///
/// The mock is intentionally behind the same application port as the future
/// backend implementation so purchase orchestration and UI do not change when
/// the backend is enabled.
final class MockPurchaseVerificationRepository
    implements PurchaseVerificationRepository {
  MockPurchaseVerificationRepository({
    this.acceptFullUnlock = true,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final bool acceptFullUnlock;
  final DateTime Function() _now;

  @override
  Future<Result<PurchaseVerification>> verify(StorePurchaseEvent event) async {
    final proof = event.serverVerificationData;
    final validRequest =
        event.requiresVerification &&
        event.productId == fullUnlockProductId &&
        proof != null &&
        proof.isNotEmpty;

    if (!validRequest || !acceptFullUnlock) {
      return Success<PurchaseVerification>(PurchaseVerification.rejected());
    }

    return Success<PurchaseVerification>(
      PurchaseVerification.full(verifiedAt: _now().toUtc()),
    );
  }
}
