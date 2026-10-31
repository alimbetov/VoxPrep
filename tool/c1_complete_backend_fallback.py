from pathlib import Path
import re


def sub_once(path: str, pattern: str, replacement: str, *, flags: int = 0) -> None:
    file = Path(path)
    text = file.read_text()
    updated, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise SystemExit(f'expected one match in {path}, got {count}: {pattern[:120]}')
    file.write_text(updated)


manifest = 'mobile/careerspeak_app/lib/application/content_delivery/content_manifest.dart'
sub_once(
    manifest,
    r"import '../../domain/content_identity\.dart';",
    "import '../../domain/application_preferences.dart';\nimport '../../domain/content_identity.dart';",
)
sub_once(
    manifest,
    r'final class ContentTombstone \{',
    '''final class LocaleFallbackRule {
  factory LocaleFallbackRule({
    required String locale,
    required Iterable<String> fallbackLocales,
  }) {
    final normalizedLocale = LocaleCode.canonicalize(locale);
    final normalizedFallbacks = fallbackLocales
        .map(LocaleCode.canonicalize)
        .toList(growable: false);
    final seen = <String>{normalizedLocale};
    for (final fallback in normalizedFallbacks) {
      if (!seen.add(fallback)) {
        throw ArgumentError.value(
          fallback,
          'fallbackLocales',
          'must not contain the requested locale or duplicates',
        );
      }
    }
    final englishIndex = normalizedFallbacks.indexOf('en');
    if (englishIndex >= 0 && englishIndex != normalizedFallbacks.length - 1) {
      throw ArgumentError.value(
        normalizedFallbacks,
        'fallbackLocales',
        'canonical English must be terminal when configured',
      );
    }
    return LocaleFallbackRule._(
      locale: normalizedLocale,
      fallbackLocales: List<String>.unmodifiable(normalizedFallbacks),
    );
  }

  const LocaleFallbackRule._({
    required this.locale,
    required this.fallbackLocales,
  });

  final String locale;
  final List<String> fallbackLocales;
}

final class ContentTombstone {''',
)
sub_once(
    manifest,
    r'''required Iterable<PackRevisionRef> packs,\n\s*required Iterable<ContentTombstone> tombstones,''',
    '''required Iterable<PackRevisionRef> packs,
    Iterable<LocaleFallbackRule> localeFallbacks = const <LocaleFallbackRule>[],
    required Iterable<ContentTombstone> tombstones,''',
)
sub_once(
    manifest,
    r'''final packList = List<PackRevisionRef>\.unmodifiable\(packs\);\n\s*final tombstoneList = List<ContentTombstone>\.unmodifiable\(tombstones\);\n\s*_requireUniquePackIdentities\(packList\);\n\s*_requireUniqueTombstoneIdentities\(tombstoneList\);''',
    '''final packList = List<PackRevisionRef>.unmodifiable(packs);
    final fallbackList = List<LocaleFallbackRule>.unmodifiable(localeFallbacks);
    final tombstoneList = List<ContentTombstone>.unmodifiable(tombstones);
    _requireUniquePackIdentities(packList);
    _requireUniqueLocaleFallbackRules(fallbackList);
    _requireUniqueTombstoneIdentities(tombstoneList);''',
)
sub_once(
    manifest,
    r'''packs: packList,\n\s*tombstones: tombstoneList,''',
    '''packs: packList,
      localeFallbacks: fallbackList,
      tombstones: tombstoneList,''',
)
sub_once(
    manifest,
    r'''required this\.packs,\n\s*required this\.tombstones,''',
    '''required this.packs,
    required this.localeFallbacks,
    required this.tombstones,''',
)
sub_once(
    manifest,
    r'''final List<PackRevisionRef> packs;\n\s*final List<ContentTombstone> tombstones;''',
    '''final List<PackRevisionRef> packs;
  final List<LocaleFallbackRule> localeFallbacks;
  final List<ContentTombstone> tombstones;''',
)
sub_once(
    manifest,
    r'void _requireUniqueTombstoneIdentities\(List<ContentTombstone> tombstones\) \{',
    '''void _requireUniqueLocaleFallbackRules(List<LocaleFallbackRule> rules) {
  final locales = <String>{};
  for (final rule in rules) {
    if (!locales.add(rule.locale)) {
      throw ArgumentError.value(
        rule.locale,
        'localeFallbacks',
        'contains duplicate requested locale',
      );
    }
  }
}

void _requireUniqueTombstoneIdentities(List<ContentTombstone> tombstones) {''',
)


