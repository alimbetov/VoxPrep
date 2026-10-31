from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if old not in text:
        raise SystemExit(f'missing anchor in {path}: {old[:160]!r}')
    file.write_text(text.replace(old, new, 1))


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
    '''    final retiredSnapshot =
        await (_database.select(_database.localContentRecords)..where(
              (row) =>
                  row.contentCode.equals(content.identity.code) &
                  row.contentType.equals(type) &
                  row.snapshotState.equals('TOMBSTONED'),
            )..limit(1))
            .getSingleOrNull();
    final retiredJournal =
        await (_database.select(_database.syncTombstones)..where(
              (row) =>
                  row.contentCode.equals(content.identity.code) &
                  row.contentType.equals(type) &
                  row.state.equals(SyncTombstoneState.applied.storageCode),
            )..limit(1))
            .getSingleOrNull();
    if (retiredSnapshot != null || retiredJournal != null) {
      throw _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_IDENTITY_RETIRED',
          message: 'A tombstoned content identity cannot be republished.',
          details: <String, Object?>{
            'contentCode': content.identity.code,
            'contentType': type,
            'incomingRevision': content.revision,
            'retiredRevision':
                retiredSnapshot?.revision ?? retiredJournal?.revision,
          },
        ),
      );
    }
''',
)

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

      final applied = await (database.select(database.syncTombstones)..where(
            (row) =>
                row.contentCode.equals(_identity.code) &
                row.contentType.equals('INTERVIEW'),
          ))
          .getSingle();
      expect(applied.state, SyncTombstoneState.applied.storageCode);
      expect(applied.revision, 2);

      await database.close();
      database = CareerSpeakDatabase(NativeDatabase(file));
      addTearDown(database.close);

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
