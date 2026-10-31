import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_localized_content_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  late CareerSpeakDatabase database;
  late DriftLocalizedContentRepository repository;

  setUp(() async {
    database = createTestDatabase();
    repository = DriftLocalizedContentRepository(database);
    await _seedCanonical(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('exact locale overlays language fallback field by field', () async {
    await _seedLocalization(
      database,
      locale: 'ru',
      title: 'Русский заголовок',
      translation: 'Базовый перевод',
      hint: 'Базовая подсказка',
    );
    await _seedLocalization(
      database,
      locale: 'ru-KZ',
      title: 'Точный заголовок',
      explanation: 'Точное объяснение',
    );

    final resolved = (await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru-kz',
    )).getOrThrow();

    expect(resolved, isNotNull);
    expect(resolved!.requestedLocale, 'ru-KZ');
    expect(resolved.resolvedLocale, 'ru-KZ');
    expect(resolved.fallbackKind, LocaleFallbackKind.exact);
    expect(resolved.matchedLocalizationLocales, <String>['ru-KZ', 'ru']);
    expect(resolved.title, 'Точный заголовок');
    expect(resolved.subtitle, 'Canonical subtitle');
    expect(resolved.description, 'Canonical description');
    expect(resolved.translation, 'Базовый перевод');
    expect(resolved.hint, 'Базовая подсказка');
    expect(resolved.explanation, 'Точное объяснение');
  });

  test('superseded exact locale is ignored and language fallback wins', () async {
    await _seedLocalization(
      database,
      locale: 'ru',
      title: 'Текущий русский заголовок',
    );
    await _seedLocalization(
      database,
      locale: 'ru-KZ',
      state: 'SUPERSEDED',
      title: 'Устаревший точный заголовок',
    );

    final resolved = (await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru-KZ',
    )).getOrThrow();

    expect(resolved, isNotNull);
    expect(resolved!.resolvedLocale, 'ru');
    expect(resolved.fallbackKind, LocaleFallbackKind.language);
    expect(resolved.matchedLocalizationLocales, <String>['ru']);
    expect(resolved.title, 'Текущий русский заголовок');
  });

  test('missing locale packs fall back to canonical English offline', () async {
    final resolved = (await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'kk-KZ',
    )).getOrThrow();

    expect(resolved, isNotNull);
    expect(resolved!.resolvedLocale, 'en');
    expect(resolved.fallbackKind, LocaleFallbackKind.canonicalEnglish);
    expect(resolved.matchedLocalizationLocales, isEmpty);
    expect(resolved.usesCanonicalEnglishOnly, isTrue);
    expect(resolved.title, 'Canonical title');
    expect(resolved.subtitle, 'Canonical subtitle');
    expect(resolved.description, 'Canonical description');
    expect(resolved.translation, isNull);
    expect(resolved.hint, isNull);
    expect(resolved.explanation, isNull);
  });

  test('unreferenced localized payload is never learner-visible', () async {
    await _insertLocalizedRead(
      database,
      locale: 'ru',
      checksum: _localizedChecksum,
      title: 'Orphan localization',
    );

    final resolved = (await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru',
    )).getOrThrow();

    expect(resolved, isNotNull);
    expect(resolved!.usesCanonicalEnglishOnly, isTrue);
    expect(resolved.title, 'Canonical title');
  });

  test('localization checksum drift fails closed', () async {
    await _seedLocalization(
      database,
      locale: 'ru',
      title: 'Русский заголовок',
      refChecksum: _otherLocalizedChecksum,
    );

    final result = await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru',
    );

    expect(result, isA<FailureResult>());
    expect(
      (result as FailureResult).failure.code,
      'LOCALIZED_CONTENT_READ_MODEL_INVALID',
    );
  });

  test('ambiguous CURRENT localization revisions fail closed', () async {
    await _seedLocalization(
      database,
      locale: 'ru',
      packCode: 'PACK_RU_A',
      localizationRevision: 1,
      title: 'Русский A',
    );
    await _seedLocalization(
      database,
      locale: 'ru',
      packCode: 'PACK_RU_B',
      localizationRevision: 2,
      payloadChecksum: _otherLocalizedChecksum,
      refChecksum: _otherLocalizedChecksum,
      title: 'Русский B',
    );

    final result = await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru',
    );

    expect(result, isA<FailureResult>());
    expect(
      (result as FailureResult).failure.code,
      'LOCALIZED_CONTENT_READ_MODEL_INVALID',
    );
  });

  test('invalid requested locale fails before reading localization rows', () async {
    final result = await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru_KZ',
    );

    expect(result, isA<FailureResult>());
    expect((result as FailureResult).failure.code, 'LOCALE_INVALID');
  });
}

