import 'package:careerspeak_app/application/continue_learning/continue_learning_resolver.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/last_opened_content.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = ContinueLearningResolver();

  group('ContinueLearningResolver', () {
    test('uses the normative BA-04 priority order', () {
      final attempt = _attempt();
      final lastOpened = _lastOpened();
      final member = _member(
        collectionCode: 'COLLECTION_A',
        collectionSortOrder: 0,
        position: 0,
      );
      const collection = ContinueLearningCollectionCandidate(
        collectionCode: 'COLLECTION_B',
        trackCode: 'TRACK_A',
        sortOrder: 0,
      );
      const browse = ContinueLearningBrowseCandidate(
        verticalCode: 'TECH',
        trackCode: 'JAVA',
      );

      final withAttempt = resolver.resolve(
        ContinueLearningInput(
          activePracticeTestAttempt: attempt,
          unfinishedLastOpenedContent: lastOpened,
          incompleteMembers: <ContinueLearningMemberCandidate>[member],
          nextCollections: const <ContinueLearningCollectionCandidate>[
            collection,
          ],
          browse: browse,
        ),
      );
      expect(withAttempt, isA<ResumePracticeTestDecision>());

      final withLastOpened = resolver.resolve(
        ContinueLearningInput(
          unfinishedLastOpenedContent: lastOpened,
          incompleteMembers: <ContinueLearningMemberCandidate>[member],
          nextCollections: const <ContinueLearningCollectionCandidate>[
            collection,
          ],
          browse: browse,
        ),
      );
      expect(withLastOpened, isA<ResumeContentDecision>());

      final withMember = resolver.resolve(
        ContinueLearningInput(
          incompleteMembers: <ContinueLearningMemberCandidate>[member],
          nextCollections: const <ContinueLearningCollectionCandidate>[
            collection,
          ],
          browse: browse,
        ),
      );
      expect(withMember, isA<OpenMemberDecision>());

      final withCollection = resolver.resolve(
        const ContinueLearningInput(
          nextCollections: <ContinueLearningCollectionCandidate>[collection],
          browse: browse,
        ),
      );
      expect(withCollection, isA<OpenCollectionDecision>());

      final withTrack = resolver.resolve(
        const ContinueLearningInput(browse: browse),
      );
      expect(withTrack, isA<BrowseTrackDecision>());

      final withVertical = resolver.resolve(
        const ContinueLearningInput(
          browse: ContinueLearningBrowseCandidate(verticalCode: 'TECH'),
        ),
      );
      expect(withVertical, isA<BrowseVerticalDecision>());

      expect(
        resolver.resolve(const ContinueLearningInput()),
        isA<ChooseDirectionDecision>(),
      );
    });

    test('member selection is invariant to input order', () {
      final expected = _member(
        collectionCode: 'COLLECTION_A',
        collectionSortOrder: 1,
        position: 0,
      );
      final sameCollectionLater = _member(
        collectionCode: 'COLLECTION_A',
        collectionSortOrder: 1,
        position: 2,
      );
      final laterCollection = _member(
        collectionCode: 'COLLECTION_Z',
        collectionSortOrder: 5,
        position: 0,
      );

      for (final members in <List<ContinueLearningMemberCandidate>>[
        <ContinueLearningMemberCandidate>[
          laterCollection,
          sameCollectionLater,
          expected,
        ],
        <ContinueLearningMemberCandidate>[
          expected,
          laterCollection,
          sameCollectionLater,
        ],
        <ContinueLearningMemberCandidate>[
          sameCollectionLater,
          expected,
          laterCollection,
        ],
      ]) {
        final decision = resolver.resolve(
          ContinueLearningInput(incompleteMembers: members),
        );
        final selected = (decision as OpenMemberDecision).candidate;
        expect(selected.collectionCode, 'COLLECTION_A');
        expect(selected.position, 0);
      }
    });

    test('collection selection is invariant to input order', () {
      const first = ContinueLearningCollectionCandidate(
        collectionCode: 'COLLECTION_A',
        trackCode: 'TRACK_A',
        sortOrder: 2,
      );
      const second = ContinueLearningCollectionCandidate(
        collectionCode: 'COLLECTION_B',
        trackCode: 'TRACK_A',
        sortOrder: 2,
      );
      const later = ContinueLearningCollectionCandidate(
        collectionCode: 'COLLECTION_0',
        trackCode: 'TRACK_A',
        sortOrder: 3,
      );

      for (final collections in <List<ContinueLearningCollectionCandidate>>[
        const <ContinueLearningCollectionCandidate>[later, second, first],
        const <ContinueLearningCollectionCandidate>[first, later, second],
        const <ContinueLearningCollectionCandidate>[second, first, later],
      ]) {
        final decision = resolver.resolve(
          ContinueLearningInput(nextCollections: collections),
        );
        final selected = (decision as OpenCollectionDecision).collection;
        expect(selected.collectionCode, 'COLLECTION_A');
      }
    });

    test('member decision preserves exact content and test revisions', () {
      const contentTarget = ContinueLearningContentTarget(
        identity: ContentIdentity(code: 'CONTENT_A', type: ContentType.topic),
        revision: 7,
      );
      final contentDecision = resolver.resolve(
        const ContinueLearningInput(
          incompleteMembers: <ContinueLearningMemberCandidate>[
            ContinueLearningMemberCandidate(
              collectionCode: 'C',
              collectionSortOrder: 0,
              position: 0,
              target: contentTarget,
            ),
          ],
        ),
      );
      expect(
        ((contentDecision as OpenMemberDecision).candidate.target
                as ContinueLearningContentTarget)
            .revision,
        7,
      );

      final testDecision = resolver.resolve(
        const ContinueLearningInput(
          incompleteMembers: <ContinueLearningMemberCandidate>[
            ContinueLearningMemberCandidate(
              collectionCode: 'C',
              collectionSortOrder: 0,
              position: 0,
              target: ContinueLearningPracticeTestTarget(
                practiceTestCode: 'TEST_A',
                revision: 11,
              ),
            ),
          ],
        ),
      );
      expect(
        ((testDecision as OpenMemberDecision).candidate.target
                as ContinueLearningPracticeTestTarget)
            .revision,
        11,
      );
    });

    test('blank track falls back to current vertical', () {
      final decision = resolver.resolve(
        const ContinueLearningInput(
          browse: ContinueLearningBrowseCandidate(
            verticalCode: 'TECH',
            trackCode: '   ',
          ),
        ),
      );

      expect(decision, isA<BrowseVerticalDecision>());
    });
  });
}

PracticeTestAttempt _attempt() {
  final now = DateTime.utc(2026, 11, 1, 10);
  return PracticeTestAttempt(
    practiceTestCode: 'TEST_A',
    practiceTestRevision: 3,
    currentIndex: 1,
    answers: const <int, int>{0: 2},
    startedAt: now,
    updatedAt: now,
  );
}

LastOpenedContent _lastOpened() {
  return LastOpenedContent(
    identity: const ContentIdentity(
      code: 'CONTENT_A',
      type: ContentType.topic,
    ),
    contentRevision: 4,
    openedAt: DateTime.utc(2026, 11, 1, 9),
  );
}

ContinueLearningMemberCandidate _member({
  required String collectionCode,
  required int collectionSortOrder,
  required int position,
}) {
  return ContinueLearningMemberCandidate(
    collectionCode: collectionCode,
    collectionSortOrder: collectionSortOrder,
    position: position,
    target: ContinueLearningContentTarget(
      identity: ContentIdentity(
        code: 'CONTENT_$collectionCode-$position',
        type: ContentType.topic,
      ),
      revision: 1,
    ),
  );
}
