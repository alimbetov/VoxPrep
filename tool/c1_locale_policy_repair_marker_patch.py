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
    Iterable<LocaleFallbackRule> currentLocaleFallbacks =
        const <LocaleFallbackRule>[],
    bool localePolicyRepairRequired = false,
  }) {
''',
)
replace_once(
    models,
    '''    final repairPacks = Set<PackIdentity>.unmodifiable(
      contentPayloadRepairPacks,
    );
''',
    '''    final repairPacks = Set<PackIdentity>.unmodifiable(
      contentPayloadRepairPacks,
    );
    final fallbackRules = List<LocaleFallbackRule>.unmodifiable(
      currentLocaleFallbacks,
    );
    final fallbackRuleLocales = <String>{};
    for (final rule in fallbackRules) {
      if (!fallbackRuleLocales.add(rule.locale)) {
        throw ArgumentError.value(
          rule.locale,
          'currentLocaleFallbacks',
          'contains duplicate requested locale policy',
        );
      }
    }
''',
)
replace_once(
    models,
    '''          packs.isNotEmpty ||
          repairPacks.isNotEmpty) {
        throw ArgumentError(
          'A missing CURRENT root cannot carry checksum, ETag, CURRENT packs, or repair work.',
        );
''',
    '''          packs.isNotEmpty ||
          repairPacks.isNotEmpty ||
          fallbackRules.isNotEmpty ||
          localePolicyRepairRequired) {
        throw ArgumentError(
          'A missing CURRENT root cannot carry checksum, ETag, CURRENT packs, fallback policy, or repair work.',
        );
''',
)
replace_once(
    models,
    '''      currentPacks: packs,
      contentPayloadRepairPacks: repairPacks,
    );
''',
    '''      currentPacks: packs,
      contentPayloadRepairPacks: repairPacks,
      currentLocaleFallbacks: fallbackRules,
      localePolicyRepairRequired: localePolicyRepairRequired,
    );
''',
)
replace_once(
    models,
    '''    required this.currentPacks,
    required this.contentPayloadRepairPacks,
  });
