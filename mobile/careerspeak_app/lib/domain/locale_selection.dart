import 'application_preferences.dart';

final class CountryLocaleProfile {
  const CountryLocaleProfile({
    required this.countryCode,
    required this.label,
    required this.defaultLocale,
    required this.supportedLocales,
  });

  final String countryCode;
  final String label;
  final AppTranslationLocale defaultLocale;
  final List<AppTranslationLocale> supportedLocales;

  bool supports(AppTranslationLocale locale) => supportedLocales.any(
    (candidate) => candidate.code == locale.code,
  );
}

/// Release fallback used before the Backend supported-locale catalogue is
/// available locally. Backend catalogue data remains authoritative and may
/// replace this list without changing persisted learner preferences.
const countryLocaleProfiles = <CountryLocaleProfile>[
  CountryLocaleProfile(
    countryCode: 'KZ',
    label: 'Kazakhstan',
    defaultLocale: AppTranslationLocale.kazakh,
    supportedLocales: <AppTranslationLocale>[
      AppTranslationLocale.kazakh,
      AppTranslationLocale.russian,
      AppTranslationLocale.english,
    ],
  ),
  CountryLocaleProfile(
    countryCode: 'UZ',
    label: 'Uzbekistan',
    defaultLocale: AppTranslationLocale.uzbek,
    supportedLocales: <AppTranslationLocale>[
      AppTranslationLocale.uzbek,
      AppTranslationLocale.russian,
      AppTranslationLocale.english,
    ],
  ),
  CountryLocaleProfile(
    countryCode: 'KG',
    label: 'Kyrgyzstan',
    defaultLocale: AppTranslationLocale.kyrgyz,
    supportedLocales: <AppTranslationLocale>[
      AppTranslationLocale.kyrgyz,
      AppTranslationLocale.russian,
      AppTranslationLocale.english,
    ],
  ),
  CountryLocaleProfile(
    countryCode: 'TR',
    label: 'Türkiye',
    defaultLocale: AppTranslationLocale.turkish,
    supportedLocales: <AppTranslationLocale>[
      AppTranslationLocale.turkish,
      AppTranslationLocale.english,
    ],
  ),
  CountryLocaleProfile(
    countryCode: 'OTHER',
    label: 'Other',
    defaultLocale: AppTranslationLocale.english,
    supportedLocales: AppTranslationLocale.values,
  ),
];

CountryLocaleProfile? countryLocaleProfileByCode(String? code) {
  if (code == null) return null;
  for (final profile in countryLocaleProfiles) {
    if (profile.countryCode == code) return profile;
  }
  return null;
}
