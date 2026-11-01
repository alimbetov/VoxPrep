import 'catalogue_revision_ref.dart';
import 'content_manifest.dart';

const universalCatalogueManifestSchemaVersion = 2;

const requiredUniversalCatalogueKindsV2 = <CatalogueKind>{
  CatalogueKind.verticalSections,
  CatalogueKind.verticals,
  CatalogueKind.verticalPresentation,
  CatalogueKind.learningGoals,
  CatalogueKind.learningTracks,
  CatalogueKind.learningCollections,
};

/// Enforces the universal-catalogue closure introduced by root manifest v2.
///
/// Schema v1 remains readable for backward compatibility. Starting with schema
/// v2, one immutable root snapshot must carry one exact revision/checksum for
/// every catalogue required to materialize the learner graph. Extra supported
/// catalogue kinds remain allowed and are still owned by the same snapshot.
void requireUniversalCatalogueManifestV2(RootContentManifest root) {
  if (root.schemaVersion < universalCatalogueManifestSchemaVersion) {
    return;
  }

  if (root.minimumAppContractVersion < 2) {
    throw ArgumentError.value(
      root.minimumAppContractVersion,
      'minimumAppContractVersion',
      'schema v2 must require application contract version 2 or newer',
    );
  }

  final present = <CatalogueKind>{for (final ref in root.catalogues) ref.kind};
  final missing = requiredUniversalCatalogueKindsV2.difference(present);
  if (missing.isNotEmpty) {
    final names = missing.map((kind) => kind.wireName).toList()..sort();
    throw ArgumentError.value(
      names,
      'catalogues',
      'schema v2 is missing required universal catalogue membership',
    );
  }
}
