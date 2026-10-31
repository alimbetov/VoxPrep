import '../../domain/application_preferences.dart';
import '../result/result.dart';

abstract interface class AppPreferencesRepository {
  Stream<Result<ApplicationPreferences>> watchPreferences();

  Future<Result<ApplicationPreferences>> getPreferences();

  Future<Result<void>> setUiLocale(AppUiLocale locale);

  Future<Result<void>> setTranslationLocale(AppTranslationLocale locale);

  Future<Result<void>> setPreferredAccent(PreferredEnglishAccent? accent);

  Future<Result<void>> setTheme(AppThemePreference theme);

  Future<Result<void>> setFocusMode(bool enabled);

  Future<Result<void>> setStorageQuotaBytes(int? bytes);
}
