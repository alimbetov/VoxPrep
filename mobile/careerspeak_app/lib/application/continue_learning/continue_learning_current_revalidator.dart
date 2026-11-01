import '../../domain/content_identity.dart';
import '../../domain/content_marker_state.dart';
import '../../domain/learner_selection.dart';
import '../../domain/practice_test_completion_key.dart';
import '../content_delivery/product_catalog.dart';
import '../content_delivery/universal_catalogue_graph.dart';
import 'continue_learning_resolver.dart';

final class ContinueLearningCurrentRevalidator {
  const ContinueLearningCurrentRevalidator();

  ContinueLearningInput revalidate({
    required ContinueLearningInput proposed,
    required UniversalCatalogueGraph graph,
    required LearnerSelection selection,
    required Map<ContentIdentity, ContentMarkerState> markers,
    Set<PracticeTestCompletionKey> completedPracticeTests =
        const <PracticeTestCompletionKey>{},
  }) {
    final activeHierarchy = _ActiveHierarchy.tryCreate(graph, selection);
    final activeCollections = _activeCollections(graph);

    final attempt = proposed.activePracticeTestAttempt;
    final validAttempt = attempt != null &&
            _containsPracticeTest(
              activeCollections,
              attempt.practiceTestCode,
              attempt.practiceTestRevision,
            )
        ? attempt
        : null;

    final lastOpened = proposed.unfinishedLastOpenedContent;
    final validLastOpened = lastOpened != null &&
            _containsContent(
              activeCollections,
              lastOpened.identity,
              lastOpened.contentRevision,
            ) &&
            !_isCompletedAtRevision(
              markers[lastOpened.identity],
              lastOpened.contentRevision,
            )
        ? lastOpened
        : null;

    final members = activeHierarchy == null
        ? const <ContinueLearningMemberCandidate>[]
        : proposed.incompleteMembers
              .where(
                (candidate) => _validMemberCandidate(
                  candidate,
                  graph,
                  activeHierarchy,
                  markers,
                  completedPracticeTests,
                ),
              )
              .toList(growable: false);

    final collections = activeHierarchy == null
        ? const <ContinueLearningCollectionCandidate>[]
        : proposed.nextCollections
              .where(
                (candidate) => _validCollectionCandidate(
                  candidate,
                  graph,
                  activeHierarchy,
                ),
              )
              .toList(growable: false);

    return ContinueLearningInput(
      activePracticeTestAttempt: validAttempt,
      unfinishedLastOpenedContent: validLastOpened,
      incompleteMembers: members,
      nextCollections: collections,
      browse: activeHierarchy?.browse,
    );
  }

  static bool _validMemberCandidate(
    ContinueLearningMemberCandidate candidate,
    UniversalCatalogueGraph graph,
    _ActiveHierarchy hierarchy,
    Map<ContentIdentity, ContentMarkerState> markers,
    Set<PracticeTestCompletionKey> completedPracticeTests,
  ) {
    LearningCollectionProjection? collection;
    for (final current in graph.collections) {
      if (current.code == candidate.collectionCode) {
        collection = current;
        break;
      }
    }
    if (collection == null ||
        !collection.active ||
        collection.trackCode != hierarchy.trackCode ||
        collection.verticalCode != hierarchy.verticalCode ||
        collection.sortOrder != candidate.collectionSortOrder) {
      return false;
    }

    LearningCollectionMember? member;
    for (final current in collection.members) {
      if (current.position == candidate.position) {
        member = current;
        break;
      }
    }
    if (member == null) return false;

    final target = candidate.target;
    if (target is ContinueLearningContentTarget) {
      final ref = member.contentRef;
      if (member.type != LearningCollectionMemberType.content || ref == null) {
        return false;
      }
      if (ref.contentCode != target.identity.code ||
          ref.contentType != target.identity.type ||
          ref.revision != target.revision) {
        return false;
      }
      return !_isCompletedAtRevision(markers[target.identity], target.revision);
    }

    if (target is ContinueLearningPracticeTestTarget) {
      final ref = member.practiceTestRef;
      if (member.type != LearningCollectionMemberType.practiceTest ||
          ref == null ||
          ref.practiceTestCode != target.practiceTestCode ||
          ref.revision != target.revision) {
        return false;
      }
      return !completedPracticeTests.contains(
        PracticeTestCompletionKey(
          practiceTestCode: target.practiceTestCode,
          revision: target.revision,
        ),
      );
    }

    return false;
  }

