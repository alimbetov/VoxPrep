import 'dart:convert';

import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_typed_content_reader.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

const _checksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

void main() {
  late CareerSpeakDatabase database;
  late DriftTypedContentReader reader;

  setUp(() {
    database = createTestDatabase();
    reader = DriftTypedContentReader(database);
  });

  tearDown(() async => database.close());

  const item = ContentItem(
    code: 'INTERVIEW_A1',
    type: ContentType.interview,
    title: 'Dependency injection',
    subtitle: 'Java',
    description: 'Technical interview',
    category: 'Java Backend',
    level: 'B2',
    minutes: 5,
    hasAudio: true,
  );

  Future<void> seed({String typedChecksum = _checksum}) async {
    final now = DateTime.utc(2026, 11, 4);
    await database.into(database.contentCatalogReads).insert(
      ContentCatalogReadsCompanion.insert(
        contentCode: item.code,
        contentType: 'INTERVIEW',
        revision: item.revision,
        checksum: _checksum,
        title: item.title,
        subtitle: item.subtitle,
        description: item.description,
        category: item.category,
        level: item.level,
        minutes: item.minutes,
        hasAudio: item.hasAudio,
        createdAt: now,
      ),
    );
    await database.into(database.typedContentReads).insert(
      TypedContentReadsCompanion.insert(
        contentCode: item.code,
        contentType: 'INTERVIEW',
        revision: item.revision,
        checksum: typedChecksum,
        categoryCode: 'JAVA_BACKEND',
        levelCode: 'B2',
        skillCodesJson: jsonEncode(['SPEAKING']),
        bodyKind: 'interview',
        bodyJson: jsonEncode({
          'kind': 'interview',
          'prompt': 'What is dependency injection?',
          'modelAnswer': 'Constructor injection.',
          'keyPoints': ['Testability', 'Loose coupling'],
        }),
        createdAt: now,
      ),
    );
  }

  test('returns exact typed body from persisted immutable payload', () async {
    await seed();
    final body = await reader.getForVisible(item);
    expect(body, isA<InterviewBody>());
    final interview = body! as InterviewBody;
    expect(interview.prompt, 'What is dependency injection?');
    expect(interview.keyPoints, ['Testability', 'Loose coupling']);
  });

  test('missing legacy typed payload returns no body', () async {
    expect(await reader.getForVisible(item), isNull);
  });

  test('typed checksum mismatch fails closed', () async {
    await seed(typedChecksum: 'b' * 64);
    expect(() => reader.getForVisible(item), throwsStateError);
  });
}
