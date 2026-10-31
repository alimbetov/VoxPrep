final class LearningVerticalProjection {
  factory LearningVerticalProjection({
    required String code,
    required String title,
    required String description,
    required String iconAssetId,
    required int sortOrder,
    required bool active,
  }) {
    return LearningVerticalProjection._(
      code: _stableCode(code, 'code'),
      title: _nonBlank(title, 'title'),
      description: _nonBlank(description, 'description'),
      iconAssetId: _nonBlank(iconAssetId, 'iconAssetId'),
      sortOrder: _sortOrder(sortOrder),
      active: active,
    );
  }

  const LearningVerticalProjection._({
    required this.code,
    required this.title,
    required this.description,
    required this.iconAssetId,
    required this.sortOrder,
    required this.active,
  });

  final String code;
  final String title;
  final String description;
  final String iconAssetId;
  final int sortOrder;
  final bool active;
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

int _sortOrder(int value) {
  if (value < 0) {
    throw ArgumentError.value(value, 'sortOrder', 'must not be negative');
  }
  return value;
}

final _stableCodePattern = RegExp(r'^[A-Z0-9][A-Z0-9_-]{1,63}$');
