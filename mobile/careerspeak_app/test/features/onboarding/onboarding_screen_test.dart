import 'package:careerspeak_app/app/catalogue_payload_providers.dart';
import 'package:careerspeak_app/app/onboarding_providers.dart';
import 'package:careerspeak_app/domain/onboarding_state.dart';
import 'package:careerspeak_app/features/onboarding/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/golden_fixtures.dart';

void main() {
  testWidgets('step 1 exposes only active verticals with active goals', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStepProvider.overrideWithValue(
            const AsyncData(OnboardingStep.learningDirection),
          ),
          universalCatalogueRepositoryProvider.overrideWithValue(
            const GoldenUniversalCatalogueRepository(),
          ),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('What do you want to practise?'), findsOneWidget);
    expect(find.text('Java Interview'), findsOneWidget);
    expect(find.text('Pass Java backend interviews'), findsOneWidget);
    expect(find.text('DevOps Interview'), findsNothing);
    expect(find.text('Medical English'), findsNothing);
  });

  testWidgets('level step offers B1 B2 C1 and Not sure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingStepProvider.overrideWithValue(
            const AsyncData(OnboardingStep.englishLevel),
          ),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('B1 — Intermediate'), findsOneWidget);
    expect(find.text('B2 — Upper intermediate'), findsOneWidget);
    expect(find.text('C1 — Advanced'), findsOneWidget);
    expect(find.text('Not sure'), findsOneWidget);
  });
}
