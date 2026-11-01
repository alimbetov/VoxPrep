import 'package:careerspeak_app/app/learner_selection_providers.dart';
import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
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
}

Future<void> _pumpHome(
  WidgetTester tester,
  AsyncValue<LearnerLearningContext?> learningContext,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        contentPageProvider.overrideWith(
          (ref) => Stream<app_page.Page<ContentItem>>.value(
            const app_page.Page<ContentItem>(items: [], hasMore: false),
          ),
        ),
        contentMarkersProvider.overrideWith(
          (ref) => Stream<Map<ContentIdentity, ContentMarkerState>>.value(
            const <ContentIdentity, ContentMarkerState>{},
          ),
        ),
        learnerLearningContextProvider.overrideWithValue(learningContext),
      ],
      child: const MaterialApp(home: Scaffold(body: HomeScreen())),
    ),
  );
  await tester.pumpAndSettle();
}
