enum VerticalCataloguePresentationMode {
  carousel('CAROUSEL'),
  shelves('SHELVES'),
  grid('GRID');

  const VerticalCataloguePresentationMode(this.wireName);

  final String wireName;

  static VerticalCataloguePresentationMode fromWireName(String value) {
    for (final mode in values) {
      if (mode.wireName == value) {
        return mode;
      }
    }
    throw FormatException(
      'Unsupported vertical catalogue presentation: $value',
    );
  }
}

final class VerticalSectionProjection {
  factory VerticalSectionProjection({
    required String code,
    required String title,
    String? description,
    String? iconAssetId,
    required int sortOrder,
    required bool active,
  }) {
    return VerticalSectionProjection._(
      code: _stableCode(code, 'code'),
      title: _nonBlank(title, 'title'),
      description: _optionalNonBlank(description, 'description'),
      iconAssetId: _optionalNonBlank(iconAssetId, 'iconAssetId'),
      sortOrder: _sortOrder(sortOrder),
      active: active,
    );
  }

  const VerticalSectionProjection._({
    required this.code,
    required this.title,
    required this.description,
    required this.iconAssetId,
    required this.sortOrder,
    required this.active,
  });

  final String code;
  final String title;
  final String? description;
  final String? iconAssetId;
  final int sortOrder;
  final bool active;
}

final class VerticalCataloguePresentation {
  factory VerticalCataloguePresentation({
    required VerticalCataloguePresentationMode mode,
    required bool showFeatured,
    required bool showSeeAll,
    String? featuredSectionCode,
  }) {
    final normalizedFeaturedSectionCode = featuredSectionCode == null
        ? null
        : _stableCode(featuredSectionCode, 'featuredSectionCode');
    if (showFeatured && normalizedFeaturedSectionCode == null) {
      throw ArgumentError(
        'featuredSectionCode is required when showFeatured is true',
      );
    }
    return VerticalCataloguePresentation._(
      mode: mode,
      showFeatured: showFeatured,
      showSeeAll: showSeeAll,
      featuredSectionCode: normalizedFeaturedSectionCode,
    );
  }

  const VerticalCataloguePresentation._({
    required this.mode,
    required this.showFeatured,
    required this.showSeeAll,
    required this.featuredSectionCode,
  });

  final VerticalCataloguePresentationMode mode;
  final bool showFeatured;
  final bool showSeeAll;
  final String? featuredSectionCode;
}

String _stableCode(String value, String field) {
  final normalized = value.trim();
  if (!_stableCodePattern.hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      field,
      'must be a stable backend-owned code',
    );
  }
  return normalized;
}

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be blank');
  }
  return normalized;
}

String? _optionalNonBlank(String? value, String field) {
  if (value == null) {
    return null;
  }
  return _nonBlank(value, field);
}

int _sortOrder(int value) {
  if (value < 0) {
    throw ArgumentError.value(value, 'sortOrder', 'must not be negative');
  }
  return value;
}

final _stableCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9_-]{1,63}$');
