import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/access/store_product.dart';
import '../application/ports/billing_repository.dart';
import '../data/billing/in_app_purchase_billing_repository.dart';
import '../data/billing/mock_billing_repository.dart';
import '../data/billing/unavailable_billing_repository.dart';
import 'app_configuration.dart';
import 'release_switch.dart';

/// Only development mode may compose the accepting mock billing adapter.
/// CAREERSPEAK_RELEASE_ENABLED=true switches a debug/profile build to the same
/// fail-closed billing boundary used by a compiler release build.
final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final configuration = ref.watch(appConfigurationProvider);
  final runMode = ref.watch(appRunModeProvider);
  final mocksAllowed =
      configuration.developmentMocksAllowed && runMode.isDevelopment;

  if (configuration.mockBillingRequested && !mocksAllowed) {
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
