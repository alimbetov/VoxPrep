import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/learner_selection_repository.dart';
import '../application/services/learner_selection_normalizer.dart';
import '../data/local/drift_learner_selection_repository.dart';
import '../domain/learner_selection.dart';
import 'learner_state_providers.dart';

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

final learnerSelectionProvider = StreamProvider<LearnerSelection>((ref) {
  final repository = ref.watch(learnerSelectionRepositoryProvider);
  return repository.watchSelection().map((result) => result.getOrThrow());
});
