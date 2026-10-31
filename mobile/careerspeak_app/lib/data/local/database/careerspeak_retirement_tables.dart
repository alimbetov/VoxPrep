import 'package:drift/drift.dart';

/// Durable business-identity retirement ledger.
///
/// Unlike SyncTombstones this table is not owned by a sync run. Once a content
/// identity is retired, later journal cleanup cannot make that identity
/// publishable again.
class ContentRetirements extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get retiredRevision =>
      integer().check(retiredRevision.isBiggerThanValue(0))();
  TextColumn get reason => text()();
  IntColumn get sourceContentVersion =>
      integer().check(sourceContentVersion.isBiggerThanValue(0))();
  DateTimeColumn get retiredAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentCode, contentType};

  @override
  List<String> get customConstraints => const [
    'CHECK (length(trim(content_code)) > 0)',
    'CHECK (length(trim(content_type)) > 0)',
    'CHECK (length(trim(reason)) > 0)',
  ];
}
