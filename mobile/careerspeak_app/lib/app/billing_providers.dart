import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/access/store_product.dart';
import '../application/ports/billing_repository.dart';
import '../data/billing/in_app_purchase_billing_repository.dart';
import '../data/billing/mock_billing_repository.dart';

const _mockBilling = bool.fromEnvironment(
  'CAREERSPEAK_MOCK_BILLING',
  defaultValue: true,
);

/// The complete purchase flow is executable without Store infrastructure by
/// default. Set CAREERSPEAK_MOCK_BILLING=false to exercise the real
/// in_app_purchase adapter without changing application or UI code.
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  if (_mockBilling) {
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
