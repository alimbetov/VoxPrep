import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_delivery/learning_collection_membership.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/publication_revision_membership.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preserves one normative order across content and practice tests', () {
    final publication = _publication();
    final membership = LearningCollectionMembership(
      collectionCode: 'JAVA_INTERVIEW_CORE',
      publication: publication,
      members: <LearningCollectionMemberRef>[
        LearningCollectionContentMemberRef(_contentRef('JAVA_Q_001', 1, _shaC)),
        LearningCollectionPracticeTestMemberRef(
          PracticeTestRevisionRef(
            practiceTestCode: 'JAVA_TEST_001',
            revision: 2,
            checksum: _shaT,
          ),
        ),
        LearningCollectionContentMemberRef(_contentRef('JAVA_Q_002', 3, _shaD)),
      ],
    );

    expect(membership.members, hasLength(3));
    expect(membership.members[0], isA<LearningCollectionContentMemberRef>());
    expect(
      membership.members[1],
      isA<LearningCollectionPracticeTestMemberRef>(),
    );
    expect(membership.members[2], isA<LearningCollectionContentMemberRef>());
    expect(
      membership.contentRefs.map((ref) => ref.contentCode).toList(),
      <String>['JAVA_Q_001', 'JAVA_Q_002'],
    );
    expect(
      membership.practiceTestRefs.single.practiceTestCode,
      'JAVA_TEST_001',
    );
  });

  test(
    'binds a frozen collection projection to the same exact ordered refs',
    () {
      final content = _contentRef('JAVA_Q_001', 1, _shaC);
      final practiceTest = PracticeTestRevisionRef(
        practiceTestCode: 'JAVA_TEST_001',
        revision: 2,
        checksum: _shaT,
      );
      final projection = LearningCollectionProjection(
        code: 'JAVA_INTERVIEW_CORE',
        trackCode: 'JAVA_SENIOR',
        title: 'Java interview core',
        description: 'Exact publication-owned learning sequence.',
        sortOrder: 0,
        active: true,
        contentRefs: <ContentRevisionRef>[content],
        practiceTestRefs: <PracticeTestRevisionRef>[practiceTest],
      );

      final membership = projection.bindToPublication(
        publication: _publication(),
        orderedMembers: <LearningCollectionMemberRef>[
          LearningCollectionContentMemberRef(content),
          LearningCollectionPracticeTestMemberRef(practiceTest),
        ],
      );

      expect(membership.collectionCode, projection.code);
      expect(membership.members, hasLength(2));
    },
  );

  test('projection binding rejects an omitted frozen exact ref', () {
    final content = _contentRef('JAVA_Q_001', 1, _shaC);
    final practiceTest = PracticeTestRevisionRef(
      practiceTestCode: 'JAVA_TEST_001',
      revision: 2,
      checksum: _shaT,
    );
    final projection = LearningCollectionProjection(
      code: 'JAVA_INTERVIEW_CORE',
      trackCode: 'JAVA_SENIOR',
      title: 'Java interview core',
      description: 'Exact publication-owned learning sequence.',
      sortOrder: 0,
      active: true,
      contentRefs: <ContentRevisionRef>[content],
      practiceTestRefs: <PracticeTestRevisionRef>[practiceTest],
    );

    expect(
      () => projection.bindToPublication(
        publication: _publication(),
        orderedMembers: <LearningCollectionMemberRef>[
          LearningCollectionContentMemberRef(content),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('rejects content revision outside publication snapshot', () {
    expect(
      () => LearningCollectionMembership(
        collectionCode: 'JAVA_INTERVIEW_CORE',
        publication: _publication(),
        members: <LearningCollectionMemberRef>[
          LearningCollectionContentMemberRef(
            _contentRef('JAVA_Q_001', 99, _shaC),
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('rejects content checksum drift for an exact revision', () {
    expect(
      () => LearningCollectionMembership(
        collectionCode: 'JAVA_INTERVIEW_CORE',
        publication: _publication(),
        members: <LearningCollectionMemberRef>[
          LearningCollectionContentMemberRef(
            _contentRef('JAVA_Q_001', 1, _shaD),
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('rejects practice test revision outside publication snapshot', () {
    expect(
      () => LearningCollectionMembership(
        collectionCode: 'JAVA_INTERVIEW_CORE',
        publication: _publication(),
        members: <LearningCollectionMemberRef>[
          LearningCollectionPracticeTestMemberRef(
            PracticeTestRevisionRef(
              practiceTestCode: 'JAVA_TEST_001',
              revision: 3,
              checksum: _shaT,
            ),
          ),
        ],
      ),
      throwsArgumentError,
    );
  });

  test('rejects duplicate exact collection member', () {
    final ref = _contentRef('JAVA_Q_001', 1, _shaC);
    expect(
      () => LearningCollectionMembership(
        collectionCode: 'JAVA_INTERVIEW_CORE',
        publication: _publication(),
        members: <LearningCollectionMemberRef>[
          LearningCollectionContentMemberRef(ref),
          LearningCollectionContentMemberRef(ref),
        ],
      ),
      throwsArgumentError,
    );
  });
}

PublicationRevisionMembership _publication() {
  final pack = PackRevisionRef(
    identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
    revision: 8,
    checksum: _shaP,
  );
  return PublicationRevisionMembership(
    packs: <PackRevisionRef>[pack],
    packManifests: <PackContentManifest>[
      PackContentManifest(
        schemaVersion: 1,
        identity: pack.identity,
        revision: pack.revision,
        checksum: pack.checksum,
        contents: <PackContentRef>[
          PackContentRef(
            identity: const ContentIdentity(
              code: 'JAVA_Q_001',
              type: ContentType.interview,
            ),
            revision: 1,
            checksum: _shaC,
          ),
          PackContentRef(
            identity: const ContentIdentity(
              code: 'JAVA_Q_002',
              type: ContentType.interview,
            ),
            revision: 3,
            checksum: _shaD,
          ),
        ],
        assets: const <ManifestAssetDescriptor>[],
        contentAssets: const <ContentAssetRef>[],
      ),
    ],
    practiceTests: <PracticeTestRevisionRef>[
      PracticeTestRevisionRef(
        practiceTestCode: 'JAVA_TEST_001',
        revision: 2,
        checksum: _shaT,
      ),
    ],
  );
}

ContentRevisionRef _contentRef(String code, int revision, String checksum) {
  return ContentRevisionRef(
    contentCode: code,
    contentType: ContentType.interview,
    revision: revision,
    checksum: checksum,
  );
}

const _shaP =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _shaC =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _shaD =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _shaT =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
