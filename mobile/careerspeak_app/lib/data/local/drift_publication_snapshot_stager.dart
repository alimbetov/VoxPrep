import '../../application/assessment/assessment_revision_loader.dart';
import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/publication_snapshot_stager.dart';
import '../../application/result/result.dart';
import 'database/careerspeak_database.dart';

final class DriftPublicationSnapshotStager implements PublicationSnapshotStager {
  const DriftPublicationSnapshotStager(
    this._database,
    this._assessmentLoader,
  );

  final CareerSpeakDatabase _database;
  final AssessmentRevisionLoader _assessmentLoader;

  @override
  Future<Result<void>> stage(RootContentManifest target) async {
    for (final ref in target.practiceTests) {
      final loaded = await _assessmentLoader.load(
        practiceTestCode: ref.practiceTestCode,
        revision: ref.revision,
        checksum: ref.checksum,
      );
      if (loaded case FailureResult(:final failure)) {
        return FailureResult<void>(failure);
      }
    }

    try {
      await _database.transaction(() async {
        await _database.customStatement(
          'DELETE FROM publication_practice_test_refs WHERE content_version = ?',
          <Object?>[target.contentVersion],
        );
        await _database.customStatement(
          'DELETE FROM publication_catalogue_refs WHERE content_version = ?',
          <Object?>[target.contentVersion],
        );

        for (final ref in target.practiceTests) {
          await _database.customStatement(
            '''
            INSERT INTO publication_practice_test_refs (
              content_version,
              practice_test_code,
              revision,
              checksum
            ) VALUES (?, ?, ?, ?)
            ''',
            <Object?>[
              target.contentVersion,
              ref.practiceTestCode,
              ref.revision,
              ref.checksum,
            ],
          );
        }

        for (final ref in target.catalogues) {
          await _database.customStatement(
            '''
            INSERT INTO publication_catalogue_refs (
              content_version,
              catalogue_kind,
              revision,
              checksum
            ) VALUES (?, ?, ?, ?)
            ''',
            <Object?>[
              target.contentVersion,
              ref.kind.wireName,
              ref.revision,
              ref.checksum,
            ],
          );
        }
      });
      return const Success(null);
    } catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'PUBLICATION_SNAPSHOT_STAGING_FAILED',
          message: 'Exact publication membership could not be staged locally.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }
}
