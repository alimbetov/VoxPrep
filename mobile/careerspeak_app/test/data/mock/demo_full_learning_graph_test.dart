import 'package:careerspeak_app/application/content_delivery/catalogue_payload.dart';
import 'package:careerspeak_app/application/content_delivery/catalogue_revision_ref.dart';
import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/content_payload.dart';
import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/ports/content_manifest_gateway.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/mock/demo_assessment_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_catalogue_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_content_manifest_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_content_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_learning_fixture.dart';
import 'package:careerspeak_app/data/mock/demo_vertical_catalogue_fixture.dart';
import 'package:careerspeak_app/data/remote/universal_catalogue_decoder_registry.dart';
import 'package:careerspeak_app/domain/assessment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo publishes a complete eight-vertical learning graph', () {
    final payloads = buildDemoVerticalCataloguePayloads().values.toList();
    const decoder = UniversalCatalogueDecoderRegistry();

    T decoded<T>(CatalogueKind kind) {
      final payload = payloads.singleWhere((item) => item.ref.kind == kind);
      return decoder.decode(payload) as T;
    }

    final graph = UniversalCatalogueGraph(
      sections: decoded<List<VerticalSectionProjection>>(
        CatalogueKind.verticalSections,
      ),
      verticals: decoded<List<LearningVerticalProjection>>(
        CatalogueKind.verticals,
      ),
      goals: decoded<List<LearningGoalProjection>>(
        CatalogueKind.learningGoals,
      ),
      tracks: decoded<List<LearningTrackProjection>>(
        CatalogueKind.learningTracks,
      ),
      collections: decoded<List<LearningCollectionProjection>>(
        CatalogueKind.learningCollections,
      ),
      presentation: decoded<VerticalCataloguePresentation>(
        CatalogueKind.verticalPresentation,
      ),
    );

    expect(graph.verticals, hasLength(8));
    expect(graph.goals, hasLength(8));
    expect(graph.tracks, hasLength(8));
    expect(graph.collections, hasLength(8));

    final java = graph.collections.singleWhere(
      (item) => item.verticalCode == 'JAVA_INTERVIEW',
    );
    expect(java.members.map((item) => item.type), [
      LearningCollectionMemberType.content,
      LearningCollectionMemberType.practiceTest,
    ]);

    final medical = graph.collections.singleWhere(
      (item) => item.verticalCode == 'MEDICAL_ENGLISH',
    );
    expect(medical.members.map((item) => item.type), [
      LearningCollectionMemberType.content,
      LearningCollectionMemberType.practiceTest,
    ]);
  });

  test('demo source serves manifest, pack, content and assessment exactly', () async {
    final cataloguePayloads = buildDemoVerticalCataloguePayloads().values;
    final manifestGateway = DemoContentManifestGateway(
      cataloguePayloads: cataloguePayloads,
      latency: Duration.zero,
    );

    final rootResult = await manifestGateway.fetchRootManifest();
    expect(rootResult, isA<Success<RootManifestFetch>>());
    final rootFetch = (rootResult as Success<RootManifestFetch>).value;
    expect(rootFetch, isA<RootManifestChanged>());
    final root = (rootFetch as RootManifestChanged).manifest;
    expect(root.packs, hasLength(1));
    expect(root.practiceTests, hasLength(2));
    expect(root.catalogues, hasLength(6));

    final packResult = await manifestGateway.fetchPackManifest(root.packs.single);
    expect(packResult, isA<Success<PackContentManifest>>());
    final pack = (packResult as Success<PackContentManifest>).value;

    final contentGateway = DemoContentPayloadGateway(latency: Duration.zero);
    final firstContent = pack.contents.first;
    final contentResult = await contentGateway.fetch(
      ContentPayloadRef(
        identity: firstContent.identity,
        revision: firstContent.revision,
        checksum: firstContent.checksum,
      ),
    );
    expect(contentResult, isA<Success<ContentPayload>>());

    final assessmentGateway = DemoAssessmentPayloadGateway(latency: Duration.zero);
    final testRef = root.practiceTests.first;
    final testResult = await assessmentGateway.fetchPracticeTestRevision(
      practiceTestCode: testRef.practiceTestCode,
      revision: testRef.revision,
      checksum: testRef.checksum,
    );
    expect(testResult, isA<Success<PracticeTestRevision>>());

    final testRevision = (testResult as Success<PracticeTestRevision>).value;
    final questionResult = await assessmentGateway.fetchQuestionRevision(
      testRevision.questionRefs.first.question,
    );
    expect(questionResult, isA<Success<AssessmentQuestionRevision>>());
  });

  test('demo catalogue gateway serves all exact six-core revisions', () async {
    final payloads = buildDemoVerticalCataloguePayloads();
    final gateway = DemoCataloguePayloadGateway(
      payloads: payloads,
      latency: Duration.zero,
    );
    for (final payload in payloads.values) {
      final result = await gateway.fetch(payload.ref);
      expect(result, isA<Success<CataloguePayload>>());
    }
  });
}
