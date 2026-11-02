import 'dart:async';

import 'package:careerspeak_app/app/learner_state_providers.dart';
import 'package:careerspeak_app/app/repository_providers.dart';
import 'package:careerspeak_app/app/review_schedule_providers.dart';
import 'package:careerspeak_app/application/ports/content_repository.dart';
import 'package:careerspeak_app/application/ports/review_schedule_repository.dart';
import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/query/page.dart' as app_page;
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_marker_state.dart';
import 'package:careerspeak_app/domain/content_review_state.dart';
import 'package:careerspeak_app/features/review/review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Correct persists deterministic schedule and removes item from Due',
    (tester) async {
      final now = DateTime.utc(2026, 11, 1, 10);
      const item = ContentItem(
        code: 'R1_TOPIC',
        type: ContentType.topic,
        title: 'R1 due topic',
        subtitle: 'Review me',
        description: 'R1 integration fixture',
        category: 'JAVA',
        level: 'B2',
        minutes: 4,
        revision: 3,
        hasAudio: false,
      );
      const identity = ContentIdentity(
        code: 'R1_TOPIC',
        type: ContentType.topic,
      );
      final schedules = _ReviewSchedules(<ContentIdentity, ContentReviewState>{
        identity: ContentReviewState(
          identity: identity,
          nextReviewAt: now,
          reviewStage: 1,
        ),
      });
      final content = _ContentRepository(item);
      addTearDown(schedules.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentRepositoryProvider.overrideWithValue(content),
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
            reviewScheduleRepositoryProvider.overrideWithValue(schedules),
            reviewClockProvider.overrideWithValue(() => now),
          ],
          child: const MaterialApp(home: Scaffold(body: ReviewScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('R1 due topic'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Known'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Correct'), findsOneWidget);

      await tester.tap(find.text('Correct'));
      await tester.pumpAndSettle();

      final persisted = schedules.values[identity];
      expect(persisted, isNotNull);
      expect(persisted!.reviewStage, 2);
      expect(persisted.lastReviewOutcome, ReviewOutcome.correct);
      expect(persisted.nextReviewAt, now.add(const Duration(days: 4)));

      expect(find.text('R1 due topic'), findsNothing);
      expect(find.text('0 items'), findsOneWidget);
    },
  );
}

final class _ContentRepository implements ContentRepository {
  const _ContentRepository(this.item);

  final ContentItem item;

  @override
  Stream<Result<app_page.Page<ContentItem>>> watchContent(ContentQuery query) =>
      Stream<Result<app_page.Page<ContentItem>>>.value(
        Success<app_page.Page<ContentItem>>(
          app_page.Page<ContentItem>(
            items: <ContentItem>[item],
            hasMore: false,
          ),
        ),
      );

  @override
  Future<Result<ContentItem?>> getByIdentity(ContentIdentity identity) async {
    return Success<ContentItem?>(
      identity == ContentIdentity.fromItem(item) ? item : null,
    );
  }
}

final class _ReviewSchedules implements ReviewScheduleRepository {
  _ReviewSchedules(Map<ContentIdentity, ContentReviewState> initial)
    : values = Map<ContentIdentity, ContentReviewState>.from(initial);

  final Map<ContentIdentity, ContentReviewState> values;
  final StreamController<Result<Map<ContentIdentity, ContentReviewState>>>
  _changes =
      StreamController<
        Result<Map<ContentIdentity, ContentReviewState>>
      >.broadcast();

  @override
  Stream<Result<Map<ContentIdentity, ContentReviewState>>>
  watchSchedules() async* {
    yield Success<Map<ContentIdentity, ContentReviewState>>(
      Map<ContentIdentity, ContentReviewState>.unmodifiable(values),
    );
    yield* _changes.stream;
  }

  @override
  Future<Result<Map<ContentIdentity, ContentReviewState>>>
  getSchedules() async {
    return Success<Map<ContentIdentity, ContentReviewState>>(
      Map<ContentIdentity, ContentReviewState>.unmodifiable(values),
    );
  }

  @override
  Future<Result<ContentReviewState>> upsertSchedule({
    required ContentIdentity identity,
    required DateTime nextReviewAt,
    required int reviewStage,
    ReviewOutcome? lastReviewOutcome,
  }) async {
    final state = ContentReviewState(
      identity: identity,
      nextReviewAt: nextReviewAt,
      reviewStage: reviewStage,
      lastReviewOutcome: lastReviewOutcome,
    );
    values[identity] = state;
    _changes.add(
      Success<Map<ContentIdentity, ContentReviewState>>(
        Map<ContentIdentity, ContentReviewState>.unmodifiable(values),
      ),
    );
    return Success<ContentReviewState>(state);
  }

  @override
  Future<Result<void>> clearSchedule(ContentIdentity identity) async {
    values.remove(identity);
    _changes.add(
      Success<Map<ContentIdentity, ContentReviewState>>(
        Map<ContentIdentity, ContentReviewState>.unmodifiable(values),
      ),
    );
    return const Success<void>(null);
  }

  Future<void> dispose() => _changes.close();
}
