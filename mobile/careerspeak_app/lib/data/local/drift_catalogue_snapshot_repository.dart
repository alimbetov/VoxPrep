import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import '../../application/ports/catalogue_snapshot_repository.dart';
import '../../application/result/result.dart';
import 'database/careerspeak_database.dart';
import 'publication_snapshot_storage.dart';

final class DriftCatalogueSnapshotRepository
    implements CatalogueSnapshotRepository {
  const DriftCatalogueSnapshotRepository(this._database);

  final CareerSpeakDatabase _database;

  @override
  Future<Result<CataloguePayload?>> readCurrent(CatalogueKind kind) async {
    try {
      await PublicationSnapshotStorage(_database).ensureReady();
      final membershipRows = await _database
          .customSelect(
            '''
        SELECT
          p.catalogue_kind,
          p.revision,
          p.checksum
        FROM content_manifest_states s
        INNER JOIN publication_catalogue_refs p
          ON p.content_version = s.current_content_version
        WHERE s.id = 1
          AND p.catalogue_kind = ?
        ''',
            variables: <Variable<Object>>[Variable<String>(kind.wireName)],
          )
          .get();

      if (membershipRows.isEmpty) {
        return const Success<CataloguePayload?>(null);
      }
      if (membershipRows.length != 1) {
        return const FailureResult<CataloguePayload?>(
          ApplicationFailure(
            code: 'CATALOGUE_READ_MODEL_INVALID',
            message: 'CURRENT catalogue membership is not unique.',
          ),
        );
      }

      final membership = membershipRows.single;
      final revision = membership.read<int>('revision');
      final checksum = membership.read<String>('checksum');
      final payloadRows = await _database
          .customSelect(
            '''
        SELECT payload_json
        FROM catalogue_revision_reads
        WHERE catalogue_kind = ?
          AND revision = ?
          AND checksum = ?
        ''',
            variables: <Variable<Object>>[
              Variable<String>(kind.wireName),
              Variable<int>(revision),
              Variable<String>(checksum),
            ],
          )
          .get();

      if (payloadRows.length != 1) {
        return const FailureResult<CataloguePayload?>(
          ApplicationFailure(
            code: 'CATALOGUE_READ_MODEL_INVALID',
            message:
                'CURRENT catalogue exact membership is missing its cached payload.',
          ),
        );
      }

      final decoded = jsonDecode(payloadRows.single.read<String>('payload_json'));
      if (decoded is! Map<String, dynamic>) {
        return const FailureResult<CataloguePayload?>(
          ApplicationFailure(
            code: 'CATALOGUE_READ_MODEL_INVALID',
            message: 'Cached catalogue payload is not a JSON object.',
          ),
        );
      }
      final items = decoded['items'];
      if (decoded['kind'] != kind.wireName ||
          decoded['revision'] != revision ||
          decoded['checksum'] != checksum ||
          items is! List<dynamic> ||
          items.any((item) => item is! Map<String, dynamic>)) {
        return const FailureResult<CataloguePayload?>(
          ApplicationFailure(
            code: 'CATALOGUE_READ_MODEL_INVALID',
            message:
                'Cached catalogue payload conflicts with CURRENT exact membership.',
          ),
        );
      }

      return Success<CataloguePayload?>(
        CataloguePayload(
          ref: CatalogueRevisionRef(
            kind: kind,
            revision: revision,
            checksum: checksum,
          ),
          items: items.cast<Object>(),
          wireJson: Map<String, Object?>.from(decoded),
        ),
      );
    } on Object catch (error) {
      return FailureResult<CataloguePayload?>(
        ApplicationFailure(
          code: 'CATALOGUE_READ_FAILED',
          message: 'The CURRENT catalogue projection could not be read.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }
}
