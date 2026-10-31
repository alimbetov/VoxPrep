import 'dart:io';

import 'package:careerspeak_app/application/content_delivery/content_manifest.dart';
import 'package:careerspeak_app/application/content_sync/content_sync_planner.dart';
import 'package:careerspeak_app/application/content_sync/sync_models.dart';
import 'package:careerspeak_app/application/result/result.dart';
import 'package:careerspeak_app/data/local/database/careerspeak_database.dart';
import 'package:careerspeak_app/data/local/drift_sync_journal.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _root108 =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _root109 =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
const _pack109 =
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc';

void main() {
  test(
    'C4.8 interrupted durable sync reopens on the same immutable target without changing CURRENT',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'c4_sync_restart_',
      );
      final file = File('${directory.path}/careerspeak.sqlite');
      final now = DateTime.utc(2026, 10, 31, 18);

      CareerSpeakDatabase? database;
      try {
        database = CareerSpeakDatabase(NativeDatabase(file));
        await database
            .into(database.contentManifestStates)
            .insert(
              ContentManifestStatesCompanion.insert(
                id: const Value(1),
                schemaVersion: 1,
                currentContentVersion: 108,
                currentManifestChecksum: _root108,
                updatedAt: now,
              ),
            );

        final journal = DriftSyncJournal(database, now: () => now);
        final started = await journal.startOrCoalesce(
          runId: 'c4-run-109',
          trigger: SyncTrigger.startup,
          translationLocale: 'en',
        );
        expect((started as Success<SyncRunStart>).value, isA<SyncRunStarted>());

        final plan = const ContentSyncPlanner()
            .plan(
              local: SyncLocalSnapshot(
                currentContentVersion: 108,
                currentManifestChecksum: _root108,
                etag: null,
                currentPacks: const <PackRevisionRef>[],
              ),
              remote: RootContentManifest(
                schemaVersion: 1,
                contentVersion: 109,
                minimumAppContractVersion: 1,
                publishedAt: now,
                checksum: _root109,
                packs: <PackRevisionRef>[
                  PackRevisionRef(
                    identity: PackIdentity(
                      code: 'JAVA_SENIOR',
                      variant: 'canonical',
                    ),
                    revision: 9,
                    checksum: _pack109,
                  ),
                ],
                tombstones: const <ContentTombstone>[],
              ),
            )
            .getOrThrow();
        expect(
          await journal.persistPlan(runId: 'c4-run-109', plan: plan),
          isA<Success<void>>(),
        );

        await database.close();
        database = null;

        final reopened = CareerSpeakDatabase(NativeDatabase(file));
        database = reopened;
        final restartedJournal = DriftSyncJournal(
          reopened,
          now: () => now.add(const Duration(minutes: 1)),
        );

        final persistedSnapshot = (await restartedJournal.readLocalSnapshot())
            .getOrThrow();
        expect(persistedSnapshot.currentContentVersion, 108);
        expect(persistedSnapshot.currentManifestChecksum, _root108);

        final restarted = await restartedJournal.startOrCoalesce(
          runId: 'c4-run-after-restart',
          trigger: SyncTrigger.startup,
          translationLocale: 'en',
        );
        expect(restarted, isA<Success<SyncRunStart>>());
        final coalesced = (restarted as Success<SyncRunStart>).value;
        expect(coalesced, isA<SyncRunCoalesced>());
        expect(coalesced.runId, 'c4-run-109');

        final run = await (reopened.select(
          reopened.syncRuns,
        )..where((row) => row.runId.equals('c4-run-109'))).getSingle();
        expect(run.targetContentVersion, 109);
        expect(run.targetSchemaVersion, 1);
        expect(run.state, SyncRunState.planning.storageCode);
        expect(run.resyncRequested, isTrue);

        final current = await reopened
            .select(reopened.contentManifestStates)
            .getSingle();
        expect(current.currentContentVersion, 108);
        expect(current.currentManifestChecksum, _root108);
      } finally {
        await database?.close();
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      }
    },
  );
}
