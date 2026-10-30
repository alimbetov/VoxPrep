import 'package:careerspeak_app/app/careerspeak_app.dart';
import 'package:careerspeak_app/app/mock_visual_preferences.dart';
import 'package:careerspeak_app/features/tests/test_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const widths = <double>[360, 600, 840, 1200];
  const scales = <MockTextScalePreview>[
    MockTextScalePreview.normal,
    MockTextScalePreview.large,
    MockTextScalePreview.extraLarge,
  ];

  for (final width in widths) {
    for (final scale in scales) {
      testWidgets(
        'P1.7 no overflow at ${width.toInt()} px / ${scale.label}',
        (tester) async {
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
        },
      );
    }
  }

  testWidgets('detail route and marker state survive compact-to-large resize',
      (tester) async {
    await _pumpApp(
      tester,
      width: 360,
      textScale: MockTextScalePreview.normal,
    );

    await _navigate(tester, 'Learn');
    await tester.tap(find.text('Dependency Injection').first);
    await tester.pumpAndSettle();

    expect(find.text('Dependency Injection'), findsWidgets);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    tester.view.physicalSize = const Size(1200, 1000);
    await tester.pumpAndSettle();

    expect(find.text('Dependency Injection'), findsWidgets);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    _expectNoFlutterException(tester);
  });

  testWidgets('compact and non-compact navigation switch at 600 px',
      (tester) async {
    await _pumpApp(
      tester,
      width: 360,
      textScale: MockTextScalePreview.normal,
    );
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    tester.view.physicalSize = const Size(600, 1000);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.byType(NavigationRail), findsOneWidget);
    _expectNoFlutterException(tester);
  });

  testWidgets('assessment remains usable at 360 px and 2.0× text scale',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 1000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
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

    await _tapScrollableText(tester, 'Start mock test');
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

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
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

  for (var attempt = 0; attempt < 8 && target.evaluate().isEmpty; attempt++) {
    final scrollables = find.byType(Scrollable);
    expect(scrollables, findsWidgets);
    await tester.drag(scrollables.first, const Offset(0, -300));
    await tester.pumpAndSettle();
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
  MockVisualPreferences build() => MockVisualPreferences(
        textScale: initialTextScale,
      );
}
