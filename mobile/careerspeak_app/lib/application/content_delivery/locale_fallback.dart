import '../../domain/application_preferences.dart';

enum LocaleFallbackKind { exact, language, canonicalEnglish }

final class LocaleFallbackCandidate {
  const LocaleFallbackCandidate({required this.locale, required this.kind});

  final String locale;
  final LocaleFallbackKind kind;
}

final class LocaleFallbackPlan {
  factory LocaleFallbackPlan(String requestedLocale) {
    final requested = LocaleCode.canonicalize(requestedLocale);
    final language = requested.split('-').first;
    final candidates = <LocaleFallbackCandidate>[];

    if (requested != canonicalEnglishLocale) {
      candidates.add(
        LocaleFallbackCandidate(
          locale: requested,
          kind: LocaleFallbackKind.exact,
        ),
      );
    }

    if (language != requested && language != canonicalEnglishLocale) {
      candidates.add(
        LocaleFallbackCandidate(
          locale: language,
          kind: LocaleFallbackKind.language,
        ),
      );
    }

    return LocaleFallbackPlan._(
      requestedLocale: requested,
      localizedCandidates: List<LocaleFallbackCandidate>.unmodifiable(
        candidates,
      ),
    );
  }

  const LocaleFallbackPlan._({
    required this.requestedLocale,
    required this.localizedCandidates,
  });

  static const canonicalEnglishLocale = 'en';

  final String requestedLocale;
  final List<LocaleFallbackCandidate> localizedCandidates;
}
