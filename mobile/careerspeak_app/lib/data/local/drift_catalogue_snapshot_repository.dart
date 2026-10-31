import 'dart:convert';

import 'package:drift/drift.dart';

import '../../application/content_delivery/catalogue_payload.dart';
import '../../application/content_delivery/catalogue_revision_ref.dart';
import '../../application/ports/catalogue_snapshot_repository.dart';
import '../../application/result/result.dart';
import 'database/careerspeak_database.dart';

final class DriftCatalogueSnapshotRepository
    implements CatalogueSnapshotRepository {
  const DriftCatalogueSnapshotRepository(this._database);

  final CareerSpeakDatabase _database;

  @override
  Future<Result<CataloguePayload?>> readCurrent(CatalogueKind kind) async {
    try {
      final rows = await _database.customSelect(
        '''
        SELECT
          p.catalogue_kind,
          p.revision,
          p.checksum,
          c.payload_json
        FROM content_manifest_states s
        INNER JOIN publication_catalogue_refs p
          ON p.content_version = s.current_content_version
        INNER JOIN catalogue_revision_reads c
          ON c.catalogue_kind = p.catalogue_kind
         AND c.revision = p.revision
         AND c.checksum = p.checksum
        WHERE s.id = 1
          AND p.catalogue_kind = ?
        ''',
        variables: <Variable<Object>>[Variable<String>(kind.wireName)],
        readsFrom: <ResultSetImplementation>{_database.contentManifestStates},
      ).get();
      if (rows.isEmpty) return const Success<CataloguePayload?>(null);
      if (rows.length != 1) {
        return const FailureResult<CataloguePayload?>(
          ApplicationFailure(
            code: 'CATALOGUE_READ_MODEL_INVALID',
            message: 'CURRENT catalogue membership is not unique.',
          ),
        );
      }

      final row = rows.single;
      final revision = row.read<int>('revision');
      final checksum = row.read<String>('checksum');
      final decoded = jsonDecode(row.read<String>('payload_json'));
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
