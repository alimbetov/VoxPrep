from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if old not in text:
        raise SystemExit(f'missing C1.6/C1.7 patch anchor in {path}: {old[:180]}')
    file.write_text(text.replace(old, new, 1))


executor = 'mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart'
replace_once(
    executor,
    """    final type = _contentTypeToStorage(content.identity.type);
    final existing =
""",
    """    final type = _contentTypeToStorage(content.identity.type);
    final tombstonedIdentity =
        await (_database.select(_database.localContentRecords)..where(
              (row) =>
                  row.contentCode.equals(content.identity.code) &
                  row.contentType.equals(type) &
                  row.snapshotState.equals('TOMBSTONED'),
            ))
            .get();
    if (tombstonedIdentity.isNotEmpty) {
      throw _SyncExecutorInvariant(
        ApplicationFailure(
          code: 'CONTENT_IDENTITY_TOMBSTONED',
          message:
              'A tombstoned content business identity cannot be published again.',
          details: <String, Object?>{
            'contentCode': content.identity.code,
            'contentType': type,
            'incomingRevision': content.revision,
            'tombstonedRevisions': tombstonedIdentity
                .map((row) => row.revision)
                .toList(growable: false),
          },
        ),
      );
    }

    final existing =
""",
)

executor_test = 'mobile/careerspeak_app/test/data/local/drift_sync_plan_executor_test.dart'
replace_once(
    executor_test,
    """  test('payload mismatch fails before any local pack staging', () async {
    final target = _targetPack();
    final root = _root(contentVersion: 109, pack: target);
    final plan = const ContentSyncPlanner()
        .plan(
          local: SyncLocalSnapshot(
            currentContentVersion: null,
            currentManifestChecksum: null,
            etag: null,
            currentPacks: const <PackRevisionRef>[],
          ),
          remote: root,
        )
        .getOrThrow();
    final journal = DriftSyncJournal(database, now: () => now);
    await _prepareRun(journal, plan);

    final executor = DriftSyncPlanExecutor(
      database,
      _PackGateway(_packManifest(target)),
      const _PayloadGateway(mismatched: true),
      now: () => now,
    );
    final result = await executor.execute(runId: 'run-1', plan: plan);

    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure.code,
      'CONTENT_PAYLOAD_MISMATCH',
    );
    expect(await database.select(database.contentPackRevisions).get(), isEmpty);
    expect(await database.select(database.localContentRecords).get(), isEmpty);
    expect(await database.select(database.contentCatalogReads).get(), isEmpty);
  });
""",
    """  test('payload mismatch fails before any local pack staging', () async {
    final target = _targetPack();
    final root = _root(contentVersion: 109, pack: target);
    final plan = const ContentSyncPlanner()
        .plan(
          local: SyncLocalSnapshot(
            currentContentVersion: null,
            currentManifestChecksum: null,
            etag: null,
            currentPacks: const <PackRevisionRef>[],
          ),
          remote: root,
        )
        .getOrThrow();
    final journal = DriftSyncJournal(database, now: () => now);
    await _prepareRun(journal, plan);

    final executor = DriftSyncPlanExecutor(
      database,
      _PackGateway(_packManifest(target)),
      const _PayloadGateway(mismatched: true),
      now: () => now,
    );
    final result = await executor.execute(runId: 'run-1', plan: plan);

    expect(result, isA<FailureResult<void>>());
    expect(
      (result as FailureResult<void>).failure.code,
      'CONTENT_PAYLOAD_MISMATCH',
    );
    expect(await database.select(database.contentPackRevisions).get(), isEmpty);
    expect(await database.select(database.localContentRecords).get(), isEmpty);
    expect(await database.select(database.contentCatalogReads).get(), isEmpty);
  });

  test(
    'tombstoned business identity rejects a newer revision before staging',
    () async {
      final identity = ContentIdentity(
        code: 'JAVA_Q_001',
        type: ContentType.interview,
      );
      await database
          .into(database.localContentRecords)
          .insert(
            LocalContentRecordsCompanion.insert(
              contentCode: identity.code,
              contentType: 'INTERVIEW',
              revision: 1,
              checksum: _contentHash,
              snapshotState: 'TOMBSTONED',
              sourceSchemaVersion: 1,
              createdAt: now,
            ),
          );

      final target = PackRevisionRef(
        identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
        revision: 9,
        checksum: _packHash,
      );
      final manifest = PackContentManifest(
        schemaVersion: 1,
        identity: target.identity,
        revision: target.revision,
        checksum: target.checksum,
        contents: <PackContentRef>[
          PackContentRef(
            identity: identity,
            revision: 2,
            checksum: _assetHash,
            sortOrder: 1,
            publishedAt: now,
          ),
        ],
        assets: const <ManifestAssetDescriptor>[],
        contentAssets: const <ContentAssetRef>[],
      );
      final root = _root(contentVersion: 109, pack: target);
      final plan = const ContentSyncPlanner()
          .plan(
            local: SyncLocalSnapshot(
              currentContentVersion: null,
              currentManifestChecksum: null,
              etag: null,
              currentPacks: const <PackRevisionRef>[],
            ),
            remote: root,
          )
          .getOrThrow();
      final journal = DriftSyncJournal(database, now: () => now);
      await _prepareRun(journal, plan);

      final result = await DriftSyncPlanExecutor(
        database,
        _PackGateway(manifest),
        const _PayloadGateway(),
        now: () => now,
      ).execute(runId: 'run-1', plan: plan);

      expect(result, isA<FailureResult<void>>());
      expect(
        (result as FailureResult<void>).failure.code,
        'CONTENT_IDENTITY_TOMBSTONED',
      );
      final rows = await (database.select(database.localContentRecords)..where(
            (row) =>
                row.contentCode.equals(identity.code) &
                row.contentType.equals('INTERVIEW'),
          ))
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.revision, 1);
      expect(rows.single.snapshotState, 'TOMBSTONED');
      expect(
        await database.select(database.contentPackRevisions).get(),
        isEmpty,
      );
    },
  );
""",
)
