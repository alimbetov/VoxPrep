import 'catalogue_revision_ref.dart';
import 'content_audio_policy.dart';
import 'content_manifest.dart';
import 'product_catalog.dart';

/// Exact immutable resource membership of one publication snapshot.
///
/// C4.2 owns only identity and closure rules. Ordering and collection semantics
/// are intentionally deferred to C4.5; wire materialization is deferred to C4.4.
final class PublicationRevisionMembership {
  factory PublicationRevisionMembership({
    required Iterable<PackRevisionRef> packs,
    required Iterable<PackContentManifest> packManifests,
    Iterable<PracticeTestRevisionRef> practiceTests =
        const <PracticeTestRevisionRef>[],
    Iterable<CatalogueRevisionRef> catalogues = const <CatalogueRevisionRef>[],
  }) {
    final packList = List<PackRevisionRef>.unmodifiable(packs);
    final manifestList = List<PackContentManifest>.unmodifiable(packManifests);
    final testList = List<PracticeTestRevisionRef>.unmodifiable(practiceTests);
    final catalogueList = List<CatalogueRevisionRef>.unmodifiable(catalogues);

    _requireUnique(
      packList.map((ref) => '${ref.identity}|${ref.revision}'),
      'packs',
    );
    _requireUnique(
      manifestList.map(
        (manifest) => '${manifest.identity}|${manifest.revision}',
      ),
      'packManifests',
    );
    _requireUnique(testList.map((ref) => ref.identityKey), 'practiceTests');
    _requireUnique(catalogueList.map((ref) => ref.identityKey), 'catalogues');

    final manifestByPack = <String, PackContentManifest>{
      for (final manifest in manifestList)
        '${manifest.identity}|${manifest.revision}': manifest,
    };
    for (final pack in packList) {
      final key = '${pack.identity}|${pack.revision}';
      final manifest = manifestByPack[key];
      if (manifest == null || manifest.checksum != pack.checksum) {
        throw ArgumentError.value(
          pack.identity.toString(),
          'packManifests',
          'does not resolve the exact pack revision/checksum',
        );
      }
    }
    if (manifestByPack.length != packList.length) {
      throw ArgumentError(
        'packManifests contains a revision outside publication pack membership',
      );
    }

    final canonicalRefs = <String, PackContentRef>{};
    final localizedRefs = <String, LocalizedContentRef>{};
    final assetRefs = <String, ManifestAssetDescriptor>{};

    for (final manifest in manifestList) {
      for (final content in manifest.contents) {
        final key = _contentRevisionKey(
          content.identity.code,
          content.identity.type.name,
          content.revision,
        );
        final existing = canonicalRefs[key];
        if (existing != null && existing.checksum != content.checksum) {
          throw ArgumentError.value(
            key,
            'packManifests',
            'same exact content revision has conflicting checksums',
          );
        }
        canonicalRefs[key] = content;
      }

      for (final localized in manifest.localizations) {
        final key =
            '${localized.identity.code}|${localized.identity.type.name}|'
            '${localized.contentRevision}|${localized.locale}|'
            '${localized.localizationRevision}';
        final existing = localizedRefs[key];
        if (existing != null && existing.checksum != localized.checksum) {
          throw ArgumentError.value(
            key,
            'packManifests',
            'same exact localization revision has conflicting checksums',
          );
        }
        localizedRefs[key] = localized;
      }

      for (final asset in manifest.assets) {
        final existing = assetRefs[asset.assetId];
        if (existing != null &&
            (existing.checksumSha256 != asset.checksumSha256 ||
                existing.deliveryKey != asset.deliveryKey ||
                existing.sizeBytes != asset.sizeBytes ||
                existing.mediaType != asset.mediaType)) {
          throw ArgumentError.value(
            asset.assetId,
            'packManifests',
            'same asset identity has conflicting immutable metadata',
          );
        }
        assetRefs[asset.assetId] = asset;
      }
    }

    _validateAudioMembership(
      manifests: manifestList,
      canonicalContents: canonicalRefs,
      assets: assetRefs,
    );

    return PublicationRevisionMembership._(
      packs: packList,
      packManifests: manifestList,
      canonicalContents: List<PackContentRef>.unmodifiable(
        canonicalRefs.values,
      ),
      localizations: List<LocalizedContentRef>.unmodifiable(
        localizedRefs.values,
      ),
      practiceTests: testList,
      catalogues: catalogueList,
      assets: List<ManifestAssetDescriptor>.unmodifiable(assetRefs.values),
    );
  }

