final class CatalogueChoice {
  factory CatalogueChoice({
    required String code,
    required int sortOrder,
    required bool active,
  }) {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      throw ArgumentError.value(code, 'code', 'must not be blank');
    }
    if (sortOrder < 0) {
      throw ArgumentError.value(sortOrder, 'sortOrder', 'must be non-negative');
    }
    return CatalogueChoice._(
      code: normalizedCode,
      sortOrder: sortOrder,
      active: active,
    );
  }

  const CatalogueChoice._({
    required this.code,
    required this.sortOrder,
    required this.active,
  });

  final String code;
  final int sortOrder;
  final bool active;
}

final class CatalogueSelectionPolicy {
  const CatalogueSelectionPolicy();

  String? resolve({
    required String? selectedCode,
    required Iterable<CatalogueChoice> choices,
  }) {
    final snapshot = List<CatalogueChoice>.unmodifiable(choices);
    final byCode = <String, CatalogueChoice>{};
    for (final choice in snapshot) {
      if (byCode.putIfAbsent(choice.code, () => choice) != choice) {
        throw ArgumentError.value(
          choice.code,
          'choices',
          'contains a duplicate catalogue code',
        );
      }
    }

    if (selectedCode != null) {
      final normalizedSelected = selectedCode.trim();
      if (normalizedSelected.isEmpty) {
        throw ArgumentError.value(
          selectedCode,
          'selectedCode',
          'must be null or non-blank',
        );
      }
      final selected = byCode[normalizedSelected];
      if (selected != null && selected.active) {
        return selected.code;
      }
    }

    final active = snapshot.where((choice) => choice.active).toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        if (order != 0) {
          return order;
        }
        return left.code.compareTo(right.code);
      });
    return active.firstOrNull?.code;
  }
}
