import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/continue_learning/continue_learning_current_revalidator.dart';
import 'package:careerspeak_app/application/continue_learning/continue_learning_resolver.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_last_opened_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_attempt_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/domain/last_opened_content.dart';
import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:careerspeak_app/domain/practice_test_completion_key.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('BA-04 durable facts survive repeated process-style reopen', () async {
    final directory = await Directory.systemTemp.createTemp('ba04-restart-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/careerspeak.sqlite');
    final startedAt = DateTime.utc(2026, 11, 1, 10);
    final openedAt = DateTime.utc(2026, 11, 1, 9, 30);

    var database = CareerSpeakDatabase(NativeDatabase(file));
    expect(database.schemaVersion, greaterThanOrEqualTo(15));
    final attemptRepository = DriftPracticeTestAttemptRepository(
      database,
      now: () => startedAt.add(const Duration(minutes: 10)),
    );
    final lastOpenedRepository = DriftLastOpenedContentRepository(
      database,
      now: () => openedAt,
    );

    final attempt = PracticeTestAttempt(
      practiceTestCode: 'TEST_A',
      practiceTestRevision: 5,
      currentIndex: 2,
      answers: const <int, int>{0: 1, 1: 2},
      startedAt: startedAt,
      updatedAt: startedAt.add(const Duration(minutes: 3)),
    );
    expect(
      await attemptRepository.saveActiveAttempt(attempt),
      isA<Success<PracticeTestAttempt>>(),
    );
    expect(
      await lastOpenedRepository.recordOpened(
        identity: _contentIdentity,
        contentRevision: 7,
      ),
      isA<Success<LastOpenedContent>>(),
    );
    await database.close();

    database = CareerSpeakDatabase(NativeDatabase(file));
    final reopenedAttemptRepository = DriftPracticeTestAttemptRepository(
      database,
      now: () => startedAt.add(const Duration(minutes: 10)),
    );
    final reopenedLastOpenedRepository = DriftLastOpenedContentRepository(
      database,
    );
    final restoredAttempt =
        (await reopenedAttemptRepository.getActiveAttempt()
                as Success<PracticeTestAttempt?>)
            .value;
    final restoredLastOpened =
        (await reopenedLastOpenedRepository.getLastOpenedContent()
                as Success<LastOpenedContent?>)
            .value;

    expect(restoredAttempt?.practiceTestCode, 'TEST_A');
    expect(restoredAttempt?.practiceTestRevision, 5);
    expect(restoredAttempt?.currentIndex, 2);
    expect(restoredAttempt?.answers, const <int, int>{0: 1, 1: 2});
    expect(restoredLastOpened?.identity, _contentIdentity);
    expect(restoredLastOpened?.contentRevision, 7);
    expect(restoredLastOpened?.openedAt, openedAt);

    const revalidator = ContinueLearningCurrentRevalidator();
    const resolver = ContinueLearningResolver();
    final graph = _graph();
    final selection = LearnerSelection(
      selectedGoalCode: 'GOAL_A',
      selectedTrackCode: 'TRACK_A',
    );
    final proposed = ContinueLearningInput(
      activePracticeTestAttempt: restoredAttempt,
      unfinishedLastOpenedContent: restoredLastOpened,
      incompleteMembers: const <ContinueLearningMemberCandidate>[
        ContinueLearningMemberCandidate(
          collectionCode: 'COLLECTION_A',
          collectionSortOrder: 0,
          position: 0,
          target: ContinueLearningContentTarget(
            identity: _contentIdentity,
            revision: 7,
          ),
        ),
        ContinueLearningMemberCandidate(
          collectionCode: 'COLLECTION_A',
          collectionSortOrder: 0,
          position: 1,
          target: ContinueLearningPracticeTestTarget(
            practiceTestCode: 'TEST_A',
            revision: 5,
          ),
        ),
      ],
      nextCollections: const <ContinueLearningCollectionCandidate>[
        ContinueLearningCollectionCandidate(
          collectionCode: 'COLLECTION_A',
          trackCode: 'TRACK_A',
          sortOrder: 0,
        ),
      ],
    );
    final current = revalidator.revalidate(
      proposed: proposed,
      graph: graph,
      selection: selection,
      markers: const <ContentIdentity, ContentMarkerState>{},
    );
    expect(resolver.resolve(current), isA<ResumePracticeTestDecision>());

    expect(
      await reopenedAttemptRepository.completeActiveAttempt(),
      isA<Success<void>>(),
    );
    await database.close();

    database = CareerSpeakDatabase(NativeDatabase(file));
    addTearDown(database.close);
    final thirdAttemptRepository = DriftPracticeTestAttemptRepository(database);
    final thirdAttempt =
        (await thirdAttemptRepository.getActiveAttempt()
                as Success<PracticeTestAttempt?>)
            .value;
    final completedPracticeTests =
        (await thirdAttemptRepository.getCompletedPracticeTests()
                as Success<Set<PracticeTestCompletionKey>>)
            .value;
    final thirdLastOpened =
        (await DriftLastOpenedContentRepository(database).getLastOpenedContent()
                as Success<LastOpenedContent?>)
            .value;

    expect(thirdAttempt, isNull);
    expect(
      completedPracticeTests,
      contains(
        const PracticeTestCompletionKey(
          practiceTestCode: 'TEST_A',
          revision: 5,
        ),
      ),
    );
    expect(thirdLastOpened?.identity, _contentIdentity);

    final afterSubmit = revalidator.revalidate(
      proposed: ContinueLearningInput(
        unfinishedLastOpenedContent: thirdLastOpened,
        incompleteMembers: proposed.incompleteMembers,
        nextCollections: proposed.nextCollections,
      ),
      graph: graph,
      selection: selection,
      markers: const <ContentIdentity, ContentMarkerState>{},
      completedPracticeTests: completedPracticeTests,
    );
    expect(
      afterSubmit.incompleteMembers.where(
        (candidate) => candidate.target is ContinueLearningPracticeTestTarget,
      ),
      isEmpty,
    );
    expect(resolver.resolve(afterSubmit), isA<ResumeContentDecision>());
  });

  test('BA-04 fails closed on corrupted durable attempt payload', () async {
    final directory = await Directory.systemTemp.createTemp('ba04-corrupt-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/careerspeak.sqlite');
    final database = CareerSpeakDatabase(NativeDatabase(file));
    addTearDown(database.close);

    await database.customStatement('''
      INSERT INTO practice_test_active_attempt (
        id,
        practice_test_code,
        practice_test_revision,
        current_index,
        answers_json,
        started_at,
        updated_at
      ) VALUES (1, 'TEST_A', 5, 0, '{"bad":-1}', 1, 1)
      ''');

    final result = await DriftPracticeTestAttemptRepository(database)
        .getActiveAttempt();

    expect(result, isA<FailureResult<PracticeTestAttempt?>>());
    expect(
      (result as FailureResult<PracticeTestAttempt?>).failure.code,
      'PRACTICE_TEST_ATTEMPT_READ_FAILED',
    );
  });

  test('BA-04 stale durable facts fall through deterministically', () {
    const revalidator = ContinueLearningCurrentRevalidator();
    const resolver = ContinueLearningResolver();
    final now = DateTime.utc(2026, 11, 1, 10);
    final staleAttempt = PracticeTestAttempt(
      practiceTestCode: 'TEST_A',
      practiceTestRevision: 4,
      currentIndex: 0,
      answers: const <int, int>{},
      startedAt: now,
      updatedAt: now,
    );
    final staleContent = LastOpenedContent(
      identity: _contentIdentity,
      contentRevision: 6,
      openedAt: now,
    );
    final selection = LearnerSelection(
      selectedGoalCode: 'GOAL_A',
      selectedTrackCode: 'TRACK_A',
    );

    final current = revalidator.revalidate(
      proposed: ContinueLearningInput(
        activePracticeTestAttempt: staleAttempt,
        unfinishedLastOpenedContent: staleContent,
        incompleteMembers: const <ContinueLearningMemberCandidate>[
          ContinueLearningMemberCandidate(
            collectionCode: 'COLLECTION_A',
            collectionSortOrder: 0,
            position: 0,
            target: ContinueLearningContentTarget(
              identity: _contentIdentity,
              revision: 7,
            ),
          ),
        ],
      ),
      graph: _graph(),
      selection: selection,
      markers: const <ContentIdentity, ContentMarkerState>{},
    );

    expect(current.activePracticeTestAttempt, isNull);
    expect(current.unfinishedLastOpenedContent, isNull);
    final decision = resolver.resolve(current);
    expect(decision, isA<OpenMemberDecision>());
    expect(
      ((decision as OpenMemberDecision).candidate.target
              as ContinueLearningContentTarget)
          .revision,
      7,
    );
  });
}

