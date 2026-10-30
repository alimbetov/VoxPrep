enum AppUiLocale {
  english('en', 'English'),
  russian('ru', 'Русский'),
  kazakh('kk', 'Қазақша');

  const AppUiLocale(this.code, this.label);

  final String code;
  final String label;

  static AppUiLocale? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

enum AppTranslationLocale {
  english('en', 'English'),
  russian('ru', 'Русский'),
  kazakh('kk', 'Қазақша');

  const AppTranslationLocale(this.code, this.label);

  final String code;
  final String label;

  static AppTranslationLocale? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

enum PreferredEnglishAccent {
  us('en-US', 'US English'),
  uk('en-GB', 'UK English'),
  australian('en-AU', 'Australian English');

  const PreferredEnglishAccent(this.code, this.label);

  final String code;
  final String label;

  static PreferredEnglishAccent? fromCode(String? code) {
    if (code == null) return null;
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

enum AppThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemePreference(this.code);

  final String code;

  static AppThemePreference? fromCode(String code) {
    for (final value in values) {
      if (value.code == code) return value;
    }
    return null;
  }
}

final class ApplicationPreferences {
  const ApplicationPreferences({
    required this.uiLocale,
    required this.translationLocale,
    required this.preferredAccent,
    required this.theme,
    required this.focusMode,
    required this.storageQuotaBytes,
  }) : assert(storageQuotaBytes == null || storageQuotaBytes >= 0);

  static const defaults = ApplicationPreferences(
    uiLocale: AppUiLocale.english,
    translationLocale: AppTranslationLocale.russian,
    preferredAccent: PreferredEnglishAccent.us,
    theme: AppThemePreference.system,
    focusMode: false,
    storageQuotaBytes: null,
  );

  final AppUiLocale uiLocale;
  final AppTranslationLocale translationLocale;
  final PreferredEnglishAccent? preferredAccent;
  final AppThemePreference theme;
  final bool focusMode;
  final int? storageQuotaBytes;

  ApplicationPreferences copyWith({
    AppUiLocale? uiLocale,
    AppTranslationLocale? translationLocale,
    PreferredEnglishAccent? preferredAccent,
    bool clearPreferredAccent = false,
    AppThemePreference? theme,
    bool? focusMode,
    int? storageQuotaBytes,
    bool clearStorageQuota = false,
  }) {
    return ApplicationPreferences(
      uiLocale: uiLocale ?? this.uiLocale,
      translationLocale: translationLocale ?? this.translationLocale,
      preferredAccent: clearPreferredAccent
          ? null
          : preferredAccent ?? this.preferredAccent,
      theme: theme ?? this.theme,
      focusMode: focusMode ?? this.focusMode,
      storageQuotaBytes: clearStorageQuota
          ? null
          : storageQuotaBytes ?? this.storageQuotaBytes,
    );
  }
}
