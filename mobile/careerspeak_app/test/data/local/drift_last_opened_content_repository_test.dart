import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/drift_last_opened_content_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:careerspeak_app/domain/last_opened_content.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  group('DriftLastOpenedContentRepository', () {
    test('schema v14 starts empty and survives repository reopen', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      expect(database.schemaVersion, 14);

      final openedAt = DateTime.utc(2026, 11, 1, 10, 15);
      final repository = DriftLastOpenedContentRepository(
        database,
        now: () => openedAt,
      );

      final initial = await repository.getLastOpenedContent();
      expect((initial as Success<LastOpenedContent?>).value, isNull);

      final write = await repository.recordOpened(
        identity: const ContentIdentity(
          code: 'JAVA_STREAMS_01',
          type: ContentType.topic,
        ),
        contentRevision: 6,
      );
      final persisted = (write as Success<LastOpenedContent>).value;
      expect(persisted.identity.code, 'JAVA_STREAMS_01');
      expect(persisted.identity.type, ContentType.topic);
      expect(persisted.contentRevision, 6);
      expect(persisted.openedAt, openedAt);

      final reopenedRepository = DriftLastOpenedContentRepository(database);
      final reopened = await reopenedRepository.getLastOpenedContent();
      expect((reopened as Success<LastOpenedContent?>).value, persisted);
    });

    test('newer open replaces previous content identity and revision', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      var clock = DateTime.utc(2026, 11, 1, 10);
      final repository = DriftLastOpenedContentRepository(
        database,
        now: () => clock,
      );

      await repository.recordOpened(
        identity: const ContentIdentity(
          code: 'FIRST',
          type: ContentType.vocabulary,
        ),
        contentRevision: 1,
      );
      clock = clock.add(const Duration(minutes: 5));
      await repository.recordOpened(
        identity: const ContentIdentity(
          code: 'SECOND',
          type: ContentType.interview,
        ),
        contentRevision: 9,
      );

      final read = await repository.getLastOpenedContent();
      final value = (read as Success<LastOpenedContent?>).value!;
      expect(value.identity.code, 'SECOND');
      expect(value.identity.type, ContentType.interview);
      expect(value.contentRevision, 9);
      expect(value.openedAt, clock);
    });

    test('older delayed write cannot overwrite a newer open event', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      var clock = DateTime.utc(2026, 11, 1, 10, 10);
      final repository = DriftLastOpenedContentRepository(
        database,
        now: () => clock,
      );

      await repository.recordOpened(
        identity: const ContentIdentity(
          code: 'NEWER',
          type: ContentType.shadowing,
        ),
        contentRevision: 4,
      );

      clock = clock.subtract(const Duration(minutes: 5));
      final delayed = await repository.recordOpened(
        identity: const ContentIdentity(
          code: 'OLDER',
          type: ContentType.phrase,
        ),
        contentRevision: 2,
      );

      final value = (delayed as Success<LastOpenedContent>).value;
      expect(value.identity.code, 'NEWER');
      expect(value.contentRevision, 4);
      expect(value.openedAt, DateTime.utc(2026, 11, 1, 10, 10));
    });

    test('rejects invalid identity and revision', () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final repository = DriftLastOpenedContentRepository(database);

      final invalid = await repository.recordOpened(
        identity: const ContentIdentity(code: ' ', type: ContentType.topic),
        contentRevision: 0,
      );

      expect(invalid, isA<FailureResult<LastOpenedContent>>());
      expect(
        (invalid as FailureResult<LastOpenedContent>).failure.code,
        'LAST_OPENED_CONTENT_INVALID',
      );
    });
  });
}
