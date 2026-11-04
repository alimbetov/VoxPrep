import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/app/review_schedule_providers.dart';
import 'package:careerspeak_app/application/ports/learner_state_repository.dart';
import 'package:careerspeak_app/application/query/page.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/features/home/home_screen.dart';
import 'package:careerspeak_app/features/learn/learn_screen.dart';
import 'package:careerspeak_app/features/review/review_screen.dart';
import 'package:flutter/material.dart' hide Page;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/ui_boundary_harness.dart';

void main() {
  for (final boundary in adaptiveUiBoundaryCases) {
    testWidgets('Home stays visually stable for $boundary', (tester) async {
      await _pump(tester, boundary: boundary, child: const HomeScreen());

      expectNoLayoutExceptions(
        tester,
        reason: 'Home initial viewport must fit $boundary',
      );
      await tester.scrollUntilVisible(
        find.text(_longTitle),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(_longTitle), findsOneWidget);
      await tester.pumpAndSettle();

      expectNoLayoutExceptions(
        tester,
        reason: 'Home full scroll must fit $boundary',
      );
    });

    testWidgets('Learn stays visually stable for $boundary', (tester) async {
      await _pump(tester, boundary: boundary, child: const LearnScreen());

      expectNoLayoutExceptions(
        tester,
        reason: 'Learn initial viewport must fit $boundary',
      );
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text(_longTitle), findsWidgets);

      if (boundary.size.width < 840) {
        await tester.scrollUntilVisible(
          find.text(_longTitle).first,
          240,
          scrollable: find.byType(Scrollable).first,
        );
      }
      await tester.pumpAndSettle();

      expectNoLayoutExceptions(
        tester,
        reason: 'Learn content list/detail must fit $boundary',
      );
    });

    testWidgets('Review stays visually stable for $boundary', (tester) async {
      await _pump(tester, boundary: boundary, child: const ReviewScreen());

      expectNoLayoutExceptions(
        tester,
        reason: 'Review initial viewport must fit $boundary',
      );
      expect(find.text('Review'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text(_longTitle),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(_longTitle), findsOneWidget);
      await tester.pumpAndSettle();

      expectNoLayoutExceptions(
        tester,
        reason: 'Review content card must fit $boundary',
      );
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required UiBoundaryCase boundary,
  required Widget child,
}) async {
  await pumpAdaptiveSurface(
    tester,
    boundary: boundary,
    child: ProviderScope(
      overrides: [
        contentPageProvider.overrideWith(
          (ref) => Stream<Page<ContentItem>>.value(
            const Page<ContentItem>(
              items: <ContentItem>[_item],
              hasMore: false,
            ),
          ),
        ),
        learnerStateRepositoryProvider.overrideWithValue(
          const _LearnerStateRepository(),
        ),
        // Review's default Due filter is driven by the due queue, not the
        // generic content page. Provide the same fixture in both streams.
        dueReviewItemsProvider.overrideWith((ref) async => const [_item]),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

const _longTitle =
    'Очень длинное название учебного материала для профессионального интервью и проверки адаптивной компоновки';

const _item = ContentItem(
  code: 'LONG_UI_CONTENT',
  type: ContentType.topic,
  title: _longTitle,
  subtitle:
      'Длинный подзаголовок с дополнительным контекстом, который должен переноситься без визуальных дефектов.',
  description:
      'Длинное описание учебного материала для проверки узких экранов, планшетов, desktop и крупного accessibility text scale без RenderFlex overflow.',
  category: 'JAVA',
  level: 'B2',
  minutes: 7,
  revision: 1,
  hasAudio: false,
);

final class _LearnerStateRepository implements LearnerStateRepository {
  const _LearnerStateRepository();

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>> watchMarkers() =>
      Stream<Result<Map<ContentIdentity, ContentMarkerState>>>.value(
        const Success<Map<ContentIdentity, ContentMarkerState>>(
          <ContentIdentity, ContentMarkerState>{},
        ),
      );

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  }) async => const Success<void>(null);

  @override
  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  }) async => const Success<void>(null);
}
