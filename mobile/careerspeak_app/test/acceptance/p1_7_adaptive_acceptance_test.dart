import 'package:careerspeak_app/app/careerspeak_app.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/mock_visual_preferences.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/application/ports/practice_test_attempt_repository.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:careerspeak_app/domain/practice_test_completion_key.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/mock/mock_content_repository.dart';
import 'package:careerspeak_app/data/mock/mock_test_repository.dart';
import 'package:careerspeak_app/features/tests/test_session_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  const widths = <double>[360, 600, 840, 1200];
  const scales = <MockTextScalePreview>[
    MockTextScalePreview.normal,
    MockTextScalePreview.large,
    MockTextScalePreview.extraLarge,
  ];

  for (final width in widths) {
    for (final scale in scales) {
      testWidgets('P1.7 no overflow at ${width.toInt()} px / ${scale.label}', (
        tester,
      ) async {
        await _pumpApp(tester, width: width, textScale: scale);
        _expectNoFlutterException(tester);

        for (final destination in const [
          'Learn',
          'Tests',
          'Review',
          'Settings',
          'Home',
        ]) {
          await _navigate(tester, destination);
          _expectNoFlutterException(tester);
        }
      });
    }
  }

  testWidgets('detail route and marker state survive compact-to-large resize', (
    tester,
  ) async {
    await _pumpApp(tester, width: 360, textScale: MockTextScalePreview.normal);

    await _navigate(tester, 'Learn');
    // Learn now opens the universal catalogue, whereas the content detail
    // route remains deep-linkable. Verify the actual route across resizing.
    GoRouter.of(
      tester.element(find.byType(NavigationBar)),
    ).go('/content/interview/JAVA_DI_001');
    await tester.pumpAndSettle();

    expect(find.text('Dependency Injection'), findsWidgets);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 1000);
    await tester.pumpAndSettle();

    expect(find.text('Dependency Injection'), findsWidgets);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('compact and non-compact navigation switch at 600 px', (
    tester,
  ) async {
    await _pumpApp(tester, width: 360, textScale: MockTextScalePreview.normal);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    tester.view.physicalSize = const Size(600, 1000);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('assessment remains usable at 360 px and 2.0× text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = CareerSpeakDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final attempts = _AcceptancePracticeTestAttemptRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          careerSpeakDatabaseProvider.overrideWithValue(database),
          // MockTestRepository is not published into Drift. The test needs
          // an isolated attempt adapter for that same mock test revision.
          practiceTestAttemptRepositoryProvider.overrideWithValue(attempts),
          practiceTestRepositoryProvider.overrideWithValue(
            const MockTestRepository(),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: const TextScaler.linear(2.0),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const Scaffold(
            body: TestSessionScreen(code: 'JAVA_SENIOR_QUICK_001'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectNoFlutterException(tester);

    await _tapScrollableText(tester, 'Start test');
    _expectNoFlutterException(tester);

    for (var index = 0; index < 4; index++) {
      await _tapScrollableText(tester, 'Next');
      _expectNoFlutterException(tester);
    }

    await _tapScrollableText(tester, 'Submit');
    expect(find.text('Result'), findsOneWidget);
    _expectNoFlutterException(tester);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required double width,
  required MockTextScalePreview textScale,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1000);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final database = CareerSpeakDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  // Navigation/resize acceptance begins after onboarding. Production sends
  // a fresh installation to /onboarding; do not bypass redirect semantics.
  await database.customStatement(
    'UPDATE onboarding_state SET completed = 1, generation = 1 WHERE id = 1',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        careerSpeakDatabaseProvider.overrideWithValue(database),
        contentRepositoryProvider.overrideWithValue(
          const MockContentRepository(),
        ),
        practiceTestRepositoryProvider.overrideWithValue(
          const MockTestRepository(),
        ),
        mockVisualPreferencesProvider.overrideWith(
          () => _AcceptanceVisualPreferencesController(textScale),
        ),
      ],
      child: const CareerSpeakApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _navigate(WidgetTester tester, String label) async {
  final navigation = find.byWidgetPredicate(
    (widget) => widget is NavigationBar || widget is NavigationRail,
  );
  final destination = find.descendant(
    of: navigation,
    matching: find.text(label),
  );

  expect(destination, findsOneWidget);
  await tester.tap(destination);
  await tester.pumpAndSettle();
}

Future<void> _tapScrollableText(WidgetTester tester, String text) async {
  final target = find.text(text);

  if (target.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      target,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  }

  expect(target, findsOneWidget);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void _expectNoFlutterException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

class _AcceptanceVisualPreferencesController
    extends MockVisualPreferencesController {
  _AcceptanceVisualPreferencesController(this.initialTextScale);

  final MockTextScalePreview initialTextScale;

  @override
  MockVisualPreferences build() =>
      MockVisualPreferences(textScale: initialTextScale);
}

final class _AcceptancePracticeTestAttemptRepository
    implements PracticeTestAttemptRepository {
  PracticeTestAttempt? _active;
  final Set<PracticeTestCompletionKey> _completed =
      <PracticeTestCompletionKey>{};

  @override
  Future<Result<PracticeTestAttempt?>> getActiveAttempt() async =>
      Success<PracticeTestAttempt?>(_active);

  @override
  Future<Result<PracticeTestAttempt>> startActiveAttempt(String code) async {
    final now = DateTime.utc(2026, 11, 4);
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
