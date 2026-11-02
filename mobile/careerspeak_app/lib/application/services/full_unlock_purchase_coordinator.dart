import 'dart:async';

import '../access/access_snapshot.dart';
import '../access/purchase_verification.dart';
import '../access/store_product.dart';
import '../access/store_purchase_event.dart';
import '../ports/access_snapshot_repository.dart';
import '../ports/billing_repository.dart';
import '../ports/purchase_verification_repository.dart';
import '../result/result.dart';

enum FullUnlockPurchasePhase {
  idle,
  launchingPurchase,
  restoring,
  awaitingStore,
  verifying,
  unlocked,
  cancelled,
  failed,
}

final class FullUnlockPurchaseState {
  const FullUnlockPurchaseState({
    required this.phase,
    required this.message,
  });

  const FullUnlockPurchaseState.idle()
    : this(phase: FullUnlockPurchasePhase.idle, message: '');

  final FullUnlockPurchasePhase phase;
  final String message;

  bool get busy => switch (phase) {
    FullUnlockPurchasePhase.launchingPurchase ||
    FullUnlockPurchasePhase.restoring ||
    FullUnlockPurchasePhase.awaitingStore ||
    FullUnlockPurchasePhase.verifying => true,
    _ => false,
  };
}

/// Coordinates Store delivery, backend-shaped verification, durable entitlement
/// persistence and Store completion in that strict order.
final class FullUnlockPurchaseCoordinator {
  FullUnlockPurchaseCoordinator({
    required BillingRepository billingRepository,
    required PurchaseVerificationRepository verificationRepository,
    required AccessSnapshotRepository accessSnapshotRepository,
  }) : _billingRepository = billingRepository,
       _verificationRepository = verificationRepository,
       _accessSnapshotRepository = accessSnapshotRepository;

  final BillingRepository _billingRepository;
  final PurchaseVerificationRepository _verificationRepository;
  final AccessSnapshotRepository _accessSnapshotRepository;
  final StreamController<FullUnlockPurchaseState> _states =
      StreamController<FullUnlockPurchaseState>.broadcast(sync: true);

  StreamSubscription<StorePurchaseEvent>? _purchaseSubscription;
  Future<void> _eventQueue = Future<void>.value();
  FullUnlockPurchaseState _state = const FullUnlockPurchaseState.idle();

  FullUnlockPurchaseState get state => _state;

  Stream<FullUnlockPurchaseState> get states async* {
    yield _state;
    yield* _states.stream;
  }

  void start() {
    if (_purchaseSubscription != null) return;
    _purchaseSubscription = _billingRepository.watchPurchaseEvents().listen(
      (event) {
        _eventQueue = _eventQueue.then((_) => _handleEvent(event));
      },
      onError: (Object error, StackTrace stackTrace) {
        _emit(
          const FullUnlockPurchaseState(
            phase: FullUnlockPurchasePhase.failed,
            message: 'Store purchase updates are temporarily unavailable.',
          ),
        );
      },
    );
  }

  Future<Result<void>> purchase(StoreProduct product) async {
    start();
    _emit(
      const FullUnlockPurchaseState(
        phase: FullUnlockPurchasePhase.launchingPurchase,
        message: 'Starting purchase…',
      ),
    );
    final result = await _billingRepository.purchaseFullUnlock(product);
    if (result case FailureResult<void>(:final failure)) {
      _emit(
        FullUnlockPurchaseState(
          phase: FullUnlockPurchasePhase.failed,
          message: failure.message,
        ),
      );
      return result;
    }
    if (_state.phase == FullUnlockPurchasePhase.launchingPurchase) {
      _emit(
        const FullUnlockPurchaseState(
          phase: FullUnlockPurchasePhase.awaitingStore,
          message: 'Waiting for Store confirmation…',
        ),
      );
    }
    return const Success<void>(null);
  }

