import 'dart:async';

import 'package:careerspeak_app/app/app_preferences_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/data/local/drift_app_preferences_repository.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_database_factory.dart';

void main() {
  test('composition root selects Drift preferences adapter', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [careerSpeakDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final repository = container.read(appPreferencesRepositoryProvider);
    expect(repository, isA<DriftAppPreferencesRepository>());

    final preferences = (await repository.getPreferences()).getOrThrow();
    expect(preferences.uiLocale, ApplicationPreferences.defaults.uiLocale);
    expect(
      preferences.translationLocale,
      ApplicationPreferences.defaults.translationLocale,
    );
    expect(
      preferences.preferredAccent,
      ApplicationPreferences.defaults.preferredAccent,
    );
    expect(preferences.theme, ApplicationPreferences.defaults.theme);
  });

  test('translation locale provider exposes persisted sync locale', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final container = ProviderContainer(
      overrides: [careerSpeakDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final kazakhObserved = Completer<void>();
    final subscription = container.listen<AsyncValue<String>>(
      translationLocaleProvider,
      (_, next) {
        if (next.asData?.value == AppTranslationLocale.kazakh.code &&
            !kazakhObserved.isCompleted) {
          kazakhObserved.complete();
        }
      },
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    await container
        .read(appPreferencesControllerProvider)
        .setTranslationLocale(AppTranslationLocale.kazakh);
    await kazakhObserved.future.timeout(const Duration(seconds: 2));

    expect(
      container.read(translationLocaleProvider).asData?.value,
      AppTranslationLocale.kazakh.code,
    );
  });
}
