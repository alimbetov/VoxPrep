import 'package:drift/drift.dart';

import '../../application/content_delivery/content_manifest.dart';
import '../../application/ports/asset_catalog_repository.dart';
import '../../application/result/result.dart';
import '../../domain/content_identity.dart';
import 'database/careerspeak_database.dart';

final class DriftAssetCatalogRepository implements AssetCatalogRepository {
  DriftAssetCatalogRepository(this._database);

  final CareerSpeakDatabase _database;

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentById(String assetId) {
    return _read(
      '''
SELECT a.*, MAX(pa.required_offline) AS required_offline
FROM asset_catalog a
JOIN pack_asset_refs pa ON pa.asset_id = a.asset_id
JOIN content_pack_revisions p
  ON p.pack_code = pa.pack_code AND p.variant_key = pa.variant_key
  AND p.revision = pa.pack_revision AND p.state = 'CURRENT'
WHERE a.asset_id = ?
GROUP BY a.asset_id
''',
      <Variable<Object>>[Variable<String>(assetId)],
    );
  }

  @override
  Future<Result<ManifestAssetDescriptor?>> findCurrentForContent({
    required ContentIdentity content,
    required int revision,
    required String role,
    String variant = 'canonical',
  }) {
    return _read(
      '''
SELECT a.*, MAX(ca.required_offline) AS required_offline
FROM content_asset_refs ca
JOIN asset_catalog a ON a.asset_id = ca.asset_id
JOIN local_content_records c
  ON c.content_code = ca.content_code AND c.content_type = ca.content_type
  AND c.revision = ca.content_revision AND c.snapshot_state = 'CURRENT'
JOIN pack_content_refs pc
  ON pc.content_code = c.content_code AND pc.content_type = c.content_type
  AND pc.content_revision = c.revision
JOIN content_pack_revisions p
  ON p.pack_code = pc.pack_code AND p.variant_key = pc.variant_key
  AND p.revision = pc.pack_revision AND p.state = 'CURRENT'
JOIN pack_asset_refs pa
  ON pa.pack_code = p.pack_code AND pa.variant_key = p.variant_key
  AND pa.pack_revision = p.revision AND pa.asset_id = a.asset_id
WHERE ca.content_code = ? AND ca.content_type = ?
  AND ca.content_revision = ? AND ca.asset_role = ? AND p.variant_key = ?
GROUP BY a.asset_id
LIMIT 2
''',
      <Variable<Object>>[
        Variable<String>(content.code),
        Variable<String>(content.type.name.toUpperCase()),
        Variable<int>(revision),
        Variable<String>(role),
        Variable<String>(variant),
      ],
    );
  }

  Future<Result<ManifestAssetDescriptor?>> _read(
    String sql,
    List<Variable<Object>> variables,
  ) async {
    try {
      final rows = await _database
          .customSelect(sql, variables: variables)
          .get();
      if (rows.isEmpty) return const Success(null);
      if (rows.length != 1) {
        return const FailureResult(
          ApplicationFailure(
            code: 'ASSET_REFERENCE_AMBIGUOUS',
            message: 'The content role refers to multiple current assets.',
          ),
        );
      }
      final row = rows.single;
      return Success(
        ManifestAssetDescriptor(
          assetId: row.read<String>('asset_id'),
          checksumSha256: row.read<String>('checksum_sha256'),
          deliveryKey: row.read<String>('delivery_key'),
          sizeBytes: row.read<int>('size_bytes'),
          mediaType: row.read<String>('mime_type'),
          requiredOffline: row.read<int>('required_offline') != 0,
        ),
      );
    } on ArgumentError {
      return const FailureResult(
        ApplicationFailure(
          code: 'ASSET_CATALOG_INVALID',
          message: 'Persisted asset metadata is invalid.',
        ),
      );
    } catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'ASSET_CATALOG_READ_FAILED',
          message: 'The local asset catalog could not be read.',
          retryable: true,
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    }
  }
}
