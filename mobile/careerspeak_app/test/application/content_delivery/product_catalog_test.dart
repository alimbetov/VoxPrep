import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

const _contentHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _testHash =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  test('freezes Goal Track Collection with exact ordered revision refs', () {
    final goal = LearningGoalProjection(
      code: 'JOB_INTERVIEW',
      title: 'Job interview',
      description: 'Prepare for international job interviews.',
      sortOrder: 0,
      active: true,
    );
    final track = LearningTrackProjection(
      code: 'JAVA_SENIOR_INTERVIEW',
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
      trackCode: track.code,
      title: 'Dependency injection',
      description: 'Explain dependency injection clearly.',
      sortOrder: 0,
      active: true,
      contentRefs: <ContentRevisionRef>[
        ContentRevisionRef(
          contentCode: 'JAVA_Q_001',
          contentType: ContentType.interview,
          revision: 3,
          checksum: _contentHash,
        ),
      ],
      practiceTestRefs: <PracticeTestRevisionRef>[
        PracticeTestRevisionRef(
          practiceTestCode: 'JAVA_DI_TEST',
          revision: 1,
          checksum: _testHash,
        ),
      ],
    );

    expect(track.goalCode, goal.code);
    expect(collection.trackCode, track.code);
    expect(collection.contentRefs.single.revision, 3);
    expect(collection.practiceTestRefs.single.practiceTestCode, 'JAVA_DI_TEST');
  });

  test('collection rejects empty or duplicate exact membership', () {
    expect(
      () => LearningCollectionProjection(
        code: 'EMPTY',
        trackCode: 'TRACK',
        title: 'Empty',
        description: 'No material.',
        sortOrder: 0,
        active: true,
        contentRefs: const <ContentRevisionRef>[],
        practiceTestRefs: const <PracticeTestRevisionRef>[],
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
        code: 'DUPLICATE',
        trackCode: 'TRACK',
        title: 'Duplicate',
        description: 'Invalid membership.',
        sortOrder: 0,
        active: true,
        contentRefs: <ContentRevisionRef>[ref, ref],
        practiceTestRefs: const <PracticeTestRevisionRef>[],
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
