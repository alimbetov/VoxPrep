from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing retirement anchor in {path}: {old[:180]!r}')
    file.write_text(text.replace(old, new, 1))


# Durable retirement registry ------------------------------------------------
tables = 'mobile/careerspeak_app/lib/data/local/database/careerspeak_sync_metadata_tables.dart'
replace_once(
    tables,
    'class AssetCatalog extends Table {',
    '''class RetiredContentIdentities extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get retiredRevision => integer()();
  TextColumn get reason => text()();
  IntColumn get sourceContentVersion => integer()();
  DateTimeColumn get retiredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentCode, contentType};

  @override
  List<String> get customConstraints => const [
    'CHECK (retired_revision > 0)',
    'CHECK (source_content_version > 0)',
    'CHECK (length(trim(reason)) > 0)',
  ];
}

class AssetCatalog extends Table {''',
)

database = 'mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart'
replace_once(
    database,
    '''    RootLocaleFallbacks,
    AssetCatalog,
''',
    '''    RootLocaleFallbacks,
    RetiredContentIdentities,
    AssetCatalog,
''',
)
replace_once(
    database,
    '''      if (from < 6) {
        await migrator.createTable(rootLocaleFallbacks);
      }
''',
    '''      if (from < 6) {
        await migrator.createTable(rootLocaleFallbacks);
        await migrator.createTable(retiredContentIdentities);
      }
''',
)

# Executor fail-closed retirement checks ------------------------------------
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
    '''    final retired = await (_database.select(
      _database.retiredContentIdentities,
    )..where(
          (row) =>
              row.contentCode.equals(content.identity.code) &
              row.contentType.equals(type),
        ))
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
            'retiredRevision': retired.retiredRevision,
            'retiredContentVersion': retired.sourceContentVersion,
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
        final existingRetirement = await (_database.select(
          _database.retiredContentIdentities,
        )..where(
              (row) =>
                  row.contentCode.equals(tombstone.identity.code) &
                  row.contentType.equals(type),
            ))
            .getSingleOrNull();
        if (existingRetirement == null) {
          await _database
              .into(_database.retiredContentIdentities)
              .insert(
                RetiredContentIdentitiesCompanion.insert(
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
          throw const _SyncExecutorInvariant(
            ApplicationFailure(
              code: 'TOMBSTONE_IMMUTABLE_CONFLICT',
              message:
                  'A retired content identity conflicts with persisted tombstone metadata.',
            ),
          );
        }

        await (_database.update(_database.localContentRecords)..where(
''',
)

# Schema qualification -------------------------------------------------------
db_test = 'mobile/careerspeak_app/test/data/local/database/careerspeak_database_test.dart'
replace_once(
    db_test,
    "        'root_locale_fallbacks',\n        'asset_catalog',",
    "        'root_locale_fallbacks',\n        'retired_content_identities',\n        'asset_catalog',",
)

# Acceptance: fresh install sees retirement before any canonical row --------
acceptance = 'mobile/careerspeak_app/test/acceptance/c1_tombstone_retirement_acceptance_test.dart'
replace_once(
    acceptance,
    '''  );
}

Future<Result<void>> _publish({
''',
    '''  );

  test(
    'fresh install persists tombstone retirement without prior content rows',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'careerspeak-c1-fresh-tombstone-',
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
        runId: 'c1-fresh-tombstone-retire',
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

      final registry = await database
          .select(database.retiredContentIdentities)
          .getSingle();
      expect(registry.contentCode, _identity.code);
      expect(registry.contentType, 'INTERVIEW');
      expect(registry.retiredRevision, 2);
      expect(registry.reason, 'RETIRED');
      expect(registry.sourceContentVersion, 1);

      await database.close();
      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);

      final persistedRegistry = await database
          .select(database.retiredContentIdentities)
          .getSingle();
      expect(persistedRegistry.retiredRevision, 2);
      expect(persistedRegistry.sourceContentVersion, 1);

      final resurrection = await _publish(
        database: database,
        runId: 'c1-fresh-tombstone-resurrection',
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
