import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_delivery/catalogue_payload.dart';
import '../application/content_delivery/catalogue_revision_ref.dart';
import '../application/ports/catalogue_payload_gateway.dart';
import '../application/ports/catalogue_snapshot_repository.dart';
import '../application/result/result.dart';
import '../data/local/drift_catalogue_snapshot_repository.dart';
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

/// Learner/UI-facing catalogue projection. The provider never resolves a
/// latest catalogue revision: the repository reads only the exact revision
/// owned by ContentManifestStates.currentContentVersion.
final currentCatalogueProvider =
    FutureProvider.family<CataloguePayload?, CatalogueKind>((ref, kind) async {
      final repository = ref.watch(catalogueSnapshotRepositoryProvider);
      return (await repository.readCurrent(kind)).getOrThrow();
    });
