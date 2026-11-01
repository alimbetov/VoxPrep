import 'package:careerspeak_app/app/learner_selection_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/data/local/drift_learner_selection_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_database_factory.dart';

void main() {
  test('production composition uses Drift learner selection repository', () {
    final database = createTestDatabase();
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [careerSpeakDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(learnerSelectionRepositoryProvider),
      isA<DriftLearnerSelectionRepository>(),
    );
  });
}
