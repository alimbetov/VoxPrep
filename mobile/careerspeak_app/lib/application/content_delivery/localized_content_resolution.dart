import '../../domain/content_identity.dart';
import 'locale_fallback.dart';

final class ResolvedLocalizedContent {
  const ResolvedLocalizedContent({
    required this.identity,
    required this.contentRevision,
    required this.requestedLocale,
    required this.resolvedLocale,
    required this.fallbackKind,
    required this.matchedLocalizationLocales,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.translation,
    required this.hint,
    required this.explanation,
  });

  final ContentIdentity identity;
  final int contentRevision;
  final String requestedLocale;

  /// Highest-priority locale that contributed localized copy.
  ///
  /// `en` means the projection fell back to canonical English only.
  final String resolvedLocale;
  final LocaleFallbackKind fallbackKind;

  /// Localized layers that contributed to the projection, ordered from most
  /// specific to least specific. Canonical English is intentionally omitted.
  final List<String> matchedLocalizationLocales;

  final String title;
  final String subtitle;
  final String description;
  final String? translation;
  final String? hint;
  final String? explanation;

  bool get usesCanonicalEnglishOnly => matchedLocalizationLocales.isEmpty;
}
