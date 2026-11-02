import 'package:careerspeak_app/application/access/access_snapshot.dart';
import 'package:careerspeak_app/application/content_delivery/product_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default access is fail-closed FREE', () {
    expect(AccessSnapshot.defaultAccessLevel, AccessLevel.free);
  });

  test('verified FULL snapshot requires UTC verification time', () {
    final snapshot = AccessSnapshot(
      accessLevel: AccessLevel.full,
      verifiedAt: DateTime.utc(2026, 11, 2, 3),
      source: AccessSnapshotSource.backendVerified,
    );

    expect(snapshot.accessLevel, AccessLevel.full);
    expect(snapshot.source, AccessSnapshotSource.backendVerified);
    expect(snapshot.verifiedAt.isUtc, isTrue);
  });

  test('non-UTC verification time is rejected', () {
    expect(
      () => AccessSnapshot(
        accessLevel: AccessLevel.full,
        verifiedAt: DateTime(2026, 11, 2, 3),
        source: AccessSnapshotSource.storeRestore,
      ),
      throwsArgumentError,
    );
  });

  test('snapshot source wire values are strict', () {
    expect(
      AccessSnapshotSource.fromWireName('BACKEND_VERIFIED'),
      AccessSnapshotSource.backendVerified,
    );
    expect(
      AccessSnapshotSource.fromWireName('STORE_RESTORE'),
      AccessSnapshotSource.storeRestore,
    );
    expect(
      () => AccessSnapshotSource.fromWireName('LOCAL_ONLY'),
      throwsFormatException,
    );
  });
}
