from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    source = target.read_text()
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one anchor, found {count}')
    target.write_text(source.replace(old, new))


# C2 owns a separate exact typed projection. The accepted C1 card read table is untouched.
read_tables = Path(
    'mobile/careerspeak_app/lib/data/local/database/careerspeak_content_read_tables.dart'
)
source = read_tables.read_text()
anchor = '\nclass LocalizedContentReads extends Table {'
if 'class TypedContentReads extends Table {' not in source:
    typed_table = '''
class TypedContentReads extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get revision => integer()();
  TextColumn get checksum => text()();
  TextColumn get categoryCode => text()();
  TextColumn get levelCode => text()();
  TextColumn get skillCodesJson => text()();
  TextColumn get bodyKind => text()();
  TextColumn get bodyJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentCode, contentType, revision};

  @override
  List<String> get customConstraints => const [
    'CHECK (revision > 0)',
    'CHECK (length(trim(checksum)) > 0)',
    'CHECK (length(trim(category_code)) > 0)',
    'CHECK (length(trim(level_code)) > 0)',
    'CHECK (length(trim(skill_codes_json)) > 0)',
    'CHECK (length(trim(body_kind)) > 0)',
    'CHECK (length(trim(body_json)) > 0)',
  ];
}
'''
    if anchor not in source:
        raise SystemExit('typed table insertion anchor missing')
    read_tables.write_text(source.replace(anchor, f'\n{typed_table}{anchor}', 1))

replace_once(
    'mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart',
    '''    ContentCatalogReads,\n    LocalizedContentReads,''',
    '''    ContentCatalogReads,\n    TypedContentReads,\n    LocalizedContentReads,''',
)
replace_once(
    'mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart',
    '  int get schemaVersion => 6;',
    '  int get schemaVersion => 7;',
)
replace_once(
    'mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart',
    '''      if (from < 6) {\n        await migrator.addColumn(''',
    '''      if (from < 6) {\n        await migrator.addColumn(''',
)
database_path = Path(
    'mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart'
)
database_source = database_path.read_text()
upgrade_anchor = '''      }\n    },\n    beforeOpen: (details) async {'''
if 'if (from < 7)' not in database_source:
    if upgrade_anchor not in database_source:
        raise SystemExit('database v7 migration anchor missing')
    database_source = database_source.replace(
        upgrade_anchor,
        '''      }\n      if (from < 7) {\n        await migrator.createTable(typedContentReads);\n      }\n    },\n    beforeOpen: (details) async {''',
        1,
    )
    database_path.write_text(database_source)

executor_path = Path('mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart')
executor = executor_path.read_text()
if not executor.startswith("import 'dart:convert';"):
    executor = "import 'dart:convert';\n\n" + executor
if "typed_content_body.dart" not in executor:
    executor = executor.replace(
        "import '../../application/content_delivery/localized_content_payload.dart';\n",
        "import '../../application/content_delivery/localized_content_payload.dart';\n"
        "import '../../application/content_delivery/typed_content_body.dart';\n",
        1,
    )
