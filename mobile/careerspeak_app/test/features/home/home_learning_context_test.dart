import 'package:careerspeak_app/app/continue_learning_providers.dart';
import 'package:careerspeak_app/app/learner_selection_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/app/review_schedule_providers.dart';
import 'package:careerspeak_app/application/continue_learning/continue_learning_resolver.dart';
import 'package:careerspeak_app/application/query/page.dart' as app_page;
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('O4 Home exposes choose-direction state when no goal exists', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      const AsyncData<LearnerLearningContext?>(null),
    );

    expect(find.text('Choose learning direction'), findsOneWidget);
    expect(find.text('Choose'), findsOneWidget);
  });

  testWidgets('O4 Home exposes current Vertical and Goal context', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      const AsyncData<LearnerLearningContext?>(
        (
          verticalCode: 'JAVA',
          verticalTitle: 'Java Interview',
          goalCode: 'JOB_INTERVIEW',
          goalTitle: 'Pass Java backend interviews',
        ),
      ),
    );

    expect(find.text('Java Interview'), findsOneWidget);
    expect(find.text('Pass Java backend interviews'), findsOneWidget);
    expect(find.text('Change'), findsOneWidget);
  });

  testWidgets('BA-04 Home renders the resolved Continue Learning target', (
    tester,
  ) async {
    await _pumpHome(
      tester,
      const AsyncData<LearnerLearningContext?>(null),
      continueTarget: const ContinueLearningHomeTarget(
        decision: BrowseVerticalDecision('TECH'),
        location: '/catalogue/vertical/TECH',
        title: 'Browse your learning direction',
        subtitle: 'TECH',
      ),
    );

    expect(find.text('Browse your learning direction'), findsOneWidget);
    expect(find.text('TECH'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });

  testWidgets('Home Due count uses all CURRENT resolved due items', (
    tester,
  ) async {
    const dueItem = ContentItem(
      code: 'DUE',
      type: ContentType.topic,
      title: 'Due topic',
      subtitle: 'Due subtitle',
      description: 'Due description',
      category: 'JAVA',
      level: 'B2',
      minutes: 4,
      revision: 1,
      hasAudio: false,
    );
    await _pumpHome(
      tester,
      const AsyncData<LearnerLearningContext?>(null),
      items: const <ContentItem>[],
      dueItems: const <ContentItem>[dueItem],
    );

    expect(find.text('Due'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester,
  AsyncValue<LearnerLearningContext?> learningContext, {
  ContinueLearningHomeTarget continueTarget = const ContinueLearningHomeTarget(
    decision: BrowseVerticalDecision('DEFAULT_VERTICAL'),
    location: '/catalogue',
    title: 'Resume learning',
    subtitle: 'Your CURRENT learning path',
  ),
  List<ContentItem> items = const <ContentItem>[],
  List<ContentItem> dueItems = const <ContentItem>[],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentPageProvider.overrideWith(
          (ref) => Stream<app_page.Page<ContentItem>>.value(
            app_page.Page<ContentItem>(items: items, hasMore: false),
          ),
        ),
        contentMarkersProvider.overrideWith(
          (ref) => Stream<Map<ContentIdentity, ContentMarkerState>>.value(
            const <ContentIdentity, ContentMarkerState>{},
          ),
        ),
        dueReviewItemsProvider.overrideWith((ref) async => dueItems),
        learnerLearningContextProvider.overrideWithValue(learningContext),
        continueLearningHomeTargetProvider.overrideWith(
          (ref) async => continueTarget,
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: HomeScreen())),
    ),
  );
  await tester.pumpAndSettle();
}
