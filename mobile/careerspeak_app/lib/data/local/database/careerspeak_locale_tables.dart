import 'package:drift/drift.dart';

/// Backend-owned deterministic locale fallback policy for the CURRENT root.
///
/// Rows are ordered per requested locale and tagged with the publication
/// contentVersion that supplied the rule. Flutter applies this order verbatim;
/// it never derives a base-language fallback itself.
class LocaleFallbackRules extends Table {
  TextColumn get locale => text()();
  IntColumn get fallbackOrder => integer()();
  TextColumn get fallbackLocale => text()();
  IntColumn get sourceContentVersion => integer()();

  @override
  Set<Column<Object>> get primaryKey => {locale, fallbackOrder};

  @override
  List<String> get customConstraints => const [
    'UNIQUE(locale, fallback_locale)',
    'CHECK (length(trim(locale)) > 0)',
    'CHECK (fallback_order >= 0)',
    'CHECK (length(trim(fallback_locale)) > 0)',
    'CHECK (source_content_version > 0)',
  ];
}
