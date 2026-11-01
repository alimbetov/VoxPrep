import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/application/review/review_scheduler.dart';
import 'package:careerspeak_app/data/local/drift_review_schedule_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_review_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  group('DriftReviewScheduleRepository', () {
    const identity = ContentIdentity(
      code: 'JAVA_REVIEW_01',
      type: ContentType.topic,
    );

    test(
      'schema v16 persists explicit review schedule across reopen',
      () async {
        final database = createTestDatabase();
        addTearDown(database.close);
        expect(database.schemaVersion, greaterThanOrEqualTo(16));
        final now = DateTime.utc(2026, 11, 1, 10);
        final repository = DriftReviewScheduleRepository(
          database,
          now: () => now,
        );

        final write = await repository.upsertSchedule(
          identity: identity,
          nextReviewAt: now.add(const Duration(days: 2)),
          reviewStage: 3,
          lastReviewOutcome: ReviewOutcome.correct,
        );
        expect(write, isA<Success<ContentReviewState>>());

        final reopened = DriftReviewScheduleRepository(database);
        final read = await reopened.getSchedules();
        final state =
            (read as Success<Map<ContentIdentity, ContentReviewState>>)
                .value[identity]!;

        expect(state.nextReviewAt, now.add(const Duration(days: 2)));
        expect(state.reviewStage, 3);
        expect(state.lastReviewOutcome, ReviewOutcome.correct);
      },
    );

    test('R1 scheduler decision survives repository reopen', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 11, 1, 10);
      final repository = DriftReviewScheduleRepository(
        database,
        now: () => now,
      );
      await repository.upsertSchedule(
        identity: identity,
        nextReviewAt: now,
        reviewStage: 1,
      );
      final scheduler = ReviewScheduler(repository: repository, now: () => now);

      final result = await scheduler.recordOutcome(
        identity: identity,
        currentStage: 1,
        outcome: ReviewOutcome.correct,
      );
      expect(result, isA<Success<ContentReviewState>>());

      final reopened = DriftReviewScheduleRepository(database);
      final read = await reopened.getSchedules();
      final state = (read as Success<Map<ContentIdentity, ContentReviewState>>)
          .value[identity]!;

      expect(state.reviewStage, 2);
      expect(state.lastReviewOutcome, ReviewOutcome.correct);
      expect(state.nextReviewAt, now.add(const Duration(days: 4)));
      expect(state.isDueAt(now), isFalse);
    });

    test('due predicate is inclusive at nextReviewAt boundary', () {
      final now = DateTime.utc(2026, 11, 1, 10);
      final due = ContentReviewState(
        identity: identity,
        nextReviewAt: now,
        reviewStage: 1,
      );
      final future = ContentReviewState(
        identity: identity,
        nextReviewAt: now.add(const Duration(microseconds: 1)),
        reviewStage: 1,
      );

      expect(due.isDueAt(now), isTrue);
      expect(future.isDueAt(now), isFalse);
    });

    test('clear removes explicit review schedule', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 11, 1, 10);
      final repository = DriftReviewScheduleRepository(
        database,
        now: () => now,
      );

      await repository.upsertSchedule(
        identity: identity,
        nextReviewAt: now,
        reviewStage: 0,
      );
      expect(await repository.clearSchedule(identity), isA<Success<void>>());

      final read = await repository.getSchedules();
      expect(
        (read as Success<Map<ContentIdentity, ContentReviewState>>).value,
        isEmpty,
      );
    });

    test('invalid negative review stage fails closed', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 11, 1, 10);
      final repository = DriftReviewScheduleRepository(database);

      final result = await repository.upsertSchedule(
        identity: identity,
        nextReviewAt: now,
        reviewStage: -1,
      );

      expect(result, isA<FailureResult<ContentReviewState>>());
      expect(
        (result as FailureResult<ContentReviewState>).failure.code,
        'REVIEW_SCHEDULE_INVALID',
      );
    });
  });
}
