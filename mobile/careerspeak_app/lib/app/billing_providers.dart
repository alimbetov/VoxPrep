import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/access/store_product.dart';
import '../application/ports/billing_repository.dart';
import '../data/billing/in_app_purchase_billing_repository.dart';
import '../data/billing/unavailable_billing_repository.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return InAppPurchaseBillingRepository();
  }
  return const UnavailableBillingRepository();
});

final fullUnlockStoreProductProvider = FutureProvider<StoreProduct>((
  ref,
) async {
  return (await ref.watch(billingRepositoryProvider).loadFullUnlockProduct())
      .getOrThrow();
});
