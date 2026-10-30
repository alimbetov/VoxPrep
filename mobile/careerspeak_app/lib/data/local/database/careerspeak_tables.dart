import 'package:drift/drift.dart';

class AppPreferences extends Table {
  IntColumn get id => integer()();
  TextColumn get uiLocale => text()();
  TextColumn get translationLocale => text()();
  TextColumn get preferredAccent => text().nullable()();
  TextColumn get themeCode => text()();
  BoolColumn get focusMode =>
      boolean().withDefault(const Constant(false))();
  IntColumn get storageQuotaBytes => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const ['CHECK (id = 1)'];
}

class InstallationRuntimeStates extends Table {
  IntColumn get id => integer()();
  TextColumn get registrationState => text()();
  DateTimeColumn get lastRegistrationAt => dateTime().nullable()();
  DateTimeColumn get lastTokenRefreshAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  TextColumn get lastErrorCode => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const ['CHECK (id = 1)'];
}

class ContentManifestStates extends Table {
  IntColumn get id => integer()();
  IntColumn get schemaVersion => integer()();
  IntColumn get currentContentVersion => integer()();
  TextColumn get currentManifestChecksum => text()();
  IntColumn get remoteContentVersionSeen => integer().nullable()();
  TextColumn get remoteManifestChecksum => text().nullable()();
  TextColumn get etag => text().nullable()();
  DateTimeColumn get lastCheckedAt => dateTime().nullable()();
  DateTimeColumn get lastSuccessfulSyncAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const ['CHECK (id = 1)'];
}

class ContentPackRevisions extends Table {
  TextColumn get packCode => text()();
  TextColumn get variantKey => text()();
  IntColumn get revision => integer()();
  IntColumn get schemaVersion => integer()();
  TextColumn get checksum => text()();
  TextColumn get state => text()();
  IntColumn get sourceContentVersion => integer()();
  DateTimeColumn get stagedAt => dateTime()();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  DateTimeColumn get currentAt => dateTime().nullable()();
  DateTimeColumn get supersededAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {packCode, variantKey, revision};
}

class LocalContentRecords extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get revision => integer()();
  TextColumn get checksum => text()();
  IntColumn get sortOrder => integer().nullable()();
  DateTimeColumn get publishedAt => dateTime().nullable()();
  TextColumn get snapshotState => text()();
  IntColumn get sourceSchemaVersion => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentCode, contentType, revision};
}

class Favorites extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentCode, contentType};
}

class ContentLearningStates extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  DateTimeColumn get listenedAt => dateTime().nullable()();
  IntColumn get listenCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get lastPositionMs => integer().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get completionSource => text().nullable()();
  IntColumn get lastRevisionSeen => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {contentCode, contentType};
}
