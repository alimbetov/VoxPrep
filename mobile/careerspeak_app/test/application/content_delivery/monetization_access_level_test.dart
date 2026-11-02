import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _hash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  test('legacy programmatic collection defaults fail-closed to FULL', () {
    final collection = LearningCollectionProjection(
      code: 'COLLECTION_ALPHA',
      verticalCode: 'VERTICAL_ALPHA',
      trackCode: 'TRACK_ALPHA',
      title: 'Collection',
      description: 'Collection description',
      sortOrder: 0,
      active: true,
      members: <LearningCollectionMember>[_member()],
    );

    expect(collection.accessLevel, AccessLevel.full);
    expect(collection.requiresFullAccess, isTrue);
  });

  test('explicit FREE collection does not require full entitlement', () {
    final collection = LearningCollectionProjection(
      code: 'COLLECTION_FREE',
      verticalCode: 'VERTICAL_ALPHA',
      trackCode: 'TRACK_ALPHA',
      title: 'Free collection',
      description: 'Free collection description',
      accessLevel: AccessLevel.free,
      sortOrder: 0,
      active: true,
      members: <LearningCollectionMember>[_member()],
    );

    expect(collection.accessLevel, AccessLevel.free);
    expect(collection.requiresFullAccess, isFalse);
  });

  test('access level wire names are strict and deterministic', () {
    expect(AccessLevel.fromWireName('FREE'), AccessLevel.free);
    expect(AccessLevel.fromWireName('FULL'), AccessLevel.full);
    expect(AccessLevel.free.wireName, 'FREE');
    expect(AccessLevel.full.wireName, 'FULL');
    expect(() => AccessLevel.fromWireName('free'), throwsFormatException);
    expect(() => AccessLevel.fromWireName('UNKNOWN'), throwsFormatException);
  });
}

LearningCollectionMember _member() {
  return LearningCollectionMember.content(
    position: 0,
    content: ContentRevisionRef(
      contentCode: 'CONTENT_ALPHA',
      contentType: ContentType.topic,
      revision: 1,
      checksum: _hash,
    ),
  );
}
