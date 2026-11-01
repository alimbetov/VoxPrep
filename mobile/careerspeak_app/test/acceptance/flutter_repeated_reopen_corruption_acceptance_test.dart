import 'dart:io';

import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_last_opened_content_repository.dart';
import 'package:careerspeak_app/data/local/drift_practice_test_attempt_repository.dart';
import 'package:careerspeak_app/data/local/drift_review_schedule_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/content_review_state.dart';
import 'package:careerspeak_app/domain/practice_test_attempt.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'repeated cold reopen isolates corrupt practice state and survives repair',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak_adversarial_reopen_',
      );
      final file = File('${directory.path}/careerspeak.sqlite');
      const identity = ContentIdentity(
        code: 'CONTENT_REOPEN_1',
        type: ContentType.topic,
      );
      final openedAt = DateTime.utc(2026, 11, 1, 8);
      final reviewAt = DateTime.utc(2026, 11, 2, 8);
      final attemptStartedAt = DateTime.utc(2026, 11, 1, 8, 30);

      CareerSpeakDatabase? database;
      try {
        database = CareerSpeakDatabase(NativeDatabase(file));
        final lastOpened = DriftLastOpenedContentRepository(
          database,
          now: () => openedAt,
        );
        final review = DriftReviewScheduleRepository(database);
        final initialPractice = DriftPracticeTestAttemptRepository(database);

        expect(
          await lastOpened.recordOpened(identity: identity, contentRevision: 7),
          isA<Success>(),
        );
        expect(
          await review.upsertSchedule(
            identity: identity,
            nextReviewAt: reviewAt,
            reviewStage: 3,
            lastReviewOutcome: ReviewOutcome.hard,
          ),
          isA<Success>(),
        );
        expect(
          await initialPractice.saveActiveAttempt(
            PracticeTestAttempt(
              practiceTestCode: 'TEST_REOPEN_1',
              practiceTestRevision: 5,
              currentIndex: 2,
              answers: const <int, int>{0: 1, 1: 0},
              startedAt: attemptStartedAt,
              updatedAt: attemptStartedAt.add(const Duration(minutes: 5)),
            ),
          ),
          isA<Success>(),
        );

        await database.close();
        database = null;

        for (var cycle = 0; cycle < 3; cycle += 1) {
          database = CareerSpeakDatabase(NativeDatabase(file));
          await _expectHealthyState(
            database,
            identity: identity,
            reviewAt: reviewAt,
          );
          await database.close();
          database = null;
        }

        database = CareerSpeakDatabase(NativeDatabase(file));
        await database.customStatement(
          "UPDATE practice_test_active_attempt SET answers_json = '{broken-json' WHERE id = 1",
        );
        await database.close();
        database = null;

        database = CareerSpeakDatabase(NativeDatabase(file));
        final corruptPractice = await DriftPracticeTestAttemptRepository(
          database,
        ).getActiveAttempt();
        expect(corruptPractice, isA<FailureResult<PracticeTestAttempt?>>());
        expect(
          (corruptPractice as FailureResult<PracticeTestAttempt?>).failure.code,
          'PRACTICE_TEST_ATTEMPT_READ_FAILED',
        );

        // Corruption of one learner aggregate must not poison unrelated state.
        await _expectDurableNeighbourState(
          database,
          identity: identity,
          reviewAt: reviewAt,
        );

        final practice = DriftPracticeTestAttemptRepository(database);
        expect(await practice.clearActiveAttempt(), isA<Success<void>>());
        final repairedAt = attemptStartedAt.add(const Duration(hours: 1));
        expect(
          await practice.saveActiveAttempt(
            PracticeTestAttempt(
              practiceTestCode: 'TEST_REOPEN_1',
              practiceTestRevision: 5,
              currentIndex: 1,
              answers: const <int, int>{0: 2},
              startedAt: repairedAt,
              updatedAt: repairedAt.add(const Duration(minutes: 1)),
            ),
          ),
          isA<Success>(),
        );
        await database.close();
        database = null;

        for (var cycle = 0; cycle < 2; cycle += 1) {
          database = CareerSpeakDatabase(NativeDatabase(file));
          await _expectHealthyState(
            database,
            identity: identity,
            reviewAt: reviewAt,
            expectedPracticeIndex: 1,
            expectedAnswers: const <int, int>{0: 2},
          );
          await database.close();
          database = null;
        }
      } finally {
        await database?.close();
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}

Future<void> _expectHealthyState(
  CareerSpeakDatabase database, {
  required ContentIdentity identity,
  required DateTime reviewAt,
  int expectedPracticeIndex = 2,
  Map<int, int> expectedAnswers = const <int, int>{0: 1, 1: 0},
}) async {
  await _expectDurableNeighbourState(
    database,
    identity: identity,
    reviewAt: reviewAt,
  );

  final attempt = (await DriftPracticeTestAttemptRepository(
    database,
  ).getActiveAttempt()).getOrThrow();
  expect(attempt, isNotNull);
  expect(attempt!.practiceTestCode, 'TEST_REOPEN_1');
  expect(attempt.practiceTestRevision, 5);
  expect(attempt.currentIndex, expectedPracticeIndex);
  expect(attempt.answers, expectedAnswers);
}

Future<void> _expectDurableNeighbourState(
  CareerSpeakDatabase database, {
  required ContentIdentity identity,
  required DateTime reviewAt,
}) async {
  final opened = (await DriftLastOpenedContentRepository(
    database,
  ).getLastOpenedContent()).getOrThrow();
  expect(opened, isNotNull);
  expect(opened!.identity, identity);
  expect(opened.contentRevision, 7);

  final schedules = (await DriftReviewScheduleRepository(
    database,
  ).getSchedules()).getOrThrow();
  expect(schedules.keys, contains(identity));
  final state = schedules[identity]!;
  expect(state.nextReviewAt, reviewAt);
  expect(state.reviewStage, 3);
  expect(state.lastReviewOutcome, ReviewOutcome.hard);
}
