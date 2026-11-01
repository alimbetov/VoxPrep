import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_localized_content_repository.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  test('C4 one root switch exposes future localization coherently', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 11, 1, 10);

    await database
        .into(database.contentManifestStates)
        .insert(
          ContentManifestStatesCompanion.insert(
            id: const Value(1),
            schemaVersion: 1,
            currentContentVersion: 1,
            currentManifestChecksum: _rootV1,
            localePolicyContentVersion: const Value(1),
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
            checksum: _canonicalChecksum,
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

    await _seedCanonicalMembership(database, version: 1, code: 'CANONICAL_V1');
    await _seedCanonicalMembership(database, version: 2, code: 'CANONICAL_V2');
    await _seedFutureLocalization(database);

    final repository = DriftLocalizedContentRepository(database);
    final before = (await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru',
    )).getOrThrow();

    expect(before, isNotNull);
    expect(before!.usesCanonicalEnglishOnly, isTrue);
    expect(before.title, 'Canonical title');

    await (database.update(
      database.contentManifestStates,
    )..where((row) => row.id.equals(1))).write(
      ContentManifestStatesCompanion(
        currentContentVersion: const Value(2),
        currentManifestChecksum: const Value(_rootV2),
        localePolicyContentVersion: const Value(2),
        updatedAt: Value(now.add(const Duration(seconds: 1))),
      ),
    );

    final after = (await repository.resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru',
    )).getOrThrow();

    expect(after, isNotNull);
    expect(after!.usesCanonicalEnglishOnly, isFalse);
    expect(after.resolvedLocale, 'ru');
    expect(after.title, 'Будущая локализация');
  });
}

Future<void> _seedCanonicalMembership(
  CareerSpeakDatabase database, {
  required int version,
  required String code,
}) async {
  final now = DateTime.utc(2026, 11, 1, 10);
  await database
      .into(database.contentPackRevisions)
      .insert(
        ContentPackRevisionsCompanion.insert(
          packCode: code,
          variantKey: 'canonical',
          revision: 1,
          schemaVersion: 1,
          checksum: _packChecksum,
          state: 'CURRENT',
          sourceContentVersion: version,
          stagedAt: now,
          currentAt: Value(now),
        ),
      );
  await database
      .into(database.packContentRefs)
      .insert(
        PackContentRefsCompanion.insert(
          packCode: code,
          variantKey: 'canonical',
          packRevision: 1,
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          contentRevision: 1,
        ),
      );
}

Future<void> _seedFutureLocalization(CareerSpeakDatabase database) async {
  final now = DateTime.utc(2026, 11, 1, 10);
  await database
      .into(database.contentPackRevisions)
      .insert(
        ContentPackRevisionsCompanion.insert(
          packCode: 'RU_V2',
          variantKey: 'locale:ru',
          revision: 1,
          schemaVersion: 1,
          checksum: _packChecksum,
          state: 'CURRENT',
          sourceContentVersion: 2,
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
          title: const Value('Будущая локализация'),
          createdAt: now,
        ),
      );
  await database
      .into(database.packLocalizationRefs)
      .insert(
        PackLocalizationRefsCompanion.insert(
          packCode: 'RU_V2',
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

const _identity = ContentIdentity(
  code: 'JAVA_DI_001',
  type: ContentType.interview,
);
const _rootV1 =
    '1111111111111111111111111111111111111111111111111111111111111111';
const _rootV2 =
    '2222222222222222222222222222222222222222222222222222222222222222';
const _canonicalChecksum =
    '3333333333333333333333333333333333333333333333333333333333333333';
const _packChecksum =
    '4444444444444444444444444444444444444444444444444444444444444444';
const _localizedChecksum =
    '5555555555555555555555555555555555555555555555555555555555555555';
