import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_localized_content_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  test('stale Backend fallback policy fails closed', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await _seedCanonicalAndRussian(database, contentVersion: 2);
    await _seedFallback(
      database,
      locale: 'ru-KZ',
      sourceContentVersion: 1,
      fallbackLocales: const <String>['ru', 'en'],
    );

    final result = await DriftLocalizedContentRepository(database).resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru-KZ',
    );

    expect(result, isA<FailureResult>());
    expect(
      (result as FailureResult).failure.code,
      'LOCALIZED_CONTENT_READ_MODEL_INVALID',
    );
  });

  test('missing Backend rule never invents base-language fallback', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await _seedCanonicalAndRussian(database, contentVersion: 2);

    final resolved = (await DriftLocalizedContentRepository(database).resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru-KZ',
    )).getOrThrow();

    expect(resolved, isNotNull);
    expect(resolved!.resolvedLocale, 'en');
    expect(resolved.fallbackKind, LocaleFallbackKind.canonicalEnglish);
    expect(resolved.matchedLocalizationLocales, isEmpty);
    expect(resolved.title, 'Canonical title');
  });
}

Future<void> _seedCanonicalAndRussian(
  CareerSpeakDatabase database, {
  required int contentVersion,
}) async {
  final now = DateTime.utc(2026, 10, 31, 6, 30);
  await database
      .into(database.contentManifestStates)
      .insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 1,
          currentContentVersion: contentVersion,
          currentManifestChecksum: _rootChecksum,
          updatedAt: now,
        ),
      );
  await database
      .into(database.localContentRecords)
      .insert(
        LocalContentRecordsCompanion.insert(
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          revision: 1,
          checksum: _contentChecksum,
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
          checksum: _contentChecksum,
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
  await database
      .into(database.contentPackRevisions)
      .insert(
        ContentPackRevisionsCompanion.insert(
          packCode: 'JAVA_SENIOR_RU',
          variantKey: 'locale:ru',
          revision: 1,
          schemaVersion: 1,
          checksum: _packChecksum,
          state: 'CURRENT',
          sourceContentVersion: contentVersion,
          stagedAt: now,
          currentAt: Value(now),
        ),
      );
  await database
      .into(database.localizedContentReads)
      .insert(
        LocalizedContentReadsCompanion.insert(
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          contentRevision: 1,
          locale: 'ru',
          localizationRevision: 1,
          checksum: _localizedChecksum,
          title: const Value('Русский заголовок'),
          createdAt: now,
        ),
      );
  await database
      .into(database.packLocalizationRefs)
      .insert(
        PackLocalizationRefsCompanion.insert(
          packCode: 'JAVA_SENIOR_RU',
          variantKey: 'locale:ru',
          packRevision: 1,
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          contentRevision: 1,
          locale: 'ru',
          localizationRevision: 1,
          checksum: _localizedChecksum,
        ),
      );
}

Future<void> _seedFallback(
  CareerSpeakDatabase database, {
  required String locale,
  required int sourceContentVersion,
  required List<String> fallbackLocales,
}) async {
  for (var order = 0; order < fallbackLocales.length; order += 1) {
    await database
        .into(database.localeFallbackRules)
        .insert(
          LocaleFallbackRulesCompanion.insert(
            locale: locale,
            fallbackOrder: order,
            fallbackLocale: fallbackLocales[order],
            sourceContentVersion: sourceContentVersion,
          ),
        );
  }
}

const _identity = ContentIdentity(
  code: 'JAVA_DI_001',
  type: ContentType.interview,
);
const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _contentChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _packChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _localizedChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
