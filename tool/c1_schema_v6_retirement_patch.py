from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing C1 schema-v6 retirement anchor in {path}: {old[:220]}')
    file.write_text(text.replace(old, new, 1))


# Final schema v6 contains both Backend fallback policy and the permanent
# content retirement registry. v6 has not been accepted/shipped yet, so these
# belong in one migration rather than creating an artificial v7.
database = 'mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart'
replace_once(
    database,
    "import 'careerspeak_content_read_tables.dart';\n",
    """import 'careerspeak_content_read_tables.dart';
import 'careerspeak_locale_tables.dart';
import 'careerspeak_retirement_tables.dart';
""",
)
replace_once(
    database,
    '''    PackLocalizationRefs,
    AssetCatalog,
''',
    '''    PackLocalizationRefs,
    LocaleFallbackRules,
    ContentRetirements,
    AssetCatalog,
''',
)
replace_once(
    database,
    '''      if (from < 5) {
        await migrator.createTable(packLocalizationRefs);
        await migrator.createTable(localizedContentReads);
      }
''',
    """      if (from < 5) {
        await migrator.createTable(packLocalizationRefs);
        await migrator.createTable(localizedContentReads);
      }
      if (from < 6) {
        await migrator.createTable(localeFallbackRules);
        await migrator.createTable(contentRetirements);

        // Preserve already-applied retirement facts when upgrading a v2-v5
        // installation. The sync journal is evidence, not the permanent owner.
        await customStatement('''
          INSERT OR IGNORE INTO content_retirements (
            content_code,
            content_type,
            retired_revision,
            reason,
            source_content_version,
            retired_at
          )
          SELECT
            st.content_code,
            st.content_type,
            COALESCE(NULLIF(st.revision, 0), 1),
            st.reason,
            COALESCE(
              NULLIF(sr.target_content_version, 0),
              NULLIF((
                SELECT current_content_version
                FROM content_manifest_states
                WHERE id = 1
              ), 0),
              1
            ),
            COALESCE(st.applied_at, sr.updated_at)
          FROM sync_tombstones st
          INNER JOIN sync_runs sr ON sr.run_id = st.run_id
          WHERE st.state = 'APPLIED'
        ''');

        // Older local snapshots may contain the retired marker even if their
        // journal row was pruned or damaged. Preserve the identity fail-closed.
        await customStatement('''
          INSERT OR IGNORE INTO content_retirements (
            content_code,
            content_type,
            retired_revision,
            reason,
            source_content_version,
            retired_at
          )
          SELECT
            local.content_code,
            local.content_type,
            local.revision,
            'LEGACY_TOMBSTONE',
            COALESCE(
              NULLIF((
                SELECT current_content_version
                FROM content_manifest_states
                WHERE id = 1
              ), 0),
              1
            ),
            local.created_at
          FROM local_content_records local
          WHERE local.snapshot_state = 'TOMBSTONED'
        ''');
      }
""",
)

executor = 'mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart'
replace_once(
    executor,
    '''    final retired =
        await (_database.select(_database.localContentRecords)..where(
              (row) =>
                  row.contentCode.equals(content.identity.code) &
                  row.contentType.equals(type) &
                  row.snapshotState.equals('TOMBSTONED'),
            )..limit(1))
            .getSingleOrNull();
    if (retired != null) {
      throw _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_IDENTITY_RETIRED',
          message: 'A tombstoned content identity cannot be republished.',
          details: <String, Object?>{
            'contentCode': content.identity.code,
            'contentType': type,
            'incomingRevision': content.revision,
            'retiredRevision': retired.revision,
          },
        ),
      );
    }
''',
    '''    final retirement =
        await (_database.select(_database.contentRetirements)..where(
              (row) =>
                  row.contentCode.equals(content.identity.code) &
                  row.contentType.equals(type),
            ))
            .getSingleOrNull();
    final legacyRetired =
        await (_database.select(_database.localContentRecords)..where(
              (row) =>
                  row.contentCode.equals(content.identity.code) &
                  row.contentType.equals(type) &
                  row.snapshotState.equals('TOMBSTONED'),
            )..limit(1))
            .getSingleOrNull();
    if (retirement != null || legacyRetired != null) {
      throw _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_IDENTITY_RETIRED',
          message: 'A tombstoned content identity cannot be republished.',
          details: <String, Object?>{
            'contentCode': content.identity.code,
            'contentType': type,
            'incomingRevision': content.revision,
            'retiredRevision':
                retirement?.retiredRevision ?? legacyRetired?.revision,
          },
        ),
      );
    }
''',
)
replace_once(
    executor,
    '''      for (final tombstone in plan.tombstones) {
        final type = _contentTypeToStorage(tombstone.identity.type);
        await (_database.update(_database.localContentRecords)..where(
''',
    '''      for (final tombstone in plan.tombstones) {
        final type = _contentTypeToStorage(tombstone.identity.type);
        final existingRetirement =
            await (_database.select(_database.contentRetirements)..where(
                  (row) =>
                      row.contentCode.equals(tombstone.identity.code) &
                      row.contentType.equals(type),
                ))
                .getSingleOrNull();
        if (existingRetirement == null) {
          await _database
              .into(_database.contentRetirements)
              .insert(
                ContentRetirementsCompanion.insert(
                  contentCode: tombstone.identity.code,
                  contentType: type,
                  retiredRevision: tombstone.revision,
                  reason: tombstone.reason,
                  sourceContentVersion: plan.target.contentVersion,
                  retiredAt: now,
                ),
              );
        } else if (existingRetirement.retiredRevision != tombstone.revision ||
            existingRetirement.reason != tombstone.reason) {
          throw _SyncExecutorInvariant(
            ApplicationFailure(
              code: 'CONTENT_RETIREMENT_IMMUTABLE_CONFLICT',
              message:
                  'A retired content identity received conflicting tombstone metadata.',
              details: <String, Object?>{
                'contentCode': tombstone.identity.code,
                'contentType': type,
                'existingRevision': existingRetirement.retiredRevision,
                'incomingRevision': tombstone.revision,
              },
            ),
          );
        }

        await (_database.update(_database.localContentRecords)..where(
''',
)

