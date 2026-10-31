import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/locale_fallback.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_localized_content_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'localized snapshot survives reopen and falls back offline without changing root identity',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-c1-localization-restart-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/careerspeak.sqlite');

      var database = CareerSpeakDatabase(NativeDatabase(file));
      await _seedCurrentLocalizedSnapshot(database);
      await database.close();

      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);
      final repository = DriftLocalizedContentRepository(database);

      final russian = (await repository.resolve(
        identity: _identity,
        contentRevision: 1,
        requestedLocale: 'ru',
      )).getOrThrow();
      expect(russian, isNotNull);
      expect(russian!.resolvedLocale, 'ru');
      expect(russian.fallbackKind, LocaleFallbackKind.exact);
      expect(russian.title, 'Русский заголовок');
      expect(russian.description, 'Canonical description');
      expect(russian.translation, 'Русский перевод');

      final regionalRussian = (await repository.resolve(
        identity: _identity,
        contentRevision: 1,
        requestedLocale: 'ru-KZ',
      )).getOrThrow();
      expect(regionalRussian, isNotNull);
      expect(regionalRussian!.resolvedLocale, 'ru');
      expect(regionalRussian.fallbackKind, LocaleFallbackKind.configured);
      expect(regionalRussian.title, 'Русский заголовок');

      final kazakh = (await repository.resolve(
        identity: _identity,
        contentRevision: 1,
        requestedLocale: 'kk',
      )).getOrThrow();
      expect(kazakh, isNotNull);
      expect(kazakh!.resolvedLocale, 'en');
      expect(kazakh.fallbackKind, LocaleFallbackKind.canonicalEnglish);
      expect(kazakh.usesCanonicalEnglishOnly, isTrue);
      expect(kazakh.title, 'Canonical title');

      final root = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(root.currentContentVersion, 42);
      expect(root.currentManifestChecksum, _rootChecksum);
    },
  );

  test(
    'tombstoned canonical content stays invisible after file-backed reopen',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-c1-tombstone-restart-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/careerspeak.sqlite');

      var database = CareerSpeakDatabase(NativeDatabase(file));
      await _seedCurrentLocalizedSnapshot(database);
      await (database.update(database.localContentRecords)..where(
            (row) =>
                row.contentCode.equals(_identity.code) &
                row.contentType.equals('INTERVIEW'),
          ))
          .write(
            const LocalContentRecordsCompanion(
              snapshotState: Value('TOMBSTONED'),
            ),
          );
      await database.close();

      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);
      final repository = DriftLocalizedContentRepository(database);

      final resolved = (await repository.resolve(
        identity: _identity,
        contentRevision: 1,
        requestedLocale: 'ru',
      )).getOrThrow();

      expect(resolved, isNull);
      final rows =
          await (database.select(database.localContentRecords)..where(
                (row) =>
                    row.contentCode.equals(_identity.code) &
                    row.contentType.equals('INTERVIEW'),
              ))
              .get();
      expect(rows, hasLength(1));
      expect(rows.single.snapshotState, 'TOMBSTONED');
    },
  );
}

Future<void> _seedCurrentLocalizedSnapshot(CareerSpeakDatabase database) async {
  final now = DateTime.utc(2026, 10, 31, 5);

  await database
      .into(database.contentManifestStates)
      .insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 1,
          currentContentVersion: 42,
          currentManifestChecksum: _rootChecksum,
          localePolicyContentVersion: const Value(42),
          remoteContentVersionSeen: const Value(42),
          remoteManifestChecksum: const Value(_rootChecksum),
          lastSuccessfulSyncAt: Value(now),
          updatedAt: now,
        ),
      );
  await database
      .into(database.localeFallbackRules)
      .insert(
        LocaleFallbackRulesCompanion.insert(
          locale: 'ru-KZ',
          fallbackOrder: 0,
          fallbackLocale: 'ru',
          sourceContentVersion: 42,
        ),
      );
  await database
      .into(database.localeFallbackRules)
      .insert(
        LocaleFallbackRulesCompanion.insert(
          locale: 'ru-KZ',
          fallbackOrder: 1,
          fallbackLocale: 'en',
          sourceContentVersion: 42,
        ),
      );

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

  await database
      .into(database.contentPackRevisions)
      .insert(
        ContentPackRevisionsCompanion.insert(
          packCode: 'JAVA_SENIOR_RU',
          variantKey: 'locale:ru',
          revision: 3,
          schemaVersion: 1,
          checksum: _packChecksum,
          state: 'CURRENT',
          sourceContentVersion: 42,
          stagedAt: now,
          verifiedAt: Value(now),
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
          localizationRevision: 2,
          checksum: _localizedChecksum,
          title: const Value('Русский заголовок'),
          translation: const Value('Русский перевод'),
          createdAt: now,
        ),
      );
  await database
      .into(database.packLocalizationRefs)
      .insert(
        PackLocalizationRefsCompanion.insert(
          packCode: 'JAVA_SENIOR_RU',
          variantKey: 'locale:ru',
          packRevision: 3,
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          contentRevision: 1,
          locale: 'ru',
          localizationRevision: 2,
          checksum: _localizedChecksum,
        ),
      );
}

const _identity = ContentIdentity(
  code: 'JAVA_DI_001',
  type: ContentType.interview,
);

const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _canonicalChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _packChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
const _localizedChecksum =
    'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd';
