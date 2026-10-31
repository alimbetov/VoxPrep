import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_database_factory.dart';

void main() {
  late CareerSpeakDatabase database;

  setUp(() {
    database = createTestDatabase();
  });

  tearDown(() async {
    await database.close();
  });

  test('content catalog read identity includes type and revision', () async {
    final now = DateTime.utc(2026, 10, 30, 12);

    ContentCatalogReadsCompanion row({
      required String type,
      required int revision,
    }) {
      return ContentCatalogReadsCompanion.insert(
        contentCode: 'SHARED_CODE',
        contentType: type,
        revision: revision,
        checksum:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        title: '$type revision $revision',
        subtitle: 'Subtitle',
        description: 'Description',
        category: 'Category',
        level: 'B2',
        minutes: 5,
        hasAudio: true,
        createdAt: now,
      );
    }

    await database
        .into(database.contentCatalogReads)
        .insert(row(type: 'INTERVIEW', revision: 1));
    await database
        .into(database.contentCatalogReads)
        .insert(row(type: 'INTERVIEW', revision: 2));
    await database
        .into(database.contentCatalogReads)
        .insert(row(type: 'TOPIC', revision: 1));

    expect(
      await database.select(database.contentCatalogReads).get(),
      hasLength(3),
    );

    await expectLater(
      database
          .into(database.contentCatalogReads)
          .insert(row(type: 'INTERVIEW', revision: 1)),
      throwsA(anything),
    );
  });

  test('content catalog read rejects invalid presentation payload', () async {
    final now = DateTime.utc(2026, 10, 30, 12);

    final invalid = ContentCatalogReadsCompanion.insert(
      contentCode: 'JAVA_DI_001',
      contentType: 'INTERVIEW',
      revision: 1,
      checksum:
          'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      title: 'Dependency Injection',
      subtitle: 'Java Backend',
      description: 'Description',
      category: 'Java Backend',
      level: 'Senior',
      minutes: 0,
      hasAudio: true,
      createdAt: now,
    );

    await expectLater(
      database.into(database.contentCatalogReads).insert(invalid),
      throwsA(anything),
    );
  });
}
