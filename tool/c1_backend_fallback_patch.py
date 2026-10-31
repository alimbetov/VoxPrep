from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    p = Path(path)
    text = p.read_text()
    if new in text:
        return
    if old not in text:
        raise SystemExit(f'missing backend-fallback anchor in {path}: {old[:220]}')
    p.write_text(text.replace(old, new, 1))


# Domain root contract -------------------------------------------------------
manifest = 'mobile/careerspeak_app/lib/application/content_delivery/content_manifest.dart'
replace_once(
    manifest,
    'final class RootContentManifest {',
    '''final class LocaleFallbackRule {
  factory LocaleFallbackRule({
    required String locale,
    required Iterable<String> fallbackLocales,
  }) {
    final normalizedLocale = _canonicalizeLocale(locale, 'locale');
    final fallbacks = fallbackLocales
        .map((value) => _canonicalizeLocale(value, 'fallbackLocales'))
        .toList(growable: false);
    final seen = <String>{normalizedLocale};
    for (final fallback in fallbacks) {
      if (!seen.add(fallback)) {
        throw ArgumentError.value(
          fallback,
          'fallbackLocales',
          'contains a duplicate or the requested locale',
        );
      }
    }
    final englishIndex = fallbacks.indexOf('en');
    if (englishIndex >= 0 && englishIndex != fallbacks.length - 1) {
      throw ArgumentError.value(
        fallbacks,
        'fallbackLocales',
        'canonical English must be terminal',
      );
    }

    return LocaleFallbackRule._(
      locale: normalizedLocale,
      fallbackLocales: List<String>.unmodifiable(fallbacks),
    );
  }

  const LocaleFallbackRule._({
    required this.locale,
    required this.fallbackLocales,
  });

  final String locale;
  final List<String> fallbackLocales;
}

final class RootContentManifest {''',
)
replace_once(
    manifest,
    '''    required Iterable<PackRevisionRef> packs,
    required Iterable<ContentTombstone> tombstones,
  }) {
    final packList = List<PackRevisionRef>.unmodifiable(packs);
    final tombstoneList = List<ContentTombstone>.unmodifiable(tombstones);
    _requireUniquePackIdentities(packList);
    _requireUniqueTombstoneIdentities(tombstoneList);
''',
    '''    required Iterable<PackRevisionRef> packs,
    Iterable<LocaleFallbackRule> localeFallbacks = const <LocaleFallbackRule>[],
    required Iterable<ContentTombstone> tombstones,
  }) {
    final packList = List<PackRevisionRef>.unmodifiable(packs);
    final fallbackList = List<LocaleFallbackRule>.unmodifiable(localeFallbacks);
    final tombstoneList = List<ContentTombstone>.unmodifiable(tombstones);
    _requireUniquePackIdentities(packList);
    _requireUniqueLocaleFallbacks(fallbackList);
    _requireUniqueTombstoneIdentities(tombstoneList);
''',
)
replace_once(
    manifest,
    '''      checksum: normalizeSha256(checksum, 'checksum'),
      packs: packList,
      tombstones: tombstoneList,
''',
    '''      checksum: normalizeSha256(checksum, 'checksum'),
      packs: packList,
      localeFallbacks: fallbackList,
      tombstones: tombstoneList,
''',
)
replace_once(
    manifest,
    '''    required this.checksum,
    required this.packs,
    required this.tombstones,
''',
    '''    required this.checksum,
    required this.packs,
    required this.localeFallbacks,
    required this.tombstones,
''',
)
replace_once(
    manifest,
    '''  final String checksum;
  final List<PackRevisionRef> packs;
  final List<ContentTombstone> tombstones;
''',
    '''  final String checksum;
  final List<PackRevisionRef> packs;
  final List<LocaleFallbackRule> localeFallbacks;
  final List<ContentTombstone> tombstones;
''',
)
replace_once(
    manifest,
    "final _deliverySegmentPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');",
    """final _deliverySegmentPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]*$');
final _alphaPattern = RegExp(r'^[A-Za-z]+$');""",
)
replace_once(
    manifest,
    '''String _requireOpaqueId(String value, String fieldName) {''',
    '''String _canonicalizeLocale(String value, String fieldName) {
  final normalized = _requireLocale(value, fieldName);
  final parts = normalized.split('-');
  final result = <String>[parts.first.toLowerCase()];
  for (final part in parts.skip(1)) {
    if (part.length == 2 && _alphaPattern.hasMatch(part)) {
      result.add(part.toUpperCase());
    } else if (part.length == 4 && _alphaPattern.hasMatch(part)) {
      result.add(
        '${part.substring(0, 1).toUpperCase()}${part.substring(1).toLowerCase()}',
      );
    } else {
      result.add(part.toLowerCase());
    }
  }
  return result.join('-');
}

String _requireOpaqueId(String value, String fieldName) {''',
)
replace_once(
    manifest,
    '''void _requireUniqueTombstoneIdentities(List<ContentTombstone> tombstones) {''',
    '''void _requireUniqueLocaleFallbacks(List<LocaleFallbackRule> rules) {
  final locales = <String>{};
  for (final rule in rules) {
    if (!locales.add(rule.locale)) {
      throw ArgumentError.value(
        rule.locale,
        'localeFallbacks',
        'contains duplicate locale fallback rule',
      );
    }
  }
}

void _requireUniqueTombstoneIdentities(List<ContentTombstone> tombstones) {''',
)

