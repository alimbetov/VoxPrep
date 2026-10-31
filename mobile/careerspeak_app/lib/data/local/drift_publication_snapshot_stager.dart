import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/assessment/assessment_revision_loader.dart';
import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/catalogue_payload_gateway.dart';
import '../../application/ports/publication_snapshot_stager.dart';
import '../../application/result/result.dart';
import 'database/careerspeak_database.dart';
import 'publication_snapshot_storage.dart';

final class DriftPublicationSnapshotStager
    implements PublicationSnapshotStager {
  const DriftPublicationSnapshotStager(
    this._database,
    this._assessmentLoader,
    this._catalogueGateway,
  );

  final CareerSpeakDatabase _database;
  final AssessmentRevisionLoader _assessmentLoader;
  final CataloguePayloadGateway _catalogueGateway;

  @override
  Future<Result<void>> stage(RootContentManifest target) async {
    try {
      await PublicationSnapshotStorage(_database).ensureReady();
    } catch (error) {
      return FailureResult<void>(
        ApplicationFailure(
          code: 'PUBLICATION_SNAPSHOT_STORAGE_FAILED',
          message: 'Publication snapshot storage could not be initialized.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }

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

    final cataloguePayloads = <CataloguePayload>[];
    for (final ref in target.catalogues) {
      final fetched = await _catalogueGateway.fetch(ref);
      if (fetched case FailureResult<CataloguePayload>(:final failure)) {
        return FailureResult<void>(failure);
      }
      cataloguePayloads.add((fetched as Success<CataloguePayload>).value);
    }

    try {
      await _database.transaction(() async {
        for (final payload in cataloguePayloads) {
          final existing = await _database
              .customSelect(
                '''
            SELECT checksum, payload_json
            FROM catalogue_revision_reads
            WHERE catalogue_kind = ? AND revision = ?
            ''',
                variables: <Variable<Object>>[
                  Variable<String>(payload.ref.kind.wireName),
                  Variable<int>(payload.ref.revision),
                ],
              )
              .getSingleOrNull();
          final payloadJson = jsonEncode(payload.wireJson);
          if (existing != null &&
              (existing.read<String>('checksum') != payload.ref.checksum ||
                  existing.read<String>('payload_json') != payloadJson)) {
            throw StateError(
              'immutable catalogue revision conflicts with local cache',
            );
          }
          if (existing == null) {
            await _database.customStatement(
              '''
              INSERT INTO catalogue_revision_reads (
                catalogue_kind,
                revision,
                checksum,
                payload_json,
                created_at
              ) VALUES (?, ?, ?, ?, ?)
              ''',
              <Object?>[
                payload.ref.kind.wireName,
                payload.ref.revision,
                payload.ref.checksum,
                payloadJson,
                DateTime.now().toUtc().millisecondsSinceEpoch,
              ],
            );
          }
        }

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
