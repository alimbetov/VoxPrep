import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import 'catalogue_revision_ref.dart';
import 'product_catalog.dart';

const supportedContentManifestSchemaVersion = 1;
const careerSpeakAppContractVersion = 1;

final class PackIdentity {
  factory PackIdentity({required String code, required String variant}) {
    return PackIdentity._(
      code: _requireBusinessCode(code, 'code'),
      variant: _requireVariant(variant),
    );
  }

  const PackIdentity._({required this.code, required this.variant});

  final String code;
  final String variant;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PackIdentity && other.code == code && other.variant == variant;
  }

  @override
  int get hashCode => Object.hash(code, variant);

  @override
  String toString() => '$code/$variant';
}

final class PackRevisionRef {
  factory PackRevisionRef({
    required PackIdentity identity,
    required int revision,
    required String checksum,
  }) {
    return PackRevisionRef._(
      identity: identity,
      revision: _requirePositive(revision, 'revision'),
      checksum: normalizeSha256(checksum, 'checksum'),
    );
  }

  const PackRevisionRef._({
    required this.identity,
    required this.revision,
    required this.checksum,
  });

  final PackIdentity identity;
  final int revision;
  final String checksum;
}

final class ContentTombstone {
  factory ContentTombstone({
    required ContentIdentity identity,
    required int revision,
    required String reason,
  }) {
    return ContentTombstone._(
      identity: identity,
      revision: _requirePositive(revision, 'revision'),
      reason: _requireNonBlank(reason, 'reason'),
    );
  }

  const ContentTombstone._({
    required this.identity,
    required this.revision,
    required this.reason,
  });

  final ContentIdentity identity;
  final int revision;
  final String reason;
}

final class LocaleFallbackRule {
  factory LocaleFallbackRule({
    required String locale,
    required Iterable<String> fallbackLocales,
  }) {
    final normalizedLocale = _canonicalizeLocale(locale, 'locale');
    final fallbacks = fallbackLocales
        .map((value) => _canonicalizeLocale(value, 'fallbackLocales'))
        .toList(growable: false);

    final seen = <String>{normalizedLocale};
    for (final fallback in fallbacks) {
      if (!seen.add(fallback)) {
        throw ArgumentError.value(
          fallback,
          'fallbackLocales',
          'contains a duplicate or the requested locale',
        );
      }
    }
    final englishIndex = fallbacks.indexOf('en');
    if (englishIndex >= 0 && englishIndex != fallbacks.length - 1) {
      throw ArgumentError.value(
        fallbacks,
        'fallbackLocales',
        'canonical English must be terminal',
      );
    }

    return LocaleFallbackRule._(
      locale: normalizedLocale,
      fallbackLocales: List<String>.unmodifiable(fallbacks),
    );
  }

  const LocaleFallbackRule._({
    required this.locale,
    required this.fallbackLocales,
  });

  final String locale;
  final List<String> fallbackLocales;
}

final class RootContentManifest {
  factory RootContentManifest({
    required int schemaVersion,
    required int contentVersion,
    required int minimumAppContractVersion,
    required DateTime publishedAt,
    required String checksum,
    required Iterable<PackRevisionRef> packs,
    Iterable<PracticeTestRevisionRef> practiceTests =
        const <PracticeTestRevisionRef>[],
    Iterable<CatalogueRevisionRef> catalogues = const <CatalogueRevisionRef>[],
    Iterable<LocaleFallbackRule> localeFallbacks = const <LocaleFallbackRule>[],
    required Iterable<ContentTombstone> tombstones,
  }) {
    final packList = List<PackRevisionRef>.unmodifiable(packs);
    final practiceTestList = List<PracticeTestRevisionRef>.unmodifiable(
      practiceTests,
    );
    final catalogueList = List<CatalogueRevisionRef>.unmodifiable(catalogues);
    final fallbackList = List<LocaleFallbackRule>.unmodifiable(localeFallbacks);
    final tombstoneList = List<ContentTombstone>.unmodifiable(tombstones);
    _requireUniquePackIdentities(packList);
    _requireUniquePracticeTestRefs(practiceTestList);
    _requireUniqueCatalogueRefs(catalogueList);
    _requireUniqueLocaleFallbacks(fallbackList);
    _requireUniqueTombstoneIdentities(tombstoneList);

    return RootContentManifest._(
      schemaVersion: _requirePositive(schemaVersion, 'schemaVersion'),
      contentVersion: _requirePositive(contentVersion, 'contentVersion'),
      minimumAppContractVersion: _requirePositive(
        minimumAppContractVersion,
        'minimumAppContractVersion',
      ),
      publishedAt: _requireUtc(publishedAt, 'publishedAt'),
      checksum: normalizeSha256(checksum, 'checksum'),
      packs: packList,
      practiceTests: practiceTestList,
      catalogues: catalogueList,
      localeFallbacks: fallbackList,
      tombstones: tombstoneList,
    );
  }

