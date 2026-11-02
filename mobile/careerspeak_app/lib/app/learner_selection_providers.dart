import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/learner_selection_repository.dart';
import '../application/services/learner_selection_normalizer.dart';
import '../application/services/learner_selection_service.dart';
import '../data/local/drift_learner_selection_repository.dart';
import '../domain/learner_selection.dart';
import 'catalogue_payload_providers.dart';
import 'learner_state_providers.dart';

typedef LearnerLearningContext = ({
  String verticalCode,
  String verticalTitle,
  String goalCode,
  String goalTitle,
});

final learnerSelectionRepositoryProvider = Provider<LearnerSelectionRepository>(
  (ref) {
    return DriftLearnerSelectionRepository(
      ref.watch(careerSpeakDatabaseProvider),
    );
  },
);

final learnerSelectionNormalizerProvider = Provider<LearnerSelectionNormalizer>(
  (ref) => const LearnerSelectionNormalizer(),
);

final learnerSelectionServiceProvider = Provider<LearnerSelectionService>((
  ref,
) {
  return LearnerSelectionService(
    repository: ref.watch(learnerSelectionRepositoryProvider),
    normalizer: ref.watch(learnerSelectionNormalizerProvider),
  );
});

final learnerSelectionProvider = StreamProvider<LearnerSelection>((ref) {
  final repository = ref.watch(learnerSelectionRepositoryProvider);
  return repository.watchSelection().map((result) => result.getOrThrow());
});

final learnerLearningContextProvider =
    Provider<AsyncValue<LearnerLearningContext?>>((ref) {
      final selection = ref.watch(learnerSelectionProvider);
      final catalogue = ref.watch(currentUniversalCatalogueProvider);

      return selection.when(
        loading: () => const AsyncLoading<LearnerLearningContext?>(),
        error: (error, stack) =>
            AsyncError<LearnerLearningContext?>(error, stack),
        data: (current) => catalogue.when(
          loading: () => const AsyncLoading<LearnerLearningContext?>(),
          error: (error, stack) =>
              AsyncError<LearnerLearningContext?>(error, stack),
          data: (snapshot) {
            final goalCode = current.selectedGoalCode;
            if (goalCode == null || snapshot == null) {
              return const AsyncData<LearnerLearningContext?>(null);
            }

            final graph = snapshot.graph;
            for (final goal in graph.goals) {
              if (goal.code != goalCode || !goal.active) continue;
              for (final vertical in graph.verticals) {
                if (vertical.code == goal.verticalCode && vertical.active) {
                  return AsyncData<LearnerLearningContext?>((
                    verticalCode: vertical.code,
                    verticalTitle: vertical.title,
                    goalCode: goal.code,
                    goalTitle: goal.title,
                  ));
                }
              }
            }
            return const AsyncData<LearnerLearningContext?>(null);
          },
        ),
      );
    });
