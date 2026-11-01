import 'package:careerspeak_app/core/adaptive/careerspeak_adaptive_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact width renders bottom navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CareerSpeakAdaptiveScaffold(
          location: '/catalogue',
          child: Text('Catalogue body'),
        ),
      ),
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
    await tester.binding.setSurfaceSize(const Size(800, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CareerSpeakAdaptiveScaffold(
          location: '/tests',
          child: Text('Tests body'),
        ),
      ),
    );

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(
      tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex,
      2,
    );
  });

  testWidgets('large width extends the navigation rail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CareerSpeakAdaptiveScaffold(
          location: '/settings',
          child: Text('Settings body'),
        ),
      ),
    );

    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(rail.selectedIndex, 4);
  });

  testWidgets('content detail remains under Learn navigation destination', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CareerSpeakAdaptiveScaffold(
          location: '/content/topic/JAVA_MEMORY_MODEL',
          child: Text('Content detail'),
        ),
      ),
    );

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets('deep catalogue hierarchy remains under Learn destination', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: CareerSpeakAdaptiveScaffold(
          location: '/catalogue/vertical/V/goal/G/track/T/collection/C',
          child: Text('Collection'),
        ),
      ),
    );

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets('compact landscape survives 200% text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(640, 320),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          home: CareerSpeakAdaptiveScaffold(
            location: '/review',
            child: Text('Landscape learner body'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Landscape learner body'), findsOneWidget);
  });

  testWidgets('RTL compact shell remains inside viewport at 200% text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(2),
        ),
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CareerSpeakAdaptiveScaffold(
              location: '/settings',
              child: Text('RTL learner body'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('RTL learner body'), findsOneWidget);
  });

  testWidgets('medium low-height rail does not overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(800, 420),
          textScaler: TextScaler.linear(1.3),
        ),
        child: MaterialApp(
          home: CareerSpeakAdaptiveScaffold(
            location: '/tests',
            child: Text('Low height body'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Low height body'), findsOneWidget);
  });
}
