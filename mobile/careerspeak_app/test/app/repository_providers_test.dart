import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_localized_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_database_factory.dart';

void main() {
  test('production composition uses Drift content repository', () {
    final database = createTestDatabase();
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [careerSpeakDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(contentRepositoryProvider),
      isA<DriftContentRepository>(),
    );
  });

  test('production composition uses Drift localized content repository', () {
    final database = createTestDatabase();
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [careerSpeakDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(localizedContentRepositoryProvider),
      isA<DriftLocalizedContentRepository>(),
    );
  });

  test('production composition uses CURRENT snapshot assessment repository', () {
    final database = createTestDatabase();
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [careerSpeakDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(practiceTestRepositoryProvider),
      isA<DriftPracticeTestRepository>(),
    );
  });
}
