from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing locale-policy repair anchor in {path}: {old[:220]}')
    file.write_text(text.replace(old, new, 1))


tables = 'mobile/careerspeak_app/lib/data/local/database/careerspeak_tables.dart'
replace_once(
    tables,
    '''  TextColumn get currentManifestChecksum => text()();
  IntColumn get remoteContentVersionSeen => integer().nullable()();
''',
    '''  TextColumn get currentManifestChecksum => text()();
  IntColumn get localePolicyContentVersion => integer().nullable()();
  IntColumn get remoteContentVersionSeen => integer().nullable()();
''',
)

database = 'mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart'
replace_once(
    database,
    '''      if (from < 6) {
        await migrator.createTable(localeFallbackRules);
        await migrator.createTable(contentRetirements);
''',
    '''      if (from < 6) {
        await migrator.addColumn(
          contentManifestStates,
          contentManifestStates.localePolicyContentVersion,
        );
        await migrator.createTable(localeFallbackRules);
        await migrator.createTable(contentRetirements);
''',
)

models = 'mobile/careerspeak_app/lib/application/content_sync/sync_models.dart'
replace_once(
    models,
    '''    Iterable<PackIdentity> contentPayloadRepairPacks = const <PackIdentity>[],
  }) {
''',
    '''    Iterable<PackIdentity> contentPayloadRepairPacks = const <PackIdentity>[],
    bool localePolicyRepairRequired = false,
  }) {
''',
)
replace_once(
    models,
    '''          repairPacks.isNotEmpty) {
        throw ArgumentError(
          'A missing CURRENT root cannot carry checksum, ETag, CURRENT packs, or repair work.',
        );
''',
    '''          repairPacks.isNotEmpty ||
          localePolicyRepairRequired) {
        throw ArgumentError(
          'A missing CURRENT root cannot carry checksum, ETag, CURRENT packs, or repair work.',
        );
''',
)
replace_once(
    models,
    '''      contentPayloadRepairPacks: repairPacks,
    );
''',
    '''      contentPayloadRepairPacks: repairPacks,
      localePolicyRepairRequired: localePolicyRepairRequired,
    );
''',
)
replace_once(
    models,
    '''    required this.contentPayloadRepairPacks,
  });
''',
    '''    required this.contentPayloadRepairPacks,
    required this.localePolicyRepairRequired,
  });
''',
)
replace_once(
    models,
    '''  final Set<PackIdentity> contentPayloadRepairPacks;
}
''',
    '''  final Set<PackIdentity> contentPayloadRepairPacks;

  /// True when the CURRENT root predates persisted Backend-owned fallback
  /// policy or the policy marker belongs to another contentVersion.
  final bool localePolicyRepairRequired;
}
''',
)

journal = 'mobile/careerspeak_app/lib/data/local/drift_sync_journal.dart'
replace_once(
    journal,
    '''          currentPacks: packs,
          contentPayloadRepairPacks: contentPayloadRepairPacks,
        ),
''',
    '''          currentPacks: packs,
          contentPayloadRepairPacks: contentPayloadRepairPacks,
          localePolicyRepairRequired:
              currentVersion != null &&
              manifest!.localePolicyContentVersion != currentVersion,
        ),
''',
)

planner = 'mobile/careerspeak_app/lib/application/content_sync/content_sync_planner.dart'
replace_once(
    planner,
    '''        rootChanged: publicationRootChanged || projectionChanged,
''',
    '''        rootChanged:
            publicationRootChanged ||
            projectionChanged ||
            local.localePolicyRepairRequired,
''',
)

executor = 'mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart'
replace_once(
    executor,
    '''              currentManifestChecksum: plan.target.checksum,
              remoteContentVersionSeen: Value(plan.target.contentVersion),
''',
    '''              currentManifestChecksum: plan.target.checksum,
              localePolicyContentVersion: Value(plan.target.contentVersion),
              remoteContentVersionSeen: Value(plan.target.contentVersion),
''',
)