  const PublicationRevisionMembership._({
    required this.packs,
    required this.packManifests,
    required this.canonicalContents,
    required this.localizations,
    required this.practiceTests,
    required this.catalogues,
    required this.assets,
  });

  final List<PackRevisionRef> packs;
  final List<PackContentManifest> packManifests;
  final List<PackContentRef> canonicalContents;
  final List<LocalizedContentRef> localizations;
  final List<PracticeTestRevisionRef> practiceTests;
  final List<CatalogueRevisionRef> catalogues;
  final List<ManifestAssetDescriptor> assets;
}

void _validateAudioMembership({
  required List<PackContentManifest> manifests,
  required Map<String, PackContentRef> canonicalContents,
  required Map<String, ManifestAssetDescriptor> assets,
}) {
  final typedBindings = <String, String>{};
  final legacyPromptByContent = <String>{};
  final schemaByContent = <String, int>{};

  for (final manifest in manifests) {
    for (final content in manifest.contents) {
      final contentKey = _contentRevisionKey(
        content.identity.code,
        content.identity.type.name,
        content.revision,
      );
      final previous = schemaByContent[contentKey];
      if (previous == null || manifest.schemaVersion > previous) {
        schemaByContent[contentKey] = manifest.schemaVersion;
      }
    }

    for (final binding in manifest.contentAssets) {
      final contentKey = _contentRevisionKey(
        binding.contentIdentity.code,
        binding.contentIdentity.type.name,
        binding.contentRevision,
      );

      if (binding.role == 'promptAudio') {
        if (manifest.schemaVersion == 1) {
          legacyPromptByContent.add(contentKey);
        }
        continue;
      }

      final role = ContentAudioRole.fromWireName(binding.role);
      if (role == null) {
        continue; // Generic non-audio asset roles remain outside this policy.
      }
      if (!ContentAudioPolicy.allows(binding.contentIdentity.type, role)) {
        throw ArgumentError.value(
          binding.role,
          'contentAssets',
          'audio role is not allowed for content type '
              '${binding.contentIdentity.type.name}',
        );
      }

      final asset = assets[binding.assetId];
      if (asset == null ||
          !asset.mediaType.toLowerCase().startsWith('audio/')) {
        throw ArgumentError.value(
          binding.assetId,
          'contentAssets',
          'audio role must reference an audio/* asset',
        );
      }

      final roleKey = '$contentKey|${role.wireName}';
      final existingAssetId = typedBindings[roleKey];
      if (existingAssetId != null && existingAssetId != binding.assetId) {
        throw ArgumentError.value(
          roleKey,
          'contentAssets',
          'exact content revision has more than one asset for one audio role',
        );
      }
      typedBindings[roleKey] = binding.assetId;
    }
  }

  for (final entry in canonicalContents.entries) {
    final contentKey = entry.key;
    final content = entry.value;
    final schemaVersion = schemaByContent[contentKey] ?? 1;
    for (final role in ContentAudioPolicy.requiredRoles(
      content.identity.type,
    )) {
      final hasTypedRole = typedBindings.containsKey(
        '$contentKey|${role.wireName}',
      );
      final hasLegacyV1Fallback =
          schemaVersion == 1 && legacyPromptByContent.contains(contentKey);
      if (!hasTypedRole && !hasLegacyV1Fallback) {
        throw ArgumentError.value(
          contentKey,
          'contentAssets',
          'required audio role ${role.wireName} is missing',
        );
      }
    }
  }
}

String _contentRevisionKey(String code, String type, int revision) {
  return '$code|$type|$revision';
}

void _requireUnique(Iterable<String> keys, String fieldName) {
  final seen = <String>{};
  for (final key in keys) {
    if (!seen.add(key)) {
      throw ArgumentError.value(
        key,
        fieldName,
        'contains duplicate exact membership',
      );
    }
  }
}
