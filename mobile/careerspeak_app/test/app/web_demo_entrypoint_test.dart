import 'package:careerspeak_app/demo_web_main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('isolated Web preview shows generated lessons without Drift', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1100, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const VoxPrepWebDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('VoxPrep — DEV Web Preview'), findsOneWidget);
    expect(find.text('Dependency Injection'), findsOneWidget);
    expect(find.text('DEMO FREE'), findsOneWidget);

    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Learning catalogue'), findsOneWidget);
    expect(find.text('ConcurrentHashMap'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(
      find.text('Simulate FULL — not a real purchase'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
