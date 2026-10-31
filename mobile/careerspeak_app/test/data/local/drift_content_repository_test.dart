import 'dart:async';

import 'package:careerspeak_app/application/query/content_query.dart';
import 'package:careerspeak_app/application/query/page.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/content_type_storage.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_content_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  late CareerSpeakDatabase database;
  late DriftContentRepository repository;

  setUp(() {
    database = createTestDatabase();
    repository = DriftContentRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('only exact CURRENT payload is learner-visible', () async {
    await _seed(
      database,
      code: 'JAVA_DI_001',
      type: ContentType.interview,
      revision: 1,
      snapshotState: 'CURRENT',
      title: 'Current title',
      sortOrder: 1,
    );
    await _seed(
      database,
      code: 'JAVA_DI_001',
      type: ContentType.interview,
      revision: 2,
      snapshotState: 'STAGED',
      title: 'Staged title',
      sortOrder: 1,
    );

    final page = (await repository.watchContent(const ContentQuery()).first)
        .getOrThrow();

    expect(page.items, hasLength(1));
    expect(page.items.single.revision, 1);
    expect(page.items.single.title, 'Current title');
  });

  test('getByIdentity requires both business code and content type', () async {
    await _seed(
      database,
      code: 'SHARED_001',
      type: ContentType.interview,
      revision: 3,
      snapshotState: 'CURRENT',
      title: 'Interview version',
      sortOrder: 1,
    );
    await _seed(
      database,
      code: 'SHARED_001',
      type: ContentType.vocabulary,
      revision: 7,
      snapshotState: 'CURRENT',
      title: 'Vocabulary version',
      sortOrder: 2,
    );

    final interview = (await repository.getByIdentity(
      const ContentIdentity(code: 'SHARED_001', type: ContentType.interview),
    )).getOrThrow();
    final vocabulary = (await repository.getByIdentity(
      const ContentIdentity(code: 'SHARED_001', type: ContentType.vocabulary),
    )).getOrThrow();

    expect(interview?.title, 'Interview version');
    expect(interview?.revision, 3);
    expect(vocabulary?.title, 'Vocabulary version');
    expect(vocabulary?.revision, 7);
  });

  test('catalog filters operate on CURRENT canonical projection', () async {
    await _seed(
      database,
      code: 'JAVA_DI_001',
      type: ContentType.interview,
      revision: 1,
      snapshotState: 'CURRENT',
      title: 'Dependency Injection',
      description: 'Spring dependency injection and testability.',
      category: 'Java Backend',
      level: 'Senior',
      sortOrder: 1,
    );
    await _seed(
      database,
      code: 'VOCAB_SCALE',
      type: ContentType.vocabulary,
      revision: 1,
      snapshotState: 'CURRENT',
      title: 'scale',
      description: 'Vocabulary for discussing system growth.',
      category: 'Vocabulary',
      level: 'B2',
      sortOrder: 2,
    );

    final page =
        (await repository
                .watchContent(
                  const ContentQuery(
                    search: 'SPRING',
                    types: <ContentType>{ContentType.interview},
                    category: 'Java Backend',
                    level: 'Senior',
                  ),
                )
                .first)
            .getOrThrow();

    expect(page.items.map((item) => item.code), <String>['JAVA_DI_001']);
  });

  test('opaque keyset cursor distinguishes equal codes across types', () async {
    await _seed(
      database,
      code: 'SHARED_001',
      type: ContentType.interview,
      revision: 1,
      snapshotState: 'CURRENT',
      title: 'Interview',
      sortOrder: 10,
    );
    await _seed(
      database,
      code: 'SHARED_001',
      type: ContentType.vocabulary,
      revision: 1,
      snapshotState: 'CURRENT',
      title: 'Vocabulary',
      sortOrder: 10,
    );

    final firstPage =
        (await repository
                .watchContent(const ContentQuery(page: PageRequest(limit: 1)))
                .first)
            .getOrThrow();

    expect(firstPage.items, hasLength(1));
    expect(firstPage.hasMore, isTrue);
    expect(firstPage.nextCursor, isNotNull);

    final secondPage =
        (await repository
                .watchContent(
                  ContentQuery(
                    page: PageRequest(limit: 1, cursor: firstPage.nextCursor),
                  ),
                )
                .first)
            .getOrThrow();

    expect(secondPage.items, hasLength(1));
    expect(
      ContentIdentity.fromItem(secondPage.items.single),
      isNot(ContentIdentity.fromItem(firstPage.items.single)),
    );
    expect(secondPage.hasMore, isFalse);
  });

  test('invalid page cursor fails closed', () async {
    final result = await repository
        .watchContent(
          const ContentQuery(page: PageRequest(cursor: 'not-a-valid-cursor')),
        )
        .first;

    expect(result, isA<FailureResult<Page<ContentItem>>>());
    expect(
      (result as FailureResult<Page<ContentItem>>).failure.code,
      'INVALID_CONTENT_CURSOR',
    );
  });

  test('CURRENT metadata checksum mismatch fails closed', () async {
    await _seed(
      database,
      code: 'JAVA_DI_001',
      type: ContentType.interview,
      revision: 1,
      snapshotState: 'CURRENT',
      metadataChecksum: _checksumA,
      payloadChecksum: _checksumB,
      sortOrder: 1,
    );

    final result = await repository.watchContent(const ContentQuery()).first;

    expect(result, isA<FailureResult<Page<ContentItem>>>());
    expect(
      (result as FailureResult<Page<ContentItem>>).failure.code,
      'CONTENT_READ_MODEL_INVALID',
    );
  });

  test('duplicate CURRENT revisions fail closed', () async {
    await _seed(
      database,
      code: 'JAVA_DI_001',
      type: ContentType.interview,
      revision: 1,
      snapshotState: 'CURRENT',
      sortOrder: 1,
    );
    await _seed(
      database,
      code: 'JAVA_DI_001',
      type: ContentType.interview,
      revision: 2,
      snapshotState: 'CURRENT',
      sortOrder: 1,
    );

    final result = await repository.watchContent(const ContentQuery()).first;

    expect(result, isA<FailureResult<Page<ContentItem>>>());
    expect(
      (result as FailureResult<Page<ContentItem>>).failure.code,
      'CONTENT_READ_MODEL_INVALID',
    );
  });

  test('CURRENT metadata without learner payload fails closed', () async {
    await _seed(
      database,
      code: 'JAVA_DI_001',
      type: ContentType.interview,
      revision: 1,
      snapshotState: 'CURRENT',
      includePayload: false,
      sortOrder: 1,
    );

    final result = await repository.watchContent(const ContentQuery()).first;

    expect(result, isA<FailureResult<Page<ContentItem>>>());
    expect(
      (result as FailureResult<Page<ContentItem>>).failure.code,
      'CONTENT_READ_MODEL_INVALID',
    );
  });

  test('catalog stream reacts after atomic CURRENT publication', () async {
    final iterator = StreamIterator<Result<Page<ContentItem>>>(
      repository.watchContent(const ContentQuery()),
    );
    addTearDown(iterator.cancel);

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.getOrThrow().items, isEmpty);

    await database.transaction(() async {
      await _seed(
        database,
        code: 'TOPIC_001',
        type: ContentType.topic,
        revision: 4,
        snapshotState: 'CURRENT',
        title: 'Architecture trade-offs',
        sortOrder: 1,
      );
    });

    expect(await iterator.moveNext(), isTrue);
    final page = iterator.current.getOrThrow();
    expect(page.items, hasLength(1));
    expect(page.items.single.code, 'TOPIC_001');
    expect(page.items.single.revision, 4);
  });
}

