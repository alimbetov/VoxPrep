import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/continue_learning/continue_learning_current_revalidator.dart';
import 'package:careerspeak_app/application/continue_learning/continue_learning_resolver.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/domain/last_opened_content.dart';
import 'package:careerspeak_app/domain/learner_selection.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:careerspeak_app/domain/practice_test_completion_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const revalidator = ContinueLearningCurrentRevalidator();
  const contentIdentity = ContentIdentity(
    code: 'CONTENT_A',
    type: ContentType.topic,
  );

  group('ContinueLearningCurrentRevalidator', () {
    test('keeps exact CURRENT candidates under active selected hierarchy', () {
      final graph = _graph();
      final attempt = _attempt(revision: 5);
      final lastOpened = _lastOpened(revision: 7);
      final proposed = ContinueLearningInput(
        activePracticeTestAttempt: attempt,
        unfinishedLastOpenedContent: lastOpened,
        incompleteMembers: const <ContinueLearningMemberCandidate>[
          ContinueLearningMemberCandidate(
            collectionCode: 'COLLECTION_A',
            collectionSortOrder: 0,
            position: 0,
            target: ContinueLearningContentTarget(
              identity: contentIdentity,
              revision: 7,
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

      final result = revalidator.revalidate(
        proposed: proposed,
        graph: graph,
        selection: _selection(),
        markers: const <ContentIdentity, ContentMarkerState>{},
      );

      expect(result.activePracticeTestAttempt, same(attempt));
      expect(result.unfinishedLastOpenedContent, same(lastOpened));
      expect(result.incompleteMembers, hasLength(1));
      expect(result.nextCollections, hasLength(1));
      expect(result.browse?.verticalCode, 'VERTICAL_A');
      expect(result.browse?.trackCode, 'TRACK_A');
    });

    test('drops stale exact revisions and dangling member candidates', () {
      final graph = _graph();
      final result = revalidator.revalidate(
        proposed: ContinueLearningInput(
          activePracticeTestAttempt: _attempt(revision: 4),
          unfinishedLastOpenedContent: _lastOpened(revision: 6),
          incompleteMembers: const <ContinueLearningMemberCandidate>[
            ContinueLearningMemberCandidate(
              collectionCode: 'COLLECTION_A',
              collectionSortOrder: 0,
              position: 0,
              target: ContinueLearningContentTarget(
                identity: contentIdentity,
                revision: 6,
              ),
            ),
            ContinueLearningMemberCandidate(
              collectionCode: 'MISSING_COLLECTION',
              collectionSortOrder: 0,
              position: 0,
              target: ContinueLearningContentTarget(
                identity: contentIdentity,
                revision: 7,
              ),
            ),
          ],
        ),
        graph: graph,
        selection: _selection(),
        markers: const <ContentIdentity, ContentMarkerState>{},
      );

      expect(result.activePracticeTestAttempt, isNull);
      expect(result.unfinishedLastOpenedContent, isNull);
      expect(result.incompleteMembers, isEmpty);
    });

    test('exact completion suppresses last-opened and content member', () {
      final result = revalidator.revalidate(
        proposed: ContinueLearningInput(
          unfinishedLastOpenedContent: _lastOpened(revision: 7),
          incompleteMembers: const <ContinueLearningMemberCandidate>[
            ContinueLearningMemberCandidate(
              collectionCode: 'COLLECTION_A',
              collectionSortOrder: 0,
              position: 0,
              target: ContinueLearningContentTarget(
                identity: contentIdentity,
                revision: 7,
              ),
            ),
          ],
        ),
        graph: _graph(),
        selection: _selection(),
        markers: <ContentIdentity, ContentMarkerState>{
          contentIdentity: const ContentMarkerState(
            completed: true,
            lastRevisionSeen: 7,
          ),
        },
      );

      expect(result.unfinishedLastOpenedContent, isNull);
      expect(result.incompleteMembers, isEmpty);
    });

    test(
      'completion of an older revision does not complete CURRENT revision',
      () {
        final result = revalidator.revalidate(
          proposed: ContinueLearningInput(
            unfinishedLastOpenedContent: _lastOpened(revision: 7),
            incompleteMembers: const <ContinueLearningMemberCandidate>[
              ContinueLearningMemberCandidate(
                collectionCode: 'COLLECTION_A',
                collectionSortOrder: 0,
                position: 0,
                target: ContinueLearningContentTarget(
                  identity: contentIdentity,
                  revision: 7,
                ),
              ),
            ],
          ),
          graph: _graph(),
          selection: _selection(),
          markers: <ContentIdentity, ContentMarkerState>{
            contentIdentity: const ContentMarkerState(
              completed: true,
              lastRevisionSeen: 6,
            ),
          },
        );

        expect(result.unfinishedLastOpenedContent, isNotNull);
        expect(result.incompleteMembers, hasLength(1));
      },
    );

    test('fails closed for inactive or stale selected hierarchy', () {
      final result = revalidator.revalidate(
        proposed: const ContinueLearningInput(
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
          ],
          nextCollections: <ContinueLearningCollectionCandidate>[
            ContinueLearningCollectionCandidate(
              collectionCode: 'COLLECTION_A',
              trackCode: 'TRACK_A',
              sortOrder: 0,
            ),
          ],
        ),
        graph: _graph(trackActive: false),
        selection: _selection(),
        markers: const <ContentIdentity, ContentMarkerState>{},
      );

      expect(result.incompleteMembers, isEmpty);
      expect(result.nextCollections, isEmpty);
      expect(result.browse, isNull);
    });

    test('practice-test member is eligible without exact completion', () {
      final result = revalidator.revalidate(
        proposed: _practiceTestOnlyInput(),
        graph: _graph(),
        selection: _selection(),
        markers: const <ContentIdentity, ContentMarkerState>{},
      );

      expect(result.incompleteMembers, hasLength(1));
      expect(
        result.incompleteMembers.single.target,
        isA<ContinueLearningPracticeTestTarget>(),
      );
    });

    test('exact practice-test completion suppresses only that revision', () {
      final exact = revalidator.revalidate(
        proposed: _practiceTestOnlyInput(),
        graph: _graph(),
        selection: _selection(),
        markers: const <ContentIdentity, ContentMarkerState>{},
        completedPracticeTests: <PracticeTestCompletionKey>{
          const PracticeTestCompletionKey(
            practiceTestCode: 'TEST_A',
            revision: 5,
          ),
        },
      );
      expect(exact.incompleteMembers, isEmpty);

      final older = revalidator.revalidate(
        proposed: _practiceTestOnlyInput(),
        graph: _graph(),
        selection: _selection(),
        markers: const <ContentIdentity, ContentMarkerState>{},
        completedPracticeTests: <PracticeTestCompletionKey>{
          const PracticeTestCompletionKey(
            practiceTestCode: 'TEST_A',
            revision: 4,
          ),
        },
      );
      expect(older.incompleteMembers, hasLength(1));
    });
  });
}

ContinueLearningInput _practiceTestOnlyInput() {
  return const ContinueLearningInput(
    incompleteMembers: <ContinueLearningMemberCandidate>[
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
  );
}

LearnerSelection _selection() =>
    LearnerSelection(selectedGoalCode: 'GOAL_A', selectedTrackCode: 'TRACK_A');

PracticeTestAttempt _attempt({required int revision}) {
  final now = DateTime.utc(2026, 11, 1, 10);
  return PracticeTestAttempt(
    practiceTestCode: 'TEST_A',
    practiceTestRevision: revision,
    currentIndex: 0,
    answers: const <int, int>{},
    startedAt: now,
    updatedAt: now,
  );
}

LastOpenedContent _lastOpened({required int revision}) => LastOpenedContent(
  identity: const ContentIdentity(code: 'CONTENT_A', type: ContentType.topic),
  contentRevision: revision,
  openedAt: DateTime.utc(2026, 11, 1, 9),
);

UniversalCatalogueGraph _graph({bool trackActive = true}) {
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
        active: trackActive,
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
