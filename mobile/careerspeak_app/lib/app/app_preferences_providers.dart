import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/ports/app_preferences_repository.dart';
import '../application/result/result.dart';
import '../data/local/drift_app_preferences_repository.dart';
import '../domain/application_preferences.dart';
import 'learner_state_providers.dart';

final appPreferencesRepositoryProvider = Provider<AppPreferencesRepository>((
  ref,
) {
  return DriftAppPreferencesRepository(ref.watch(careerSpeakDatabaseProvider));
});

final applicationPreferencesProvider = StreamProvider<ApplicationPreferences>((
  ref,
) {
  return ref
      .watch(appPreferencesRepositoryProvider)
      .watchPreferences()
      .map((result) => result.getOrThrow());
});

final appPreferencesControllerProvider = Provider<AppPreferencesController>((
  ref,
) {
  return AppPreferencesController(ref.watch(appPreferencesRepositoryProvider));
});

final translationLocaleProvider = Provider<AsyncValue<String>>((ref) {
  return ref
      .watch(applicationPreferencesProvider)
      .whenData((preferences) => preferences.translationLocale.code);
});

final class AppPreferencesController {
  const AppPreferencesController(this._repository);

  final AppPreferencesRepository _repository;

  Future<Result<void>> setUiLocale(AppUiLocale locale) {
    return _repository.setUiLocale(locale);
  }

  Future<Result<void>> setTranslationLocale(AppTranslationLocale locale) {
    return _repository.setTranslationLocale(locale);
  }

  Future<Result<void>> setPreferredAccent(PreferredEnglishAccent? accent) {
    return _repository.setPreferredAccent(accent);
  }

  Future<Result<void>> setTheme(AppThemePreference theme) {
    return _repository.setTheme(theme);
  }

  Future<Result<void>> setFocusMode(bool enabled) {
    return _repository.setFocusMode(enabled);
  }

  Future<Result<void>> setStorageQuotaBytes(int? bytes) {
    return _repository.setStorageQuotaBytes(bytes);
  }
}
