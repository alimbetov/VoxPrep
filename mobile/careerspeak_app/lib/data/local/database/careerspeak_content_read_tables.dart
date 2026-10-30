import 'package:drift/drift.dart';

class ContentCatalogReads extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get revision => integer()();
  TextColumn get checksum => text()();
  TextColumn get title => text()();
  TextColumn get subtitle => text()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  TextColumn get level => text()();
  IntColumn get minutes => integer()();
  BoolColumn get hasAudio => boolean()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentCode, contentType, revision};

  @override
  List<String> get customConstraints => const [
    'CHECK (revision > 0)',
    'CHECK (minutes > 0)',
    'CHECK (length(trim(title)) > 0)',
    'CHECK (length(trim(category)) > 0)',
    'CHECK (length(trim(level)) > 0)',
  ];
}
