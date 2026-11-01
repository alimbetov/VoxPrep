import 'dart:async';

import '../../application/ports/learner_selection_repository.dart';
import '../../application/result/result.dart';
import '../../domain/learner_selection.dart';
import 'database/careerspeak_database.dart';

final class DriftLearnerSelectionRepository
    implements LearnerSelectionRepository {
  DriftLearnerSelectionRepository(this._database, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final DateTime Function() _now;
  final StreamController<Result<LearnerSelection>> _changes =
      StreamController<Result<LearnerSelection>>.broadcast();

  @override
  Stream<Result<LearnerSelection>> watchSelection() async* {
    yield await getSelection();
    yield* _changes.stream;
  }

  @override
  Future<Result<LearnerSelection>> getSelection() async {
    try {
      return Success<LearnerSelection>(await _readSelection());
    } catch (error) {
      return FailureResult<LearnerSelection>(
        _failure('LEARNER_SELECTION_READ_FAILED', error),
      );
    }
  }

  @override
  Future<Result<LearnerSelection>> compareAndSet({
    required int expectedGeneration,
    required LearnerSelection next,
  }) async {
    if (expectedGeneration < 0) {
      return FailureResult<LearnerSelection>(
        ApplicationFailure(
          code: 'LEARNER_SELECTION_INVALID_GENERATION',
          message: 'Learner selection generation must not be negative.',
          details: <String, Object?>{'generation': expectedGeneration},
        ),
      );
    }

    try {
      final result = await _database.transaction<Result<LearnerSelection>>(
        () async {
          final current = await _readSelection();
          if (current.generation != expectedGeneration) {
            return FailureResult<LearnerSelection>(
              ApplicationFailure(
                code: 'LEARNER_SELECTION_CONFLICT',
                message: 'Learner selection changed before this update.',
                retryable: true,
                details: <String, Object?>{
                  'expectedGeneration': expectedGeneration,
                  'actualGeneration': current.generation,
                },
              ),
            );
          }

          final persisted = next.withGeneration(current.generation + 1);
          await _database.customStatement(
            '''
            UPDATE learner_selection
            SET selected_goal_code = ?,
                selected_track_code = ?,
                self_assessed_level_code = ?,
                level_decision_made = ?,
                generation = ?,
                updated_at = ?
            WHERE id = 1 AND generation = ?
            ''',
            <Object?>[
              persisted.selectedGoalCode,
              persisted.selectedTrackCode,
              persisted.selfAssessedLevelCode,
              persisted.levelDecisionMade ? 1 : 0,
              persisted.generation,
              _now().millisecondsSinceEpoch,
              expectedGeneration,
            ],
          );
          final changesRow = await _database
              .customSelect('SELECT changes() AS affected_rows')
              .getSingle();
          if (changesRow.read<int>('affected_rows') != 1) {
            return FailureResult<LearnerSelection>(
              const ApplicationFailure(
                code: 'LEARNER_SELECTION_CONFLICT',
                message: 'Learner selection changed before this update.',
                retryable: true,
              ),
            );
          }
          return Success<LearnerSelection>(persisted);
        },
      );

      if (result case Success<LearnerSelection>()) {
        _changes.add(result);
      }
      return result;
    } catch (error) {
      return FailureResult<LearnerSelection>(
        _failure('LEARNER_SELECTION_WRITE_FAILED', error),
      );
    }
  }

  Future<LearnerSelection> _readSelection() async {
    final row = await _database.customSelect('''
      SELECT
        selected_goal_code,
        selected_track_code,
        self_assessed_level_code,
        level_decision_made,
        generation
      FROM learner_selection
      WHERE id = 1
      ''').getSingle();

    return LearnerSelection(
      selectedGoalCode: row.readNullable<String>('selected_goal_code'),
      selectedTrackCode: row.readNullable<String>('selected_track_code'),
      selfAssessedLevelCode: row.readNullable<String>(
        'self_assessed_level_code',
      ),
      levelDecisionMade: row.read<int>('level_decision_made') == 1,
      generation: row.read<int>('generation'),
    );
  }

  static ApplicationFailure _failure(String code, Object error) {
    return ApplicationFailure(
      code: code,
      message: 'Learner learning-direction state is temporarily unavailable.',
      retryable: true,
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}
