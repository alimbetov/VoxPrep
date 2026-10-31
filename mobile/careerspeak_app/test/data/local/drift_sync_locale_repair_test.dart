import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:careerspeak_app/domain/content_identity.dart';
import 'package:careerspeak_app/domain/content_item.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database_factory.dart';

void main() {
  test(
    'missing localized payload marks CURRENT locale pack for same-root repair',
    () async {
      final database = createTestDatabase();
      addTearDown(database.close);
      final now = DateTime.utc(2026, 10, 31, 5, 30);
      final localePack = PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'locale:ru'),
        revision: 4,
        checksum: _packChecksum,
      );

      await database
          .into(database.contentManifestStates)
          .insert(
            ContentManifestStatesCompanion.insert(
              id: const Value(1),
              schemaVersion: 1,
              currentContentVersion: 108,
              currentManifestChecksum: _rootChecksum,
              localePolicyContentVersion: const Value(108),
              updatedAt: now,
            ),
          );
      await database
          .into(database.contentPackRevisions)
          .insert(
            ContentPackRevisionsCompanion.insert(
              packCode: localePack.identity.code,
              variantKey: localePack.identity.variant,
              revision: localePack.revision,
              schemaVersion: 1,
              checksum: localePack.checksum,
              state: 'CURRENT',
              sourceContentVersion: 108,
              stagedAt: now,
              currentAt: Value(now),
            ),
          );
      await database
          .into(database.packLocalizationRefs)
          .insert(
            PackLocalizationRefsCompanion.insert(
              packCode: localePack.identity.code,
              variantKey: localePack.identity.variant,
              packRevision: localePack.revision,
              contentCode: _identity.code,
              contentType: 'INTERVIEW',
              contentRevision: 1,
              locale: 'ru',
              localizationRevision: 2,
              checksum: _localizedChecksum,
            ),
          );

      final snapshot = (await DriftSyncJournal(
        database,
      ).readLocalSnapshot()).getOrThrow();

      expect(snapshot.contentPayloadRepairPacks, <PackIdentity>{
        localePack.identity,
      });

      final remote = RootContentManifest(
        schemaVersion: 1,
        contentVersion: 108,
        minimumAppContractVersion: 1,
        publishedAt: now,
        checksum: _rootChecksum,
        packs: <PackRevisionRef>[localePack],
        tombstones: const <ContentTombstone>[],
      );
      final plan = const ContentSyncPlanner()
          .plan(local: snapshot, remote: remote)
          .getOrThrow();
      expect(plan.rootChanged, isFalse);
      expect(plan.changedPacks, hasLength(1));
      expect(plan.changedPacks.single.identity, localePack.identity);
    },
  );

  test('complete localized payload graph needs no repair', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 31, 5, 30);

    await _seedCompleteLocalePack(database, now);

    final snapshot = (await DriftSyncJournal(
      database,
    ).readLocalSnapshot()).getOrThrow();
    expect(snapshot.contentPayloadRepairPacks, isEmpty);
  });
}

Future<void> _seedCompleteLocalePack(
  CareerSpeakDatabase database,
  DateTime now,
) async {
  await database
      .into(database.contentManifestStates)
      .insert(
        ContentManifestStatesCompanion.insert(
          id: const Value(1),
          schemaVersion: 1,
          currentContentVersion: 108,
          currentManifestChecksum: _rootChecksum,
          updatedAt: now,
        ),
      );
  await database
      .into(database.contentPackRevisions)
      .insert(
        ContentPackRevisionsCompanion.insert(
          packCode: 'JAVA_SENIOR',
          variantKey: 'locale:ru',
          revision: 4,
          schemaVersion: 1,
          checksum: _packChecksum,
          state: 'CURRENT',
          sourceContentVersion: 108,
          stagedAt: now,
          currentAt: Value(now),
        ),
      );
  await database
      .into(database.packLocalizationRefs)
      .insert(
        PackLocalizationRefsCompanion.insert(
          packCode: 'JAVA_SENIOR',
          variantKey: 'locale:ru',
          packRevision: 4,
          contentCode: _identity.code,
          contentType: 'INTERVIEW',
          contentRevision: 1,
          locale: 'ru',
          localizationRevision: 2,
          checksum: _localizedChecksum,
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
          createdAt: now,
        ),
      );
}

const _identity = ContentIdentity(
  code: 'JAVA_DI_001',
  type: ContentType.interview,
);
const _rootChecksum =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _packChecksum =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _localizedChecksum =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';
