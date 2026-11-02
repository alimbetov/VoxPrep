import 'package:careerspeak_app/app/billing_providers.dart';
import 'package:careerspeak_app/application/access/store_product.dart';
import 'package:careerspeak_app/application/access/store_purchase_event.dart';
import 'package:careerspeak_app/application/ports/billing_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/features/access/full_unlock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows localized Store price and never invents USD price', (
    tester,
  ) async {
    final billing = _FakeBillingRepository();
    await _pump(tester, billing);

    expect(find.text('₸2,490'), findsOneWidget);
    expect(find.text(r'$4.99'), findsNothing);
    expect(find.text('One-time purchase'), findsOneWidget);
  });

  testWidgets('purchase action is delegated to BillingRepository', (
    tester,
  ) async {
    final billing = _FakeBillingRepository();
    await _pump(tester, billing);

    await tester.tap(find.byKey(const Key('full-unlock-purchase-button')));
    await tester.pumpAndSettle();

    expect(billing.purchaseCalls, 1);
    expect(billing.lastPurchasedProduct?.productId, fullUnlockProductId);
  });

  testWidgets('restore action is delegated to BillingRepository', (
    tester,
  ) async {
    final billing = _FakeBillingRepository();
    await _pump(tester, billing);

    await tester.tap(find.text('Restore Purchases'));
    await tester.pumpAndSettle();

    expect(billing.restoreCalls, 1);
  });

  testWidgets('unavailable Store degrades safely without fake price', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: FullUnlockScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Store purchases are temporarily unavailable.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('full-unlock-localized-price')), findsNothing);
  });
}

Future<void> _pump(WidgetTester tester, _FakeBillingRepository billing) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [billingRepositoryProvider.overrideWithValue(billing)],
      child: const MaterialApp(home: Scaffold(body: FullUnlockScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FakeBillingRepository implements BillingRepository {
  final product = StoreProduct(
    productId: fullUnlockProductId,
    title: 'Full VoxPrep',
    description: 'Complete catalogue',
    localizedPrice: '₸2,490',
  );

  int purchaseCalls = 0;
  int restoreCalls = 0;
  StoreProduct? lastPurchasedProduct;

  @override
  Future<Result<StoreProduct>> loadFullUnlockProduct() async =>
      Success(product);

  @override
  Stream<StorePurchaseEvent> watchPurchaseEvents() =>
      const Stream<StorePurchaseEvent>.empty();

  @override
  Future<Result<void>> purchaseFullUnlock(StoreProduct product) async {
    purchaseCalls++;
    lastPurchasedProduct = product;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> restorePurchases() async {
    restoreCalls++;
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> completePurchase(String eventId) async =>
      const Success<void>(null);
}
