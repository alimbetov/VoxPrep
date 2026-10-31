import 'package:careerspeak_app/app/api_client_providers.dart';
import 'package:careerspeak_app/app/assessment_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/ports/api_client.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/remote/http_assessment_payload_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_database_factory.dart';

void main() {
  test('composition root exposes production exact assessment lifecycle', () {
    final database = createTestDatabase();
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(const _UnusedApiClient()),
        careerSpeakDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(database.close);

    expect(
      container.read(assessmentPayloadGatewayProvider),
      isA<HttpAssessmentPayloadGateway>(),
    );
    expect(
      container.read(assessmentRevisionRepositoryProvider),
      isA<DriftAssessmentRevisionRepository>(),
    );
    expect(
      container.read(assessmentRevisionLoaderProvider),
      isA<AssessmentRevisionLoader>(),
    );
  });
}

final class _UnusedApiClient implements ApiClient {
  const _UnusedApiClient();

  @override
  Future<Result<ApiResponse>> send(ApiRequest request) {
    throw StateError('Transport must not be called by composition test.');
  }
}