old_function = '''  Future<void> _ensureContentRead(ContentPayload payload, DateTime now) async {
    final type = _contentTypeToStorage(payload.ref.identity.type);
    final existing =
        await (_database.select(_database.contentCatalogReads)..where(
              (row) =>
                  row.contentCode.equals(payload.ref.identity.code) &
                  row.contentType.equals(type) &
                  row.revision.equals(payload.ref.revision),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.contentCatalogReads)
          .insert(
            ContentCatalogReadsCompanion.insert(
              contentCode: payload.ref.identity.code,
              contentType: type,
              revision: payload.ref.revision,
              checksum: payload.ref.checksum,
              title: payload.title,
              subtitle: payload.subtitle,
              description: payload.description,
              category: payload.category,
              level: payload.level,
              minutes: payload.minutes,
              hasAudio: payload.hasAudio,
              createdAt: now,
            ),
          );
      return;
    }

    if (existing.checksum != payload.ref.checksum ||
        existing.title != payload.title ||
        existing.subtitle != payload.subtitle ||
        existing.description != payload.description ||
        existing.category != payload.category ||
        existing.level != payload.level ||
        existing.minutes != payload.minutes ||
        existing.hasAudio != payload.hasAudio) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_PAYLOAD_IMMUTABLE_CONFLICT',
          message:
              'A persisted content payload conflicts with its immutable revision.',
        ),
      );
    }
  }
'''
new_function = '''  Future<void> _ensureContentRead(ContentPayload payload, DateTime now) async {
    final type = _contentTypeToStorage(payload.ref.identity.type);
    final existing =
        await (_database.select(_database.contentCatalogReads)..where(
              (row) =>
                  row.contentCode.equals(payload.ref.identity.code) &
                  row.contentType.equals(type) &
                  row.revision.equals(payload.ref.revision),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.contentCatalogReads)
          .insert(
            ContentCatalogReadsCompanion.insert(
              contentCode: payload.ref.identity.code,
              contentType: type,
              revision: payload.ref.revision,
              checksum: payload.ref.checksum,
              title: payload.title,
              subtitle: payload.subtitle,
              description: payload.description,
              category: payload.category,
              level: payload.level,
              minutes: payload.minutes,
              hasAudio: payload.hasAudio,
              createdAt: now,
            ),
          );
      await _ensureTypedContentRead(payload, now);
      return;
    }

    if (existing.checksum != payload.ref.checksum ||
        existing.title != payload.title ||
        existing.subtitle != payload.subtitle ||
        existing.description != payload.description ||
        existing.category != payload.category ||
        existing.level != payload.level ||
        existing.minutes != payload.minutes ||
        existing.hasAudio != payload.hasAudio) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_PAYLOAD_IMMUTABLE_CONFLICT',
          message:
              'A persisted content payload conflicts with its immutable revision.',
        ),
      );
    }

    await _ensureTypedContentRead(payload, now);
  }

  Future<void> _ensureTypedContentRead(
    ContentPayload payload,
    DateTime now,
  ) async {
    final body = payload.body;
    if (body == null) {
      return;
    }

    final type = _contentTypeToStorage(payload.ref.identity.type);
    final skillCodesJson = jsonEncode(payload.skillCodes);
    final bodyKind = body.contentType.name;
    final bodyJson = jsonEncode(_typedBodyJson(body));
    final existing =
        await (_database.select(_database.typedContentReads)..where(
              (row) =>
                  row.contentCode.equals(payload.ref.identity.code) &
                  row.contentType.equals(type) &
                  row.revision.equals(payload.ref.revision),
            ))
            .getSingleOrNull();

    if (existing == null) {
      await _database
          .into(_database.typedContentReads)
          .insert(
            TypedContentReadsCompanion.insert(
              contentCode: payload.ref.identity.code,
              contentType: type,
              revision: payload.ref.revision,
              checksum: payload.ref.checksum,
              categoryCode: payload.categoryCode,
              levelCode: payload.levelCode,
              skillCodesJson: skillCodesJson,
              bodyKind: bodyKind,
              bodyJson: bodyJson,
              createdAt: now,
            ),
          );
      return;
    }

    if (existing.checksum != payload.ref.checksum ||
        existing.categoryCode != payload.categoryCode ||
        existing.levelCode != payload.levelCode ||
        existing.skillCodesJson != skillCodesJson ||
        existing.bodyKind != bodyKind ||
        existing.bodyJson != bodyJson) {
      throw const _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'TYPED_CONTENT_PAYLOAD_IMMUTABLE_CONFLICT',
          message:
              'A persisted typed content payload conflicts with its immutable revision.',
        ),
      );
    }
  }
'''
if old_function not in executor:
    raise SystemExit('executor content read anchor missing')