  const RootContentManifest._({
    required this.schemaVersion,
    required this.contentVersion,
    required this.minimumAppContractVersion,
    required this.publishedAt,
    required this.checksum,
    required this.packs,
    required this.practiceTests,
    required this.catalogues,
    required this.localeFallbacks,
    required this.tombstones,
  });

  final int schemaVersion;
  final int contentVersion;
  final int minimumAppContractVersion;
  final DateTime publishedAt;
  final String checksum;
  final List<PackRevisionRef> packs;
  final List<PracticeTestRevisionRef> practiceTests;
  final List<CatalogueRevisionRef> catalogues;
  final List<LocaleFallbackRule> localeFallbacks;
  final List<ContentTombstone> tombstones;
}

final class PackContentRef {
  factory PackContentRef({
    required ContentIdentity identity,
    required int revision,
    required String checksum,
    int? sortOrder,
    DateTime? publishedAt,
  }) {
    if (sortOrder != null && sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder', 'must not be negative');
    }

    return PackContentRef._(
      identity: identity,
      revision: _requirePositive(revision, 'revision'),
      checksum: normalizeSha256(checksum, 'checksum'),
      sortOrder: sortOrder,
      publishedAt: publishedAt == null
          ? null
          : _requireUtc(publishedAt, 'publishedAt'),
    );
  }

  const PackContentRef._({
    required this.identity,
    required this.revision,
    required this.checksum,
    required this.sortOrder,
    required this.publishedAt,
  });

  final ContentIdentity identity;
  final int revision;
  final String checksum;
  final int? sortOrder;
  final DateTime? publishedAt;
}

final class LocalizedContentRef {
  factory LocalizedContentRef({
    required ContentIdentity identity,
    required int contentRevision,
    required String locale,
    required int localizationRevision,
    required String checksum,
  }) {
    return LocalizedContentRef._(
      identity: identity,
      contentRevision: _requirePositive(contentRevision, 'contentRevision'),
      locale: _canonicalizeLocale(locale, 'locale'),
      localizationRevision: _requirePositive(
        localizationRevision,
        'localizationRevision',
      ),
      checksum: normalizeSha256(checksum, 'checksum'),
    );
  }

  const LocalizedContentRef._({
    required this.identity,
    required this.contentRevision,
    required this.locale,
    required this.localizationRevision,
    required this.checksum,
  });

  final ContentIdentity identity;
  final int contentRevision;
  final String locale;
  final int localizationRevision;
  final String checksum;
}

final class ManifestAssetDescriptor {
  factory ManifestAssetDescriptor({
    required String assetId,
    required String checksumSha256,
    required String deliveryKey,
    required int sizeBytes,
    required String mediaType,
    required bool requiredOffline,
  }) {
    if (sizeBytes <= 0) {
      throw ArgumentError.value(sizeBytes, 'sizeBytes', 'must be positive');
    }

    return ManifestAssetDescriptor._(
      assetId: _requireOpaqueId(assetId, 'assetId'),
      checksumSha256: normalizeSha256(checksumSha256, 'checksumSha256'),
      deliveryKey: _requireDeliveryKey(deliveryKey),
      sizeBytes: sizeBytes,
      mediaType: _requireNonBlank(mediaType, 'mediaType'),
      requiredOffline: requiredOffline,
    );
  }

