import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  test('v6 root without policy marker requests a repair commit', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 31, 7);
    await database
        .into(database.contentManifestStates)
        .insert(
          ContentManifestStatesCompanion.insert(
            id: const Value(1),
            schemaVersion: 1,
            currentContentVersion: 108,
            currentManifestChecksum: _rootChecksum,
            updatedAt: now,
          ),
        );

    final snapshot = (await DriftSyncJournal(database).readLocalSnapshot())
        .getOrThrow();

    expect(snapshot.localePolicyRepairRequired, isTrue);
  });

  test('matching policy marker makes CURRENT root policy complete', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 31, 7);
    await database
        .into(database.contentManifestStates)
        .insert(
          ContentManifestStatesCompanion.insert(
            id: const Value(1),
            schemaVersion: 1,
            currentContentVersion: 108,
            currentManifestChecksum: _rootChecksum,
            localePolicyContentVersion: const Value(108),
            updatedAt: now,
          ),
        );

    final snapshot = (await DriftSyncJournal(database).readLocalSnapshot())
        .getOrThrow();

    expect(snapshot.localePolicyRepairRequired, isFalse);
  });
}

const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
