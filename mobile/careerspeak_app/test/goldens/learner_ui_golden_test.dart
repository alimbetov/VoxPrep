import 'package:careerspeak_app/app/app_preferences_providers.dart';
import 'package:careerspeak_app/app/asset_resolver_providers.dart';
import 'package:careerspeak_app/app/audio_playback_providers.dart';
import 'package:careerspeak_app/app/catalogue_payload_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/application/content_delivery/content_audio_policy.dart';
import 'package:careerspeak_app/application/query/page.dart';
import 'package:careerspeak_app/application/services/role_audio_clip_controller.dart';
import 'package:careerspeak_app/domain/application_preferences.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/features/catalogue/catalogue_home_screen.dart';
import 'package:careerspeak_app/features/content/content_detail_panel.dart';
import 'package:careerspeak_app/features/home/home_screen.dart';
import 'package:careerspeak_app/features/settings/settings_screen.dart';
import 'package:careerspeak_app/features/tests/test_session_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/golden_fixtures.dart';

void main() {
  testWidgets('golden catalogue grid', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      overrides: [
        universalCatalogueRepositoryProvider.overrideWithValue(
          const GoldenUniversalCatalogueRepository(),
        ),
        catalogueIconAssetProvider.overrideWith((ref, assetId) async => null),
      ],
      child: const CatalogueHomeScreen(),
    );

    await expectLater(
      find.byKey(_goldenRootKey),
      matchesGoldenFile('baselines/catalogue_grid.png'),
    );
  });

  testWidgets('golden content detail', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      overrides: [
        learnerStateRepositoryProvider.overrideWithValue(
          const GoldenLearnerStateRepository(),
        ),
      ],
      child: const ContentDetailPanel(
        item: goldenTopic,
        localizedHint: 'Think about happens-before relationships.',
      ),
    );

    await expectLater(
      find.byKey(_goldenRootKey),
      matchesGoldenFile('baselines/content_detail.png'),
    );
  });

  testWidgets('golden interview with question and sample-answer audio', (
    tester,
  ) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      overrides: [
        learnerStateRepositoryProvider.overrideWithValue(
          const GoldenLearnerStateRepository(),
        ),
        interviewAudioAvailableRolesProvider.overrideWith(
          (ref, query) async => const <ContentAudioRole>{
            ContentAudioRole.question,
            ContentAudioRole.sampleAnswer,
          },
        ),
        interviewAudioClipStateProvider.overrideWith(
          (ref) => Stream<RoleAudioClipState>.value(
            const RoleAudioClipState(),
          ),
        ),
      ],
      child: const ContentDetailPanel(item: goldenInterview),
    );

    await expectLater(
      find.byKey(_goldenRootKey),
      matchesGoldenFile('baselines/interview_two_audio_roles.png'),
    );
  });

  testWidgets('golden practice question', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      overrides: [
        practiceTestRepositoryProvider.overrideWithValue(
          const GoldenPracticeTestRepository(),
        ),
      ],
      child: const TestSessionScreen(code: 'JAVA_GOLDEN_TEST'),
    );

    await tester.tap(find.text('Start test'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_goldenRootKey),
      matchesGoldenFile('baselines/practice_question.png'),
    );
  });

  testWidgets('golden practice result', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      overrides: [
        practiceTestRepositoryProvider.overrideWithValue(
          const GoldenPracticeTestRepository(),
        ),
      ],
      child: const TestSessionScreen(code: 'JAVA_GOLDEN_TEST'),
    );

    await tester.tap(find.text('Start test'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('It provides concurrency-oriented'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Submit'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(_goldenRootKey),
      matchesGoldenFile('baselines/practice_result.png'),
    );
  });

  testWidgets('golden settings rtl', (tester) async {
    final preferences = ApplicationPreferences.defaults.copyWith(
      uiLocale: AppUiLocale.arabic,
      translationLocale: AppTranslationLocale.arabic,
    );

    await _pumpGolden(
      tester,
      size: const Size(390, 844),
      textDirection: TextDirection.rtl,
      overrides: [
        appPreferencesRepositoryProvider.overrideWithValue(
          GoldenPreferencesRepository(preferences: preferences),
        ),
      ],
      child: const SettingsScreen(),
    );

    await expectLater(
      find.byKey(_goldenRootKey),
      matchesGoldenFile('baselines/settings_rtl.png'),
    );
  });

  testWidgets('golden small-phone home', (tester) async {
    await _pumpGolden(
      tester,
      size: const Size(320, 568),
      overrides: [
        contentPageProvider.overrideWith(
          (ref) => Stream<Page<ContentItem>>.value(
            const Page<ContentItem>(
              items: <ContentItem>[goldenTopic, goldenInterview],
              hasMore: false,
            ),
          ),
        ),
        learnerStateRepositoryProvider.overrideWithValue(
          const GoldenLearnerStateRepository(),
        ),
      ],
      child: const HomeScreen(),
    );

    await expectLater(
      find.byKey(_goldenRootKey),
      matchesGoldenFile('baselines/home_small_phone.png'),
    );
  });
}

const _goldenRootKey = ValueKey<String>('learner-ui-golden-root');

Future<void> _pumpGolden(
  WidgetTester tester, {
  required Size size,
  required List<Override> overrides,
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
        ),
        home: Directionality(
          textDirection: textDirection,
          child: Scaffold(
            body: RepaintBoundary(
              key: _goldenRootKey,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