  static bool _validCollectionCandidate(
    ContinueLearningCollectionCandidate candidate,
    UniversalCatalogueGraph graph,
    _ActiveHierarchy hierarchy,
  ) {
    for (final collection in graph.collections) {
      if (collection.code == candidate.collectionCode) {
        return collection.active &&
            collection.trackCode == hierarchy.trackCode &&
            collection.verticalCode == hierarchy.verticalCode &&
            collection.trackCode == candidate.trackCode &&
            collection.sortOrder == candidate.sortOrder;
      }
    }
    return false;
  }

  static List<LearningCollectionProjection> _activeCollections(
    UniversalCatalogueGraph graph,
  ) {
    final activeVerticals = <String>{
      for (final vertical in graph.verticals)
        if (vertical.active) vertical.code,
    };
    final activeGoals = <String>{
      for (final goal in graph.goals)
        if (goal.active && activeVerticals.contains(goal.verticalCode)) goal.code,
    };
    final activeTracks = <String>{
      for (final track in graph.tracks)
        if (track.active &&
            activeVerticals.contains(track.verticalCode) &&
            activeGoals.contains(track.goalCode))
          track.code,
    };
    return <LearningCollectionProjection>[
      for (final collection in graph.collections)
        if (collection.active &&
            activeVerticals.contains(collection.verticalCode) &&
            activeTracks.contains(collection.trackCode))
          collection,
    ];
  }

  static bool _containsContent(
    List<LearningCollectionProjection> collections,
    ContentIdentity identity,
    int revision,
  ) {
    for (final collection in collections) {
      for (final member in collection.members) {
        final ref = member.contentRef;
        if (member.type == LearningCollectionMemberType.content &&
            ref != null &&
            ref.contentCode == identity.code &&
            ref.contentType == identity.type &&
            ref.revision == revision) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _containsPracticeTest(
    List<LearningCollectionProjection> collections,
    String code,
    int revision,
  ) {
    for (final collection in collections) {
      for (final member in collection.members) {
        final ref = member.practiceTestRef;
        if (member.type == LearningCollectionMemberType.practiceTest &&
            ref != null &&
            ref.practiceTestCode == code &&
            ref.revision == revision) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _isCompletedAtRevision(
    ContentMarkerState? marker,
    int revision,
  ) {
    return marker?.completed == true && marker?.lastRevisionSeen == revision;
  }
}

final class _ActiveHierarchy {
  const _ActiveHierarchy({
    required this.verticalCode,
    required this.goalCode,
    required this.trackCode,
  });

  static _ActiveHierarchy? tryCreate(
    UniversalCatalogueGraph graph,
    LearnerSelection selection,
  ) {
    final goalCode = selection.selectedGoalCode;
    final trackCode = selection.selectedTrackCode;
    if (goalCode == null || trackCode == null) return null;

    LearningGoalProjection? goal;
    for (final current in graph.goals) {
      if (current.code == goalCode && current.active) {
        goal = current;
        break;
      }
    }
    if (goal == null) return null;

    var verticalActive = false;
    for (final vertical in graph.verticals) {
      if (vertical.code == goal.verticalCode && vertical.active) {
        verticalActive = true;
        break;
      }
    }
    if (!verticalActive) return null;

    LearningTrackProjection? track;
    for (final current in graph.tracks) {
      if (current.code == trackCode &&
          current.active &&
          current.goalCode == goal.code &&
          current.verticalCode == goal.verticalCode) {
        track = current;
        break;
      }
    }
    if (track == null) return null;

    return _ActiveHierarchy(
      verticalCode: goal.verticalCode,
      goalCode: goal.code,
      trackCode: track.code,
    );
  }

  final String verticalCode;
  final String goalCode;
  final String trackCode;

  ContinueLearningBrowseCandidate get browse => ContinueLearningBrowseCandidate(
    verticalCode: verticalCode,
    trackCode: trackCode,
  );
}
