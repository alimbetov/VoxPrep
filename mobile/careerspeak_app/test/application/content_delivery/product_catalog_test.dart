import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _contentHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _testHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  test('freezes Goal Track Collection with one ordered member stream', () {
    final goal = LearningGoalProjection(
      code: 'JOB_INTERVIEW',
      verticalCode: 'JAVA_INTERVIEW',
      title: 'Job interview',
      description: 'Prepare for international job interviews.',
      sortOrder: 0,
      active: true,
    );
    final track = LearningTrackProjection(
      code: 'JAVA_SENIOR_INTERVIEW',
      verticalCode: goal.verticalCode,
      goalCode: goal.code,
      title: 'Senior Java interview',
      description: 'Practice senior Java interview English.',
      levelCode: 'B2',
      careerTrackCode: 'JAVA_BACKEND',
      sortOrder: 0,
      active: true,
    );
    final collection = LearningCollectionProjection(
      code: 'JAVA_DI',
      verticalCode: track.verticalCode,
      trackCode: track.code,
      title: 'Dependency injection',
      description: 'Explain dependency injection clearly.',
      sortOrder: 0,
      active: true,
      members: <LearningCollectionMember>[
        LearningCollectionMember.content(
          position: 0,
          content: ContentRevisionRef(
            contentCode: 'JAVA_Q_001',
            contentType: ContentType.interview,
            revision: 3,
            checksum: _contentHash,
          ),
        ),
        LearningCollectionMember.practiceTest(
          position: 1,
          practiceTest: PracticeTestRevisionRef(
            practiceTestCode: 'JAVA_DI_TEST',
            revision: 1,
            checksum: _testHash,
          ),
        ),
      ],
    );

    expect(track.goalCode, goal.code);
    expect(collection.trackCode, track.code);
    expect(collection.members, hasLength(2));
    expect(collection.members[0].type, LearningCollectionMemberType.content);
    expect(collection.members[0].contentRef!.revision, 3);
    expect(
      collection.members[1].type,
      LearningCollectionMemberType.practiceTest,
    );
    expect(
      collection.members[1].practiceTestRef!.practiceTestCode,
      'JAVA_DI_TEST',
    );
  });

  test(
    'collection rejects empty, non-contiguous, and duplicate membership',
    () {
      expect(
        () => LearningCollectionProjection(
          code: 'EMPTY',
          verticalCode: 'JAVA_INTERVIEW',
          trackCode: 'TRACK',
          title: 'Empty',
          description: 'No material.',
          sortOrder: 0,
          active: true,
          members: const <LearningCollectionMember>[],
        ),
        throwsArgumentError,
      );

      final ref = ContentRevisionRef(
        contentCode: 'JAVA_Q_001',
        contentType: ContentType.interview,
        revision: 3,
        checksum: _contentHash,
      );

      expect(
        () => LearningCollectionProjection(
          code: 'GAP',
          verticalCode: 'JAVA_INTERVIEW',
          trackCode: 'TRACK',
          title: 'Gap',
          description: 'Invalid ordering.',
          sortOrder: 0,
          active: true,
          members: <LearningCollectionMember>[
            LearningCollectionMember.content(position: 1, content: ref),
          ],
        ),
        throwsArgumentError,
      );

      expect(
        () => LearningCollectionProjection(
          code: 'DUPLICATE',
          verticalCode: 'JAVA_INTERVIEW',
          trackCode: 'TRACK',
          title: 'Duplicate',
          description: 'Invalid membership.',
          sortOrder: 0,
          active: true,
          members: <LearningCollectionMember>[
            LearningCollectionMember.content(position: 0, content: ref),
            LearningCollectionMember.content(position: 1, content: ref),
          ],
        ),
        throwsArgumentError,
      );
    },
  );

  test(
    'freezes taxonomy locale and learner-facing voice capability shapes',
    () {
      final category = TaxonomyProjection(
        code: 'JAVA_BACKEND',
        label: 'Java Backend',
        sortOrder: 0,
        active: true,
      );
      final locale = SupportedLocaleProjection(
        code: 'ru-KZ',
        label: 'Русский',
        sortOrder: 0,
        active: true,
      );
      final voice = TtsVoiceProjection(
        code: 'EN_US_AMY',
        locale: 'en-US',
        accentCode: 'US',
        label: 'Amy',
        sortOrder: 0,
        active: true,
      );

      expect(category.code, 'JAVA_BACKEND');
      expect(locale.code, 'ru-KZ');
      expect(voice.accentCode, 'US');
    },
  );

  group('catalogue primitive validation', () {
    test('revision refs normalize checksums and expose deterministic identity', () {
      final content = ContentRevisionRef(
        contentCode: 'java.topic-1',
        contentType: ContentType.topic,
        revision: 2,
        checksum: _contentHash.toUpperCase(),
      );
      final practice = PracticeTestRevisionRef(
        practiceTestCode: 'java.test-1',
        revision: 4,
        checksum: _testHash.toUpperCase(),
      );

      expect(content.checksum, _contentHash);
      expect(content.identityKey, 'java.topic-1|topic|2');
      expect(practice.checksum, _testHash);
      expect(practice.identityKey, 'java.test-1|4');
    });

    test('revision refs reject non-positive revision and malformed checksum', () {
      expect(
        () => ContentRevisionRef(
          contentCode: 'CONTENT',
          contentType: ContentType.topic,
          revision: 0,
          checksum: _contentHash,
        ),
        throwsArgumentError,
      );
      expect(
        () => PracticeTestRevisionRef(
          practiceTestCode: 'TEST',
          revision: -1,
          checksum: _testHash,
        ),
        throwsArgumentError,
      );
      expect(
        () => ContentRevisionRef(
          contentCode: 'CONTENT',
          contentType: ContentType.topic,
          revision: 1,
          checksum: 'not-a-sha256',
        ),
        throwsArgumentError,
      );
    });

    test('member factories reject negative position and preserve wire identity', () {
      final content = ContentRevisionRef(
        contentCode: 'CONTENT',
        contentType: ContentType.topic,
        revision: 1,
        checksum: _contentHash,
      );
      final member = LearningCollectionMember.content(
        position: 0,
        content: content,
      );

      expect(member.identityKey, 'CONTENT|CONTENT|topic|1');
      expect(
        LearningCollectionMemberType.fromWireName('CONTENT'),
        LearningCollectionMemberType.content,
      );
      expect(
        LearningCollectionMemberType.fromWireName('PRACTICE_TEST'),
        LearningCollectionMemberType.practiceTest,
      );
      expect(
        () => LearningCollectionMember.content(position: -1, content: content),
        throwsArgumentError,
      );
      expect(
        () => LearningCollectionMemberType.fromWireName('UNKNOWN'),
        throwsFormatException,
      );
    });

    test('stable-code projections reject lowercase, blank text and negative order', () {
      expect(
        () => TaxonomyProjection(
          code: 'java_backend',
          label: 'Java',
          sortOrder: 0,
          active: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => TaxonomyProjection(
          code: 'JAVA_BACKEND',
          label: '   ',
          sortOrder: 0,
          active: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => LearningGoalProjection(
          code: 'GOAL',
          verticalCode: 'VERTICAL',
          title: 'Goal',
          description: 'Description',
          sortOrder: -1,
          active: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => LearningTrackProjection(
          code: 'TRACK',
          verticalCode: 'VERTICAL',
          goalCode: 'GOAL',
          title: 'Track',
          description: 'Description',
          levelCode: 'b2',
          sortOrder: 0,
          active: true,
        ),
        throwsArgumentError,
      );
    });

    test('optional career track accepts null but rejects invalid stable code', () {
      final track = LearningTrackProjection(
        code: 'TRACK',
        verticalCode: 'VERTICAL',
        goalCode: 'GOAL',
        title: 'Track',
        description: 'Description',
        levelCode: 'B2',
        sortOrder: 0,
        active: true,
      );
      expect(track.careerTrackCode, isNull);

      expect(
        () => LearningTrackProjection(
          code: 'TRACK',
          verticalCode: 'VERTICAL',
          goalCode: 'GOAL',
          title: 'Track',
          description: 'Description',
          levelCode: 'B2',
          careerTrackCode: 'java backend',
          sortOrder: 0,
          active: true,
        ),
        throwsArgumentError,
      );
    });

    test('locale and voice reject malformed locale codes', () {
      expect(
        () => SupportedLocaleProjection(
          code: 'r',
          label: 'Russian',
          sortOrder: 0,
          active: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => TtsVoiceProjection(
          code: 'VOICE',
          locale: 'english_US',
          accentCode: 'US',
          label: 'Voice',
          sortOrder: 0,
          active: true,
        ),
        throwsArgumentError,
      );
    });
  });
}
