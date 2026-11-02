import 'dart:async';

import 'package:careerspeak_app/app/review_schedule_providers.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_review_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Due invalidates exactly at the nearest future review boundary',
    () async {
      const identity = ContentIdentity(
        code: 'BOUNDARY_ITEM',
        type: ContentType.topic,
      );
      var now = DateTime.utc(2026, 11, 1, 10);
      final nextReviewAt = now.add(const Duration(minutes: 5));
      Duration? scheduledDelay;
      void Function()? scheduledCallback;

      final container = ProviderContainer(
        overrides: [
          reviewSchedulesProvider.overrideWith(
            (ref) => Stream<Map<ContentIdentity, ContentReviewState>>.value(
              <ContentIdentity, ContentReviewState>{
                identity: ContentReviewState(
                  identity: identity,
                  nextReviewAt: nextReviewAt,
                  reviewStage: 1,
                ),
              },
            ),
          ),
          reviewClockProvider.overrideWithValue(() => now),
          reviewDueTimerFactoryProvider.overrideWithValue((delay, callback) {
            scheduledDelay = delay;
            scheduledCallback = callback;
            return _FakeTimer();
          }),
        ],
      );
      addTearDown(container.dispose);

      final firstDue = Completer<Set<ContentIdentity>>();
      final subscription = container.listen(dueReviewIdentitiesProvider, (
        previous,
        next,
      ) {
        next.when(
          data: (value) {
            if (!firstDue.isCompleted) firstDue.complete(value);
          },
          error: (error, stackTrace) {
            if (!firstDue.isCompleted) {
              firstDue.completeError(error, stackTrace);
            }
          },
          loading: () {},
        );
      }, fireImmediately: true);
      addTearDown(subscription.close);

      final before = await firstDue.future;
      expect(before, isEmpty);
      expect(scheduledDelay, const Duration(minutes: 5));
      expect(scheduledCallback, isNotNull);

      now = nextReviewAt;
      scheduledCallback!();
      await Future<void>.delayed(Duration.zero);

      final atBoundary = container.read(dueReviewIdentitiesProvider);
      expect(atBoundary.requireValue, contains(identity));
    },
  );

  test('Due schedules only the earliest future boundary', () async {
    const first = ContentIdentity(code: 'FIRST', type: ContentType.topic);
    const second = ContentIdentity(code: 'SECOND', type: ContentType.topic);
    final now = DateTime.utc(2026, 11, 1, 10);
    Duration? scheduledDelay;

    final container = ProviderContainer(
      overrides: [
        reviewSchedulesProvider.overrideWith(
          (ref) => Stream<Map<ContentIdentity, ContentReviewState>>.value(
            <ContentIdentity, ContentReviewState>{
              first: ContentReviewState(
                identity: first,
                nextReviewAt: now.add(const Duration(minutes: 10)),
                reviewStage: 1,
              ),
              second: ContentReviewState(
                identity: second,
                nextReviewAt: now.add(const Duration(minutes: 3)),
                reviewStage: 2,
              ),
            },
          ),
        ),
        reviewClockProvider.overrideWithValue(() => now),
        reviewDueTimerFactoryProvider.overrideWithValue((delay, callback) {
          scheduledDelay = delay;
          return _FakeTimer();
        }),
      ],
    );
    addTearDown(container.dispose);

    final firstDue = Completer<Set<ContentIdentity>>();
    final subscription = container.listen(dueReviewIdentitiesProvider, (
      previous,
      next,
    ) {
      next.when(
        data: (value) {
          if (!firstDue.isCompleted) firstDue.complete(value);
        },
        error: (error, stackTrace) {
          if (!firstDue.isCompleted) {
            firstDue.completeError(error, stackTrace);
          }
        },
        loading: () {},
      );
    }, fireImmediately: true);
    addTearDown(subscription.close);

    await firstDue.future;
    expect(scheduledDelay, const Duration(minutes: 3));
  });
}

final class _FakeTimer implements Timer {
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;

  @override
  void cancel() {
    _active = false;
  }
}
