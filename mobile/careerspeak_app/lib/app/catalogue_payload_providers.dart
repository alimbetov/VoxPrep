import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_delivery/catalogue_payload.dart';
import '../application/content_delivery/catalogue_revision_ref.dart';
import '../application/ports/catalogue_payload_gateway.dart';
import '../application/ports/catalogue_snapshot_repository.dart';
import '../application/ports/universal_catalogue_repository.dart';
import '../data/local/drift_catalogue_snapshot_repository.dart';
import '../data/local/drift_universal_catalogue_repository.dart';
import '../data/remote/http_catalogue_payload_gateway.dart';
import 'api_client_providers.dart';
import 'learner_state_providers.dart';

/// Production catalogue transport. Tests and golden fixtures override this
/// provider explicitly when deterministic fixture payloads are required.
final cataloguePayloadGatewayProvider = Provider<CataloguePayloadGateway>((
  ref,
) {
  return HttpCataloguePayloadGateway(apiClient: ref.watch(apiClientProvider));
});

final catalogueSnapshotRepositoryProvider =
    Provider<CatalogueSnapshotRepository>((ref) {
      return DriftCatalogueSnapshotRepository(
        ref.watch(careerSpeakDatabaseProvider),
      );
    });

final currentCatalogueProvider =
    FutureProvider.family<CataloguePayload?, CatalogueKind>((ref, kind) async {
      final repository = ref.watch(catalogueSnapshotRepositoryProvider);
      return (await repository.readCurrent(kind)).getOrThrow();
    });

final universalCatalogueRepositoryProvider =
    Provider<UniversalCatalogueRepository>((ref) {
      return DriftUniversalCatalogueRepository(
        ref.watch(careerSpeakDatabaseProvider),
      );
    });

final currentUniversalCatalogueProvider =
    FutureProvider<CurrentUniversalCatalogueSnapshot?>((ref) async {
      final repository = ref.watch(universalCatalogueRepositoryProvider);
      return (await repository.readCurrent()).getOrThrow();
    });
