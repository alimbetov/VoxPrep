import 'package:careerspeak_app/application/access/access_snapshot.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_access_snapshot_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  test('missing access snapshot stays FREE by absence', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    final result = await DriftAccessSnapshotRepository(database).read();

    expect(result, isA<Success<AccessSnapshot?>>());
    expect((result as Success<AccessSnapshot?>).value, isNull);
  });

  test('verified FULL snapshot survives a repository reopen', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final repository = DriftAccessSnapshotRepository(database);
    final expected = AccessSnapshot(
      accessLevel: AccessLevel.full,
      verifiedAt: DateTime.utc(2026, 11, 2, 4, 30),
      source: AccessSnapshotSource.backendVerified,
    );

    expect(await repository.replace(expected), isA<Success<void>>());

    final result = await DriftAccessSnapshotRepository(database).read();
    expect(result, isA<Success<AccessSnapshot?>>());
    final restored = (result as Success<AccessSnapshot?>).value!;
    expect(restored.accessLevel, AccessLevel.full);
    expect(restored.verifiedAt, expected.verifiedAt);
    expect(restored.source, AccessSnapshotSource.backendVerified);
  });

  test(
    'verified FREE snapshot can replace FULL after revocation sync',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftAccessSnapshotRepository(database);

      await repository.replace(
        AccessSnapshot(
          accessLevel: AccessLevel.full,
          verifiedAt: DateTime.utc(2026, 11, 2, 4),
          source: AccessSnapshotSource.backendVerified,
        ),
      );
      await repository.replace(
        AccessSnapshot(
          accessLevel: AccessLevel.free,
          verifiedAt: DateTime.utc(2026, 11, 2, 5),
          source: AccessSnapshotSource.backendVerified,
        ),
      );

      final result = await repository.read();
      final restored = (result as Success<AccessSnapshot?>).value!;
      expect(restored.accessLevel, AccessLevel.free);
      expect(restored.verifiedAt, DateTime.utc(2026, 11, 2, 5));
    },
  );

  test('schema v18 bounds access and source values', () async {
    final database = createTestDatabase();
    addTearDown(database.close);

    expect(database.schemaVersion, 18);
    await expectLater(
      database.customStatement('''INSERT INTO learner_access_snapshot
           (id, access_level, verified_at, source, updated_at)
           VALUES (1, 'TRIAL', 1, 'BACKEND_VERIFIED', 1)'''),
      throwsA(anything),
    );
    await expectLater(
      database.customStatement('''INSERT INTO learner_access_snapshot
           (id, access_level, verified_at, source, updated_at)
           VALUES (1, 'FULL', 1, 'LOCAL_ONLY', 1)'''),
      throwsA(anything),
    );
  });
}