  const ManifestAssetDescriptor._({
    required this.assetId,
    required this.checksumSha256,
    required this.deliveryKey,
    required this.sizeBytes,
    required this.mediaType,
    required this.requiredOffline,
  });

  final String assetId;
  final String checksumSha256;
  final String deliveryKey;
  final int sizeBytes;
  final String mediaType;
  final bool requiredOffline;
}

final class ContentAssetRef {
  factory ContentAssetRef({
    required ContentIdentity contentIdentity,
    required int contentRevision,
    required String assetId,
    required String role,
  }) {
    return ContentAssetRef._(
      contentIdentity: contentIdentity,
      contentRevision: _requirePositive(contentRevision, 'contentRevision'),
      assetId: _requireOpaqueId(assetId, 'assetId'),
      role: _requireNonBlank(role, 'role'),
    );
  }

  const ContentAssetRef._({
    required this.contentIdentity,
    required this.contentRevision,
    required this.assetId,
    required this.role,
  });

  final ContentIdentity contentIdentity;
  final int contentRevision;
  final String assetId;
  final String role;
}

final class PackContentManifest {
  factory PackContentManifest({
    required int schemaVersion,
    required PackIdentity identity,
    required int revision,
    required String checksum,
    required Iterable<PackContentRef> contents,
    Iterable<LocalizedContentRef> localizations = const <LocalizedContentRef>[],
    required Iterable<ManifestAssetDescriptor> assets,
    required Iterable<ContentAssetRef> contentAssets,
  }) {
    final contentList = List<PackContentRef>.unmodifiable(contents);
    final localizationList = List<LocalizedContentRef>.unmodifiable(
      localizations,
    );
    final assetList = List<ManifestAssetDescriptor>.unmodifiable(assets);
    final contentAssetList = List<ContentAssetRef>.unmodifiable(contentAssets);

    _requireUniqueContentIdentities(contentList);
    _requireValidLocalizedRefs(identity, contentList, localizationList);
    _requireUniqueAssets(assetList);
    _requireValidContentAssetRefs(contentList, assetList, contentAssetList);

    return PackContentManifest._(
      schemaVersion: _requirePositive(schemaVersion, 'schemaVersion'),
      identity: identity,
      revision: _requirePositive(revision, 'revision'),
      checksum: normalizeSha256(checksum, 'checksum'),
      contents: contentList,
      localizations: localizationList,
      assets: assetList,
      contentAssets: contentAssetList,
    );
  }

  const PackContentManifest._({
    required this.schemaVersion,
    required this.identity,
    required this.revision,
    required this.checksum,
    required this.contents,
    required this.localizations,
    required this.assets,
    required this.contentAssets,
  });

  final int schemaVersion;
  final PackIdentity identity;
  final int revision;
  final String checksum;
  final List<PackContentRef> contents;
  final List<LocalizedContentRef> localizations;
  final List<ManifestAssetDescriptor> assets;
  final List<ContentAssetRef> contentAssets;
}

ContentType? contentTypeFromWireName(String value) {
  for (final type in ContentType.values) {
    if (type.name == value) {
      return type;
    }
  }
  return null;
}

String normalizeSha256(String value, String fieldName) {
  final normalized = value.trim().toLowerCase();
  if (!_sha256Pattern.hasMatch(normalized)) {
    throw ArgumentError.value(value, fieldName, 'must be a SHA-256 hex digest');
  }
  return normalized;
}

final _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
final _businessCodePattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _localePattern = RegExp(r'^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$');
final _opaqueIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]*$');
final _deliverySegmentPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _alphaPattern = RegExp(r'^[A-Za-z]+$');

