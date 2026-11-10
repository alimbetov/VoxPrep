import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_delivery/catalogue_payload.dart';
import '../application/content_delivery/catalogue_revision_ref.dart';
import '../application/ports/catalogue_payload_gateway.dart';
import '../application/ports/catalogue_snapshot_repository.dart';
import '../application/ports/universal_catalogue_repository.dart';
import '../data/local/drift_catalogue_snapshot_repository.dart';
import '../data/local/drift_universal_catalogue_repository.dart';
import '../data/mock/demo_catalogue_payload_gateway.dart';
import '../data/mock/demo_vertical_catalogue_fixture.dart';
import '../data/remote/http_catalogue_payload_gateway.dart';
import '../domain/catalogue_source_mode.dart';
import 'api_client_providers.dart';
import 'catalogue_source_providers.dart';
import 'learner_state_providers.dart';

final demoCataloguePayloadsProvider = Provider<Map<String, CataloguePayload>>((
  ref,
) {
  return buildDemoVerticalCataloguePayloads();
});

/// Production defaults to HTTP. Tests and local development may override the
/// runtime source provider to use deterministic demo payloads.
final cataloguePayloadGatewayProvider = Provider<CataloguePayloadGateway>((
  ref,
) {
  return switch (ref.watch(catalogueSourceModeProvider)) {
    CatalogueSourceMode.production => HttpCataloguePayloadGateway(
      apiClient: ref.watch(apiClientProvider),
    ),
    CatalogueSourceMode.demo => DemoCataloguePayloadGateway(
      payloads: ref.watch(demoCataloguePayloadsProvider),
    ),
  };
});

final catalogueSnapshotRepositoryProvider =
    Provider<CatalogueSnapshotRepository>((ref) {
      return DriftCatalogueSnapshotRepository(
        ref.watch(careerSpeakDatabaseProvider),
      );
    });

// Observe only committed CURRENT changes. Staged catalogue rows must not
// replace the visible graph, and a first sync must refresh an initially empty UI.
final currentPublicationVersionProvider = StreamProvider<int?>((ref) {
  final database = ref.watch(careerSpeakDatabaseProvider);
  return (database.select(database.contentManifestStates)
        ..where((row) => row.id.equals(1)))
      .watchSingleOrNull()
      .map((state) => state?.currentContentVersion)
      .distinct();
});

final currentCatalogueProvider =
    FutureProvider.family<CataloguePayload?, CatalogueKind>((ref, kind) async {
      ref.watch(currentPublicationVersionProvider);
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
      ref.watch(currentPublicationVersionProvider);
      final repository = ref.watch(universalCatalogueRepositoryProvider);
      return (await repository.readCurrent()).getOrThrow();
    });
