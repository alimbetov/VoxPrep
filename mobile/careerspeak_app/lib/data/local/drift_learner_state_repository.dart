import 'package:drift/drift.dart';

import '../../application/ports/learner_state_repository.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';
import '../../domain/content_item.dart';
import '../../domain/content_marker_state.dart';
import 'database/careerspeak_database.dart';

final class DriftLearnerStateRepository implements LearnerStateRepository {
  DriftLearnerStateRepository(this._database, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final DateTime Function() _now;

  @override
  Stream<Result<Map<ContentIdentity, ContentMarkerState>>>
  watchMarkers() async* {
    final query = _database.customSelect(
      '''
SELECT
  content_code,
  content_type,
  MAX(is_favorite) AS is_favorite,
  MAX(is_listened) AS is_listened,
  MAX(is_completed) AS is_completed,
  MAX(last_position_ms) AS last_position_ms
FROM (
  SELECT
    content_code,
    content_type,
    1 AS is_favorite,
    0 AS is_listened,
    0 AS is_completed,
    NULL AS last_position_ms
  FROM favorites

  UNION ALL

  SELECT
    content_code,
    content_type,
    0 AS is_favorite,
    CASE WHEN listened_at IS NULL THEN 0 ELSE 1 END AS is_listened,
    CASE WHEN completed_at IS NULL THEN 0 ELSE 1 END AS is_completed,
    last_position_ms
  FROM content_learning_states
)
GROUP BY content_code, content_type
''',
      readsFrom: {_database.favorites, _database.contentLearningStates},
    );

    try {
      await for (final rows in query.watch()) {
        final markers = <ContentIdentity, ContentMarkerState>{};
        for (final row in rows) {
          final identity = ContentIdentity(
            code: row.read<String>('content_code'),
            type: _contentTypeFromStorage(row.read<String>('content_type')),
          );
          markers[identity] = ContentMarkerState(
            favorite: row.read<int>('is_favorite') != 0,
            listened: row.read<int>('is_listened') != 0,
            completed: row.read<int>('is_completed') != 0,
            lastPositionMs: row.readNullable<int>('last_position_ms'),
          );
        }
        yield Success(Map.unmodifiable(markers));
      }
    } catch (error) {
      yield FailureResult(
        _databaseFailure('LEARNER_STATE_WATCH_FAILED', error),
      );
    }
  }

  @override
  Future<Result<void>> setFavorite(
    ContentIdentity identity, {
    required bool favorite,
  }) async {
    try {
      if (favorite) {
        await _database
            .into(_database.favorites)
            .insertOnConflictUpdate(
              FavoritesCompanion.insert(
                contentCode: identity.code,
                contentType: _contentTypeToStorage(identity.type),
                createdAt: _now(),
              ),
            );
      } else {
        await (_database.delete(_database.favorites)..where(
              (row) =>
                  row.contentCode.equals(identity.code) &
                  row.contentType.equals(_contentTypeToStorage(identity.type)),
            ))
            .go();
      }
      return const Success(null);
    } catch (error) {
      return FailureResult(_databaseFailure('FAVORITE_WRITE_FAILED', error));
    }
  }

  @override
  Future<Result<void>> setListened(
    ContentIdentity identity, {
    required bool listened,
    int? lastRevisionSeen,
  }) async {
    try {
      await _database.transaction(() async {
        final existing = await _learningState(identity);
        final now = _now();

        if (existing == null) {
          await _database
              .into(_database.contentLearningStates)
              .insert(
                ContentLearningStatesCompanion.insert(
                  contentCode: identity.code,
                  contentType: _contentTypeToStorage(identity.type),
                  listenedAt: Value(listened ? now : null),
                  listenCount: Value(listened ? 1 : 0),
                  lastPlayedAt: Value(listened ? now : null),
                  lastRevisionSeen: Value(lastRevisionSeen),
                  updatedAt: now,
                ),
              );
          return;
        }

        final shouldIncrement = listened && existing.listenedAt == null;
        await (_database.update(_database.contentLearningStates)..where(
              (row) =>
                  row.contentCode.equals(identity.code) &
                  row.contentType.equals(_contentTypeToStorage(identity.type)),
            ))
            .write(
              ContentLearningStatesCompanion(
                listenedAt: Value(listened ? now : null),
                listenCount: Value(
                  shouldIncrement
                      ? existing.listenCount + 1
                      : existing.listenCount,
                ),
                lastPlayedAt: listened ? Value(now) : const Value.absent(),
                lastRevisionSeen: lastRevisionSeen == null
                    ? const Value.absent()
                    : Value(lastRevisionSeen),
                updatedAt: Value(now),
              ),
            );
      });
      return const Success(null);
    } catch (error) {
      return FailureResult(_databaseFailure('LISTENED_WRITE_FAILED', error));
    }
  }

  @override
  Future<Result<void>> setCompleted(
    ContentIdentity identity, {
    required bool completed,
    String completionSource = 'USER_ACTION',
    int? lastRevisionSeen,
  }) async {
    try {
      await _database.transaction(() async {
        final existing = await _learningState(identity);
        final now = _now();

        if (existing == null) {
          await _database
              .into(_database.contentLearningStates)
              .insert(
                ContentLearningStatesCompanion.insert(
                  contentCode: identity.code,
                  contentType: _contentTypeToStorage(identity.type),
                  completedAt: Value(completed ? now : null),
                  completionSource: Value(completed ? completionSource : null),
                  lastRevisionSeen: Value(lastRevisionSeen),
                  updatedAt: now,
                ),
              );
          return;
        }

        await (_database.update(_database.contentLearningStates)..where(
              (row) =>
                  row.contentCode.equals(identity.code) &
                  row.contentType.equals(_contentTypeToStorage(identity.type)),
            ))
            .write(
              ContentLearningStatesCompanion(
                completedAt: Value(completed ? now : null),
                completionSource: Value(completed ? completionSource : null),
                lastRevisionSeen: lastRevisionSeen == null
                    ? const Value.absent()
                    : Value(lastRevisionSeen),
                updatedAt: Value(now),
              ),
            );
      });
      return const Success(null);
    } catch (error) {
      return FailureResult(_databaseFailure('COMPLETED_WRITE_FAILED', error));
    }
  }

  @override
  Future<Result<void>> savePlaybackPosition(
    ContentIdentity identity, {
    required int positionMs,
    int? lastRevisionSeen,
  }) async {
    if (positionMs < 0) {
      return const FailureResult(
        ApplicationFailure(
          code: 'INVALID_PLAYBACK_POSITION',
          message: 'Playback position must be zero or greater.',
        ),
      );
    }

    try {
      await _database.transaction(() async {
        final existing = await _learningState(identity);
        final now = _now();

        if (existing == null) {
          await _database
              .into(_database.contentLearningStates)
              .insert(
                ContentLearningStatesCompanion.insert(
                  contentCode: identity.code,
                  contentType: _contentTypeToStorage(identity.type),
                  lastPlayedAt: Value(now),
                  lastPositionMs: Value(positionMs),
                  lastRevisionSeen: Value(lastRevisionSeen),
                  updatedAt: now,
                ),
              );
          return;
        }

        await (_database.update(_database.contentLearningStates)..where(
              (row) =>
                  row.contentCode.equals(identity.code) &
                  row.contentType.equals(_contentTypeToStorage(identity.type)),
            ))
            .write(
              ContentLearningStatesCompanion(
                lastPlayedAt: Value(now),
                lastPositionMs: Value(positionMs),
                lastRevisionSeen: lastRevisionSeen == null
                    ? const Value.absent()
                    : Value(lastRevisionSeen),
                updatedAt: Value(now),
              ),
            );
      });
      return const Success(null);
    } catch (error) {
      return FailureResult(
        _databaseFailure('PLAYBACK_POSITION_WRITE_FAILED', error),
      );
    }
  }

  Future<ContentLearningState?> _learningState(ContentIdentity identity) {
    return (_database.select(_database.contentLearningStates)..where(
          (row) =>
              row.contentCode.equals(identity.code) &
              row.contentType.equals(_contentTypeToStorage(identity.type)),
        ))
        .getSingleOrNull();
  }

  ApplicationFailure _databaseFailure(String code, Object error) {
    return ApplicationFailure(
      code: code,
      message: 'Local learner state persistence failed: $error',
      retryable: true,
    );
  }
}

String _contentTypeToStorage(ContentType type) => switch (type) {
  ContentType.vocabulary => 'VOCABULARY',
  ContentType.interview => 'INTERVIEW',
  ContentType.topic => 'TOPIC',
  ContentType.shadowing => 'SHADOWING',
  ContentType.phrase => 'PHRASE',
};

ContentType _contentTypeFromStorage(String value) => switch (value) {
  'VOCABULARY' => ContentType.vocabulary,
  'INTERVIEW' => ContentType.interview,
  'TOPIC' => ContentType.topic,
  'SHADOWING' => ContentType.shadowing,
  'PHRASE' => ContentType.phrase,
  _ => throw FormatException('Unsupported content type: $value'),
};