const _contentIdentity = ContentIdentity(
  code: 'CONTENT_A',
  type: ContentType.topic,
);

UniversalCatalogueGraph _graph() {
  const checksum =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  return UniversalCatalogueGraph(
    sections: <VerticalSectionProjection>[
      VerticalSectionProjection(
        code: 'SECTION_A',
        title: 'Section',
        sortOrder: 0,
        active: true,
      ),
    ],
    verticals: <LearningVerticalProjection>[
      LearningVerticalProjection(
        code: 'VERTICAL_A',
        sectionCode: 'SECTION_A',
        title: 'Vertical',
        description: 'Vertical description',
        iconAssetId: 'ICON_A',
        sortOrder: 0,
        active: true,
      ),
    ],
    goals: <LearningGoalProjection>[
      LearningGoalProjection(
        code: 'GOAL_A',
        verticalCode: 'VERTICAL_A',
        title: 'Goal',
        description: 'Goal description',
        sortOrder: 0,
        active: true,
      ),
    ],
    tracks: <LearningTrackProjection>[
      LearningTrackProjection(
        code: 'TRACK_A',
        verticalCode: 'VERTICAL_A',
        goalCode: 'GOAL_A',
        title: 'Track',
        description: 'Track description',
        levelCode: 'B2',
        sortOrder: 0,
        active: true,
      ),
    ],
    collections: <LearningCollectionProjection>[
      LearningCollectionProjection(
        code: 'COLLECTION_A',
        verticalCode: 'VERTICAL_A',
        trackCode: 'TRACK_A',
        title: 'Collection',
        description: 'Collection description',
        sortOrder: 0,
        active: true,
        members: <LearningCollectionMember>[
          LearningCollectionMember.content(
            position: 0,
            content: ContentRevisionRef(
              contentCode: 'CONTENT_A',
              contentType: ContentType.topic,
              revision: 7,
              checksum: checksum,
            ),
          ),
          LearningCollectionMember.practiceTest(
            position: 1,
            practiceTest: PracticeTestRevisionRef(
              practiceTestCode: 'TEST_A',
              revision: 5,
              checksum: checksum,
            ),
          ),
        ],
      ),
    ],
    presentation: VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.shelves,
      showFeatured: false,
      showSeeAll: true,
    ),
  );
}