  Future<Result<void>> restore() async {
    start();
    _emit(
      const FullUnlockPurchaseState(
        phase: FullUnlockPurchasePhase.restoring,
        message: 'Checking previous purchases…',
      ),
    );
    final result = await _billingRepository.restorePurchases();
    if (result case FailureResult<void>(:final failure)) {
      _emit(
        FullUnlockPurchaseState(
          phase: FullUnlockPurchasePhase.failed,
          message: failure.message,
        ),
      );
      return result;
    }
    if (_state.phase == FullUnlockPurchasePhase.restoring) {
      _emit(
        const FullUnlockPurchaseState(
          phase: FullUnlockPurchasePhase.awaitingStore,
          message: 'Waiting for restored purchase…',
        ),
      );
    }
    return const Success<void>(null);
  }

  Future<void> _handleEvent(StorePurchaseEvent event) async {
    if (event.productId != fullUnlockProductId) {
      if (event.requiresVerification) {
        _emit(
          const FullUnlockPurchaseState(
            phase: FullUnlockPurchasePhase.failed,
            message: 'The Store returned an unsupported purchase.',
          ),
        );
      }
      return;
    }

    switch (event.status) {
      case StorePurchaseStatus.pending:
        _emit(
          const FullUnlockPurchaseState(
            phase: FullUnlockPurchasePhase.awaitingStore,
            message: 'Waiting for Store confirmation…',
          ),
        );
      case StorePurchaseStatus.cancelled:
        _emit(
          const FullUnlockPurchaseState(
            phase: FullUnlockPurchasePhase.cancelled,
            message: 'Purchase cancelled.',
          ),
        );
      case StorePurchaseStatus.failed:
        _emit(
          const FullUnlockPurchaseState(
            phase: FullUnlockPurchasePhase.failed,
            message: 'Purchase could not be completed.',
          ),
        );
      case StorePurchaseStatus.purchased:
      case StorePurchaseStatus.restored:
        await _verifyGrantAndComplete(event);
    }
  }

  Future<void> _verifyGrantAndComplete(StorePurchaseEvent event) async {
    _emit(
      const FullUnlockPurchaseState(
        phase: FullUnlockPurchasePhase.verifying,
        message: 'Verifying purchase…',
      ),
    );

    final verificationResult = await _verificationRepository.verify(event);
    if (verificationResult
        case FailureResult<PurchaseVerification>(:final failure)) {
      _emit(
        FullUnlockPurchaseState(
          phase: FullUnlockPurchasePhase.failed,
          message: failure.message,
        ),
      );
      return;
    }

    final verification =
        (verificationResult as Success<PurchaseVerification>).value;
    if (!verification.grantsFullAccess || verification.verifiedAt == null) {
      _emit(
        const FullUnlockPurchaseState(
          phase: FullUnlockPurchasePhase.failed,
          message: 'This purchase could not be verified.',
        ),
      );
      return;
    }

    final snapshot = AccessSnapshot(
      accessLevel: verification.accessLevel,
      verifiedAt: verification.verifiedAt!,
      source: event.status == StorePurchaseStatus.restored
          ? AccessSnapshotSource.storeRestore
          : AccessSnapshotSource.backendVerified,
    );
    final persistResult = await _accessSnapshotRepository.replace(snapshot);
    if (persistResult case FailureResult<void>(:final failure)) {
      _emit(
        FullUnlockPurchaseState(
          phase: FullUnlockPurchasePhase.failed,
          message: failure.message,
        ),
      );
      return;
    }

    final completionResult = await _billingRepository.completePurchase(
      event.eventId,
    );
    if (completionResult case FailureResult<void>()) {
      _emit(
        const FullUnlockPurchaseState(
          phase: FullUnlockPurchasePhase.unlocked,
          message: 'Full access is active. Store confirmation is pending.',
        ),
      );
      return;
    }

    _emit(
      const FullUnlockPurchaseState(
        phase: FullUnlockPurchasePhase.unlocked,
        message: 'Full VoxPrep access unlocked.',
      ),
    );
  }

  void _emit(FullUnlockPurchaseState value) {
    _state = value;
    if (!_states.isClosed) _states.add(value);
  }

  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    await _states.close();
  }
}
