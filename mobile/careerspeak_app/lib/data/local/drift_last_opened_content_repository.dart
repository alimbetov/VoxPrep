import '../../application/ports/last_opened_content_repository.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';
import '../../domain/last_opened_content.dart';
import 'content_type_storage.dart';
import 'database/careerspeak_database.dart';

final class DriftLastOpenedContentRepository
    implements LastOpenedContentRepository {
  DriftLastOpenedContentRepository(
    this._database, {
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final DateTime Function() _now;

  @override
  Future<Result<LastOpenedContent?>> getLastOpenedContent() async {
    try {
      final rows = await _database.customSelect('''
        SELECT content_code, content_type, content_revision, opened_at
        FROM learner_last_opened_content
        WHERE id = 1
      ''').get();
      if (rows.isEmpty) {
        return const Success<LastOpenedContent?>(null);
      }
      if (rows.length != 1) {
        return FailureResult<LastOpenedContent?>(
          _failure(
            'LAST_OPENED_CONTENT_INVALID',
            StateError('multiple last-opened rows'),
          ),
        );
      }

      final row = rows.single;
      return Success<LastOpenedContent?>(
        LastOpenedContent(
          identity: ContentIdentity(
            code: row.read<String>('content_code'),
            type: contentTypeFromStorage(row.read<String>('content_type')),
          ),
          contentRevision: row.read<int>('content_revision'),
          openedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('opened_at'),
            isUtc: true,
          ),
        ),
      );
    } on Object catch (error) {
      return FailureResult<LastOpenedContent?>(
        _failure('LAST_OPENED_CONTENT_READ_FAILED', error),
      );
    }
  }

  @override
  Future<Result<LastOpenedContent>> recordOpened({
    required ContentIdentity identity,
    required int contentRevision,
  }) async {
    final code = identity.code.trim();
    if (code.isEmpty || contentRevision <= 0) {
      return const FailureResult<LastOpenedContent>(
        ApplicationFailure(
          code: 'LAST_OPENED_CONTENT_INVALID',
          message: 'Last-opened content identity or revision is invalid.',
        ),
      );
    }

    final openedAt = _now().toUtc();
    if (openedAt.millisecondsSinceEpoch <= 0) {
      return const FailureResult<LastOpenedContent>(
        ApplicationFailure(
          code: 'LAST_OPENED_CONTENT_INVALID',
          message: 'Last-opened content timestamp is invalid.',
        ),
      );
    }

    try {
      await _database.customStatement(
        '''
        INSERT INTO learner_last_opened_content (
          id,
          content_code,
          content_type,
          content_revision,
          opened_at
        ) VALUES (1, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          content_code = excluded.content_code,
          content_type = excluded.content_type,
          content_revision = excluded.content_revision,
          opened_at = excluded.opened_at
        WHERE excluded.opened_at >= learner_last_opened_content.opened_at
        ''',
        <Object?>[
          code,
          contentTypeToStorage(identity.type),
          contentRevision,
          openedAt.millisecondsSinceEpoch,
        ],
      );

      final persisted = await getLastOpenedContent();
      if (persisted case FailureResult<LastOpenedContent?>(:final failure)) {
        return FailureResult<LastOpenedContent>(failure);
      }
      final value = (persisted as Success<LastOpenedContent?>).value;
      if (value == null) {
        return FailureResult<LastOpenedContent>(
          _failure(
            'LAST_OPENED_CONTENT_WRITE_FAILED',
            StateError('last-opened row missing after write'),
          ),
        );
      }
      return Success<LastOpenedContent>(value);
    } on Object catch (error) {
      return FailureResult<LastOpenedContent>(
        _failure('LAST_OPENED_CONTENT_WRITE_FAILED', error),
      );
    }
  }

  static ApplicationFailure _failure(String code, Object error) {
    return ApplicationFailure(
      code: code,
      message: 'Last-opened content persistence is unavailable.',
      retryable: true,
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}
