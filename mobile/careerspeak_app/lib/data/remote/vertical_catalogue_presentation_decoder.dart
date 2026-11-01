import '../../application/content_delivery/vertical_catalogue_presentation.dart';

final class VerticalCataloguePresentationDecoder {
  const VerticalCataloguePresentationDecoder();

  VerticalSectionProjection decodeSection(Object value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Vertical section must be an object.');
    }
    const allowed = <String>{
      'code',
      'title',
      'description',
      'iconAssetId',
      'sortOrder',
      'active',
    };
    _rejectUnexpected(value, allowed, 'Vertical section');

    final code = value['code'];
    final title = value['title'];
    final description = value['description'];
    final iconAssetId = value['iconAssetId'];
    final sortOrder = value['sortOrder'];
    final active = value['active'];
    if (code is! String ||
        title is! String ||
        (description != null && description is! String) ||
        (iconAssetId != null && iconAssetId is! String) ||
        sortOrder is! int ||
        active is! bool) {
      throw const FormatException('Vertical section has invalid field types.');
    }

    return VerticalSectionProjection(
      code: code,
      title: title,
      description: description as String?,
      iconAssetId: iconAssetId as String?,
      sortOrder: sortOrder,
      active: active,
    );
  }

  List<VerticalSectionProjection> decodeSections(List<Object> items) {
    final decoded = items.map(decodeSection).toList(growable: false);
    final seen = <String>{};
    for (final section in decoded) {
      if (!seen.add(section.code)) {
        throw FormatException(
          'Vertical sections contain duplicate code ${section.code}.',
        );
      }
    }
    return List<VerticalSectionProjection>.unmodifiable(decoded);
  }

  VerticalCataloguePresentation decodePresentation(Object value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Vertical presentation must be an object.');
    }
    const allowed = <String>{
      'mode',
      'showFeatured',
      'showSeeAll',
      'featuredSectionCode',
    };
    _rejectUnexpected(value, allowed, 'Vertical presentation');

    final mode = value['mode'];
    final showFeatured = value['showFeatured'];
    final showSeeAll = value['showSeeAll'];
    final featuredSectionCode = value['featuredSectionCode'];
    if (mode is! String ||
        showFeatured is! bool ||
        showSeeAll is! bool ||
        (featuredSectionCode != null && featuredSectionCode is! String)) {
      throw const FormatException(
        'Vertical presentation has invalid field types.',
      );
    }

    return VerticalCataloguePresentation(
      mode: VerticalCataloguePresentationMode.fromWireName(mode),
      showFeatured: showFeatured,
      showSeeAll: showSeeAll,
      featuredSectionCode: featuredSectionCode as String?,
    );
  }
}

void _rejectUnexpected(
  Map<String, dynamic> value,
  Set<String> allowed,
  String entityName,
) {
  final unexpected = value.keys.where((key) => !allowed.contains(key));
  if (unexpected.isNotEmpty) {
    throw FormatException(
      '$entityName contains non-publication fields: ${unexpected.join(', ')}',
    );
  }
}