String _requireBusinessCode(String value, String fieldName) {
  final normalized = _requireNonBlank(value, fieldName);
  if (!_businessCodePattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must contain only letters, digits, dot, underscore, or hyphen',
    );
  }
  return normalized;
}

String _requireVariant(String value) {
  final normalized = _requireNonBlank(value, 'variant');
  if (normalized == 'canonical') {
    return normalized;
  }

  if (!normalized.startsWith('locale:')) {
    throw ArgumentError.value(
      value,
      'variant',
      'must be canonical or locale:<BCP-47>',
    );
  }

  final locale = normalized.substring('locale:'.length);
  return 'locale:${_canonicalizeLocale(locale, 'variant')}';
}

String _requireLocale(String value, String fieldName) {
  final normalized = _requireNonBlank(value, fieldName);
  if (!_localePattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'must be a BCP-47-compatible locale identifier',
    );
  }
  return normalized;
}

String _canonicalizeLocale(String value, String fieldName) {
  final normalized = _requireLocale(value, fieldName);
  final parts = normalized.split('-');
  final result = <String>[parts.first.toLowerCase()];
  for (final part in parts.skip(1)) {
    if (part.length == 2 && _alphaPattern.hasMatch(part)) {
      result.add(part.toUpperCase());
    } else if (part.length == 4 && _alphaPattern.hasMatch(part)) {
      result.add(
        '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
      );
    } else {
      result.add(part.toLowerCase());
    }
  }
  return result.join('-');
}

String _requireOpaqueId(String value, String fieldName) {
  final normalized = _requireNonBlank(value, fieldName);
  if (!_opaqueIdPattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      fieldName,
      'contains an invalid opaque id',
    );
  }
  return normalized;
}

String _requireDeliveryKey(String value) {
  final normalized = _requireNonBlank(value, 'deliveryKey');
  final segments = normalized.split('/');
  final invalid =
      normalized.startsWith('/') ||
      normalized.endsWith('/') ||
      normalized.contains('\\') ||
      normalized.contains('?') ||
      normalized.contains('#') ||
      normalized.contains('%') ||
      normalized.contains('://') ||
      segments.any(
        (segment) =>
            segment.isEmpty ||
            segment == '.' ||
            segment == '..' ||
            !_deliverySegmentPattern.hasMatch(segment),
      );
  if (invalid) {
    throw ArgumentError.value(
      value,
      'deliveryKey',
      'must be a relative immutable object key',
    );
  }
  return normalized;
}

String _requireNonBlank(String value, String fieldName) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be blank');
  }
  return normalized;
}

int _requirePositive(int value, String fieldName) {
  if (value < 1) {
    throw ArgumentError.value(value, fieldName, 'must be positive');
  }
  return value;
}

DateTime _requireUtc(DateTime value, String fieldName) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, fieldName, 'must use UTC semantics');
  }
  return value;
}

void _requireUniquePackIdentities(List<PackRevisionRef> packs) {
  final identities = <PackIdentity>{};
  for (final pack in packs) {
    if (!identities.add(pack.identity)) {
      throw ArgumentError.value(
        pack.identity,
        'packs',
        'contains duplicate pack identity',
      );
    }
  }
}

void _requireUniquePracticeTestRefs(List<PracticeTestRevisionRef> refs) {
  final identities = <String>{};
  for (final ref in refs) {
    if (!identities.add(ref.practiceTestCode)) {
      throw ArgumentError.value(
        ref.practiceTestCode,
        'practiceTests',
        'contains duplicate practice test identity',
      );
    }
  }
}

void _requireUniqueCatalogueRefs(List<CatalogueRevisionRef> refs) {
  final identities = <CatalogueKind>{};
  for (final ref in refs) {
    if (!identities.add(ref.kind)) {
      throw ArgumentError.value(
        ref.kind.wireName,
        'catalogues',
        'contains duplicate catalogue kind',
      );
    }
  }
}

