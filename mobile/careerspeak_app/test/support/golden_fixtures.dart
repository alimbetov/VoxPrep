import 'package:careerspeak_app/application/content_delivery/learning_vertical.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/content_delivery/universal_catalogue_graph.dart';
import 'package:careerspeak_app/application/content_delivery/vertical_catalogue_presentation.dart';
import 'package:careerspeak_app/application/ports/app_preferences_repository.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/ports/practice_test_attempt_repository.dart';
import 'package:careerspeak_app/application/ports/practice_test_repository.dart';
import 'package:careerspeak_app/application/ports/universal_catalogue_repository.dart';
import 'package:careerspeak_app/application/query/page.dart';
import 'package:careerspeak_app/application/query/practice_test_query.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/domain/practice_test.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:careerspeak_app/domain/practice_test_completion_key.dart';

const goldenHash =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

const goldenTopic = ContentItem(
  code: 'JAVA_CONCURRENCY_GOLDEN',
  type: ContentType.topic,
  title: 'Java Concurrency and Thread Safety',
  subtitle: 'Explain synchronization clearly during a backend interview',
  description: 'Review race conditions, synchronization, visibility and practical trade-offs with concise professional English.',
  category: 'JAVA',
  level: 'B2',
  minutes: 8,
  revision: 3,
  hasAudio: false,
);

const goldenInterview = ContentItem(
  code: 'JAVA_HASHMAP_INTERVIEW_GOLDEN',
  type: ContentType.interview,
  title: 'HashMap vs ConcurrentHashMap',
  subtitle:
      'Interview question with independent question and sample-answer audio',
  description: 'Practice answering a realistic Java interview question, then compare your response with a concise sample answer.',
  category: 'JAVA',
  level: 'B2',
  minutes: 5,
  revision: 4,
  hasAudio: true,
);

const goldenPracticeTest = PracticeTest(
  code: 'JAVA_GOLDEN_TEST',
  title: 'Java Backend Interview Check',
  subtitle: 'A compact practice session covering concurrency and collections.',
  mode: PracticeTestMode.learn,
  questions: [
    PracticeQuestion(
      code: 'Q1',
      prompt: 'Which statement best explains why ConcurrentHashMap is preferred over HashMap for shared mutable state?',
      options: [
        'It provides concurrency-oriented thread-safety semantics without requiring callers to synchronize every access.',
        'It stores every entry in a separate operating-system process.',
        'It prevents all threads from reading the map concurrently.',
        'It automatically converts mutable values into immutable objects.',
      ],
      correctIndex: 0,
      skill: 'Java concurrency',
      explanation: 'ConcurrentHashMap is designed for concurrent access and avoids the unsafe shared-state behavior of a plain HashMap.',
    ),
  ],
);

CurrentUniversalCatalogueSnapshot goldenCatalogueSnapshot() {
  final contentRef = ContentRevisionRef(
    contentCode: 'JAVA_CONCURRENCY_GOLDEN',
    contentType: ContentType.topic,
    revision: 3,
    checksum: goldenHash,
  );
  return CurrentUniversalCatalogueSnapshot(
    contentVersion: 42,
    graph: UniversalCatalogueGraph(
      sections: [
        VerticalSectionProjection(
          code: 'ENGINEERING',
          title: 'Software Engineering',
          description: 'Interview and professional English learning paths.',
          sortOrder: 10,
          active: true,
        ),
      ],
      verticals: [
        LearningVerticalProjection(
          code: 'JAVA_INTERVIEW',
          sectionCode: 'ENGINEERING',
          title: 'Java Interview',
          description: 'Backend interview preparation with questions, explanations, audio and practice.',
          iconAssetId: 'asset-java',
          sortOrder: 10,
          active: true,
        ),
        LearningVerticalProjection(
          code: 'DEVOPS_INTERVIEW',
          sectionCode: 'ENGINEERING',
          title: 'DevOps Interview',
          description: 'Infrastructure, delivery, containers and Kubernetes interview preparation.',
          iconAssetId: 'asset-devops',
          sortOrder: 20,
          active: true,
        ),
        LearningVerticalProjection(
          code: 'MEDICAL_ENGLISH',
          sectionCode: 'ENGINEERING',
          title: 'Medical English',
          description: 'Professional communication vocabulary and scenario-based English practice.',
          iconAssetId: 'asset-medical',
          sortOrder: 30,
          active: true,
        ),
      ],
      goals: [
        LearningGoalProjection(
          code: 'GOAL_JAVA',
          verticalCode: 'JAVA_INTERVIEW',
          title: 'Pass Java backend interviews',
          description: 'Build precise technical answers and vocabulary.',
          sortOrder: 10,
          active: true,
        ),
      ],
      tracks: [
        LearningTrackProjection(
          code: 'TRACK_JAVA_B2',
          verticalCode: 'JAVA_INTERVIEW',
          goalCode: 'GOAL_JAVA',
          title: 'Java Backend B2',
          description: 'Core backend interview track.',
          levelCode: 'B2',
          sortOrder: 10,
          active: true,
        ),
      ],
      collections: [
        LearningCollectionProjection(
          code: 'COLLECTION_JAVA_CORE',
          verticalCode: 'JAVA_INTERVIEW',
          trackCode: 'TRACK_JAVA_B2',
          title: 'Java Core Interview',
          description: 'Collections, concurrency and JVM fundamentals.',
          sortOrder: 10,
          active: true,
          members: [
            LearningCollectionMember.content(position: 0, content: contentRef),
          ],
        ),
      ],
      presentation: VerticalCataloguePresentation(
        mode: VerticalCataloguePresentationMode.grid,
        showFeatured: false,
        showSeeAll: true,
      ),
    ),
  );
}

