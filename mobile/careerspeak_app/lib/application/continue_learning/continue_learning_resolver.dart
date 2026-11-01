import '../../domain/content_identity.dart';
import '../../domain/last_opened_content.dart';
import '../../domain/practice_test_attempt.dart';

sealed class ContinueLearningMemberTarget {
  const ContinueLearningMemberTarget();
}

final class ContinueLearningContentTarget extends ContinueLearningMemberTarget {
  const ContinueLearningContentTarget({
    required this.identity,
    required this.revision,
  });

  final ContentIdentity identity;
  final int revision;
}

final class ContinueLearningPracticeTestTarget
    extends ContinueLearningMemberTarget {
  const ContinueLearningPracticeTestTarget({
    required this.practiceTestCode,
    required this.revision,
  });

  final String practiceTestCode;
  final int revision;
}

final class ContinueLearningMemberCandidate {
  const ContinueLearningMemberCandidate({
    required this.collectionCode,
    required this.collectionSortOrder,
    required this.position,
    required this.target,
  });

  final String collectionCode;
  final int collectionSortOrder;
  final int position;
  final ContinueLearningMemberTarget target;
}

final class ContinueLearningCollectionCandidate {
  const ContinueLearningCollectionCandidate({
    required this.collectionCode,
    required this.trackCode,
    required this.sortOrder,
  });

  final String collectionCode;
  final String trackCode;
  final int sortOrder;
}

final class ContinueLearningBrowseCandidate {
  const ContinueLearningBrowseCandidate({
    required this.verticalCode,
    this.trackCode,
  });

  final String verticalCode;
  final String? trackCode;
}

final class ContinueLearningInput {
  const ContinueLearningInput({
    this.activePracticeTestAttempt,
    this.unfinishedLastOpenedContent,
    this.incompleteMembers = const <ContinueLearningMemberCandidate>[],
    this.nextCollections = const <ContinueLearningCollectionCandidate>[],
    this.browse,
  });

  final PracticeTestAttempt? activePracticeTestAttempt;
  final LastOpenedContent? unfinishedLastOpenedContent;
  final List<ContinueLearningMemberCandidate> incompleteMembers;
  final List<ContinueLearningCollectionCandidate> nextCollections;
  final ContinueLearningBrowseCandidate? browse;
}

sealed class ContinueLearningDecision {
  const ContinueLearningDecision();
}

final class ResumePracticeTestDecision extends ContinueLearningDecision {
  const ResumePracticeTestDecision(this.attempt);

  final PracticeTestAttempt attempt;
}

final class ResumeContentDecision extends ContinueLearningDecision {
  const ResumeContentDecision(this.content);

  final LastOpenedContent content;
}

final class OpenMemberDecision extends ContinueLearningDecision {
  const OpenMemberDecision(this.candidate);

  final ContinueLearningMemberCandidate candidate;
}

final class OpenCollectionDecision extends ContinueLearningDecision {
  const OpenCollectionDecision(this.collection);

  final ContinueLearningCollectionCandidate collection;
}

final class BrowseTrackDecision extends ContinueLearningDecision {
  const BrowseTrackDecision({
    required this.verticalCode,
    required this.trackCode,
  });

  final String verticalCode;
  final String trackCode;
}

final class BrowseVerticalDecision extends ContinueLearningDecision {
  const BrowseVerticalDecision(this.verticalCode);

  final String verticalCode;
}

final class ChooseDirectionDecision extends ContinueLearningDecision {
  const ChooseDirectionDecision();
}

final class ContinueLearningResolver {
  const ContinueLearningResolver();

  ContinueLearningDecision resolve(ContinueLearningInput input) {
    final activeAttempt = input.activePracticeTestAttempt;
    if (activeAttempt != null) {
      return ResumePracticeTestDecision(activeAttempt);
    }

    final lastOpened = input.unfinishedLastOpenedContent;
    if (lastOpened != null) {
      return ResumeContentDecision(lastOpened);
    }

    if (input.incompleteMembers.isNotEmpty) {
      final members = input.incompleteMembers.toList(growable: false)
        ..sort(_compareMembers);
      return OpenMemberDecision(members.first);
    }

    if (input.nextCollections.isNotEmpty) {
      final collections = input.nextCollections.toList(growable: false)
        ..sort(_compareCollections);
      return OpenCollectionDecision(collections.first);
    }

    final browse = input.browse;
    if (browse != null) {
      final trackCode = browse.trackCode;
      if (trackCode != null && trackCode.trim().isNotEmpty) {
        return BrowseTrackDecision(
          verticalCode: browse.verticalCode,
          trackCode: trackCode,
        );
      }
      return BrowseVerticalDecision(browse.verticalCode);
    }

    return const ChooseDirectionDecision();
  }

  static int _compareMembers(
    ContinueLearningMemberCandidate left,
    ContinueLearningMemberCandidate right,
  ) {
    var result = left.collectionSortOrder.compareTo(right.collectionSortOrder);
    if (result != 0) return result;
    result = left.collectionCode.compareTo(right.collectionCode);
    if (result != 0) return result;
    result = left.position.compareTo(right.position);
    if (result != 0) return result;
    return _compareTargets(left.target, right.target);
  }

  static int _compareCollections(
    ContinueLearningCollectionCandidate left,
    ContinueLearningCollectionCandidate right,
  ) {
    var result = left.sortOrder.compareTo(right.sortOrder);
    if (result != 0) return result;
    result = left.collectionCode.compareTo(right.collectionCode);
    if (result != 0) return result;
    return left.trackCode.compareTo(right.trackCode);
  }

  static int _compareTargets(
    ContinueLearningMemberTarget left,
    ContinueLearningMemberTarget right,
  ) {
    if (left is ContinueLearningContentTarget &&
        right is ContinueLearningPracticeTestTarget) {
      return -1;
    }
    if (left is ContinueLearningPracticeTestTarget &&
        right is ContinueLearningContentTarget) {
      return 1;
    }
    if (left is ContinueLearningContentTarget &&
        right is ContinueLearningContentTarget) {
      var result = left.identity.type.name.compareTo(right.identity.type.name);
      if (result != 0) return result;
      result = left.identity.code.compareTo(right.identity.code);
      if (result != 0) return result;
      return left.revision.compareTo(right.revision);
    }
    if (left is ContinueLearningPracticeTestTarget &&
        right is ContinueLearningPracticeTestTarget) {
      var result = left.practiceTestCode.compareTo(right.practiceTestCode);
      if (result != 0) return result;
      return left.revision.compareTo(right.revision);
    }
    return 0;
  }
}
