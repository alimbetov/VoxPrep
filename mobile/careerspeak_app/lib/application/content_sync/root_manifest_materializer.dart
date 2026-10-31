import '../../domain/application_preferences.dart';
import '../content_delivery/content_manifest.dart';
import '../content_delivery/locale_fallback.dart';
import '../result/result.dart';

/// Builds the device-local pack projection from one locale-independent backend
/// root snapshot. The global contentVersion/checksum remain the identity of the
/// full published root; Flutter only applies Backend-owned fallback metadata.
///
/// Non-pack snapshot membership is never locale-projected. Exact practice-test
/// and catalogue refs therefore survive materialization unchanged and remain
/// owned by the same immutable PublicationSnapshot.
final class RootManifestMaterializer {
  const RootManifestMaterializer();

  Result<RootContentManifest> materialize({
    required RootContentManifest root,
    required String translationLocale,
  }) {
    final locale = AppTranslationLocale.fromCode(translationLocale);
    if (locale == null) {
      return const FailureResult<RootContentManifest>(
        ApplicationFailure(
          code: 'LOCALE_INVALID',
          message: 'Translation locale is not a valid BCP-47 identifier.',
        ),
      );
    }

    Iterable<String> configuredFallbacks = const <String>[];
    for (final rule in root.localeFallbacks) {
      if (rule.locale == locale.code) {
        configuredFallbacks = rule.fallbackLocales;
        break;
      }
    }

    final LocaleFallbackPlan fallback;
    try {
      fallback = LocaleFallbackPlan(
        requestedLocale: locale.code,
        configuredFallbackLocales: configuredFallbacks,
      );
    } on FormatException catch (error) {
      return FailureResult<RootContentManifest>(
        ApplicationFailure(
          code: 'LOCALE_FALLBACK_INVALID',
          message: 'Backend locale fallback metadata is invalid.',
          details: <String, Object?>{'reason': error.message},
        ),
      );
    }

    final selectedVariants = <String>{
      'canonical',
      for (final candidate in fallback.localizedCandidates)
        'locale:${candidate.locale}',
    };
    final packs = root.packs
        .where((pack) => selectedVariants.contains(pack.identity.variant))
        .toList(growable: false);

    return Success<RootContentManifest>(
      RootContentManifest(
        schemaVersion: root.schemaVersion,
        contentVersion: root.contentVersion,
        minimumAppContractVersion: root.minimumAppContractVersion,
        publishedAt: root.publishedAt,
        checksum: root.checksum,
        packs: packs,
        practiceTests: root.practiceTests,
        catalogues: root.catalogues,
        localeFallbacks: root.localeFallbacks,
        tombstones: root.tombstones,
      ),
    );
  }
}
