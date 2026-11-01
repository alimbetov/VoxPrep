import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/universal_catalogue_repository.dart';
import '../application/result/result.dart';
import '../application/services/application_bootstrap_service.dart';
import 'api_client_providers.dart';
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

        final manager = await ref.watch(
          assetCacheRetentionManagerProvider.future,
        );
        // Cache maintenance is deliberately best-effort. Failure must never
        // prevent startup or invalidate the last committed publication.
        await manager.cleanupExpiredAudio();
      }

      return result;
    });