''',
    '''    required this.currentPacks,
    required this.contentPayloadRepairPacks,
    required this.currentLocaleFallbacks,
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

  /// Persisted Backend-owned policy for the CURRENT immutable root. This is
  /// compared with the freshly fetched root so deleted/tampered rows trigger a
  /// same-root repair instead of silently changing fallback behavior.
  final List<LocaleFallbackRule> currentLocaleFallbacks;

  /// True when the CURRENT root predates persisted Backend-owned fallback
  /// policy, the policy marker belongs to another contentVersion, or the local
  /// row ordering/version metadata is internally inconsistent.
  final bool localePolicyRepairRequired;
}
''',
)

journal = 'mobile/careerspeak_app/lib/data/local/drift_sync_journal.dart'
replace_once(
    journal,
    '''      return Success(
        SyncLocalSnapshot(
''',
    '''      var localePolicyRepairRequired =
          currentVersion != null &&
          manifest!.localePolicyContentVersion != currentVersion;
      final currentLocaleFallbacks = <LocaleFallbackRule>[];
      if (currentVersion != null) {
        final policyRows = await (_database.select(_database.localeFallbackRules)
              ..orderBy([
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
''',
)
replace_once(
    journal,
    '''          currentPacks: packs,
          contentPayloadRepairPacks: contentPayloadRepairPacks,
        ),
''',
    '''          currentPacks: packs,
          contentPayloadRepairPacks: contentPayloadRepairPacks,
          currentLocaleFallbacks: currentLocaleFallbacks,
          localePolicyRepairRequired: localePolicyRepairRequired,
        ),
''',
)

planner = 'mobile/careerspeak_app/lib/application/content_sync/content_sync_planner.dart'
replace_once(
    planner,
    '''    final projectionChanged =
        currentVersion == remote.contentVersion &&
        !_samePackProjection(local.currentPacks, remote.packs);
    return Success(
''',
    '''    final projectionChanged =
        currentVersion == remote.contentVersion &&
        !_samePackProjection(local.currentPacks, remote.packs);
    final localePolicyChanged =
        currentVersion == remote.contentVersion &&
        !_sameLocaleFallbackPolicy(
          local.currentLocaleFallbacks,
          remote.localeFallbacks,
        );
    return Success(
''',
)
replace_once(
    planner,
    '''        rootChanged: publicationRootChanged || projectionChanged,
''',
    '''        rootChanged:
            publicationRootChanged ||
            projectionChanged ||
            localePolicyChanged ||
            local.localePolicyRepairRequired,
''',
)
replace_once(
    planner,
    '''bool _samePackProjection(
''',
    '''bool _sameLocaleFallbackPolicy(
  Iterable<LocaleFallbackRule> current,
  Iterable<LocaleFallbackRule> target,
) {
  Map<String, List<String>> normalize(Iterable<LocaleFallbackRule> rules) =>
      <String, List<String>>{
        for (final rule in rules)
          if (rule.fallbackLocales.isNotEmpty)
            rule.locale: rule.fallbackLocales,
      };

  final currentByLocale = normalize(current);
  final targetByLocale = normalize(target);
  if (currentByLocale.length != targetByLocale.length) return false;

  for (final entry in targetByLocale.entries) {
    final installed = currentByLocale[entry.key];
    if (installed == null || installed.length != entry.value.length) {
      return false;
    }
    for (var index = 0; index < installed.length; index += 1) {
      if (installed[index] != entry.value[index]) return false;
    }
  }
  return true;
}

bool _samePackProjection(
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

# Offline reads only trust fallback rows that are part of a committed CURRENT
# policy snapshot. Marker-less/stale rows are corruption, not usable policy.
repository = 'mobile/careerspeak_app/lib/data/local/drift_localized_content_repository.dart'
replace_once(
    repository,
    '''    final rows = await (_database.select(_database.localeFallbackRules)
          ..where((row) => row.locale.equals(locale))
          ..orderBy([(row) => OrderingTerm.asc(row.fallbackOrder)]))
        .get();
    for (var index = 0; index < rows.length; index += 1) {
''',
    '''    final rows = await (_database.select(_database.localeFallbackRules)
          ..where((row) => row.locale.equals(locale))
          ..orderBy([(row) => OrderingTerm.asc(row.fallbackOrder)]))
        .get();
    if (manifest.localePolicyContentVersion != manifest.currentContentVersion) {
      if (rows.isEmpty) {
        return const <String>[];
      }
      throw _LocalizedReadInvariant(
        'Backend fallback rows are not committed for the CURRENT root',
      );
    }
    for (var index = 0; index < rows.length; index += 1) {
''',
)

# Qualify same-root policy corruption repair without adding another schema
# marker. A partial local chain must differ from the immutable backend root and
# therefore force a metadata-only commit.
planner_test = Path(
    'mobile/careerspeak_app/test/application/content_sync/locale_policy_repair_test.dart'
)
planner_text = planner_test.read_text()
planner_anchor = "  test('same root is no-op after policy marker reaches current version', () {\n"
planner_case = '''  test('same root repairs a partially persisted Backend fallback chain', () {
    final pack = PackRevisionRef(
      identity: PackIdentity(code: 'JAVA_SENIOR', variant: 'canonical'),
      revision: 8,
      checksum: _packChecksum,
    );
    final remote = RootContentManifest(
      schemaVersion: 1,
      contentVersion: 108,
      minimumAppContractVersion: 1,
      publishedAt: DateTime.utc(2026, 10, 31, 7),
      checksum: _rootChecksum,
      packs: <PackRevisionRef>[pack],
      localeFallbacks: <LocaleFallbackRule>[
        LocaleFallbackRule(
          locale: 'ru-KZ',
          fallbackLocales: const <String>['ru', 'en'],
        ),
      ],
      tombstones: const <ContentTombstone>[],
    );
    final local = SyncLocalSnapshot(
      currentContentVersion: 108,
      currentManifestChecksum: _rootChecksum,
      etag: 'root-108',
      currentPacks: <PackRevisionRef>[pack],
      currentLocaleFallbacks: <LocaleFallbackRule>[
        LocaleFallbackRule(
          locale: 'ru-KZ',
          fallbackLocales: const <String>['ru'],
        ),
      ],
    );

    final plan = const ContentSyncPlanner()
        .plan(local: local, remote: remote)
        .getOrThrow();

    expect(plan.rootChanged, isTrue);
    expect(plan.changedPacks, isEmpty);
    expect(plan.isNoOp, isFalse);
  });

'''
if planner_case not in planner_text:
    if planner_anchor not in planner_text:
        raise SystemExit('missing policy corruption planner test anchor')
    planner_text = planner_text.replace(planner_anchor, planner_case + planner_anchor, 1)
planner_test.write_text(planner_text)

journal_test = Path(
    'mobile/careerspeak_app/test/data/local/drift_locale_policy_repair_marker_test.dart'
)
journal_text = journal_test.read_text()
journal_anchor = "  test('matching policy marker makes CURRENT root policy complete', () async {\n"
journal_case = '''  test('journal exposes persisted policy chain for immutable-root comparison', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    final now = DateTime.utc(2026, 10, 31, 7);
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
        .into(database.localeFallbackRules)
        .insert(
          LocaleFallbackRulesCompanion.insert(
            locale: 'ru-KZ',
            fallbackOrder: 0,
            fallbackLocale: 'ru',
            sourceContentVersion: 108,
          ),
        );

    final snapshot = (await DriftSyncJournal(database).readLocalSnapshot())
        .getOrThrow();

    expect(snapshot.localePolicyRepairRequired, isFalse);
    expect(snapshot.currentLocaleFallbacks, hasLength(1));
    expect(snapshot.currentLocaleFallbacks.single.locale, 'ru-KZ');
    expect(
      snapshot.currentLocaleFallbacks.single.fallbackLocales,
      <String>['ru'],
    );
  });

'''
if journal_case not in journal_text:
    if journal_anchor not in journal_text:
        raise SystemExit('missing policy journal test anchor')
    journal_text = journal_text.replace(journal_anchor, journal_case + journal_anchor, 1)
journal_test.write_text(journal_text)

policy_test = Path(
    'mobile/careerspeak_app/test/data/local/drift_locale_fallback_policy_test.dart'
)
policy_text = policy_test.read_text()
policy_anchor = "  test('missing Backend rule never invents base-language fallback', () async {\n"
policy_case = '''  test('uncommitted CURRENT-version fallback rows fail closed offline', () async {
    final database = createTestDatabase();
    addTearDown(database.close);
    await _seedCanonicalAndRussian(database, contentVersion: 2);
    await _seedFallback(
      database,
      locale: 'ru-KZ',
      sourceContentVersion: 2,
      fallbackLocales: const <String>['ru', 'en'],
    );

    final result = await DriftLocalizedContentRepository(database).resolve(
      identity: _identity,
      contentRevision: 1,
      requestedLocale: 'ru-KZ',
    );

    expect(result, isA<FailureResult<ResolvedLocalizedContent?>>());
    expect(
      (result as FailureResult<ResolvedLocalizedContent?>).failure.code,
      'LOCALIZED_CONTENT_READ_MODEL_INVALID',
    );
  });

'''
if policy_case not in policy_text:
    if policy_anchor not in policy_text:
        raise SystemExit('missing offline policy marker test anchor')
    policy_text = policy_text.replace(policy_anchor, policy_case + policy_anchor, 1)
policy_test.write_text(policy_text)
