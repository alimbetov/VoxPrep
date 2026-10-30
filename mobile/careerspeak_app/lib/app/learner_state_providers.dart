import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/learner_state_repository.dart';
import '../data/local/database/careerspeak_database.dart';
import '../data/local/drift_learner_state_repository.dart';
import '../domain/content_identity.dart';
import '../domain/content_marker_state.dart';

final careerSpeakDatabaseProvider = Provider<CareerSpeakDatabase>((ref) {
  final database = CareerSpeakDatabase();
  ref.onDispose(database.close);
  return database;
});

final learnerStateRepositoryProvider = Provider<LearnerStateRepository>((ref) {
  return DriftLearnerStateRepository(ref.watch(careerSpeakDatabaseProvider));
});

final contentMarkersProvider =
    StreamProvider<Map<ContentIdentity, ContentMarkerState>>((ref) {
      final repository = ref.watch(learnerStateRepositoryProvider);
      return repository.watchMarkers().map((result) => result.getOrThrow());
    });
