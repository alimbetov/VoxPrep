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

class LocalizedContentReads extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get contentRevision => integer()();
  TextColumn get locale => text()();
  IntColumn get localizationRevision => integer()();
  TextColumn get checksum => text()();
  TextColumn get title => text().nullable()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get translation => text().nullable()();
  TextColumn get hint => text().nullable()();
  TextColumn get explanation => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {
    contentCode,
    contentType,
    contentRevision,
    locale,
    localizationRevision,
  };

  @override
  List<String> get customConstraints => const [
    'CHECK (content_revision > 0)',
    'CHECK (localization_revision > 0)',
    'CHECK (length(trim(locale)) > 0)',
    'CHECK (length(trim(checksum)) > 0)',
    'CHECK (title IS NULL OR length(trim(title)) > 0)',
    'CHECK (subtitle IS NULL OR length(trim(subtitle)) > 0)',
    'CHECK (description IS NULL OR length(trim(description)) > 0)',
    'CHECK (translation IS NULL OR length(trim(translation)) > 0)',
    'CHECK (hint IS NULL OR length(trim(hint)) > 0)',
    'CHECK (explanation IS NULL OR length(trim(explanation)) > 0)',
    'CHECK (title IS NOT NULL OR subtitle IS NOT NULL OR description IS NOT NULL OR translation IS NOT NULL OR hint IS NOT NULL OR explanation IS NOT NULL)',
  ];
}
