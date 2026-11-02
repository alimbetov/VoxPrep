import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/access/access_snapshot.dart';
import '../application/content_delivery/product_catalog.dart';
import '../application/ports/access_snapshot_repository.dart';
import '../data/local/drift_access_snapshot_repository.dart';
import 'learner_state_providers.dart';

final accessSnapshotRepositoryProvider = Provider<AccessSnapshotRepository>((
  ref,
) {
  return DriftAccessSnapshotRepository(ref.watch(careerSpeakDatabaseProvider));
});

final learnerAccessSnapshotProvider = FutureProvider<AccessSnapshot?>((ref) async {
  final repository = ref.watch(accessSnapshotRepositoryProvider);
  return (await repository.read()).getOrThrow();
});

final learnerAccessLevelProvider = Provider<AccessLevel>((ref) {
  final snapshot = ref.watch(learnerAccessSnapshotProvider);
  return snapshot.when(
    data: (value) => value?.accessLevel ?? AccessSnapshot.defaultAccessLevel,
    loading: () => AccessSnapshot.defaultAccessLevel,
    error: (error, stackTrace) => AccessSnapshot.defaultAccessLevel,
  );
});