# Wire decoder ---------------------------------------------------------------
decoder = 'mobile/careerspeak_app/lib/data/remote/content_manifest_decoder.dart'
replace_once(
    decoder,
    '''      final tombstones = <ContentTombstoneDto>[];
''',
    '''      final localeFallbacks = <LocaleFallbackRuleDto>[];
      final fallbackValues = object.containsKey('localeFallbacks')
          ? _list(object, 'localeFallbacks', r'$.localeFallbacks')
          : const <Object?>[];
      for (var index = 0; index < fallbackValues.length; index += 1) {
        final path = '\\$.localeFallbacks[$index]';
        final rule = _object(fallbackValues[index], path);
        final values = _list(rule, 'fallbackLocales', '$path.fallbackLocales');
        final fallbacks = <String>[];
        for (var fallbackIndex = 0;
            fallbackIndex < values.length;
            fallbackIndex += 1) {
          final fallbackPath = '$path.fallbackLocales[$fallbackIndex]';
          final value = values[fallbackIndex];
          if (value is! String || !_localePattern.hasMatch(value.trim())) {
            throw _ContractViolation(
              fallbackPath,
              'must be a BCP-47-compatible locale',
            );
          }
          fallbacks.add(value.trim());
        }
        localeFallbacks.add(
          LocaleFallbackRuleDto(
            locale: _locale(rule, 'locale', '$path.locale'),
            fallbackLocales: List<String>.unmodifiable(fallbacks),
          ),
        );
      }

      final tombstones = <ContentTombstoneDto>[];
''',
)
replace_once(
    decoder,
    '''        checksum: _string(object, 'checksum', r'$.checksum'),
        packs: packs,
        tombstones: tombstones,
''',
    '''        checksum: _string(object, 'checksum', r'$.checksum'),
        packs: packs,
        localeFallbacks: localeFallbacks,
        tombstones: tombstones,
''',
)

# Drift schema v6 ------------------------------------------------------------
tables = 'mobile/careerspeak_app/lib/data/local/database/careerspeak_sync_metadata_tables.dart'
replace_once(
    tables,
    'class AssetCatalog extends Table {',
    '''class RootLocaleFallbacks extends Table {
  IntColumn get contentVersion => integer()();
  TextColumn get locale => text()();
  IntColumn get position => integer()();
  TextColumn get fallbackLocale => text()();

  @override
  Set<Column<Object>> get primaryKey => {contentVersion, locale, position};

  @override
  List<String> get customConstraints => const [
    'CHECK (content_version > 0)',
    'CHECK (position >= 0)',
    'CHECK (length(trim(locale)) > 0)',
    'CHECK (length(trim(fallback_locale)) > 0)',
  ];
}

class AssetCatalog extends Table {''',
)

