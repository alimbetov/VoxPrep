import 'package:drift/drift.dart';

class AppPreferences extends Table {
  IntColumn get id => integer()();
  TextColumn get uiLocale => text()();
  TextColumn get translationLocale => text()();
  TextColumn get preferredAccent => text().nullable()();
  TextColumn get themeCode => text()();
  BoolColumn get focusMode => boolean().withDefault(const Constant(false))();
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

class SyncRuns extends Table {
  TextColumn get runId => text()();
  TextColumn get trigger => text()();
  TextColumn get translationLocale => text()();
  IntColumn get fromContentVersion => integer().nullable()();
  IntColumn get targetContentVersion => integer().nullable()();
  IntColumn get targetSchemaVersion => integer().nullable()();
  TextColumn get state => text()();
  BoolColumn get resyncRequested =>
      boolean().withDefault(const Constant(false))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  BoolColumn get retryable => boolean().withDefault(const Constant(false))();
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {runId};

  @override
  List<String> get customConstraints => const ['CHECK (attempt_count >= 0)'];
}

class SyncPackUpdates extends Table {
  TextColumn get runId =>
      text().references(SyncRuns, #runId, onDelete: KeyAction.cascade)();
  TextColumn get packCode => text()();
  TextColumn get variantKey => text()();
  IntColumn get targetRevision => integer()();
  TextColumn get targetChecksum => text()();
  TextColumn get state => text()();
  IntColumn get requiredAssetCount =>
      integer().withDefault(const Constant(0))();
  IntColumn get verifiedAssetCount =>
      integer().withDefault(const Constant(0))();
  TextColumn get errorCode => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {runId, packCode, variantKey};

  @override
  List<String> get customConstraints => const [
    'CHECK (target_revision > 0)',
    'CHECK (required_asset_count >= 0)',
    'CHECK (verified_asset_count >= 0)',
    'CHECK (verified_asset_count <= required_asset_count)',
  ];
}

class SyncTombstones extends Table {
  TextColumn get runId =>
      text().references(SyncRuns, #runId, onDelete: KeyAction.cascade)();
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get revision => integer().nullable()();
  TextColumn get reason => text()();
  TextColumn get state => text()();
  DateTimeColumn get appliedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {runId, contentCode, contentType};
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
