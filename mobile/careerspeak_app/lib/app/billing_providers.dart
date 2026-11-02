import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/access/store_product.dart';
import '../application/ports/billing_repository.dart';
import '../data/billing/in_app_purchase_billing_repository.dart';
import '../data/billing/mock_billing_repository.dart';
import '../data/billing/unavailable_billing_repository.dart';

const _mockBilling = bool.fromEnvironment(
  'CAREERSPEAK_MOCK_BILLING',
  defaultValue: !kReleaseMode,
);

/// Development and test builds may use the mock Store adapter by default.
/// Release builds default to the real Store adapter. If a release build is
/// explicitly compiled with CAREERSPEAK_MOCK_BILLING=true, composition fails
/// closed by exposing an unavailable billing boundary instead of a mock that
/// could manufacture a purchasable Full entitlement path.
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  if (kReleaseMode && _mockBilling) {
    return const UnavailableBillingRepository();
  }
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
