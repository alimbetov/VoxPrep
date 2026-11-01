import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/app/review_schedule_providers.dart';
import 'package:careerspeak_app/application/query/page.dart' as app_page;
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/review/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Due includes only explicitly scheduled CURRENT content', (
    tester,
  ) async {
    const dueItem = ContentItem(
      code: 'DUE_ITEM',
      type: ContentType.topic,
      title: 'Explicitly due topic',
      subtitle: 'Due subtitle',
      description: 'Due description',
      category: 'JAVA',
      level: 'B2',
      minutes: 4,
      revision: 1,
      hasAudio: false,
    );
    const incompleteButUnscheduled = ContentItem(
      code: 'UNSCHEDULED_ITEM',
      type: ContentType.topic,
      title: 'Incomplete but unscheduled topic',
      subtitle: 'Unscheduled subtitle',
      description: 'Unscheduled description',
      category: 'JAVA',
      level: 'B2',
      minutes: 4,
      revision: 1,
      hasAudio: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentPageProvider.overrideWith(
            (ref) => Stream<app_page.Page<ContentItem>>.value(
              const app_page.Page<ContentItem>(
                items: <ContentItem>[incompleteButUnscheduled],
                hasMore: false,
              ),
            ),
          ),
          contentMarkersProvider.overrideWith(
            (ref) => Stream<Map<ContentIdentity, ContentMarkerState>>.value(
              const <ContentIdentity, ContentMarkerState>{},
            ),
          ),
          dueReviewItemsProvider.overrideWith(
            (ref) async => const <ContentItem>[dueItem],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ReviewScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 items'), findsOneWidget);
    expect(find.text('Explicitly due topic'), findsOneWidget);
    expect(find.text('Incomplete but unscheduled topic'), findsNothing);
  });

  testWidgets('Due is empty when incomplete content has no schedule', (
    tester,
  ) async {
    const item = ContentItem(
      code: 'UNSCHEDULED',
      type: ContentType.topic,
      title: 'Not due merely because incomplete',
      subtitle: 'Subtitle',
      description: 'Description',
      category: 'JAVA',
      level: 'B2',
      minutes: 4,
      revision: 1,
      hasAudio: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentPageProvider.overrideWith(
            (ref) => Stream<app_page.Page<ContentItem>>.value(
              const app_page.Page<ContentItem>(
                items: <ContentItem>[item],
                hasMore: false,
              ),
            ),
          ),
          contentMarkersProvider.overrideWith(
            (ref) => Stream<Map<ContentIdentity, ContentMarkerState>>.value(
              const <ContentIdentity, ContentMarkerState>{},
            ),
          ),
          dueReviewItemsProvider.overrideWith(
            (ref) async => const <ContentItem>[],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ReviewScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 items'), findsOneWidget);
    expect(find.text('Not due merely because incomplete'), findsNothing);
  });
}