database = 'mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart'
replace_once(
    database,
    '''    PackLocalizationRefs,
    AssetCatalog,
''',
    '''    PackLocalizationRefs,
    RootLocaleFallbacks,
    AssetCatalog,
''',
)
replace_once(database, 'int get schemaVersion => 5;', 'int get schemaVersion => 6;')
replace_once(
    database,
    '''      if (from < 5) {
        await migrator.createTable(packLocalizationRefs);
        await migrator.createTable(localizedContentReads);
      }
''',
    '''      if (from < 5) {
        await migrator.createTable(packLocalizationRefs);
        await migrator.createTable(localizedContentReads);
      }
      if (from < 6) {
        await migrator.createTable(rootLocaleFallbacks);
      }
''',
)

# Persist fallback metadata atomically with the root -------------------------
executor = 'mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart'
replace_once(
    executor,
    '''      await _database
          .into(_database.contentManifestStates)
''',
    '''      await (_database.delete(_database.rootLocaleFallbacks)..where(
            (row) => row.contentVersion.equals(plan.target.contentVersion),
          ))
          .go();
      for (final rule in plan.target.localeFallbacks) {
        for (var position = 0;
            position < rule.fallbackLocales.length;
            position += 1) {
          await _database
              .into(_database.rootLocaleFallbacks)
              .insert(
                RootLocaleFallbacksCompanion.insert(
                  contentVersion: plan.target.contentVersion,
                  locale: rule.locale,
                  position: position,
                  fallbackLocale: rule.fallbackLocales[position],
                ),
              );
        }
      }

      await _database
          .into(_database.contentManifestStates)
''',
)

# Read Backend-owned fallback metadata offline -------------------------------
repository = 'mobile/careerspeak_app/lib/data/local/drift_localized_content_repository.dart'
replace_once(
    repository,
    "import '../../domain/content_identity.dart';",
    """import '../../domain/application_preferences.dart';
import '../../domain/content_identity.dart';""",
)
replace_once(
    repository,
    '''    final LocaleFallbackPlan fallback;
    try {
      fallback = LocaleFallbackPlan(requestedLocale);
    } on FormatException {
      return FailureResult<ResolvedLocalizedContent?>(
        ApplicationFailure(
          code: 'LOCALE_INVALID',
          message: 'Requested localization locale is invalid.',
          details: <String, Object?>{'requestedLocale': requestedLocale},
        ),
      );
    }

    try {
      final canonical = await _readCanonical(
''',
    '''    final String normalizedRequestedLocale;
    try {
      normalizedRequestedLocale = LocaleCode.canonicalize(requestedLocale);
    } on FormatException {
      return FailureResult<ResolvedLocalizedContent?>(
        ApplicationFailure(
          code: 'LOCALE_INVALID',
          message: 'Requested localization locale is invalid.',
          details: <String, Object?>{'requestedLocale': requestedLocale},
        ),
      );
    }

    try {
      final configuredFallbacks = await _readConfiguredFallbacks(
        normalizedRequestedLocale,
      );
      final LocaleFallbackPlan fallback;
      try {
        fallback = LocaleFallbackPlan(
          requestedLocale: normalizedRequestedLocale,
          configuredFallbackLocales: configuredFallbacks,
        );
      } on FormatException catch (error) {
        throw _LocalizedReadInvariant(
          'persisted Backend fallback chain is invalid: ${error.message}',
        );
      }

      final canonical = await _readCanonical(
''',
)
replace_once(
    repository,
    '''  Future<_CanonicalProjection?> _readCanonical({''',
    '''  Future<List<String>> _readConfiguredFallbacks(String locale) async {
    if (locale == LocaleFallbackPlan.canonicalEnglishLocale) {
      return const <String>[];
    }

    final manifest = await (_database.select(_database.contentManifestStates)
          ..where((row) => row.id.equals(1)))
        .getSingleOrNull();
    if (manifest == null || manifest.currentContentVersion <= 0) {
      return const <String>[];
    }

    final rows = await (_database.select(_database.rootLocaleFallbacks)
          ..where(
            (row) =>
                row.contentVersion.equals(manifest.currentContentVersion) &
                row.locale.equals(locale),
          )
          ..orderBy([(row) => OrderingTerm.asc(row.position)]))
        .get();
    for (var index = 0; index < rows.length; index += 1) {
      if (rows[index].position != index) {
        throw _LocalizedReadInvariant(
          'Backend fallback chain for $locale has a non-contiguous position',
        );
      }
    }
    return List<String>.unmodifiable(
      rows.map((row) => row.fallbackLocale),
    );
  }

  Future<_CanonicalProjection?> _readCanonical({''',
)

