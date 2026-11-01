import 'dart:async';

import 'package:drift/drift.dart';

import '../../application/ports/onboarding_state_repository.dart';
import '../../application/result/result.dart';
import '../../domain/onboarding_state.dart';
import 'database/careerspeak_database.dart';

final class DriftOnboardingStateRepository implements OnboardingStateRepository {
  DriftOnboardingStateRepository(
    this._database, {
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final DateTime Function() _now;
  final StreamController<Result<OnboardingState>> _changes =
      StreamController<Result<OnboardingState>>.broadcast();

  @override
  Stream<Result<OnboardingState>> watchState() async* {
    yield await getState();
    yield* _changes.stream;
  }

  @override
  Future<Result<OnboardingState>> getState() async {
    try {
      return Success<OnboardingState>(await _readState());
    } catch (error) {
      return FailureResult<OnboardingState>(
        _failure('ONBOARDING_STATE_READ_FAILED', error),
      );
    }
  }

  @override
  Future<Result<OnboardingState>> compareAndSet({
    required int expectedGeneration,
    required bool completed,
  }) async {
    if (expectedGeneration < 0) {
      return FailureResult<OnboardingState>(
        const ApplicationFailure(
          code: 'ONBOARDING_STATE_INVALID_GENERATION',
          message: 'Onboarding state generation must not be negative.',
        ),
      );
    }

    try {
      final updated = await _database.customUpdate(
        '''
        UPDATE onboarding_state
        SET completed = ?, generation = generation + 1, updated_at = ?
        WHERE id = 1 AND generation = ?
        ''',
        variables: <Variable<Object>>[
          Variable<int>(completed ? 1 : 0),
          Variable<int>(_now().millisecondsSinceEpoch),
          Variable<int>(expectedGeneration),
        ],
      );
      if (updated != 1) {
        return const FailureResult<OnboardingState>(
          ApplicationFailure(
            code: 'ONBOARDING_STATE_CONFLICT',
            message: 'Onboarding state changed before this update.',
            retryable: true,
          ),
        );
      }

      final state = await _readState();
      final result = Success<OnboardingState>(state);
      _changes.add(result);
      return result;
    } catch (error) {
      return FailureResult<OnboardingState>(
        _failure('ONBOARDING_STATE_WRITE_FAILED', error),
      );
    }
  }

  Future<OnboardingState> _readState() async {
    final row = await _database.customSelect(
      '''
      SELECT completed, generation
      FROM onboarding_state
      WHERE id = 1
      ''',
    ).getSingle();
    return OnboardingState(
      completed: row.read<int>('completed') == 1,
      generation: row.read<int>('generation'),
    );
  }

  static ApplicationFailure _failure(String code, Object error) {
    return ApplicationFailure(
      code: code,
      message: 'Onboarding state is temporarily unavailable.',
      retryable: true,
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}