void _requireUniqueLocaleFallbacks(List<LocaleFallbackRule> rules) {
  final locales = <String>{};
  for (final rule in rules) {
    if (!locales.add(rule.locale)) {
      throw ArgumentError.value(
        rule.locale,
        'localeFallbacks',
        'contains duplicate locale fallback rule',
      );
    }
  }
}

void _requireUniqueTombstoneIdentities(List<ContentTombstone> tombstones) {
  final identities = <ContentIdentity>{};
  for (final tombstone in tombstones) {
    if (!identities.add(tombstone.identity)) {
      throw ArgumentError.value(
        tombstone.identity.code,
        'tombstones',
        'contains duplicate content identity',
      );
    }
  }
}

void _requireUniqueContentIdentities(List<PackContentRef> contents) {
  final identities = <ContentIdentity>{};
  for (final content in contents) {
    if (!identities.add(content.identity)) {
      throw ArgumentError.value(
        content.identity.code,
        'contents',
        'contains duplicate content identity',
      );
    }
  }
}

void _requireValidLocalizedRefs(
  PackIdentity packIdentity,
  List<PackContentRef> contents,
  List<LocalizedContentRef> localizations,
) {
  if (packIdentity.variant == 'canonical') {
    if (localizations.isNotEmpty) {
      throw ArgumentError.value(
        localizations.length,
        'localizations',
        'canonical packs must not contain localized payload refs',
      );
    }
    return;
  }

  final expectedLocale = packIdentity.variant.substring('locale:'.length);
  final contentByIdentity = <ContentIdentity, PackContentRef>{
    for (final content in contents) content.identity: content,
  };
  final keys = <String>{};

  for (final localization in localizations) {
    if (localization.locale != expectedLocale) {
      throw ArgumentError.value(
        localization.locale,
        'localizations',
        'must match the locale pack variant $expectedLocale',
      );
    }

    final content = contentByIdentity[localization.identity];
    if (content == null || content.revision != localization.contentRevision) {
      throw ArgumentError.value(
        localization.identity.code,
        'localizations',
        'references missing canonical content revision',
      );
    }

    final key =
        '${localization.identity.code}|${localization.identity.type.name}|'
        '${localization.contentRevision}|${localization.locale}';
    if (!keys.add(key)) {
      throw ArgumentError.value(
        key,
        'localizations',
        'contains duplicate localized content identity',
      );
    }
  }
}

void _requireUniqueAssets(List<ManifestAssetDescriptor> assets) {
  final assetIds = <String>{};
  for (final asset in assets) {
    if (!assetIds.add(asset.assetId)) {
      throw ArgumentError.value(
        asset.assetId,
        'assets',
        'contains duplicate asset identity',
      );
    }
  }
}

void _requireValidContentAssetRefs(
  List<PackContentRef> contents,
  List<ManifestAssetDescriptor> assets,
  List<ContentAssetRef> refs,
) {
  final contentByIdentity = <ContentIdentity, PackContentRef>{
    for (final content in contents) content.identity: content,
  };
  final assetIds = <String>{for (final asset in assets) asset.assetId};
  final refKeys = <String>{};

  for (final ref in refs) {
    final content = contentByIdentity[ref.contentIdentity];
    if (content == null || content.revision != ref.contentRevision) {
      throw ArgumentError.value(
        ref.contentIdentity.code,
        'contentAssets',
        'references missing content revision',
      );
    }
    if (!assetIds.contains(ref.assetId)) {
      throw ArgumentError.value(
        ref.assetId,
        'contentAssets',
        'references missing asset',
      );
    }

    final key =
        '${ref.contentIdentity.code}|${ref.contentIdentity.type.name}|'
        '${ref.contentRevision}|${ref.assetId}|${ref.role}';
    if (!refKeys.add(key)) {
      throw ArgumentError.value(key, 'contentAssets', 'contains duplicate ref');
    }
  }
}