decoder = 'mobile/careerspeak_app/lib/data/remote/content_manifest_decoder.dart'
sub_once(
    decoder,
    r'''\n\s*final tombstones = <ContentTombstoneDto>\[\];''',
    '''

      final localeFallbacks = <LocaleFallbackRuleDto>[];
      final fallbackRuleValues = object['localeFallbacks'] == null
          ? const <Object?>[]
          : _list(object, 'localeFallbacks', r'$.localeFallbacks');
      for (var index = 0; index < fallbackRuleValues.length; index += 1) {
        final path = '\\$.localeFallbacks[$index]';
        final rule = _object(fallbackRuleValues[index], path);
        final fallbackValues = _list(
          rule,
          'fallbackLocales',
          '$path.fallbackLocales',
        );
        final fallbacks = <String>[];
        for (var fallbackIndex = 0;
            fallbackIndex < fallbackValues.length;
            fallbackIndex += 1) {
          final fallbackPath = '$path.fallbackLocales[$fallbackIndex]';
          final value = fallbackValues[fallbackIndex];
          if (value is! String || value.trim().isEmpty) {
            throw _ContractViolation(fallbackPath, 'must be a locale string');
          }
          final normalized = value.trim();
          if (!_localePattern.hasMatch(normalized)) {
            throw _ContractViolation(
              fallbackPath,
              'must be a BCP-47-compatible locale',
            );
          }
          fallbacks.add(normalized);
        }
        localeFallbacks.add(
          LocaleFallbackRuleDto(
            locale: _locale(rule, 'locale', '$path.locale'),
            fallbackLocales: List<String>.unmodifiable(fallbacks),
          ),
        );
      }

      final tombstones = <ContentTombstoneDto>[];''',
)
sub_once(
    decoder,
    r'''packs: packs,\n\s*tombstones: tombstones,''',
    '''packs: packs,
        localeFallbacks: localeFallbacks,
        tombstones: tombstones,''',
)


materializer = 'mobile/careerspeak_app/lib/application/content_sync/root_manifest_materializer.dart'
sub_once(
    materializer,
    r'''final fallback = LocaleFallbackPlan\(locale\.code\);''',
    '''LocaleFallbackRule? fallbackRule;
    for (final rule in root.localeFallbacks) {
      if (rule.locale == locale.code) {
        fallbackRule = rule;
        break;
      }
    }
    final fallback = LocaleFallbackPlan(
      requestedLocale: locale.code,
      configuredFallbackLocales:
          fallbackRule?.fallbackLocales ?? const <String>[],
    );''',
)
sub_once(
    materializer,
    r'''packs: packs,\n\s*tombstones: root\.tombstones,''',
    '''packs: packs,
        localeFallbacks: root.localeFallbacks,
        tombstones: root.tombstones,''',
)


api = 'contracts/learner-api-v1.yaml'
sub_once(
    api,
    r'''    ContentTombstone:\n''',
    '''    LocaleFallbackRule:
      type: object
      additionalProperties: false
      description: >-
        Backend-owned ordered fallback locales for one requested locale.
        The requested locale itself is implicit. Canonical English is always
        the final product fallback and may be omitted or terminal in the list.
      required:
        - locale
        - fallbackLocales
      properties:
        locale:
          $ref: '#/components/schemas/LocaleCode'
        fallbackLocales:
          type: array
          uniqueItems: true
          items:
            $ref: '#/components/schemas/LocaleCode'

    ContentTombstone:
''',
)
sub_once(
    api,
    r'''(        packs:\n          type: array\n          items:\n            \$ref: '#/components/schemas/PackRevisionRef'\n)(        tombstones:)''',
    r'''\1        localeFallbacks:
          type: array
          description: >-
            Backend-owned fallback policy. Omitted or empty means exact locale
            then canonical English.
          default: []
          items:
            $ref: '#/components/schemas/LocaleFallbackRule'
\2''',
)


executor = 'mobile/careerspeak_app/lib/data/local/drift_sync_plan_executor.dart'
sub_once(
    executor,
    r'''\n\s*await _database\n\s*\.into\(_database\.contentManifestStates\)''',
    '''

      await _database.delete(_database.localeFallbackRules).go();
      for (final rule in plan.target.localeFallbacks) {
        for (var index = 0; index < rule.fallbackLocales.length; index += 1) {
          await _database.into(_database.localeFallbackRules).insert(
            LocaleFallbackRulesCompanion.insert(
              locale: rule.locale,
              fallbackOrder: index,
              fallbackLocale: rule.fallbackLocales[index],
              sourceContentVersion: plan.target.contentVersion,
            ),
          );
        }
      }

      await _database
          .into(_database.contentManifestStates)''',
)


