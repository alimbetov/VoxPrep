import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/access/store_product.dart';
import '../application/ports/billing_repository.dart';
import '../data/billing/in_app_purchase_billing_repository.dart';
import '../data/billing/mock_billing_repository.dart';
import '../data/billing/unavailable_billing_repository.dart';
import 'app_configuration.dart';

/// Only non-release development builds may compose the accepting mock billing
/// adapter. Any mock request outside that boundary fails closed instead of
/// manufacturing a purchasable FULL entitlement path.
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final configuration = ref.watch(appConfigurationProvider);
  if (configuration.mockBillingRequested &&
      !configuration.developmentMocksAllowed) {
    return const UnavailableBillingRepository();
  }
  if (configuration.mockBillingRequested) {
    final repository = MockBillingRepository();
    ref.onDispose(() => unawaited(repository.dispose()));
    return repository;
  }
  return InAppPurchaseBillingRepository();
});

final fullUnlockStoreProductProvider = FutureProvider<StoreProduct>((
  ref,
) async {
  return (await ref.watch(billingRepositoryProvider).loadFullUnlockProduct())
      .getOrThrow();
});