# Database test / production workflow ---------------------------------------
db_test = 'mobile/careerspeak_app/test/data/local/database/careerspeak_database_test.dart'
replace_once(
    db_test,
    "test('schema version 5 creates the production content foundation', () async {",
    "test('schema version 6 creates the production content foundation', () async {",
)
replace_once(db_test, 'expect(database.schemaVersion, 5);', 'expect(database.schemaVersion, 6);')
replace_once(
    db_test,
    "expect(userVersion.read<int>('user_version'), 5);",
    "expect(userVersion.read<int>('user_version'), 6);",
)
replace_once(
    db_test,
    "        'pack_localization_refs',\n        'asset_catalog',",
    "        'pack_localization_refs',\n        'root_locale_fallbacks',\n        'asset_catalog',",
)

workflow = '.github/workflows/flutter-production-adapters.yml'
replace_once(workflow, 'drift_schemas/drift_schema_v5.json', 'drift_schemas/drift_schema_v6.json')
replace_once(
    workflow,
    '''            drift_schemas/drift_schema_v5.json \\
            test/generated_migrations
''',
    '''            drift_schemas/drift_schema_v5.json \\
            drift_schemas/drift_schema_v6.json \\
            test/generated_migrations
''',
)

# OpenAPI -------------------------------------------------------------------
openapi = 'contracts/learner-api-v1.yaml'
replace_once(openapi, 'version: 1.1.0', 'version: 1.2.0')
replace_once(
    openapi,
    '''        - packs
        - tombstones
''',
    '''        - packs
        - localeFallbacks
        - tombstones
''',
)
replace_once(
    openapi,
    '''        packs:
          type: array
          items:
            $ref: '#/components/schemas/PackRevisionRef'
        tombstones:
''',
    '''        packs:
          type: array
          items:
            $ref: '#/components/schemas/PackRevisionRef'
        localeFallbacks:
          type: array
          description: >-
            Backend-owned deterministic fallback chains. Flutter applies this
            order and must not derive fallback locales from BCP-47 tags.
          items:
            $ref: '#/components/schemas/LocaleFallbackRule'
        tombstones:
''',
)
replace_once(
    openapi,
    '''    ContentTombstone:
''',
    '''    LocaleFallbackRule:
      type: object
      additionalProperties: false
      required:
        - locale
        - fallbackLocales
      properties:
        locale:
          $ref: '#/components/schemas/LocaleCode'
        fallbackLocales:
          type: array
          uniqueItems: true
          description: >-
            Ordered Backend-owned fallbacks. Canonical English, when present,
            must be terminal.
          items:
            $ref: '#/components/schemas/LocaleCode'

    ContentTombstone:
''',
)

# Contract baseline should explicitly freeze the fallback shape.
baseline = 'mobile/careerspeak_app/test/contracts/openapi_contract_baseline_test.dart'
replace_once(
    baseline,
    "      'RootContentManifest:',\n      'PackContentManifest:',",
    "      'RootContentManifest:',\n      'LocaleFallbackRule:',\n      'localeFallbacks:',\n      'fallbackLocales:',\n      'PackContentManifest:',",
)
