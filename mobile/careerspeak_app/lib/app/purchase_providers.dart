import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/purchase_verification_repository.dart';
import '../application/services/full_unlock_purchase_coordinator.dart';
import '../data/billing/mock_purchase_verification_repository.dart';
import '../data/remote/http_purchase_verification_repository.dart';
import 'access_providers.dart';
import 'api_client_providers.dart';
import 'billing_providers.dart';

const _mockPurchaseVerification = bool.fromEnvironment(
  'CAREERSPEAK_MOCK_PURCHASE_VERIFICATION',
  defaultValue: !kReleaseMode,
);

final purchaseVerificationRepositoryProvider =
    Provider<PurchaseVerificationRepository>((ref) {
      if (_mockPurchaseVerification && !kReleaseMode) {
        return MockPurchaseVerificationRepository();
      }

      // Release builds never compose the accepting mock verifier. Even if a
      // release build is accidentally compiled with the mock flag enabled,
      // verification is routed through the real backend boundary. Without a
      // successful backend verification the entitlement remains fail-closed.
      return HttpPurchaseVerificationRepository(
        apiClient: ref.watch(apiClientProvider),
      );
    });

final fullUnlockPurchaseCoordinatorProvider =
    Provider<FullUnlockPurchaseCoordinator>((ref) {
      final coordinator = FullUnlockPurchaseCoordinator(
        billingRepository: ref.watch(billingRepositoryProvider),
        verificationRepository: ref.watch(
          purchaseVerificationRepositoryProvider,
        ),
        accessSnapshotRepository: ref.watch(accessSnapshotRepositoryProvider),
      );
      coordinator.start();
      ref.onDispose(() => unawaited(coordinator.dispose()));
      return coordinator;
    });

final fullUnlockPurchaseStateProvider = StreamProvider<FullUnlockPurchaseState>(
  (ref) async* {
    final coordinator = ref.watch(fullUnlockPurchaseCoordinatorProvider);
    await for (final state in coordinator.states) {
      if (state.phase == FullUnlockPurchasePhase.unlocked) {
        ref.invalidate(learnerAccessSnapshotProvider);
      }
      yield state;
    }
  },
);
