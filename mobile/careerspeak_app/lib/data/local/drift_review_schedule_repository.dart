import 'dart:async';

import '../../application/ports/review_schedule_repository.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_review_state.dart';
import 'content_type_storage.dart';
import 'database/careerspeak_database.dart';

final class DriftReviewScheduleRepository implements ReviewScheduleRepository {
  DriftReviewScheduleRepository(
    this._database, {
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final DateTime Function() _now;
  final StreamController<Result<Map<ContentIdentity, ContentReviewState>>>
      _changes = StreamController<
        Result<Map<ContentIdentity, ContentReviewState>>
      >.broadcast();

  @override
  Stream<Result<Map<ContentIdentity, ContentReviewState>>> watchSchedules()
      async* {
    yield await getSchedules();
    yield* _changes.stream;
  }

  @override
  Future<Result<Map<ContentIdentity, ContentReviewState>>> getSchedules() async {
    try {
      final rows = await _database.customSelect('''
        SELECT
          content_code,
          content_type,
          next_review_at,
          review_stage,
          last_review_outcome
        FROM content_review_states
        ORDER BY content_type, content_code
      ''').get();
      final states = <ContentIdentity, ContentReviewState>{};
      for (final row in rows) {
        final identity = ContentIdentity(
          code: row.read<String>('content_code'),
          type: contentTypeFromStorage(row.read<String>('content_type')),
        );
        final outcomeValue = row.readNullable<String>('last_review_outcome');
        final outcome = outcomeValue == null
            ? null
            : ReviewOutcome.values.byName(outcomeValue);
        final state = ContentReviewState(
          identity: identity,
          nextReviewAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('next_review_at'),
            isUtc: true,
          ),
          reviewStage: row.read<int>('review_stage'),
          lastReviewOutcome: outcome,
        );
        if (state.reviewStage < 0 ||
            state.nextReviewAt.millisecondsSinceEpoch <= 0) {
          throw const FormatException('invalid review state');
        }
        states[identity] = state;
      }
      return Success<Map<ContentIdentity, ContentReviewState>>(
        Map<ContentIdentity, ContentReviewState>.unmodifiable(states),
      );
    } on Object catch (error) {
      return FailureResult<Map<ContentIdentity, ContentReviewState>>(
        _failure('REVIEW_SCHEDULE_READ_FAILED', error),
      );
    }
  }

  @override
  Future<Result<ContentReviewState>> upsertSchedule({
    required ContentIdentity identity,
    required DateTime nextReviewAt,
    required int reviewStage,
    ReviewOutcome? lastReviewOutcome,
  }) async {
    final code = identity.code.trim();
    final next = nextReviewAt.toUtc();
    if (code.isEmpty ||
        reviewStage < 0 ||
        next.millisecondsSinceEpoch <= 0) {
      return const FailureResult<ContentReviewState>(
        ApplicationFailure(
          code: 'REVIEW_SCHEDULE_INVALID',
          message: 'Review schedule state is invalid.',
        ),
      );
    }

    final persisted = ContentReviewState(
      identity: ContentIdentity(code: code, type: identity.type),
      nextReviewAt: next,
      reviewStage: reviewStage,
      lastReviewOutcome: lastReviewOutcome,
    );
    try {
      final updatedAt = _now().toUtc();
      await _database.customStatement(
        '''
        INSERT INTO content_review_states (
          content_code,
          content_type,
          next_review_at,
          review_stage,
          last_review_outcome,
          updated_at
        ) VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(content_code, content_type) DO UPDATE SET
          next_review_at = excluded.next_review_at,
          review_stage = excluded.review_stage,
          last_review_outcome = excluded.last_review_outcome,
          updated_at = excluded.updated_at
        ''',
        <Object?>[
          code,
          contentTypeToStorage(identity.type),
          next.millisecondsSinceEpoch,
          reviewStage,
          lastReviewOutcome?.name,
          updatedAt.millisecondsSinceEpoch,
        ],
      );
      final snapshot = await getSchedules();
      if (snapshot case Success<Map<ContentIdentity, ContentReviewState>>()) {
        _changes.add(snapshot);
      }
      return Success<ContentReviewState>(persisted);
    } on Object catch (error) {
      return FailureResult<ContentReviewState>(
        _failure('REVIEW_SCHEDULE_WRITE_FAILED', error),
      );
    }
  }

  @override
  Future<Result<void>> clearSchedule(ContentIdentity identity) async {
    try {
      await _database.customStatement(
        '''
        DELETE FROM content_review_states
        WHERE content_code = ? AND content_type = ?
        ''',
        <Object?>[
          identity.code,
          contentTypeToStorage(identity.type),
        ],
      );
      final snapshot = await getSchedules();
      if (snapshot case Success<Map<ContentIdentity, ContentReviewState>>()) {
        _changes.add(snapshot);
      }
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        _failure('REVIEW_SCHEDULE_CLEAR_FAILED', error),
      );
    }
  }

  static ApplicationFailure _failure(String code, Object error) {
    return ApplicationFailure(
      code: code,
      message: 'Local review schedule is temporarily unavailable.',
      retryable: true,
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}
