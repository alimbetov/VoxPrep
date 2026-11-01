import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/content_delivery/product_catalog.dart';
import '../application/continue_learning/continue_learning_current_revalidator.dart';
import '../application/continue_learning/continue_learning_resolver.dart';
import '../domain/content_identity.dart';
import 'catalogue_payload_providers.dart';
import 'content_locations.dart';
import 'learner_selection_providers.dart';
import 'learner_state_providers.dart';
import 'repository_providers.dart';

final class ContinueLearningHomeTarget {
  const ContinueLearningHomeTarget({
    required this.decision,
    required this.location,
    required this.title,
    required this.subtitle,
  });

  final ContinueLearningDecision decision;
  final String location;
  final String title;
  final String subtitle;
}

final continueLearningResolverProvider = Provider<ContinueLearningResolver>(
  (ref) => const ContinueLearningResolver(),
);

final continueLearningCurrentRevalidatorProvider =
    Provider<ContinueLearningCurrentRevalidator>(
      (ref) => const ContinueLearningCurrentRevalidator(),
    );

final continueLearningHomeTargetProvider =
    FutureProvider<ContinueLearningHomeTarget>((ref) async {
      final selection = await ref.watch(learnerSelectionProvider.future);
      final snapshot = await ref.watch(
        currentUniversalCatalogueProvider.future,
      );
      final markers = await ref.watch(contentMarkersProvider.future);
      final attemptRepository = ref.watch(
        practiceTestAttemptRepositoryProvider,
      );
      final attempt = (await attemptRepository.getActiveAttempt()).getOrThrow();
      final completedPracticeTests =
          (await attemptRepository.getCompletedPracticeTests()).getOrThrow();
      final lastOpened =
          (await ref
                  .watch(lastOpenedContentRepositoryProvider)
                  .getLastOpenedContent())
              .getOrThrow();

      if (snapshot == null) {
        return _chooseDirectionTarget();
      }

      final graph = snapshot.graph;
      final proposedMembers = <ContinueLearningMemberCandidate>[];
      final proposedCollections = <ContinueLearningCollectionCandidate>[];

      for (final collection in graph.collections) {
        proposedCollections.add(
          ContinueLearningCollectionCandidate(
            collectionCode: collection.code,
            trackCode: collection.trackCode,
            sortOrder: collection.sortOrder,
          ),
        );
        for (final member in collection.members) {
          final target = switch (member.type) {
            LearningCollectionMemberType.content =>
              ContinueLearningContentTarget(
                identity: ContentIdentity(
                  code: member.contentRef!.contentCode,
                  type: member.contentRef!.contentType,
                ),
                revision: member.contentRef!.revision,
              ),
            LearningCollectionMemberType.practiceTest =>
              ContinueLearningPracticeTestTarget(
                practiceTestCode: member.practiceTestRef!.practiceTestCode,
                revision: member.practiceTestRef!.revision,
              ),
          };
          proposedMembers.add(
            ContinueLearningMemberCandidate(
              collectionCode: collection.code,
              collectionSortOrder: collection.sortOrder,
              position: member.position,
              target: target,
            ),
          );
        }
      }

      final current = ref
          .watch(continueLearningCurrentRevalidatorProvider)
          .revalidate(
            proposed: ContinueLearningInput(
              activePracticeTestAttempt: attempt,
              unfinishedLastOpenedContent: lastOpened,
              incompleteMembers: proposedMembers,
              nextCollections: proposedCollections,
            ),
            graph: graph,
            selection: selection,
            markers: markers,
            completedPracticeTests: completedPracticeTests,
          );
      final decision = ref
          .watch(continueLearningResolverProvider)
          .resolve(current);

      return _homeTarget(
        decision,
        selectedGoalCode: selection.selectedGoalCode,
        validatedBrowse: current.browse,
      );
    });

ContinueLearningHomeTarget _homeTarget(
  ContinueLearningDecision decision, {
  required String? selectedGoalCode,
  required ContinueLearningBrowseCandidate? validatedBrowse,
}) {
  if (decision is ResumePracticeTestDecision) {
    return ContinueLearningHomeTarget(
      decision: decision,
      location:
          '/tests/${Uri.encodeComponent(decision.attempt.practiceTestCode)}',
      title: 'Resume practice test',
      subtitle: decision.attempt.practiceTestCode,
    );
  }
  if (decision is ResumeContentDecision) {
    return ContinueLearningHomeTarget(
      decision: decision,
      location: contentDetailLocation(decision.content.identity),
      title: 'Continue where you left off',
      subtitle: decision.content.identity.code,
    );
  }
  if (decision is OpenMemberDecision) {
    final target = decision.candidate.target;
    if (target is ContinueLearningContentTarget) {
      return ContinueLearningHomeTarget(
        decision: decision,
        location: contentDetailLocation(target.identity),
        title: 'Continue next item',
        subtitle: target.identity.code,
      );
    }
    final test = target as ContinueLearningPracticeTestTarget;
    return ContinueLearningHomeTarget(
      decision: decision,
      location: '/tests/${Uri.encodeComponent(test.practiceTestCode)}',
      title: 'Continue next practice test',
      subtitle: test.practiceTestCode,
    );
  }
  if (decision is OpenCollectionDecision) {
    final goalCode = selectedGoalCode;
    final browse = validatedBrowse;
    if (goalCode == null ||
        browse == null ||
        browse.trackCode != decision.collection.trackCode) {
      return ContinueLearningHomeTarget(
        decision: decision,
        location: '/catalogue',
        title: 'Browse learning collections',
        subtitle: decision.collection.collectionCode,
      );
    }
    return ContinueLearningHomeTarget(
      decision: decision,
      location:
          '/catalogue/vertical/${Uri.encodeComponent(browse.verticalCode)}/goal/${Uri.encodeComponent(goalCode)}/track/${Uri.encodeComponent(decision.collection.trackCode)}/collection/${Uri.encodeComponent(decision.collection.collectionCode)}',
      title: 'Open next collection',
      subtitle: decision.collection.collectionCode,
    );
  }
  if (decision is BrowseTrackDecision) {
    final goalCode = selectedGoalCode;
    if (goalCode == null) {
      return ContinueLearningHomeTarget(
        decision: decision,
        location:
            '/catalogue/vertical/${Uri.encodeComponent(decision.verticalCode)}',
        title: 'Browse your learning direction',
        subtitle: decision.verticalCode,
      );
    }
    return ContinueLearningHomeTarget(
      decision: decision,
      location:
          '/catalogue/vertical/${Uri.encodeComponent(decision.verticalCode)}/goal/${Uri.encodeComponent(goalCode)}/track/${Uri.encodeComponent(decision.trackCode)}',
      title: 'Browse current track',
      subtitle: decision.trackCode,
    );
  }
  if (decision is BrowseVerticalDecision) {
    return ContinueLearningHomeTarget(
      decision: decision,
      location:
          '/catalogue/vertical/${Uri.encodeComponent(decision.verticalCode)}',
      title: 'Browse your learning direction',
      subtitle: decision.verticalCode,
    );
  }
  return _chooseDirectionTarget();
}

ContinueLearningHomeTarget _chooseDirectionTarget() {
  return const ContinueLearningHomeTarget(
    decision: ChooseDirectionDecision(),
    location: '/learn/direction',
    title: 'Choose learning direction',
    subtitle: 'Select a direction before continuing your learning path.',
  );
}