# Fresh schema acceptance includes both v6 metadata tables.
db_test = 'mobile/careerspeak_app/test/data/local/database/careerspeak_database_test.dart'
replace_once(
    db_test,
    "        'locale_fallback_rules',\n        'asset_catalog',",
    "        'locale_fallback_rules',\n        'content_retirements',\n        'asset_catalog',",
)

# Migration assertions use the real table names and verify no retirement is
# invented when historical data contains none.
migration = Path(
    'mobile/careerspeak_app/test/data/local/database/careerspeak_database_migration_test.dart'
)
text = migration.read_text().replace(
    'migratedDatabase.rootLocaleFallbacks',
    'migratedDatabase.localeFallbackRules',
)
if 'migratedDatabase.contentRetirements' not in text:
    marker = '''    expect(
      await migratedDatabase.select(migratedDatabase.localeFallbackRules).get(),
      isEmpty,
    );
'''
    replacement = marker + '''    expect(
      await migratedDatabase.select(migratedDatabase.contentRetirements).get(),
      isEmpty,
    );
'''
    if marker not in text:
        raise SystemExit('missing migration v6 empty metadata marker')
    text = text.replace(marker, replacement)
migration.write_text(text)

# Fresh-install retirement acceptance: no prior local content row is required.
acceptance = 'mobile/careerspeak_app/test/acceptance/c1_tombstone_retirement_acceptance_test.dart'
replace_once(
    acceptance,
    '''  );
}

Future<Result<void>> _publish({
''',
    '''  );

  test(
    'fresh install persists retirement without a prior content row',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-c1-fresh-retirement-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final file = File('${directory.path}/careerspeak.sqlite');

      var database = CareerSpeakDatabase(NativeDatabase(file));
      final retired = await _publish(
        database: database,
        runId: 'fresh-retire',
        root: _root(
          contentVersion: 1,
          checksum: _rootV1,
          tombstones: <ContentTombstone>[
            ContentTombstone(
              identity: _identity,
              revision: 2,
              reason: 'RETIRED',
            ),
          ],
        ),
      );
      expect(retired, isA<Success<void>>());
      expect(await database.select(database.localContentRecords).get(), isEmpty);
      final retirement = await database
          .select(database.contentRetirements)
          .getSingle();
      expect(retirement.contentCode, _identity.code);
      expect(retirement.retiredRevision, 2);
      expect(retirement.sourceContentVersion, 1);

      await database.close();
      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);

      final resurrection = await _publish(
        database: database,
        runId: 'fresh-resurrection',
        root: _root(
          contentVersion: 2,
          checksum: _rootV2,
          pack: _packRef(revision: 1, checksum: _packV1),
        ),
        pack: _packManifest(
          packRevision: 1,
          packChecksum: _packV1,
          contentRevision: 3,
          contentChecksum: _contentV1,
        ),
        payload: _payload(
          revision: 3,
          checksum: _contentV1,
          title: 'Fresh-install resurrection attempt',
        ),
      );

      expect(resurrection, isA<FailureResult<void>>());
      expect(
        (resurrection as FailureResult<void>).failure.code,
        'CONTENT_IDENTITY_RETIRED',
      );
      expect(await database.select(database.localContentRecords).get(), isEmpty);
      expect(await database.select(database.contentRetirements).get(), hasLength(1));
      final manifest = await database
          .select(database.contentManifestStates)
          .getSingle();
      expect(manifest.currentContentVersion, 1);
      expect(manifest.currentManifestChecksum, _rootV1);
    },
  );
}

Future<Result<void>> _publish({
''',
)