Future<void> _seed(
  CareerSpeakDatabase database, {
  required String code,
  required ContentType type,
  required int revision,
  required String snapshotState,
  String title = 'Title',
  String subtitle = 'Subtitle',
  String description = 'Description',
  String category = 'Java Backend',
  String level = 'Senior',
  int minutes = 8,
  bool hasAudio = true,
  int? sortOrder,
  String metadataChecksum = _checksumA,
  String? payloadChecksum,
  bool includePayload = true,
}) async {
  final now = DateTime.utc(2026, 10, 30, 18);
  final storageType = contentTypeToStorage(type);
  await database
      .into(database.localContentRecords)
      .insert(
        LocalContentRecordsCompanion.insert(
          contentCode: code,
          contentType: storageType,
          revision: revision,
          checksum: metadataChecksum,
          sortOrder: Value<int?>(sortOrder),
          publishedAt: Value<DateTime?>(now),
          snapshotState: snapshotState,
          sourceSchemaVersion: 1,
          createdAt: now,
        ),
      );

  if (!includePayload) {
    return;
  }

  await database
      .into(database.contentCatalogReads)
      .insert(
        ContentCatalogReadsCompanion.insert(
          contentCode: code,
          contentType: storageType,
          revision: revision,
          checksum: payloadChecksum ?? metadataChecksum,
          title: title,
          subtitle: subtitle,
          description: description,
          category: category,
          level: level,
          minutes: minutes,
          hasAudio: hasAudio,
          createdAt: now,
        ),
      );
}

const _checksumA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _checksumB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
