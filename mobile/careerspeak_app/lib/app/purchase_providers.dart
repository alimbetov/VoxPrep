import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/purchase_verification_repository.dart';
import '../application/services/full_unlock_purchase_coordinator.dart';
import '../data/billing/mock_purchase_verification_repository.dart';
import '../data/remote/http_purchase_verification_repository.dart';
import 'access_providers.dart';
import 'api_client_providers.dart';
import 'app_configuration.dart';
import 'billing_providers.dart';

final purchaseVerificationRepositoryProvider =
    Provider<PurchaseVerificationRepository>((ref) {
      final configuration = ref.watch(appConfigurationProvider);
      if (configuration.mockPurchaseVerificationRequested &&
          configuration.developmentMocksAllowed) {
        return MockPurchaseVerificationRepository();
      }

      // Staging and production always use the real Backend verification
      // boundary. A release build therefore cannot manufacture FULL access by
      // enabling CAREERSPEAK_MOCK_PURCHASE_VERIFICATION.
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
