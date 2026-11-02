import 'dart:async';

import 'package:careerspeak_app/application/access/access_snapshot.dart';
import 'package:careerspeak_app/application/access/purchase_verification.dart';
import 'package:careerspeak_app/application/access/store_product.dart';
import 'package:careerspeak_app/application/access/store_purchase_event.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/ports/access_snapshot_repository.dart';
import 'package:careerspeak_app/application/ports/billing_repository.dart';
import 'package:careerspeak_app/application/ports/purchase_verification_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/services/full_unlock_purchase_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FullUnlockPurchaseCoordinator', () {
    test('verified purchase persists FULL before Store completion', () async {
      final calls = <String>[];
      final billing = _FakeBillingRepository(calls: calls);
      final access = _FakeAccessSnapshotRepository(calls: calls);
      final coordinator = FullUnlockPurchaseCoordinator(
        billingRepository: billing,
        verificationRepository: _FakeVerificationRepository(
          calls: calls,
          decision: PurchaseVerification.full(
            verifiedAt: DateTime.utc(2026, 11, 2, 4),
          ),
        ),
        accessSnapshotRepository: access,
      );
      addTearDown(coordinator.dispose);
      coordinator.start();

      final unlocked = coordinator.states.firstWhere(
        (state) => state.phase == FullUnlockPurchasePhase.unlocked,
      );
      billing.emit(_purchasedEvent('purchase-1'));
      await unlocked;

      expect(access.snapshot?.accessLevel, AccessLevel.full);
      expect(
        calls,
        <String>['verify:purchase-1', 'persist:FULL', 'complete:purchase-1'],
      );
    });

    test('verification rejection fails closed and never completes Store', () async {
      final calls = <String>[];
      final billing = _FakeBillingRepository(calls: calls);
      final access = _FakeAccessSnapshotRepository(calls: calls);
      final coordinator = FullUnlockPurchaseCoordinator(
        billingRepository: billing,
        verificationRepository: _FakeVerificationRepository(
          calls: calls,
          decision: PurchaseVerification.rejected(),
        ),
        accessSnapshotRepository: access,
      );
      addTearDown(coordinator.dispose);
      coordinator.start();

      final failed = coordinator.states.firstWhere(
        (state) => state.phase == FullUnlockPurchasePhase.failed,
      );
      billing.emit(_purchasedEvent('purchase-2'));
      await failed;

      expect(access.snapshot, isNull);
      expect(calls, <String>['verify:purchase-2']);
    });

    test('restore uses the same verification path and records source', () async {
      final calls = <String>[];
      final billing = _FakeBillingRepository(calls: calls);
      final access = _FakeAccessSnapshotRepository(calls: calls);
      final coordinator = FullUnlockPurchaseCoordinator(
        billingRepository: billing,
        verificationRepository: _FakeVerificationRepository(
          calls: calls,
          decision: PurchaseVerification.full(
            verifiedAt: DateTime.utc(2026, 11, 2, 5),
          ),
        ),
        accessSnapshotRepository: access,
      );
      addTearDown(coordinator.dispose);
      coordinator.start();

      final unlocked = coordinator.states.firstWhere(
        (state) => state.phase == FullUnlockPurchasePhase.unlocked,
      );
      billing.emit(_restoredEvent('restore-1'));
      await unlocked;

      expect(access.snapshot?.source, AccessSnapshotSource.storeRestore);
      expect(calls.last, 'complete:restore-1');
    });

    test('persistence failure leaves Store transaction incomplete', () async {
      final calls = <String>[];
      final billing = _FakeBillingRepository(calls: calls);
      final access = _FakeAccessSnapshotRepository(
        calls: calls,
        replaceFailure: const ApplicationFailure(
          code: 'ACCESS_WRITE_FAILED',
          message: 'Access could not be saved.',
          retryable: true,
        ),
      );
      final coordinator = FullUnlockPurchaseCoordinator(
        billingRepository: billing,
        verificationRepository: _FakeVerificationRepository(
          calls: calls,
          decision: PurchaseVerification.full(
            verifiedAt: DateTime.utc(2026, 11, 2, 6),
          ),
        ),
        accessSnapshotRepository: access,
      );
      addTearDown(coordinator.dispose);
      coordinator.start();

      final failed = coordinator.states.firstWhere(
        (state) => state.phase == FullUnlockPurchasePhase.failed,
      );
      billing.emit(_purchasedEvent('purchase-3'));
      await failed;

      expect(calls, <String>['verify:purchase-3', 'persist:FULL']);
    });
  });
}

StorePurchaseEvent _purchasedEvent(String eventId) {
  return StorePurchaseEvent(
    eventId: eventId,
    provider: StoreProvider.googlePlay,
    productId: fullUnlockProductId,
    status: StorePurchaseStatus.purchased,
    serverVerificationData: 'proof-$eventId',
  );
}

StorePurchaseEvent _restoredEvent(String eventId) {
  return StorePurchaseEvent(
    eventId: eventId,
    provider: StoreProvider.googlePlay,
    productId: fullUnlockProductId,
    status: StorePurchaseStatus.restored,
    serverVerificationData: 'proof-$eventId',
  );
}

final class _FakeBillingRepository implements BillingRepository {
  _FakeBillingRepository({required this.calls});

  final List<String> calls;
  final StreamController<StorePurchaseEvent> _events =
      StreamController<StorePurchaseEvent>.broadcast(sync: true);

  void emit(StorePurchaseEvent event) => _events.add(event);

  @override
  Future<Result<void>> completePurchase(String eventId) async {
    calls.add('complete:$eventId');
    return const Success<void>(null);
  }

  @override
  Future<Result<StoreProduct>> loadFullUnlockProduct() async {
    return Success<StoreProduct>(
      StoreProduct(
        productId: fullUnlockProductId,
        title: 'Full',
        description: 'Full access',
        localizedPrice: r'$4.99',
      ),
    );
  }

  @override
  Future<Result<void>> purchaseFullUnlock(StoreProduct product) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> restorePurchases() async {
    return const Success<void>(null);
  }

  @override
  Stream<StorePurchaseEvent> watchPurchaseEvents() => _events.stream;
}

final class _FakeVerificationRepository
    implements PurchaseVerificationRepository {
  _FakeVerificationRepository({required this.calls, required this.decision});

  final List<String> calls;
  final PurchaseVerification decision;

  @override
  Future<Result<PurchaseVerification>> verify(StorePurchaseEvent event) async {
    calls.add('verify:${event.eventId}');
    return Success<PurchaseVerification>(decision);
  }
}

final class _FakeAccessSnapshotRepository
    implements AccessSnapshotRepository {
  _FakeAccessSnapshotRepository({required this.calls, this.replaceFailure});

  final List<String> calls;
  final ApplicationFailure? replaceFailure;
  AccessSnapshot? snapshot;

  @override
  Future<Result<AccessSnapshot?>> read() async {
    return Success<AccessSnapshot?>(snapshot);
  }

  @override
  Future<Result<void>> replace(AccessSnapshot value) async {
    calls.add('persist:${value.accessLevel.wireName}');
    if (replaceFailure != null) {
      return FailureResult<void>(replaceFailure!);
    }
    snapshot = value;
    return const Success<void>(null);
  }
}
