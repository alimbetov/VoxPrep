import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_asset_catalog_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  test('C4 future-root asset stays invisible before root switch', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 11, 1, 10);

    await database.into(database.contentManifestStates).insert(
      ContentManifestStatesCompanion.insert(
        id: const Value(1),
        schemaVersion: 1,
        currentContentVersion: 1,
        currentManifestChecksum: _rootV1,
        updatedAt: now,
      ),
    );
    await database.into(database.contentPackRevisions).insert(
      ContentPackRevisionsCompanion.insert(
        packCode: 'PACK_FUTURE',
        variantKey: 'canonical',
        revision: 1,
        schemaVersion: 1,
        checksum: _packChecksum,
        state: 'CURRENT',
        sourceContentVersion: 2,
        stagedAt: now,
        currentAt: Value(now),
      ),
    );
    await database.into(database.assetCatalog).insert(
      AssetCatalogCompanion.insert(
        assetId: 'audio.future.1',
        checksumSha256: _assetChecksum,
        assetKind: 'AUDIO',
        mimeType: 'audio/mpeg',
        sizeBytes: 128,
        deliveryKey: 'audio/future-1.mp3',
        createdAt: now,
      ),
    );
    await database.into(database.packAssetRefs).insert(
      PackAssetRefsCompanion.insert(
        packCode: 'PACK_FUTURE',
        variantKey: 'canonical',
        packRevision: 1,
        assetId: 'audio.future.1',
        requiredOffline: const Value(true),
      ),
    );

    final repository = DriftAssetCatalogRepository(database);
    final before = await repository.findCurrentById('audio.future.1');
    expect(before, isA<Success>());
    expect((before as Success).value, isNull);

    await (database.update(database.contentManifestStates)
          ..where((row) => row.id.equals(1)))
        .write(
      ContentManifestStatesCompanion(
        currentContentVersion: const Value(2),
        currentManifestChecksum: const Value(_rootV2),
        updatedAt: Value(now.add(const Duration(seconds: 1))),
      ),
    );

    final after = await repository.findCurrentById('audio.future.1');
    expect(after, isA<Success>());
    final asset = (after as Success).value;
    expect(asset, isNotNull);
    expect(asset.assetId, 'audio.future.1');
    expect(asset.requiredOffline, isTrue);
  });
}

const _rootV1 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _rootV2 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _packChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _assetChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
