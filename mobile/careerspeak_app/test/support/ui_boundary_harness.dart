import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class UiBoundaryCase {
  const UiBoundaryCase({
    required this.name,
    required this.size,
    required this.textScale,
  });

  final String name;
  final Size size;
  final double textScale;

  @override
  String toString() => '$name ${size.width}x${size.height} @ $textScale';
}

const adaptiveUiBoundaryCases = <UiBoundaryCase>[
  UiBoundaryCase(name: 'small-phone', size: Size(320, 568), textScale: 1),
  UiBoundaryCase(name: 'compact-phone', size: Size(360, 640), textScale: 1.3),
  UiBoundaryCase(name: 'accessible-phone', size: Size(390, 844), textScale: 2),
  UiBoundaryCase(name: 'small-tablet', size: Size(600, 960), textScale: 2),
  UiBoundaryCase(name: 'tablet', size: Size(800, 1024), textScale: 1.3),
  UiBoundaryCase(
    name: 'desktop-accessible',
    size: Size(1280, 900),
    textScale: 2,
  ),
];

Future<void> configureAdaptiveSurface(
  WidgetTester tester, {
  required UiBoundaryCase boundary,
}) async {
  await tester.binding.setSurfaceSize(boundary.size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

TransitionBuilder adaptiveMediaQueryBuilder(UiBoundaryCase boundary) {
  return (context, child) {
    final inherited = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    return MediaQuery(
      data: inherited.copyWith(
        size: boundary.size,
        textScaler: TextScaler.linear(boundary.textScale),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  };
}

Future<void> pumpAdaptiveSurface(
  WidgetTester tester, {
  required UiBoundaryCase boundary,
  required Widget child,
}) async {
  await configureAdaptiveSurface(tester, boundary: boundary);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: boundary.size,
        textScaler: TextScaler.linear(boundary.textScale),
      ),
      child: child,
    ),
  );
  await tester.pumpAndSettle();
}

void expectNoLayoutExceptions(WidgetTester tester, {required String reason}) {
  final exceptions = <Object>[];
  Object? exception;
  while ((exception = tester.takeException()) != null) {
    exceptions.add(exception!);
  }

  expect(exceptions, isEmpty, reason: '$reason\n${exceptions.join('\n---\n')}');
}

void expectFinderInsideViewport(
  WidgetTester tester,
  Finder finder, {
  required Size viewport,
  required String reason,
}) {
  expect(finder, findsOneWidget, reason: reason);
  final rect = tester.getRect(finder);
  const tolerance = 0.5;

  expect(rect.left, greaterThanOrEqualTo(-tolerance), reason: reason);
  expect(rect.top, greaterThanOrEqualTo(-tolerance), reason: reason);
  expect(
    rect.right,
    lessThanOrEqualTo(viewport.width + tolerance),
    reason: reason,
  );
  expect(
    rect.bottom,
    lessThanOrEqualTo(viewport.height + tolerance),
    reason: reason,
  );
}
