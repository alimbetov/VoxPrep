import 'package:drift/drift.dart';

import '../../application/content_delivery/content_manifest.dart';
import '../../application/content_sync/sync_models.dart';
import '../../application/ports/sync_journal.dart';
import '../../application/result/result.dart';
import '../../domain/content_item.dart';
import 'database/careerspeak_database.dart' hide LocaleFallbackRule;

final class DriftSyncJournal implements SyncJournal {
  DriftSyncJournal(this._database, {DateTime Function()? now})
    : _now = now ?? (() => DateTime.now().toUtc());

  final CareerSpeakDatabase _database;
  final DateTime Function() _now;

  @override
  Future<Result<SyncLocalSnapshot>> readLocalSnapshot() async {
    try {
      final manifest = await (_database.select(
        _database.contentManifestStates,
      )..where((row) => row.id.equals(1))).getSingleOrNull();
      final currentRows = await (_database.select(
        _database.contentPackRevisions,
      )..where((row) => row.state.equals('CURRENT'))).get();

      final currentVersion =
          manifest == null || manifest.currentContentVersion <= 0
          ? null
          : manifest.currentContentVersion;

      if (currentVersion == null && currentRows.isNotEmpty) {
        return const FailureResult(
          ApplicationFailure(
            code: 'LOCAL_SYNC_STATE_CORRUPT',
            message:
                'CURRENT pack revisions exist without a CURRENT root snapshot.',
          ),
        );
      }

      final packs = <PackRevisionRef>[];
      final contentPayloadRepairPacks = <PackIdentity>{};
      for (final row in currentRows) {
        final identity = PackIdentity(
          code: row.packCode,
          variant: row.variantKey,
        );
        packs.add(
          PackRevisionRef(
            identity: identity,
            revision: row.revision,
            checksum: row.checksum,
          ),
        );
        if (row.variantKey != 'canonical') {
          final localizationRefs =
              await (_database.select(_database.packLocalizationRefs)..where(
                    (ref) =>
                        ref.packCode.equals(row.packCode) &
                        ref.variantKey.equals(row.variantKey) &
                        ref.packRevision.equals(row.revision),
                  ))
                  .get();
          for (final ref in localizationRefs) {
            final payload =
                await (_database.select(_database.localizedContentReads)..where(
                      (content) =>
                          content.contentCode.equals(ref.contentCode) &
                          content.contentType.equals(ref.contentType) &
                          content.contentRevision.equals(ref.contentRevision) &
                          content.locale.equals(ref.locale) &
                          content.localizationRevision.equals(
                            ref.localizationRevision,
                          ),
                    ))
                    .getSingleOrNull();
            if (payload == null || payload.checksum != ref.checksum) {
              contentPayloadRepairPacks.add(identity);
              break;
            }
          }
          continue;
        }

        final refs =
            await (_database.select(_database.packContentRefs)..where(
                  (ref) =>
                      ref.packCode.equals(row.packCode) &
                      ref.variantKey.equals(row.variantKey) &
                      ref.packRevision.equals(row.revision),
                ))
                .get();
        for (final ref in refs) {
          final local =
              await (_database.select(_database.localContentRecords)..where(
                    (content) =>
                        content.contentCode.equals(ref.contentCode) &
                        content.contentType.equals(ref.contentType) &
                        content.revision.equals(ref.contentRevision),
                  ))
                  .getSingleOrNull();
          final payload =
              await (_database.select(_database.contentCatalogReads)..where(
                    (content) =>
                        content.contentCode.equals(ref.contentCode) &
                        content.contentType.equals(ref.contentType) &
                        content.revision.equals(ref.contentRevision),
                  ))
                  .getSingleOrNull();
          if (local == null ||
              local.snapshotState != 'CURRENT' ||
              payload == null ||
              payload.checksum != local.checksum) {
            contentPayloadRepairPacks.add(identity);
            break;
          }
        }
      }

      var localePolicyRepairRequired =
          currentVersion != null &&
          manifest!.localePolicyContentVersion != currentVersion;
      final currentLocaleFallbacks = <LocaleFallbackRule>[];
      if (currentVersion != null) {
        final policyRows =
            await (_database.select(_database.localeFallbackRules)..orderBy([
                  (row) => OrderingTerm.asc(row.locale),
                  (row) => OrderingTerm.asc(row.fallbackOrder),
                ]))
                .get();
        final fallbackByLocale = <String, List<String>>{};
        final expectedOrderByLocale = <String, int>{};
        for (final row in policyRows) {
          if (row.sourceContentVersion != currentVersion) {
            localePolicyRepairRequired = true;
          }
          final expectedOrder = expectedOrderByLocale[row.locale] ?? 0;
          if (row.fallbackOrder != expectedOrder) {
            localePolicyRepairRequired = true;
          }
          expectedOrderByLocale[row.locale] = expectedOrder + 1;
          fallbackByLocale
              .putIfAbsent(row.locale, () => <String>[])
              .add(row.fallbackLocale);
        }
        for (final entry in fallbackByLocale.entries) {
          try {
            currentLocaleFallbacks.add(
              LocaleFallbackRule(
                locale: entry.key,
                fallbackLocales: entry.value,
              ),
            );
          } on ArgumentError {
            localePolicyRepairRequired = true;
          }
        }
      }

      return Success(
        SyncLocalSnapshot(
          currentContentVersion: currentVersion,
          currentManifestChecksum: currentVersion == null
              ? null
              : manifest!.currentManifestChecksum,
          etag: currentVersion == null ? null : manifest!.etag,
          currentPacks: packs,
          contentPayloadRepairPacks: contentPayloadRepairPacks,
          currentLocaleFallbacks: currentLocaleFallbacks,
          localePolicyRepairRequired: localePolicyRepairRequired,
        ),
      );
    } on ArgumentError catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'LOCAL_SYNC_STATE_CORRUPT',
          message: 'Local CURRENT metadata violates the sync contract.',
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    } catch (error) {
      return FailureResult(_databaseFailure('SYNC_JOURNAL_READ_FAILED', error));
    }
  }

  @override
  Future<Result<SyncRunStart>> startOrCoalesce({
    required String runId,
    required SyncTrigger trigger,
    required String translationLocale,
  }) async {
    final normalizedRunId = runId.trim();
    final normalizedLocale = translationLocale.trim();
    if (normalizedRunId.isEmpty || normalizedLocale.isEmpty) {
      return const FailureResult(
        ApplicationFailure(
          code: 'INVALID_SYNC_RUN_REQUEST',
          message: 'Sync run id and translation locale must not be blank.',
        ),
      );
    }

    try {
      final start = await _database.transaction<SyncRunStart>(() async {
        final activeCodes = SyncRunState.values
            .where((state) => !state.terminal)
            .map((state) => state.storageCode)
            .toList(growable: false);
        final active =
            await (_database.select(_database.syncRuns)
                  ..where((row) => row.state.isIn(activeCodes))
                  ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
                  ..limit(1))
                .getSingleOrNull();
        final now = _now();

        if (active != null) {
          await (_database.update(
            _database.syncRuns,
          )..where((row) => row.runId.equals(active.runId))).write(
            SyncRunsCompanion(
              resyncRequested: const Value(true),
              updatedAt: Value(now),
            ),
          );
          return SyncRunCoalesced(active.runId);
        }

        final manifest = await (_database.select(
          _database.contentManifestStates,
        )..where((row) => row.id.equals(1))).getSingleOrNull();
        final fromVersion =
            manifest == null || manifest.currentContentVersion <= 0
            ? null
            : manifest.currentContentVersion;

        await _database
            .into(_database.syncRuns)
            .insert(
              SyncRunsCompanion.insert(
                runId: normalizedRunId,
                trigger: trigger.storageCode,
                translationLocale: normalizedLocale,
                fromContentVersion: Value(fromVersion),
                state: SyncRunState.created.storageCode,
                startedAt: now,
                updatedAt: now,
              ),
            );
        return SyncRunStarted(normalizedRunId);
      });
      return Success(start);
    } catch (error) {
      return FailureResult(_databaseFailure('SYNC_RUN_START_FAILED', error));
    }
  }

  @override
  Future<Result<void>> persistPlan({
    required String runId,
    required SyncPlan plan,
  }) async {
    try {
      await _database.transaction(() async {
        final run = await (_database.select(
          _database.syncRuns,
        )..where((row) => row.runId.equals(runId))).getSingleOrNull();
        if (run == null) {
          throw const _SyncJournalInvariant(
            ApplicationFailure(
              code: 'SYNC_RUN_NOT_FOUND',
              message: 'The sync run does not exist.',
            ),
          );
        }

        final currentState = SyncRunState.fromStorage(run.state);
        if (currentState.terminal) {
          throw const _SyncJournalInvariant(
            ApplicationFailure(
              code: 'SYNC_RUN_TERMINAL',
              message: 'A terminal sync run cannot accept a new plan.',
            ),
          );
        }
        if (run.targetContentVersion != null &&
            run.targetContentVersion != plan.target.contentVersion) {
          throw const _SyncJournalInvariant(
            ApplicationFailure(
              code: 'SYNC_TARGET_IMMUTABLE',
              message: 'A sync run cannot change its target content version.',
            ),
          );
        }
        if (run.targetSchemaVersion != null &&
            run.targetSchemaVersion != plan.target.schemaVersion) {
          throw const _SyncJournalInvariant(
            ApplicationFailure(
              code: 'SYNC_TARGET_IMMUTABLE',
              message: 'A sync run cannot change its target schema version.',
            ),
          );
        }

        await (_database.delete(
          _database.syncPackUpdates,
        )..where((row) => row.runId.equals(runId))).go();
        await (_database.delete(
          _database.syncTombstones,
        )..where((row) => row.runId.equals(runId))).go();

        final now = _now();
        await (_database.update(
          _database.syncRuns,
        )..where((row) => row.runId.equals(runId))).write(
          SyncRunsCompanion(
            targetContentVersion: Value(plan.target.contentVersion),
            targetSchemaVersion: Value(plan.target.schemaVersion),
            state: Value(SyncRunState.planning.storageCode),
            updatedAt: Value(now),
          ),
        );

        for (final pack in plan.changedPacks) {
          await _database
              .into(_database.syncPackUpdates)
              .insert(
                SyncPackUpdatesCompanion.insert(
                  runId: runId,
                  packCode: pack.identity.code,
                  variantKey: pack.identity.variant,
                  targetRevision: pack.revision,
                  targetChecksum: pack.checksum,
                  state: SyncPackUpdateState.planned.storageCode,
                  updatedAt: now,
                ),
              );
        }

        for (final tombstone in plan.tombstones) {
          await _database
              .into(_database.syncTombstones)
              .insert(
                SyncTombstonesCompanion.insert(
                  runId: runId,
                  contentCode: tombstone.identity.code,
                  contentType: _contentTypeToStorage(tombstone.identity.type),
                  revision: Value(tombstone.revision),
                  reason: tombstone.reason,
                  state: SyncTombstoneState.planned.storageCode,
                ),
              );
        }
      });
      return const Success(null);
    } on _SyncJournalInvariant catch (error) {
      return FailureResult(error.failure);
    } on FormatException catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'LOCAL_SYNC_STATE_CORRUPT',
          message: 'Persisted sync run state is not supported.',
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    } catch (error) {
      return FailureResult(_databaseFailure('SYNC_PLAN_WRITE_FAILED', error));
    }
  }

  @override
  Future<Result<void>> transitionRun({
    required String runId,
    required SyncRunState state,
    ApplicationFailure? failure,
  }) async {
    try {
      final result = await _database.transaction<Result<void>>(() async {
        final run = await (_database.select(
          _database.syncRuns,
        )..where((row) => row.runId.equals(runId))).getSingleOrNull();
        if (run == null) {
          return const FailureResult(
            ApplicationFailure(
              code: 'SYNC_RUN_NOT_FOUND',
              message: 'The sync run does not exist.',
            ),
          );
        }

        final currentState = SyncRunState.fromStorage(run.state);
        if (currentState.terminal) {
          if (currentState == state) return const Success(null);
          return const FailureResult(
            ApplicationFailure(
              code: 'SYNC_RUN_TERMINAL',
              message: 'A terminal sync run is immutable.',
            ),
          );
        }

        final now = _now();
        await (_database.update(
          _database.syncRuns,
        )..where((row) => row.runId.equals(runId))).write(
          SyncRunsCompanion(
            state: Value(state.storageCode),
            retryable: Value(
              failure?.retryable ?? state == SyncRunState.failedRetryable,
            ),
            errorCode: Value(failure?.code),
            errorMessage: Value(failure?.message),
            updatedAt: Value(now),
            finishedAt: state.terminal ? Value(now) : const Value.absent(),
          ),
        );
        return const Success(null);
      });
      return result;
    } on FormatException catch (error) {
      return FailureResult(
        ApplicationFailure(
          code: 'LOCAL_SYNC_STATE_CORRUPT',
          message: 'Persisted sync run state is not supported.',
          details: <String, Object?>{'errorType': error.runtimeType.toString()},
        ),
      );
    } catch (error) {
      return FailureResult(
        _databaseFailure('SYNC_RUN_TRANSITION_FAILED', error),
      );
    }
  }

  ApplicationFailure _databaseFailure(String code, Object error) {
    return ApplicationFailure(
      code: code,
      message: 'Local sync journal operation failed.',
      retryable: true,
      details: <String, Object?>{'errorType': error.runtimeType.toString()},
    );
  }
}

final class _SyncJournalInvariant implements Exception {
  const _SyncJournalInvariant(this.failure);

  final ApplicationFailure failure;
}

String _contentTypeToStorage(ContentType type) => switch (type) {
  ContentType.vocabulary => 'VOCABULARY',
  ContentType.interview => 'INTERVIEW',
  ContentType.topic => 'TOPIC',
  ContentType.shadowing => 'SHADOWING',
  ContentType.phrase => 'PHRASE',
};
