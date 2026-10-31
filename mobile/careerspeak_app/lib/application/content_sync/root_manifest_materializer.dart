import '../../domain/application_preferences.dart';
import '../content_delivery/content_manifest.dart';
import '../content_delivery/locale_fallback.dart';
import '../result/result.dart';

/// Builds the device-local pack projection from one locale-independent backend
/// root snapshot. The global contentVersion/checksum remain the identity of the
/// full published root; only canonical + the deterministic locale fallback
/// chain are materialized locally.
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

    final fallback = LocaleFallbackPlan(locale.code);
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
        tombstones: root.tombstones,
      ),
    );
  }
}