executor = executor.replace(old_function, new_function, 1)
helper_anchor = '''String _assetKind(String mediaType) {'''
if '_typedBodyJson(TypedContentBody body)' not in executor:
    helper = '''Map<String, Object?> _typedBodyJson(TypedContentBody body) {
  if (body is VocabularyBody) {
    return <String, Object?>{
      'kind': 'vocabulary',
      'term': body.term,
      'definition': body.definition,
      'partOfSpeech': body.partOfSpeech,
      'examples': body.examples,
    };
  }
  if (body is InterviewBody) {
    return <String, Object?>{
      'kind': 'interview',
      'prompt': body.prompt,
      'modelAnswer': body.modelAnswer,
      'keyPoints': body.keyPoints,
    };
  }
  if (body is TopicBody) {
    return <String, Object?>{
      'kind': 'topic',
      'sections': <Object?>[
        for (final section in body.sections)
          <String, Object?>{'heading': section.heading, 'text': section.text},
      ],
    };
  }
  if (body is PhraseBody) {
    return <String, Object?>{
      'kind': 'phrase',
      'phrase': body.phrase,
      'usage': body.usage,
      'examples': body.examples,
    };
  }
  if (body is ShadowingBody) {
    return <String, Object?>{
      'kind': 'shadowing',
      'transcript': body.transcript,
      'segments': <Object?>[
        for (final segment in body.segments)
          <String, Object?>{
            'order': segment.order,
            'text': segment.text,
            'startMs': segment.startMs,
            'endMs': segment.endMs,
          },
      ],
    };
  }
  throw StateError('Unsupported typed content body ${body.runtimeType}.');
}

'''
    if helper_anchor not in executor:
        raise SystemExit('executor helper anchor missing')
    executor = executor.replace(helper_anchor, helper + helper_anchor, 1)
executor_path.write_text(executor)

# Make the existing executor acceptance exercise the C2 typed projection.
executor_test = Path('mobile/careerspeak_app/test/data/local/drift_sync_plan_executor_test.dart')
test_source = executor_test.read_text()
if "typed_content_body.dart" not in test_source:
    test_source = test_source.replace(
        "import 'package:careerspeak_app/application/content_delivery/content_payload.dart';\n",
        "import 'package:careerspeak_app/application/content_delivery/content_payload.dart';\n"
        "import 'package:careerspeak_app/application/content_delivery/typed_content_body.dart';\n",
        1,
    )
old_payload = '''      ContentPayload(
        ref: ref,
        title: 'Dependency Injection',
        subtitle: 'Java Backend',
        description: 'Explain constructor injection and its tradeoffs.',
        category: 'Java Backend',
        level: 'Senior',
        minutes: 6,
        hasAudio: true,
      ),'''
new_payload = '''      ContentPayload.typed(
        ref: ref,
        title: 'Dependency Injection',
        subtitle: 'Java Backend',
        description: 'Explain constructor injection and its tradeoffs.',
        categoryCode: 'JAVA_BACKEND',
        category: 'Java Backend',
        levelCode: 'SENIOR',
        level: 'Senior',
        minutes: 6,
        hasAudio: true,
        skillCodes: const <String>['COMMUNICATION', 'SYSTEM_DESIGN'],
        body: InterviewBody(
          prompt: 'What is dependency injection?',
          modelAnswer: 'Dependencies are supplied externally.',
          keyPoints: const <String>['loose coupling', 'testability'],
        ),
      ),'''
if old_payload not in test_source:
    raise SystemExit('executor test payload anchor missing')
test_source = test_source.replace(old_payload, new_payload, 1)
assert_anchor = '''    expect(payload.title, 'Dependency Injection');
    expect(payload.minutes, 6);

    final asset ='''
assert_replacement = '''    expect(payload.title, 'Dependency Injection');
    expect(payload.minutes, 6);

    final typedPayload = await database
        .select(database.typedContentReads)
        .getSingle();
    expect(typedPayload.contentCode, 'JAVA_Q_001');
    expect(typedPayload.categoryCode, 'JAVA_BACKEND');
    expect(typedPayload.levelCode, 'SENIOR');
    expect(
      typedPayload.skillCodesJson,
      '["COMMUNICATION","SYSTEM_DESIGN"]',
    );
    expect(typedPayload.bodyKind, 'interview');
    expect(typedPayload.bodyJson, contains('"prompt":"What is dependency injection?"'));

    final asset ='''
if assert_anchor not in test_source:
    raise SystemExit('executor test assertion anchor missing')
test_source = test_source.replace(assert_anchor, assert_replacement, 1)
executor_test.write_text(test_source)

# Update migration qualification to schema v7 and add an explicit v6 -> v7 check.
migration_test = Path(
    'mobile/careerspeak_app/test/data/local/database/careerspeak_database_migration_test.dart'
)
migration = migration_test.read_text()
if "schema_v7.dart" not in migration:
    migration = migration.replace(
        "import '../../../generated_migrations/schema_v6.dart' as v6;\n",
        "import '../../../generated_migrations/schema_v6.dart' as v6;\n"
        "import '../../../generated_migrations/schema_v7.dart' as v7;\n",
        1,
    )
