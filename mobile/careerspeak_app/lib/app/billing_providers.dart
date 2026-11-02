import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/access/store_product.dart';
import '../application/ports/billing_repository.dart';
import '../data/billing/unavailable_billing_repository.dart';

/// Production composition remains fail-closed until backend purchase
/// verification and entitlement delivery are wired. The real Store adapter is
/// implemented separately and must not be enabled before that boundary exists.
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  return const UnavailableBillingRepository();
});

final fullUnlockStoreProductProvider = FutureProvider<StoreProduct>((
  ref,
) async {
  return (await ref.watch(billingRepositoryProvider).loadFullUnlockProduct())
      .getOrThrow();
});
