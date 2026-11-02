import 'package:careerspeak_app/core/adaptive/careerspeak_adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact width renders bottom navigation', (tester) async {
    await _pumpScaffold(
      tester,
      size: const Size(390, 800),
      location: '/catalogue',
      child: const Text('Catalogue body'),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.text('Catalogue body'), findsOneWidget);
  });

  testWidgets('medium width renders navigation rail', (tester) async {
    await _pumpScaffold(
      tester,
      size: const Size(800, 900),
      location: '/tests',
      child: const Text('Tests body'),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      2,
    );
  });

  testWidgets('large width extends the navigation rail', (tester) async {
    await _pumpScaffold(
      tester,
      size: const Size(1280, 900),
      location: '/settings',
      child: const Text('Settings body'),
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(rail.selectedIndex, 4);
  });

  testWidgets('content detail remains under Learn navigation destination', (
    tester,
  ) async {
    await _pumpScaffold(
      tester,
      size: const Size(390, 800),
      location: '/content/topic/JAVA_MEMORY_MODEL',
      child: const Text('Content detail'),
    );

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets('deep catalogue hierarchy remains under Learn destination', (
    tester,
  ) async {
    await _pumpScaffold(
      tester,
      size: const Size(390, 800),
      location: '/catalogue/vertical/V/goal/G/track/T/collection/C',
      child: const Text('Collection'),
    );

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets(
    'low-height landscape falls back to bottom navigation at 200% text scale',
    (tester) async {
      await _pumpScaffold(
        tester,
        size: const Size(640, 320),
        location: '/review',
        textScale: 2,
        child: const Text('Landscape learner body'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(find.text('Landscape learner body'), findsOneWidget);
    },
  );

  testWidgets('RTL compact shell remains inside viewport at 200% text scale', (
    tester,
  ) async {
    await _pumpScaffold(
      tester,
      size: const Size(320, 568),
      location: '/settings',
      textScale: 2,
      textDirection: TextDirection.rtl,
      child: const Text('RTL learner body'),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('RTL learner body'), findsOneWidget);
  });

  testWidgets('medium low-height rail does not overflow', (tester) async {
    await _pumpScaffold(
      tester,
      size: const Size(800, 420),
      location: '/tests',
      textScale: 1.3,
      child: const Text('Low height body'),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Low height body'), findsOneWidget);
  });
}

Future<void> _pumpScaffold(
  WidgetTester tester, {
  required Size size,
  required String location,
  required Widget child,
  double textScale = 1,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, appChild) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(textScale)),
          child: Directionality(textDirection: textDirection, child: appChild!),
        );
      },
      home: CareerSpeakAdaptiveScaffold(location: location, child: child),
    ),
  );
  await tester.pumpAndSettle();
}