resolver = 'mobile/careerspeak_app/lib/data/local/drift_localized_content_repository.dart'
sub_once(
    resolver,
    r'''final LocaleFallbackPlan fallback;\n\s*try \{\n\s*fallback = LocaleFallbackPlan\(requestedLocale\);\n\s*\} on FormatException \{''',
    '''final LocaleFallbackPlan exactFallback;
    try {
      exactFallback = LocaleFallbackPlan(requestedLocale: requestedLocale);
    } on FormatException {''',
)
sub_once(
    resolver,
    r'''try \{\n\s*final canonical = await _readCanonical\(''',
    '''try {
      final fallback = await _readFallbackPlan(exactFallback.requestedLocale);
      final canonical = await _readCanonical(''',
)
sub_once(
    resolver,
    r'''\n\s*Future<_CanonicalProjection\?> _readCanonical\(\{''',
    '''

  Future<LocaleFallbackPlan> _readFallbackPlan(String requestedLocale) async {
    final rows = await (_database.select(_database.localeFallbackRules)
          ..where((row) => row.locale.equals(requestedLocale))
          ..orderBy([(row) => OrderingTerm.asc(row.fallbackOrder)]))
        .get();
    if (rows.isEmpty) {
      return LocaleFallbackPlan(requestedLocale: requestedLocale);
    }

    final manifest = await (_database.select(_database.contentManifestStates)
          ..where((row) => row.id.equals(1)))
        .getSingleOrNull();
    if (manifest == null ||
        rows.any(
          (row) => row.sourceContentVersion != manifest.currentContentVersion,
        )) {
      throw const _LocalizedReadInvariant(
        'locale fallback policy does not belong to the CURRENT root snapshot',
      );
    }

    try {
      return LocaleFallbackPlan(
        requestedLocale: requestedLocale,
        configuredFallbackLocales: rows.map((row) => row.fallbackLocale),
      );
    } on FormatException {
      throw const _LocalizedReadInvariant(
        'persisted locale fallback policy is invalid',
      );
    }
  }

  Future<_CanonicalProjection?> _readCanonical({''',
)


fallback_test = 'mobile/careerspeak_app/test/data/local/drift_localized_content_repository_test.dart'
sub_once(
    fallback_test,
    r'''test\('exact locale overlays language fallback field by field', \(\) async \{''',
    '''test('exact locale overlays configured fallback field by field', () async {
    await _seedFallback(
      database,
      locale: 'ru-KZ',
      fallbacks: const <String>['ru', 'en'],
    );''',
)
sub_once(
    fallback_test,
    r'''test\(\n\s*'superseded exact locale is ignored and language fallback wins',\n\s*\(\) async \{''',
    '''test(
    'superseded exact locale is ignored and configured fallback wins',
    () async {
      await _seedFallback(
        database,
        locale: 'ru-KZ',
        fallbacks: const <String>['ru', 'en'],
      );''',
)
text_path = Path(fallback_test)
text = text_path.read_text().replace(
    'LocaleFallbackKind.language',
    'LocaleFallbackKind.configured',
)
marker = 'Future<void> _seedCanonical(CareerSpeakDatabase database) async {'
helper = '''Future<void> _seedFallback(
  CareerSpeakDatabase database, {
  required String locale,
  required List<String> fallbacks,
}) async {
  await database.into(database.contentManifestStates).insertOnConflictUpdate(
    ContentManifestStatesCompanion.insert(
      id: const Value(1),
      schemaVersion: 1,
      currentContentVersion: 1,
      currentManifestChecksum: _canonicalChecksum,
      remoteContentVersionSeen: const Value(1),
      remoteManifestChecksum: const Value(_canonicalChecksum),
      updatedAt: DateTime.utc(2026, 10, 31, 4),
    ),
  );
  for (var index = 0; index < fallbacks.length; index += 1) {
    await database.into(database.localeFallbackRules).insert(
      LocaleFallbackRulesCompanion.insert(
        locale: locale,
        fallbackOrder: index,
        fallbackLocale: fallbacks[index],
        sourceContentVersion: 1,
      ),
    );
  }
}

'''
if marker not in text:
    raise SystemExit(f'fallback helper marker missing: {fallback_test}')
text_path.write_text(text.replace(marker, helper + marker, 1))


restart = 'mobile/careerspeak_app/test/acceptance/c1_locale_offline_restart_acceptance_test.dart'
restart_path = Path(restart)
restart_text = restart_path.read_text()
restart_text = restart_text.replace(
    'AppTranslationLocale.russian',
    "AppTranslationLocale('ru-KZ')",
    1,
).replace(
    "expect(restored.translationLocale.code, 'ru');",
    "expect(restored.translationLocale.code, 'ru-KZ');",
    1,
).replace(
    "expect(russian!.resolvedLocale, 'ru');",
    "expect(russian!.resolvedLocale, 'ru');\n      expect(russian.fallbackKind, LocaleFallbackKind.configured);",
    1,
).replace(
    "      expect(russian.fallbackKind, LocaleFallbackKind.exact);\n",
    '',
    1,
)
needle = "    packs: <PackRevisionRef>[canonicalRef, russianRef],\n    tombstones: const <ContentTombstone>[],"
replacement = "    packs: <PackRevisionRef>[canonicalRef, russianRef],\n    localeFallbacks: <LocaleFallbackRule>[\n      LocaleFallbackRule(\n        locale: 'ru-KZ',\n        fallbackLocales: const <String>['ru', 'en'],\n      ),\n    ],\n    tombstones: const <ContentTombstone>[],"
if needle not in restart_text:
    raise SystemExit('restart root fallback anchor missing')
restart_path.write_text(restart_text.replace(needle, replacement, 1))