final class GoldenUniversalCatalogueRepository
    implements UniversalCatalogueRepository {
  const GoldenUniversalCatalogueRepository();

  @override
  Future<Result<CurrentUniversalCatalogueSnapshot?>> readCurrent() async =>
      Success<CurrentUniversalCatalogueSnapshot?>(goldenCatalogueSnapshot());
}

final class GoldenLearnerStateRepository implements LearnerStateRepository {
  const GoldenLearnerStateRepository({this.markers = const {}});

  final Map<ContentIdentity, ContentMarkerState> markers;

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() =>
      Stream<Result<Map<ContentIdentity, ContentMarkerState>>>.value(
        Success<Map<ContentIdentity, ContentMarkerState>>(markers),
      );

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);
}

final class GoldenPracticeTestRepository implements PracticeTestRepository {
  const GoldenPracticeTestRepository();

  @override
  Future<Result<PracticeTest?>> getByCode(String code) async =>
      Success<PracticeTest?>(
        code == goldenPracticeTest.code ? goldenPracticeTest : null,
      );

  @override
  Stream<Result<Page<PracticeTestSummary>>> watchTests(
    PracticeTestQuery query,
  ) => Stream<Result<Page<PracticeTestSummary>>>.value(
    const Success<Page<PracticeTestSummary>>(
      Page<PracticeTestSummary>(
        items: [
          PracticeTestSummary(
            code: 'JAVA_GOLDEN_TEST',
            title: 'Java Backend Interview Check',
            subtitle: 'Concurrency and collections.',
            mode: PracticeTestMode.learn,
            questionCount: 1,
          ),
        ],
        hasMore: false,
      ),
    ),
  );
}

final class GoldenPracticeTestAttemptRepository
    implements PracticeTestAttemptRepository {
  PracticeTestAttempt? _active;
  final Set<PracticeTestCompletionKey> _completed =
      <PracticeTestCompletionKey>{};

  @override
  Future<Result<PracticeTestAttempt?>> getActiveAttempt() async =>
      Success<PracticeTestAttempt?>(_active);

  @override
  Future<Result<PracticeTestAttempt>> startActiveAttempt(String code) async {
    final now = DateTime.utc(2026, 11, 1, 10);
    _active = PracticeTestAttempt(
      practiceTestCode: code,
      practiceTestRevision: 1,
      currentIndex: 0,
      answers: const <int, int>{},
      startedAt: now,
      updatedAt: now,
    );
    return Success<PracticeTestAttempt>(_active!);
  }

  @override
  Future<Result<PracticeTestAttempt>> saveActiveAttempt(
    PracticeTestAttempt attempt,
  ) async {
    _active = attempt;
    return Success<PracticeTestAttempt>(attempt);
  }

  @override
  Future<Result<Set<PracticeTestCompletionKey>>>
  getCompletedPracticeTests() async => Success<Set<PracticeTestCompletionKey>>(
    Set<PracticeTestCompletionKey>.unmodifiable(_completed),
  );

  @override
  Future<Result<void>> completeActiveAttempt() async {
    final active = _active;
    if (active != null) {
      _completed.add(
        PracticeTestCompletionKey(
          practiceTestCode: active.practiceTestCode,
          revision: active.practiceTestRevision,
        ),
      );
      _active = null;
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> clearActiveAttempt() async {
    _active = null;
    return const Success<void>(null);
  }
}

final class GoldenPreferencesRepository implements AppPreferencesRepository {
  const GoldenPreferencesRepository({
    this.preferences = ApplicationPreferences.defaults,
  });

  final ApplicationPreferences preferences;

  @override
  Stream<Result<ApplicationPreferences>> watchPreferences() =>
      Stream<Result<ApplicationPreferences>>.value(
        Success<ApplicationPreferences>(preferences),
      );

  @override
  Future<Result<ApplicationPreferences>> getPreferences() async =>
      Success<ApplicationPreferences>(preferences);

  @override
  Future<Result<void>> setLocaleSelection({
    required String countryCode,
    required AppTranslationLocale locale,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setFocusMode(bool enabled) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setPreferredAccent(
    PreferredEnglishAccent? accent,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> setStorageQuotaBytes(int? bytes) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setTheme(AppThemePreference theme) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> setTranslationLocale(
    AppTranslationLocale locale,
  ) async => const Success<void>(null);

  @override
  Future<Result<void>> setUiLocale(AppUiLocale locale) async =>
      const Success<void>(null);
}
