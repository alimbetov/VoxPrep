import 'dart:io';

import 'package:careerspeak_app/application/assessment/assessment_revision_loader.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_coordinator.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/ports/universal_catalogue_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_assessment_revision_repository.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_repository.dart';
import 'package:careerspeak_app/data/local/drift_publication_snapshot_stager.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/data/local/drift_sync_plan_executor.dart';
import 'package:careerspeak_app/data/local/drift_universal_catalogue_repository.dart';
import 'package:careerspeak_app/data/mock/demo_assessment_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_catalogue_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_content_manifest_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_content_payload_gateway.dart';
import 'package:careerspeak_app/data/mock/demo_learning_fixture.dart';
import 'package:careerspeak_app/data/mock/demo_vertical_catalogue_fixture.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/practice_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'demo sync survives full database restart and remains fully learner-readable offline',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-v11-offline-restart-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final file = File('${directory.path}/careerspeak.sqlite');

      // Online phase: the demo source is used exactly once to stage and publish
      // the same production read models that real backend payloads use.
      var database = CareerSpeakDatabase(NativeDatabase(file));
      final cataloguePayloads = buildDemoVerticalCataloguePayloads();
      final manifestGateway = DemoContentManifestGateway(
        cataloguePayloads: cataloguePayloads.values,
        latency: Duration.zero,
      );
      final contentGateway = DemoContentPayloadGateway(latency: Duration.zero);
      final assessmentGateway = DemoAssessmentPayloadGateway(
        latency: Duration.zero,
      );
      final catalogueGateway = DemoCataloguePayloadGateway(
        payloads: cataloguePayloads,
        latency: Duration.zero,
      );
      final assessmentRepository = DriftAssessmentRevisionRepository(database);

      final coordinator = ContentSyncCoordinator(
        journal: DriftSyncJournal(database),
        manifestGateway: manifestGateway,
        planner: const ContentSyncPlanner(),
        executor: DriftSyncPlanExecutor(
          database,
          manifestGateway,
          contentGateway,
        ),
        snapshotStager: DriftPublicationSnapshotStager(
          database,
          AssessmentRevisionLoader(
            gateway: assessmentGateway,
            repository: assessmentRepository,
          ),
          catalogueGateway,
        ),
      );

      final synchronized = await coordinator.synchronize(
        runId: 'v11-demo-online-sync',
        trigger: SyncTrigger.manual,
        translationLocale: 'en',
      );
      expect(synchronized, isA<Success<ContentSyncOutcome>>());

      final beforeRestart = await DriftUniversalCatalogueRepository(
        database,
      ).readCurrent();
      expect(beforeRestart, isA<Success<CurrentUniversalCatalogueSnapshot?>>());
      final beforeSnapshot =
          (beforeRestart as Success<CurrentUniversalCatalogueSnapshot?>).value;
      expect(beforeSnapshot, isNotNull);
      expect(beforeSnapshot!.graph.verticals, hasLength(8));

      final manifestState = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(manifestState.currentContentVersion, 1);

      await database.close();

      // Offline phase: create a brand-new database/repository object graph over
      // the durable SQLite file. No demo gateway and no HTTP gateway is created
      // after this point.
      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);

      final catalogueRepository = DriftUniversalCatalogueRepository(database);
      final contentRepository = DriftContentRepository(database);
      final reopenedAssessmentRepository = DriftAssessmentRevisionRepository(
        database,
      );
      final practiceTestRepository = DriftPracticeTestRepository(
        database,
        reopenedAssessmentRepository,
      );

      final reopenedResult = await catalogueRepository.readCurrent();
      expect(
        reopenedResult,
        isA<Success<CurrentUniversalCatalogueSnapshot?>>(),
      );
      final reopened =
          (reopenedResult as Success<CurrentUniversalCatalogueSnapshot?>).value;
      expect(reopened, isNotNull);
      expect(reopened!.contentVersion, 1);
      expect(reopened.graph.verticals, hasLength(8));
      expect(reopened.graph.goals, hasLength(8));
      expect(reopened.graph.tracks, hasLength(8));
      expect(reopened.graph.collections, hasLength(8));

      final javaVertical = reopened.graph.verticals.singleWhere(
        (item) => item.code == 'JAVA_INTERVIEW',
      );
      final javaGoal = reopened.graph.goals.singleWhere(
        (item) => item.verticalCode == javaVertical.code,
      );
      final javaTrack = reopened.graph.tracks.singleWhere(
        (item) =>
            item.verticalCode == javaVertical.code &&
            item.goalCode == javaGoal.code,
      );
      final javaCollection = reopened.graph.collections.singleWhere(
        (item) =>
            item.verticalCode == javaVertical.code &&
            item.trackCode == javaTrack.code,
      );
      expect(javaCollection.members, hasLength(2));

      final contentMember = javaCollection.members.first;
      expect(contentMember.contentRef, isNotNull);
      final contentRef = contentMember.contentRef!;
      final content = await contentRepository.getByIdentity(
        ContentIdentity(
          code: contentRef.contentCode,
          type: contentRef.contentType,
        ),
      );
      expect(content, isA<Success<ContentItem?>>());
      final contentItem = (content as Success<ContentItem?>).value;
      expect(contentItem, isNotNull);
      expect(contentItem!.code, demoJavaContentCode);
      expect(contentItem.revision, contentRef.revision);

      final testMember = javaCollection.members.last;
      expect(testMember.practiceTestRef, isNotNull);
      final testRef = testMember.practiceTestRef!;
      final practiceTest = await practiceTestRepository.getByCode(
        testRef.practiceTestCode,
      );
      expect(practiceTest, isA<Success<PracticeTest?>>());
      final test = (practiceTest as Success<PracticeTest?>).value;
      expect(test, isNotNull);
      expect(test!.code, demoJavaTestCode);
      expect(test.questions, isNotEmpty);

      // Restart must not mutate CURRENT or require remote reconstruction.
      final reopenedState = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(reopenedState.currentContentVersion, 1);
    },
  );
}
