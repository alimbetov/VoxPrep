import 'product_catalog.dart';
import 'publication_revision_membership.dart';

sealed class LearningCollectionMemberRef {
  const LearningCollectionMemberRef();

  String get exactIdentityKey;
}

final class LearningCollectionContentMemberRef
    extends LearningCollectionMemberRef {
  const LearningCollectionContentMemberRef(this.ref);

  final ContentRevisionRef ref;

  @override
  String get exactIdentityKey => 'content|${ref.identityKey}|${ref.checksum}';
}

final class LearningCollectionPracticeTestMemberRef
    extends LearningCollectionMemberRef {
  const LearningCollectionPracticeTestMemberRef(this.ref);

  final PracticeTestRevisionRef ref;

  @override
  String get exactIdentityKey =>
      'practiceTest|${ref.identityKey}|${ref.checksum}';
}

/// C4.5 ordered exact membership of one LearningCollection.
///
/// The list order is normative. Every member must resolve to an exact revision
/// with the same checksum inside the same PublicationRevisionMembership.
final class LearningCollectionMembership {
  factory LearningCollectionMembership({
    required String collectionCode,
    required Iterable<LearningCollectionMemberRef> members,
    required PublicationRevisionMembership publication,
  }) {
    final normalizedCode = collectionCode.trim();
    if (normalizedCode.isEmpty) {
      throw ArgumentError.value(
        collectionCode,
        'collectionCode',
        'must not be blank',
      );
    }

    final memberList = List<LearningCollectionMemberRef>.unmodifiable(members);
    if (memberList.isEmpty) {
      throw ArgumentError.value(
        memberList,
        'members',
        'a learning collection must contain at least one exact member',
      );
    }

    final exactKeys = <String>{};
    final publicationContent = <String, String>{
      for (final ref in publication.canonicalContents)
        '${ref.identity.code}|${ref.identity.type.name}|${ref.revision}':
            ref.checksum,
    };
    final publicationTests = <String, String>{
      for (final ref in publication.practiceTests)
        ref.identityKey: ref.checksum,
    };

    for (final member in memberList) {
      if (!exactKeys.add(member.exactIdentityKey)) {
        throw ArgumentError.value(
          member.exactIdentityKey,
          'members',
          'contains duplicate exact collection membership',
        );
      }

      switch (member) {
        case LearningCollectionContentMemberRef(:final ref):
          final key =
              '${ref.contentCode}|${ref.contentType.name}|${ref.revision}';
          final checksum = publicationContent[key];
          if (checksum == null || checksum != ref.checksum) {
            throw ArgumentError.value(
              key,
              'members',
              'content ref is outside this publication snapshot',
            );
          }
        case LearningCollectionPracticeTestMemberRef(:final ref):
          final checksum = publicationTests[ref.identityKey];
          if (checksum == null || checksum != ref.checksum) {
            throw ArgumentError.value(
              ref.identityKey,
              'members',
              'practice test ref is outside this publication snapshot',
            );
          }
      }
    }

    return LearningCollectionMembership._(
      collectionCode: normalizedCode,
      members: memberList,
    );
  }

  const LearningCollectionMembership._({
    required this.collectionCode,
    required this.members,
  });

  final String collectionCode;
  final List<LearningCollectionMemberRef> members;

  List<ContentRevisionRef> get contentRefs =>
      List<ContentRevisionRef>.unmodifiable(
        members
            .whereType<LearningCollectionContentMemberRef>()
            .map((member) => member.ref),
      );

  List<PracticeTestRevisionRef> get practiceTestRefs =>
      List<PracticeTestRevisionRef>.unmodifiable(
        members
            .whereType<LearningCollectionPracticeTestMemberRef>()
            .map((member) => member.ref),
      );
}

extension LearningCollectionPublicationBinding on LearningCollectionProjection {
  LearningCollectionMembership bindToPublication({
    required PublicationRevisionMembership publication,
    required Iterable<LearningCollectionMemberRef> orderedMembers,
  }) {
    final membership = LearningCollectionMembership(
      collectionCode: code,
      members: orderedMembers,
      publication: publication,
    );

    _requireSameExactRefs(
      expected: contentRefs.map(
        (ref) => '${ref.identityKey}|${ref.checksum}',
      ),
      actual: membership.contentRefs.map(
        (ref) => '${ref.identityKey}|${ref.checksum}',
      ),
      fieldName: 'contentRefs',
    );
    _requireSameExactRefs(
      expected: practiceTestRefs.map(
        (ref) => '${ref.identityKey}|${ref.checksum}',
      ),
      actual: membership.practiceTestRefs.map(
        (ref) => '${ref.identityKey}|${ref.checksum}',
      ),
      fieldName: 'practiceTestRefs',
    );

    return membership;
  }
}

void _requireSameExactRefs({
  required Iterable<String> expected,
  required Iterable<String> actual,
  required String fieldName,
}) {
  final expectedSet = expected.toSet();
  final actualSet = actual.toSet();
  if (expectedSet.length != actualSet.length ||
      !expectedSet.containsAll(actualSet) ||
      !actualSet.containsAll(expectedSet)) {
    throw ArgumentError.value(
      actualSet,
      fieldName,
      'ordered membership must contain exactly the projection refs',
    );
  }
}
