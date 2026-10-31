import 'package:careerspeak_app/core/motion/careerspeak_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('motion uses configured duration when animations are enabled', (
    tester,
  ) async {
    late Duration resolved;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            resolved = CareerSpeakMotion.duration(
              context,
              CareerSpeakMotion.navigation,
            );
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved, CareerSpeakMotion.navigation);
  });

  testWidgets('reduced motion resolves non-essential duration to zero', (
    tester,
  ) async {
    late Duration resolved;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              resolved = CareerSpeakMotion.duration(
                context,
                CareerSpeakMotion.emphasized,
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(resolved, Duration.zero);
  });

  testWidgets('route motion mirrors horizontal entry in RTL', (tester) async {
    late Widget transition;
    final controller = AnimationController(
      vsync: tester,
      duration: CareerSpeakMotion.navigation,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(
            builder: (context) {
              transition = CareerSpeakMotion.routeTransition(
                context: context,
                animation: controller,
                hierarchical: true,
                child: const Text('child'),
              );
              return transition;
            },
          ),
        ),
      ),
    );

    expect(transition, isA<FadeTransition>());
    final fade = transition as FadeTransition;
    expect(fade.child, isA<SlideTransition>());
    final slide = fade.child! as SlideTransition;
    expect(slide.position.value.dx, closeTo(-0.04, 0.000001));
  });
}