migration = migration.replace('to v6', 'to v7')
migration = migration.replace('migrateAndValidate(database, 6)', 'migrateAndValidate(database, 7)')
migration = migration.replace('v6.DatabaseAtV6', 'v7.DatabaseAtV7')
if "v6 to v7 adds typed content projection" not in migration:
    closing = '\n}\n'
    test_block = r'''

  test('v6 to v7 adds typed content projection without mutating C1 reads', () async {
    final schema = await verifier.schemaAt(6);
    final storedNow =
        DateTime.utc(2026, 10, 31, 8).millisecondsSinceEpoch ~/ 1000;

    final oldDatabase = v6.DatabaseAtV6(schema.newConnection());
    await oldDatabase
        .into(oldDatabase.contentCatalogReads)
        .insert(
          v6.ContentCatalogReadsCompanion.insert(
            contentCode: 'JAVA_DI_001',
            contentType: 'INTERVIEW',
            revision: 3,
            checksum:
                'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
            title: 'Dependency Injection',
            subtitle: 'Java Backend',
            description: 'Explain constructor injection and its tradeoffs.',
            category: 'Java Backend',
            level: 'Senior',
            minutes: 6,
            hasAudio: true,
            createdAt: storedNow,
          ),
        );
    await oldDatabase.close();

    final database = CareerSpeakDatabase(schema.newConnection());
    await verifier.migrateAndValidate(database, 7);
    await database.close();

    final migratedDatabase = v7.DatabaseAtV7(schema.newConnection());
    final common = await migratedDatabase
        .select(migratedDatabase.contentCatalogReads)
        .get();
    expect(common, hasLength(1));
    expect(common.single.contentCode, 'JAVA_DI_001');
    expect(
      await migratedDatabase.select(migratedDatabase.typedContentReads).get(),
      isEmpty,
    );
    await migratedDatabase.close();
  });
'''
    if not migration.endswith(closing):
        raise SystemExit('migration test closing anchor missing')
    migration = migration[:-len(closing)] + test_block + closing
migration_test.write_text(migration)

# File-backed durability test for the new C2 table.
restart_test = Path(
    'mobile/careerspeak_app/test/data/local/database/typed_content_read_restart_test.dart'
)
restart_test.write_text(r'''import 'dart:io';

import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('typed content projection survives file-backed close and reopen', () async {
    final directory = await Directory.systemTemp.createTemp('careerspeak-c2-typed-');
    final file = File('${directory.path}/careerspeak.sqlite');
    final now = DateTime.utc(2026, 10, 31, 9);

    final first = CareerSpeakDatabase(NativeDatabase(file));
    await first
        .into(first.typedContentReads)
        .insert(
          TypedContentReadsCompanion.insert(
            contentCode: 'JAVA_Q_001',
            contentType: 'INTERVIEW',
            revision: 3,
            checksum:
                'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
            categoryCode: 'JAVA_BACKEND',
            levelCode: 'SENIOR',
            skillCodesJson: '["COMMUNICATION","SYSTEM_DESIGN"]',
            bodyKind: 'interview',
            bodyJson:
                '{"kind":"interview","prompt":"What is dependency injection?","modelAnswer":"Dependencies are supplied externally.","keyPoints":["loose coupling","testability"]}',
            createdAt: now,
          ),
        );
    await first.close();

    final reopened = CareerSpeakDatabase(NativeDatabase(file));
    final row = await reopened.select(reopened.typedContentReads).getSingle();
    expect(row.contentCode, 'JAVA_Q_001');
    expect(row.revision, 3);
    expect(row.categoryCode, 'JAVA_BACKEND');
    expect(row.levelCode, 'SENIOR');
    expect(row.skillCodesJson, '["COMMUNICATION","SYSTEM_DESIGN"]');
    expect(row.bodyKind, 'interview');
    expect(row.bodyJson, contains('"keyPoints":["loose coupling","testability"]'));
    await reopened.close();

    await directory.delete(recursive: true);
  });
}
''')
