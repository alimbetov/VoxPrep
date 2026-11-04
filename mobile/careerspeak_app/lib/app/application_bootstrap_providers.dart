import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/universal_catalogue_repository.dart';
import '../application/result/result.dart';
import '../application/services/application_bootstrap_service.dart';
import 'api_client_providers.dart';
import 'access_providers.dart';
import 'app_configuration.dart';
import 'entitlement_refresh_providers.dart';
import 'asset_cache_retention_providers.dart';
import 'catalogue_payload_providers.dart';
import 'content_sync_providers.dart';
import 'learner_selection_providers.dart';

export 'api_client_providers.dart'
    show
        installationBootstrapServiceProvider,
        installationRegistrationGatewayProvider;

final applicationBootstrapServiceProvider =
    Provider<ApplicationBootstrapService>((ref) {
      final contentSync = ref.watch(preferenceAwareContentSyncProvider);
      return ApplicationBootstrapService(
        installationBootstrapService: ref.watch(
          installationBootstrapServiceProvider,
        ),
        synchronizeContent: contentSync.synchronize,
      );
    });

final applicationBootstrapProvider =
    FutureProvider<Result<ApplicationBootstrapOutcome>>((ref) async {
      final result = await ref
          .watch(applicationBootstrapServiceProvider)
          .bootstrap();

      if (result is Success<ApplicationBootstrapOutcome>) {
        final configuration = ref.read(appConfigurationProvider);
        // A development-only local Store simulator is intentionally not a
        // server entitlement source. Release and real-backend development
        // always refresh before rendering cached FULL entitlement.
        final isLocalMock = configuration.developmentMocksAllowed &&
            configuration.mockPurchaseVerificationRequested;
        if (configuration.networkEnabled && !isLocalMock) {
          try {
            final entitlementResult = await ref
                .read(entitlementStatusRefreshServiceProvider)
                .refresh();
            if (entitlementResult is Success<bool>) {
              ref.invalidate(learnerAccessSnapshotProvider);
            }
          } catch (_) {
            // Offline bootstrap retains the last verified local snapshot;
            // backend still denies FULL resource access without entitlement.
          }
        }
        final catalogueResult = await ref
            .read(universalCatalogueRepositoryProvider)
            .readCurrent();
        CurrentUniversalCatalogueSnapshot? snapshot;
        switch (catalogueResult) {
          case Success<CurrentUniversalCatalogueSnapshot?>(:final value):
            snapshot = value;
          case FailureResult<CurrentUniversalCatalogueSnapshot?>(
            :final failure,
          ):
            return FailureResult<ApplicationBootstrapOutcome>(failure);
        }
        if (snapshot != null) {
          final normalized = await ref
              .read(learnerSelectionServiceProvider)
              .normalizeAgainst(snapshot.graph);
          switch (normalized) {
            case Success():
              break;
            case FailureResult(:final failure):
              return FailureResult<ApplicationBootstrapOutcome>(failure);
          }
        }

        // Cache maintenance is deliberately best-effort and must never block
        // startup or invalidate the last committed publication.
        unawaited(() async {
          try {
            final manager = await ref.read(
              assetCacheRetentionManagerProvider.future,
            );
            await manager.cleanupExpiredAudio();
          } catch (_) {
            // Startup remains successful when maintenance cannot run.
          }
        }());
      }

      return result;
    });

/// Eagerly watches the production bootstrap provider while keeping the app
/// shell independently testable. This restores the acceptance-test host
/// without coupling [CareerSpeakApp] itself to bootstrap orchestration.
class ProductionBootstrapHost extends ConsumerWidget {
  const ProductionBootstrapHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(applicationBootstrapProvider);
    return child;
  }
}
