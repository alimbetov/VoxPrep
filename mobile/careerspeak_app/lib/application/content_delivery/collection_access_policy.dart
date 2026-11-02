import 'product_catalog.dart';

final class CollectionAccessPolicy {
  const CollectionAccessPolicy._();

  static bool canAccess({
    required AccessLevel learnerAccess,
    required LearningCollectionProjection collection,
  }) {
    if (learnerAccess == AccessLevel.full) return true;
    return collection.accessLevel == AccessLevel.free;
  }

  static bool requiresUnlock({
    required AccessLevel learnerAccess,
    required LearningCollectionProjection collection,
  }) => !canAccess(learnerAccess: learnerAccess, collection: collection);
}
