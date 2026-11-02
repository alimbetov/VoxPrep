import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/ports/practice_test_attempt_repository.dart';
import '../../application/result/result.dart';
import '../../domain/practice_test_attempt.dart';
import '../../domain/practice_test_completion_key.dart';
import 'database/careerspeak_database.dart';
import 'publication_snapshot_storage.dart';

final class DriftPracticeTestAttemptRepository
    implements PracticeTestAttemptRepository {
  DriftPracticeTestAttemptRepository(this._database, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final DateTime Function() _now;

  @override
  Future<Result<PracticeTestAttempt?>> getActiveAttempt() async {
    try {
      final rows = await _database.customSelect('''
        SELECT
          practice_test_code,
          practice_test_revision,
          current_index,
          answers_json,
          started_at,
          updated_at
        FROM practice_test_active_attempt
        WHERE id = 1
      ''').get();
      if (rows.isEmpty) {
        return const Success<PracticeTestAttempt?>(null);
      }
      if (rows.length != 1) {
        return FailureResult<PracticeTestAttempt?>(
          _failure(
            'PRACTICE_TEST_ATTEMPT_INVALID',
            StateError('multiple active attempts'),
          ),
        );
      }

      final row = rows.single;
      final decoded = jsonDecode(row.read<String>('answers_json'));
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('answers_json must be an object');
      }
      final answers = <int, int>{};
      for (final entry in decoded.entries) {
        final questionIndex = int.tryParse(entry.key);
        final optionIndex = entry.value;
        if (questionIndex == null ||
            questionIndex < 0 ||
            optionIndex is! int ||
            optionIndex < 0) {
          throw const FormatException('answers_json contains invalid indexes');
        }
        answers[questionIndex] = optionIndex;
      }

      return Success<PracticeTestAttempt?>(
        PracticeTestAttempt(
          practiceTestCode: row.read<String>('practice_test_code'),
          practiceTestRevision: row.read<int>('practice_test_revision'),
          currentIndex: row.read<int>('current_index'),
          answers: Map<int, int>.unmodifiable(answers),
          startedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('started_at'),
            isUtc: true,
          ),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('updated_at'),
            isUtc: true,
          ),
        ),
      );
    } on Object catch (error) {
      return FailureResult<PracticeTestAttempt?>(
        _failure('PRACTICE_TEST_ATTEMPT_READ_FAILED', error),
      );
    }
  }

  @override
  Future<Result<PracticeTestAttempt>> startActiveAttempt(
    String practiceTestCode,
  ) async {
    final code = practiceTestCode.trim();
    if (code.isEmpty) {
      return const FailureResult<PracticeTestAttempt>(
        ApplicationFailure(
          code: 'PRACTICE_TEST_ATTEMPT_INVALID',
          message: 'Practice-test code must not be blank.',
        ),
      );
    }

    try {
      await PublicationSnapshotStorage(_database).ensureReady();
      final refs = await _database
          .customSelect(
            '''
            SELECT p.revision
            FROM content_manifest_states s
            INNER JOIN publication_practice_test_refs p
              ON p.content_version = s.current_content_version
            WHERE s.id = 1
              AND p.practice_test_code = ?
            ''',
            variables: <Variable<Object>>[Variable<String>(code)],
          )
          .get();
      if (refs.length != 1) {
        return FailureResult<PracticeTestAttempt>(
          ApplicationFailure(
            code: refs.isEmpty
                ? 'PRACTICE_TEST_ATTEMPT_NOT_CURRENT'
                : 'PRACTICE_TEST_ATTEMPT_INVALID',
            message: refs.isEmpty
                ? 'Practice-test is not part of the CURRENT publication.'
                : 'CURRENT practice-test membership is inconsistent.',
            details: <String, Object?>{'practiceTestCode': code},
          ),
        );
      }

      final now = _now().toUtc();
      return await saveActiveAttempt(
        PracticeTestAttempt(
          practiceTestCode: code,
          practiceTestRevision: refs.single.read<int>('revision'),
          currentIndex: 0,
          answers: const <int, int>{},
          startedAt: now,
          updatedAt: now,
        ),
      );
    } on Object catch (error) {
      return FailureResult<PracticeTestAttempt>(
        _failure('PRACTICE_TEST_ATTEMPT_START_FAILED', error),
      );
    }
  }

  @override
  Future<Result<PracticeTestAttempt>> saveActiveAttempt(
    PracticeTestAttempt attempt,
  ) async {
    final validation = _validate(attempt);
    if (validation != null) {
      return FailureResult<PracticeTestAttempt>(validation);
    }

    try {
      final orderedEntries = attempt.answers.entries.toList(growable: false)
        ..sort((left, right) => left.key.compareTo(right.key));
      final answers = <String, int>{
        for (final entry in orderedEntries) entry.key.toString(): entry.value,
      };
      await _database.customStatement(
        '''
        INSERT INTO practice_test_active_attempt (
          id,
          practice_test_code,
          practice_test_revision,
          current_index,
          answers_json,
          started_at,
          updated_at
        ) VALUES (1, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          practice_test_code = excluded.practice_test_code,
          practice_test_revision = excluded.practice_test_revision,
          current_index = excluded.current_index,
          answers_json = excluded.answers_json,
          started_at = excluded.started_at,
          updated_at = excluded.updated_at
        ''',
        <Object?>[
          attempt.practiceTestCode.trim(),
          attempt.practiceTestRevision,
          attempt.currentIndex,
          jsonEncode(answers),
          attempt.startedAt.toUtc().millisecondsSinceEpoch,
          attempt.updatedAt.toUtc().millisecondsSinceEpoch,
        ],
      );
      return Success<PracticeTestAttempt>(attempt);
    } on Object catch (error) {
      return FailureResult<PracticeTestAttempt>(
        _failure('PRACTICE_TEST_ATTEMPT_WRITE_FAILED', error),
      );
    }
  }

  @override
  Future<Result<Set<PracticeTestCompletionKey>>>
  getCompletedPracticeTests() async {
    try {
      final rows = await _database.customSelect('''
        SELECT practice_test_code, practice_test_revision
        FROM practice_test_completions
        ORDER BY practice_test_code, practice_test_revision
      ''').get();
      final completed = <PracticeTestCompletionKey>{};
      for (final row in rows) {
        final code = row.read<String>('practice_test_code').trim();
        final revision = row.read<int>('practice_test_revision');
        if (code.isEmpty || revision <= 0) {
          throw const FormatException('invalid practice-test completion row');
        }
        completed.add(
          PracticeTestCompletionKey(practiceTestCode: code, revision: revision),
        );
      }
      return Success<Set<PracticeTestCompletionKey>>(
        Set<PracticeTestCompletionKey>.unmodifiable(completed),
      );
    } on Object catch (error) {
      return FailureResult<Set<PracticeTestCompletionKey>>(
        _failure('PRACTICE_TEST_COMPLETION_READ_FAILED', error),
      );
    }
  }

  @override
  Future<Result<void>> completeActiveAttempt() async {
    try {
      return await _database.transaction<Result<void>>(() async {
        final rows = await _database.customSelect('''
          SELECT practice_test_code, practice_test_revision
          FROM practice_test_active_attempt
          WHERE id = 1
        ''').get();
        if (rows.isEmpty) return const Success<void>(null);
        if (rows.length != 1) {
          return FailureResult<void>(
            _failure(
              'PRACTICE_TEST_ATTEMPT_INVALID',
              StateError('multiple active attempts'),
            ),
          );
        }

        final row = rows.single;
        final code = row.read<String>('practice_test_code');
        final revision = row.read<int>('practice_test_revision');
        final completedAt = _now().toUtc().millisecondsSinceEpoch;
        if (completedAt <= 0) {
          return FailureResult<void>(
            _failure(
              'PRACTICE_TEST_COMPLETION_WRITE_FAILED',
              StateError('invalid completion timestamp'),
            ),
          );
        }

        await _database.customStatement(
          '''
          INSERT INTO practice_test_completions (
            practice_test_code,
            practice_test_revision,
            completed_at
          ) VALUES (?, ?, ?)
          ON CONFLICT(practice_test_code, practice_test_revision)
          DO UPDATE SET completed_at = excluded.completed_at
          ''',
          <Object?>[code, revision, completedAt],
        );
        await _database.customStatement(
          '''
          DELETE FROM practice_test_active_attempt
          WHERE id = 1
            AND practice_test_code = ?
            AND practice_test_revision = ?
          ''',
          <Object?>[code, revision],
        );
        return const Success<void>(null);
      });
    } on Object catch (error) {
      return FailureResult<void>(
        _failure('PRACTICE_TEST_COMPLETION_WRITE_FAILED', error),
      );
    }
  }

  @override
  Future<Result<void>> clearActiveAttempt() async {
    try {
      await _database.customStatement(
        'DELETE FROM practice_test_active_attempt WHERE id = 1',
      );
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        _failure('PRACTICE_TEST_ATTEMPT_CLEAR_FAILED', error),
      );
    }
  }

  ApplicationFailure? _validate(PracticeTestAttempt attempt) {
    if (attempt.practiceTestCode.trim().isEmpty ||
        attempt.practiceTestRevision <= 0 ||
        attempt.currentIndex < 0 ||
        attempt.startedAt.millisecondsSinceEpoch <= 0 ||
        attempt.updatedAt.isBefore(attempt.startedAt)) {
      return const ApplicationFailure(
        code: 'PRACTICE_TEST_ATTEMPT_INVALID',
        message: 'Practice-test attempt state is invalid.',
      );
    }
    for (final entry in attempt.answers.entries) {
      if (entry.key < 0 || entry.value < 0) {
        return const ApplicationFailure(
          code: 'PRACTICE_TEST_ATTEMPT_INVALID',
          message: 'Practice-test attempt answers contain invalid indexes.',
        );
      }
    }
    return null;
  }

  static ApplicationFailure _failure(String code, Object error) {
    return ApplicationFailure(
      code: code,
      message: 'Practice-test attempt persistence is unavailable.',
      retryable: true,
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}
