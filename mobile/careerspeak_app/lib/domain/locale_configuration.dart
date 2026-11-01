import 'application_preferences.dart';

final class SupportedLocaleOption {
  factory SupportedLocaleOption({
    required String code,
    required String label,
  }) {
    final locale = AppTranslationLocale(code);
    final normalizedLabel = label.trim();
    if (normalizedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be blank');
    }
    return SupportedLocaleOption._(locale: locale, label: normalizedLabel);
  }

  const SupportedLocaleOption._({required this.locale, required this.label});

  final AppTranslationLocale locale;
  final String label;
}

final class CountryLocaleConfiguration {
  factory CountryLocaleConfiguration({
    required String countryCode,
    required String defaultLocale,
    required List<SupportedLocaleOption> locales,
  }) {
    final country = countryCode.trim().toUpperCase();
    if (!_countryCodePattern.hasMatch(country)) {
      throw ArgumentError.value(
        countryCode,
        'countryCode',
        'must be an ISO-3166 alpha-2 code',
      );
    }
    if (locales.isEmpty) {
      throw ArgumentError.value(locales, 'locales', 'must not be empty');
    }
    final seen = <String>{};
    for (final option in locales) {
      if (!seen.add(option.locale.code)) {
        throw ArgumentError.value(
          option.locale.code,
          'locales',
          'must not contain duplicate locale codes',
        );
      }
    }
    final normalizedDefault = AppTranslationLocale(defaultLocale);
    if (!seen.contains(normalizedDefault.code)) {
      throw ArgumentError.value(
        defaultLocale,
        'defaultLocale',
        'must be present in locales',
      );
    }
    return CountryLocaleConfiguration._(
      countryCode: country,
      defaultLocale: normalizedDefault,
      locales: List<SupportedLocaleOption>.unmodifiable(locales),
    );
  }

  const CountryLocaleConfiguration._({
    required this.countryCode,
    required this.defaultLocale,
    required this.locales,
  });

  final String countryCode;
  final AppTranslationLocale defaultLocale;
  final List<SupportedLocaleOption> locales;

  bool supports(AppTranslationLocale locale) =>
      locales.any((option) => option.locale.code == locale.code);
}

final _countryCodePattern = RegExp(r'^[A-Z]{2}$');
