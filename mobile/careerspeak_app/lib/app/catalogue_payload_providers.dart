import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final demoCataloguePayloadsProvider = Provider((ref) {
  return buildDemoVerticalCataloguePayloads();
});

final cataloguePayloadGatewayProvider = Provider<CataloguePayloadGateway>((ref) {
  final source = ref.watch(catalogueSourceModeProvider);
  return switch (source) {
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
