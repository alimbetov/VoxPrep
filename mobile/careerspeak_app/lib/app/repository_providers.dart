import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/content_repository.dart';
import '../application/ports/practice_test_repository.dart';
import '../application/query/content_query.dart';
import '../application/query/page.dart';
import '../application/query/practice_test_query.dart';
import '../data/local/drift_content_repository.dart';
import '../data/production/unavailable_practice_test_repository.dart';
import '../domain/content_identity.dart';
import '../domain/content_item.dart';
import '../domain/practice_test.dart';
import 'learner_state_providers.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return DriftContentRepository(ref.watch(careerSpeakDatabaseProvider));
});

final practiceTestRepositoryProvider = Provider<PracticeTestRepository>((ref) {
  return const UnavailablePracticeTestRepository();
});

final contentPageProvider = StreamProvider<Page<ContentItem>>((ref) {
  final repository = ref.watch(contentRepositoryProvider);
  return repository
      .watchContent(const ContentQuery())
      .map((result) => result.getOrThrow());
});

final contentByIdentityProvider =
    FutureProvider.family<ContentItem?, ContentIdentity>((ref, identity) async {
      final repository = ref.watch(contentRepositoryProvider);
      return (await repository.getByIdentity(identity)).getOrThrow();
    });

final practiceTestPageProvider = StreamProvider<Page<PracticeTestSummary>>((
  ref,
) {
  final repository = ref.watch(practiceTestRepositoryProvider);
  return repository
      .watchTests(const PracticeTestQuery())
      .map((result) => result.getOrThrow());
});

final practiceTestByCodeProvider = FutureProvider.family<PracticeTest?, String>(
  (ref, code) async {
    final repository = ref.watch(practiceTestRepositoryProvider);
    return (await repository.getByCode(code)).getOrThrow();
  },
);
