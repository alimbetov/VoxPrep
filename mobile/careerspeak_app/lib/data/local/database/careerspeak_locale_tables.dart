import 'package:drift/drift.dart';

class LocaleFallbackRules extends Table {
  TextColumn get locale => text()();

  IntColumn get fallbackOrder => integer().check(fallbackOrder.isBiggerOrEqualValue(0))();

  TextColumn get fallbackLocale => text()();

  IntColumn get sourceContentVersion =>
      integer().check(sourceContentVersion.isBiggerThanValue(0))();

  @override
  Set<Column<Object>> get primaryKey => {locale, fallbackOrder};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {locale, fallbackLocale},
  ];
}
