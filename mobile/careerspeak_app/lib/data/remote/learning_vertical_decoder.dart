import '../../application/content_delivery/learning_vertical.dart';

final class LearningVerticalDecoder {
  const LearningVerticalDecoder();

  LearningVerticalProjection decode(Object value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Vertical catalogue item must be an object.');
    }

    const allowed = <String>{
      'code',
      'title',
      'description',
      'iconAssetId',
      'sortOrder',
      'active',
    };
    final unexpected = value.keys.where((key) => !allowed.contains(key));
    if (unexpected.isNotEmpty) {
      throw FormatException(
        'Vertical catalogue item contains non-publication fields: '
        '${unexpected.join(', ')}',
      );
    }

    final code = value['code'];
    final title = value['title'];
    final description = value['description'];
    final iconAssetId = value['iconAssetId'];
    final sortOrder = value['sortOrder'];
    final active = value['active'];

    if (code is! String ||
        title is! String ||
        description is! String ||
        iconAssetId is! String ||
        sortOrder is! int ||
        active is! bool) {
      throw const FormatException(
        'Vertical catalogue item has invalid field types.',
      );
    }

    return LearningVerticalProjection(
      code: code,
      title: title,
      description: description,
      iconAssetId: iconAssetId,
      sortOrder: sortOrder,
      active: active,
    );
  }

  List<LearningVerticalProjection> decodeAll(List<Object> items) {
    final decoded = items.map(decode).toList(growable: false);
    final seen = <String>{};
    for (final vertical in decoded) {
      if (!seen.add(vertical.code)) {
        throw FormatException(
          'Vertical catalogue contains duplicate code ${vertical.code}.',
        );
      }
    }
    return List<LearningVerticalProjection>.unmodifiable(decoded);
  }
}
