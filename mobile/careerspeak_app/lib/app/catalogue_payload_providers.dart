import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/catalogue_payload_gateway.dart';
import '../application/ports/catalogue_snapshot_repository.dart';
import '../application/ports/universal_catalogue_repository.dart';
import '../data/local/drift_catalogue_snapshot_repository.dart';
import '../data/local/drift_universal_catalogue_repository.dart';
import '../data/remote/http_catalogue_payload_gateway.dart';
import 'api_client_providers.dart';
import 'learner_state_providers.dart';

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

final universalCatalogueRepositoryProvider =
    Provider<UniversalCatalogueRepository>((ref) {
      return DriftUniversalCatalogueRepository(
        ref.watch(careerSpeakDatabaseProvider),
      );
    });
