import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/assessment/assessment_revision_loader.dart';
import '../application/ports/assessment_payload_gateway.dart';
import '../application/ports/assessment_revision_repository.dart';
import '../data/local/drift_assessment_revision_repository.dart';
import '../data/mock/demo_assessment_payload_gateway.dart';
import '../data/remote/http_assessment_payload_gateway.dart';
import '../domain/catalogue_source_mode.dart';
import 'api_client_providers.dart';
import 'catalogue_source_providers.dart';
import 'learner_state_providers.dart';

final assessmentPayloadGatewayProvider = Provider<AssessmentPayloadGateway>((
  ref,
) {
  final source = ref.watch(catalogueSourceModeProvider);
  return switch (source) {
    CatalogueSourceMode.demo => DemoAssessmentPayloadGateway(),
    CatalogueSourceMode.production => HttpAssessmentPayloadGateway(
      apiClient: ref.watch(apiClientProvider),
    ),
  };
});

final assessmentRevisionRepositoryProvider =
    Provider<AssessmentRevisionRepository>((ref) {
      return DriftAssessmentRevisionRepository(
        ref.watch(careerSpeakDatabaseProvider),
      );
    });

final assessmentRevisionLoaderProvider = Provider<AssessmentRevisionLoader>((
  ref,
) {
  return AssessmentRevisionLoader(
    gateway: ref.watch(assessmentPayloadGatewayProvider),
    repository: ref.watch(assessmentRevisionRepositoryProvider),
  );
});
