const fullUnlockProductId = 'voxprep_full_unlock';

final class StoreProduct {
  factory StoreProduct({
    required String productId,
    required String title,
    required String description,
    required String localizedPrice,
  }) {
    final normalizedId = productId.trim();
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    final normalizedPrice = localizedPrice.trim();
    if (normalizedId.isEmpty ||
        normalizedTitle.isEmpty ||
        normalizedPrice.isEmpty) {
      throw ArgumentError('Store product identity, title and price are required.');
    }
    return StoreProduct._(
      productId: normalizedId,
      title: normalizedTitle,
      description: normalizedDescription,
      localizedPrice: normalizedPrice,
    );
  }

  const StoreProduct._({
    required this.productId,
    required this.title,
    required this.description,
    required this.localizedPrice,
  });

  final String productId;
  final String title;
  final String description;
  final String localizedPrice;

  bool get isFullUnlock => productId == fullUnlockProductId;
}