Future<void> _seedCanonical(CareerSpeakDatabase database) async {
  final now = DateTime.utc(2026, 10, 31, 4);
  await database
      .into(database.localContentRecords)
      .insert(
        LocalContentRecordsCompanion.insert(
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          revision: 1,
          checksum: _canonicalChecksum,
          sortOrder: const Value(10),
          publishedAt: Value(now),
          snapshotState: 'CURRENT',
          sourceSchemaVersion: 1,
          createdAt: now,
        ),
      );
  await database
      .into(database.contentCatalogReads)
      .insert(
        ContentCatalogReadsCompanion.insert(
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          revision: 1,
          checksum: _canonicalChecksum,
          title: 'Canonical title',
          subtitle: 'Canonical subtitle',
          description: 'Canonical description',
          category: 'Java Backend',
          level: 'Senior',
          minutes: 8,
          hasAudio: false,
          createdAt: now,
        ),
      );
}

Future<void> _seedLocalization(
  CareerSpeakDatabase database, {
  required String locale,
  String state = 'CURRENT',
  String? packCode,
  int localizationRevision = 1,
  String payloadChecksum = _localizedChecksum,
  String? title,
  String? subtitle,
  String? description,
  String? translation,
  String? hint,
  String? explanation,
  String refChecksum = _localizedChecksum,
}) async {
  final now = DateTime.utc(2026, 10, 31, 4, 5);
  final resolvedPackCode = packCode ?? 'PACK_${locale.replaceAll('-', '_')}';
  await database
      .into(database.contentPackRevisions)
      .insert(
        ContentPackRevisionsCompanion.insert(
          packCode: resolvedPackCode,
          variantKey: 'locale:$locale',
          revision: 1,
          schemaVersion: 1,
          checksum: _packChecksum,
          state: state,
          sourceContentVersion: 1,
          stagedAt: now,
          currentAt: Value(state == 'CURRENT' ? now : null),
          supersededAt: Value(state == 'SUPERSEDED' ? now : null),
        ),
      );
  await _insertLocalizedRead(
    database,
    locale: locale,
    localizationRevision: localizationRevision,
    checksum: payloadChecksum,
    title: title,
    subtitle: subtitle,
    description: description,
    translation: translation,
    hint: hint,
    explanation: explanation,
  );
  await database
      .into(database.packLocalizationRefs)
      .insert(
        PackLocalizationRefsCompanion.insert(
          packCode: resolvedPackCode,
          variantKey: 'locale:$locale',
          packRevision: 1,
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          contentRevision: 1,
          locale: locale,
          localizationRevision: localizationRevision,
          checksum: refChecksum,
        ),
      );
}

Future<void> _insertLocalizedRead(
  CareerSpeakDatabase database, {
  required String locale,
  int localizationRevision = 1,
  required String checksum,
  String? title,
  String? subtitle,
  String? description,
  String? translation,
  String? hint,
  String? explanation,
}) async {
  await database
      .into(database.localizedContentReads)
      .insert(
        LocalizedContentReadsCompanion.insert(
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          contentRevision: 1,
          locale: locale,
          localizationRevision: localizationRevision,
          checksum: checksum,
          title: Value(title),
          subtitle: Value(subtitle),
          description: Value(description),
          translation: Value(translation),
          hint: Value(hint),
          explanation: Value(explanation),
          createdAt: DateTime.utc(2026, 10, 31, 4, 5),
        ),
      );
}

const _identity = ContentIdentity(
  code: 'JAVA_DI_001',
  type: ContentType.interview,
);

const _canonicalChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _packChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _localizedChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _otherLocalizedChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
