import 'package:careerspeak_app/application/content_delivery/collection_access_policy.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('FREE learner can access FREE collection', () {
    expect(
      CollectionAccessPolicy.canAccess(
        learnerAccess: AccessLevel.free,
        collection: _collection(AccessLevel.free),
      ),
      isTrue,
    );
  });

  test('FREE learner cannot access FULL collection', () {
    final collection = _collection(AccessLevel.full);

    expect(
      CollectionAccessPolicy.canAccess(
        learnerAccess: AccessLevel.free,
        collection: collection,
      ),
      isFalse,
    );
    expect(
      CollectionAccessPolicy.requiresUnlock(
        learnerAccess: AccessLevel.free,
        collection: collection,
      ),
      isTrue,
    );
  });

  test('FULL learner can access FREE and FULL collections', () {
    for (final requirement in AccessLevel.values) {
      expect(
        CollectionAccessPolicy.canAccess(
          learnerAccess: AccessLevel.full,
          collection: _collection(requirement),
        ),
        isTrue,
      );
    }
  });
}

LearningCollectionProjection _collection(AccessLevel accessLevel) {
  return LearningCollectionProjection(
    code: 'COLLECTION_${accessLevel.wireName}',
    verticalCode: 'VERTICAL',
    trackCode: 'TRACK',
    title: 'Collection',
    description: 'Description',
    accessLevel: accessLevel,
    sortOrder: 0,
    active: true,
    members: <LearningCollectionMember>[
      LearningCollectionMember.content(
        position: 0,
        content: ContentRevisionRef(
          contentCode: 'CONTENT_${accessLevel.wireName}',
          contentType: ContentType.topic,
          revision: 1,
          checksum: _hash,
        ),
      ),
    ],
  );
}
