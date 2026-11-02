import '../../application/access/access_snapshot.dart';
import '../../application/content_delivery/product_catalog.dart';
import '../../application/ports/access_snapshot_repository.dart';
import '../../application/result/result.dart';
import 'database/careerspeak_database.dart';

final class DriftAccessSnapshotRepository implements AccessSnapshotRepository {
  const DriftAccessSnapshotRepository(this._database);

  final CareerSpeakDatabase _database;

  @override
  Future<Result<AccessSnapshot?>> read() async {
    try {
      final row = await _database.customSelect('''
        SELECT access_level, verified_at, source
        FROM learner_access_snapshot
        WHERE id = 1
      ''').getSingleOrNull();
      if (row == null) {
        return const Success<AccessSnapshot?>(null);
      }

      return Success<AccessSnapshot?>(
        AccessSnapshot(
          accessLevel: AccessLevel.fromWireName(
            row.read<String>('access_level'),
          ),
          verifiedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('verified_at'),
            isUtc: true,
          ),
          source: AccessSnapshotSource.fromWireName(row.read<String>('source')),
        ),
      );
    } on Object catch (error) {
      return FailureResult<AccessSnapshot?>(
        ApplicationFailure(
          code: 'ACCESS_SNAPSHOT_READ_FAILED',
          message: 'Saved access state is temporarily unavailable.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }

  @override
  Future<Result<void>> replace(AccessSnapshot snapshot) async {
    try {
      final updatedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
      await _database.customStatement(
        '''
        INSERT INTO learner_access_snapshot (
          id, access_level, verified_at, source, updated_at
        ) VALUES (1, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
          access_level = excluded.access_level,
          verified_at = excluded.verified_at,
          source = excluded.source,
          updated_at = excluded.updated_at
        ''',
        <Object?>[
          snapshot.accessLevel.wireName,
          snapshot.verifiedAt.millisecondsSinceEpoch,
          snapshot.source.wireName,
          updatedAt,
        ],
      );
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'ACCESS_SNAPSHOT_WRITE_FAILED',
          message: 'Verified access state could not be saved.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }
}
