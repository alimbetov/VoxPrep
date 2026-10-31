sealed class LocaleCode {
  const LocaleCode._(this.code);

  final String code;

  String get languageCode => code.split('-').first.toLowerCase();

  bool get isRtl => const <String>{'ar', 'ur', 'fa', 'he'}.contains(languageCode);

  String get label => switch (code) {
    'en' => 'English',
    'ru' => 'Русский',
    'kk' => 'Қазақша',
    'uz' => 'O‘zbekcha',
    'ky' => 'Кыргызча',
    'tr' => 'Türkçe',
    'uk' => 'Українська',
    'es' => 'Español',
    'pt-BR' => 'Português (Brasil)',
    'fr' => 'Français',
    'de' => 'Deutsch',
    'ar' => 'العربية',
    'ur' => 'اردو',
    'hi' => 'हिन्दी',
    'bn' => 'বাংলা',
    'id' => 'Bahasa Indonesia',
    'vi' => 'Tiếng Việt',
    _ => code,
  };

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is LocaleCode &&
      other.code == code;

  @override
  int get hashCode => Object.hash(runtimeType, code);

  @override
  String toString() => code;

  static String canonicalize(String input) {
    final trimmed = input.trim();
    if (!_localePattern.hasMatch(trimmed)) {
      throw FormatException('Invalid BCP-47 locale code: $input');
    }

    final parts = trimmed.split('-');
    final normalized = <String>[parts.first.toLowerCase()];
    for (final part in parts.skip(1)) {
      if (part.length == 2 && _alpha.hasMatch(part)) {
        normalized.add(part.toUpperCase());
      } else if (part.length == 4 && _alpha.hasMatch(part)) {
        normalized.add(
          '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
        );
      } else {
        normalized.add(part.toLowerCase());
      }
    }
    return normalized.join('-');
  }
}

final class AppUiLocale extends LocaleCode {
  const AppUiLocale._(String code) : super._(code);

  factory AppUiLocale(String code) =>
      AppUiLocale._(LocaleCode.canonicalize(code));

  static const english = AppUiLocale._('en');
  static const russian = AppUiLocale._('ru');
  static const kazakh = AppUiLocale._('kk');
  static const uzbek = AppUiLocale._('uz');
  static const turkish = AppUiLocale._('tr');
  static const arabic = AppUiLocale._('ar');

  /// Release-qualified UI locales. This list is intentionally not the storage
  /// validation boundary; any valid BCP-47 value can be represented.
  static const values = <AppUiLocale>[
    english,
    russian,
    kazakh,
    uzbek,
    turkish,
    arabic,
  ];

  static AppUiLocale? fromCode(String code) {
    try {
      return AppUiLocale(code);
    } on FormatException {
      return null;
    }
  }
}

final class AppTranslationLocale extends LocaleCode {
  const AppTranslationLocale._(String code) : super._(code);

  factory AppTranslationLocale(String code) =>
      AppTranslationLocale._(LocaleCode.canonicalize(code));

  static const english = AppTranslationLocale._('en');
  static const russian = AppTranslationLocale._('ru');
  static const kazakh = AppTranslationLocale._('kk');
  static const uzbek = AppTranslationLocale._('uz');
  static const kyrgyz = AppTranslationLocale._('ky');
  static const turkish = AppTranslationLocale._('tr');
  static const ukrainian = AppTranslationLocale._('uk');
  static const spanish = AppTranslationLocale._('es');
  static const brazilianPortuguese = AppTranslationLocale._('pt-BR');
  static const french = AppTranslationLocale._('fr');
  static const german = AppTranslationLocale._('de');
  static const arabic = AppTranslationLocale._('ar');
  static const urdu = AppTranslationLocale._('ur');
  static const hindi = AppTranslationLocale._('hi');
  static const bengali = AppTranslationLocale._('bn');
  static const indonesian = AppTranslationLocale._('id');
  static const vietnamese = AppTranslationLocale._('vi');

  /// Initial launch catalog. Backend SupportedLocale is authoritative at
  /// runtime and can add future valid BCP-47 locales without a model release.
  static const values = <AppTranslationLocale>[
    english,
    russian,
    kazakh,
    uzbek,
    kyrgyz,
    turkish,
    ukrainian,
    spanish,
    brazilianPortuguese,
    french,
    german,
    arabic,
    urdu,
    hindi,
    bengali,
    indonesian,
    vietnamese,
  ];

  static AppTranslationLocale? fromCode(String code) {
    try {
      return AppTranslationLocale(code);
    } on FormatException {
      return null;
    }
  }
}

final RegExp _localePattern = RegExp(
  r'^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$',
);
final RegExp _alpha = RegExp(r'^[A-Za-z]+$');

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
