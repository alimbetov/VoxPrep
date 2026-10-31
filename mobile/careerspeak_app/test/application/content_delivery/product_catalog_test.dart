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

  test('collection rejects empty, non-contiguous, and duplicate membership', () {
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
  });

  test('freezes taxonomy locale and learner-facing voice capability shapes', () {
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
  });
}
