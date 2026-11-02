import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/continue_learning/continue_learning_current_revalidator.dart';
import 'package:careerspeak_app/application/continue_learning/continue_learning_resolver.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:careerspeak_app/domain/practice_test_completion_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fully completed collection falls through to browse current track', () {
    const contentIdentity = ContentIdentity(
      code: 'CONTENT_A',
      type: ContentType.topic,
    );
    const proposed = ContinueLearningInput(
      incompleteMembers: <ContinueLearningMemberCandidate>[
        ContinueLearningMemberCandidate(
          collectionCode: 'COLLECTION_A',
          collectionSortOrder: 0,
          position: 0,
          target: ContinueLearningContentTarget(
            identity: contentIdentity,
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
      nextCollections: <ContinueLearningCollectionCandidate>[
        ContinueLearningCollectionCandidate(
          collectionCode: 'COLLECTION_A',
          trackCode: 'TRACK_A',
          sortOrder: 0,
        ),
      ],
    );

    final current = const ContinueLearningCurrentRevalidator().revalidate(
      proposed: proposed,
      graph: _graph(),
      selection: LearnerSelection(
        selectedGoalCode: 'GOAL_A',
        selectedTrackCode: 'TRACK_A',
      ),
      markers: <ContentIdentity, ContentMarkerState>{
        contentIdentity: ContentMarkerState(
          completed: true,
          lastRevisionSeen: 7,
        ),
      },
      completedPracticeTests: <PracticeTestCompletionKey>{
        PracticeTestCompletionKey(practiceTestCode: 'TEST_A', revision: 5),
      },
    );

    expect(current.incompleteMembers, isEmpty);
    expect(current.nextCollections, isEmpty);
    expect(current.browse?.trackCode, 'TRACK_A');
    expect(
      const ContinueLearningResolver().resolve(current),
      isA<BrowseTrackDecision>(),
    );
  });

  test('collection remains a valid fallback while any exact member is incomplete', () {
    const contentIdentity = ContentIdentity(
      code: 'CONTENT_A',
      type: ContentType.topic,
    );
    const proposed = ContinueLearningInput(
      nextCollections: <ContinueLearningCollectionCandidate>[
        ContinueLearningCollectionCandidate(
          collectionCode: 'COLLECTION_A',
          trackCode: 'TRACK_A',
          sortOrder: 0,
        ),
      ],
    );

    final current = const ContinueLearningCurrentRevalidator().revalidate(
      proposed: proposed,
      graph: _graph(),
      selection: LearnerSelection(
        selectedGoalCode: 'GOAL_A',
        selectedTrackCode: 'TRACK_A',
      ),
      markers: <ContentIdentity, ContentMarkerState>{
        contentIdentity: ContentMarkerState(
          completed: true,
          lastRevisionSeen: 7,
        ),
      },
      completedPracticeTests: const <PracticeTestCompletionKey>{},
    );

    expect(current.nextCollections, hasLength(1));
    expect(
      const ContinueLearningResolver().resolve(current),
      isA<OpenCollectionDecision>(),
    );
  });
}

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
