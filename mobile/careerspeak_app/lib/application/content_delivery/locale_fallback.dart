import '../../domain/application_preferences.dart';

enum LocaleFallbackKind { exact, configured, canonicalEnglish }

final class LocaleFallbackCandidate {
  const LocaleFallbackCandidate({required this.locale, required this.kind});

  final String locale;
  final LocaleFallbackKind kind;
}

/// Deterministic application of a Backend-owned fallback chain.
///
/// Flutter validates and applies the supplied order. It never derives a base
/// language from the requested BCP-47 tag. Canonical English remains the final
/// product fallback and therefore is not represented as a locale-pack fetch.
final class LocaleFallbackPlan {
  factory LocaleFallbackPlan({
    required String requestedLocale,
    Iterable<String> configuredFallbackLocales = const <String>[],
  }) {
    final requested = LocaleCode.canonicalize(requestedLocale);
    final configured = configuredFallbackLocales
        .map(LocaleCode.canonicalize)
        .toList(growable: false);

    final seen = <String>{requested};
    for (final locale in configured) {
      if (!seen.add(locale)) {
        throw FormatException(
          'Configured fallback chain contains duplicate locale: $locale',
        );
      }
    }
    final englishIndex = configured.indexOf(canonicalEnglishLocale);
    if (englishIndex >= 0 && englishIndex != configured.length - 1) {
      throw const FormatException(
        'Canonical English must be the terminal configured fallback.',
      );
    }

    final candidates = <LocaleFallbackCandidate>[];
    if (requested != canonicalEnglishLocale) {
      candidates.add(
        LocaleFallbackCandidate(
          locale: requested,
          kind: LocaleFallbackKind.exact,
        ),
      );
    }
    for (final locale in configured) {
      if (locale == canonicalEnglishLocale) break;
      candidates.add(
        LocaleFallbackCandidate(
          locale: locale,
          kind: LocaleFallbackKind.configured,
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
