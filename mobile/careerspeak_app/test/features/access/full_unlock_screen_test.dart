import 'dart:async';

import 'package:careerspeak_app/app/access_providers.dart';
import 'package:careerspeak_app/app/billing_providers.dart';
import 'package:careerspeak_app/app/purchase_providers.dart';
import 'package:careerspeak_app/application/access/access_snapshot.dart';
import 'package:careerspeak_app/application/access/purchase_verification.dart';
import 'package:careerspeak_app/application/access/store_product.dart';
import 'package:careerspeak_app/application/access/store_purchase_event.dart';
import 'package:careerspeak_app/application/ports/access_snapshot_repository.dart';
import 'package:careerspeak_app/application/ports/billing_repository.dart';
import 'package:careerspeak_app/application/ports/purchase_verification_repository.dart';
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

  testWidgets('purchase action runs Store to verification to Full Unlock', (
    tester,
  ) async {
    final billing = _FakeBillingRepository();
    final access = _MemoryAccessSnapshotRepository();
    await _pump(tester, billing, access: access);

    await tester.ensureVisible(
      find.byKey(const Key('full-unlock-purchase-button')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('full-unlock-purchase-button')));
    await tester.pumpAndSettle();

    expect(billing.purchaseCalls, 1);
    expect(billing.completeCalls, 1);
    expect(billing.lastPurchasedProduct?.productId, fullUnlockProductId);
    expect(access.snapshot?.accessLevel.wireName, 'FULL');
    expect(find.text('Full VoxPrep access unlocked.'), findsOneWidget);
  });

  testWidgets('restore action uses the same verified entitlement flow', (
    tester,
  ) async {
    final billing = _FakeBillingRepository();
    final access = _MemoryAccessSnapshotRepository();
    await _pump(tester, billing, access: access);

    await tester.ensureVisible(
      find.byKey(const Key('full-unlock-restore-button')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('full-unlock-restore-button')));
    await tester.pumpAndSettle();

    expect(billing.restoreCalls, 1);
    expect(billing.completeCalls, 1);
    expect(access.snapshot?.source, AccessSnapshotSource.storeRestore);
  });

  testWidgets('unavailable Store degrades safely without fake price', (
    tester,
  ) async {
    await _pump(tester, const _UnavailableBillingRepository());

    expect(
      find.text('Store purchases are temporarily unavailable.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('full-unlock-localized-price')), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester,
  BillingRepository billing, {
  _MemoryAccessSnapshotRepository? access,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        billingRepositoryProvider.overrideWithValue(billing),
        accessSnapshotRepositoryProvider.overrideWithValue(
          access ?? _MemoryAccessSnapshotRepository(),
        ),
        purchaseVerificationRepositoryProvider.overrideWithValue(
          const _AcceptingVerificationRepository(),
        ),
      ],
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
  final StreamController<StorePurchaseEvent> _events =
      StreamController<StorePurchaseEvent>.broadcast(sync: true);

  int purchaseCalls = 0;
  int restoreCalls = 0;
  int completeCalls = 0;
  StoreProduct? lastPurchasedProduct;

  @override
  Future<Result<StoreProduct>> loadFullUnlockProduct() async =>
      Success(product);

  @override
  Stream<StorePurchaseEvent> watchPurchaseEvents() => _events.stream;

  @override
  Future<Result<void>> purchaseFullUnlock(StoreProduct product) async {
    purchaseCalls++;
    lastPurchasedProduct = product;
    _events.add(
      StorePurchaseEvent(
        eventId: 'purchase-$purchaseCalls',
        provider: StoreProvider.googlePlay,
        productId: fullUnlockProductId,
        status: StorePurchaseStatus.purchased,
        serverVerificationData: 'proof-purchase-$purchaseCalls',
      ),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> restorePurchases() async {
    restoreCalls++;
    _events.add(
      StorePurchaseEvent(
        eventId: 'restore-$restoreCalls',
        provider: StoreProvider.googlePlay,
        productId: fullUnlockProductId,
        status: StorePurchaseStatus.restored,
        serverVerificationData: 'proof-restore-$restoreCalls',
      ),
    );
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> completePurchase(String eventId) async {
    completeCalls++;
    return const Success<void>(null);
  }
}

final class _MemoryAccessSnapshotRepository
    implements AccessSnapshotRepository {
  AccessSnapshot? snapshot;

  @override
  Future<Result<AccessSnapshot?>> read() async {
    return Success<AccessSnapshot?>(snapshot);
  }

  @override
  Future<Result<void>> replace(AccessSnapshot value) async {
    snapshot = value;
    return const Success<void>(null);
  }
}

final class _AcceptingVerificationRepository
    implements PurchaseVerificationRepository {
  const _AcceptingVerificationRepository();

  @override
  Future<Result<PurchaseVerification>> verify(StorePurchaseEvent event) async {
    return Success<PurchaseVerification>(
      PurchaseVerification.full(verifiedAt: DateTime.utc(2026, 11, 2, 4)),
    );
  }
}

final class _UnavailableBillingRepository implements BillingRepository {
  const _UnavailableBillingRepository();

  static const _failure = ApplicationFailure(
    code: 'STORE_UNAVAILABLE',
    message: 'Store purchases are temporarily unavailable.',
    retryable: true,
  );

  @override
  Future<Result<StoreProduct>> loadFullUnlockProduct() async {
    return const FailureResult<StoreProduct>(_failure);
  }

  @override
  Stream<StorePurchaseEvent> watchPurchaseEvents() {
    return const Stream<StorePurchaseEvent>.empty();
  }

  @override
  Future<Result<void>> purchaseFullUnlock(StoreProduct product) async {
    return const FailureResult<void>(_failure);
  }

  @override
  Future<Result<void>> restorePurchases() async {
    return const FailureResult<void>(_failure);
  }

  @override
  Future<Result<void>> completePurchase(String eventId) async {
    return const FailureResult<void>(_failure);
  }
}
