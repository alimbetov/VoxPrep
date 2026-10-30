import 'package:drift/drift.dart';

class PackContentRefs extends Table {
  TextColumn get packCode => text()();
  TextColumn get variantKey => text()();
  IntColumn get packRevision => integer()();
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get contentRevision => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    packCode,
    variantKey,
    packRevision,
    contentCode,
    contentType,
    contentRevision,
  };

  @override
  List<String> get customConstraints => const [
    'CHECK (pack_revision > 0)',
    'CHECK (content_revision > 0)',
  ];
}

class AssetCatalog extends Table {
  TextColumn get assetId => text()();
  TextColumn get checksumSha256 => text()();
  TextColumn get assetKind => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get durationMs => integer().nullable()();
  TextColumn get deliveryKey => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {assetId};

  @override
  List<String> get customConstraints => const [
    'CHECK (size_bytes > 0)',
    'CHECK (duration_ms IS NULL OR duration_ms >= 0)',
  ];
}

class ContentAssetRefs extends Table {
  TextColumn get contentCode => text()();
  TextColumn get contentType => text()();
  IntColumn get contentRevision => integer()();
  TextColumn get assetId =>
      text().references(AssetCatalog, #assetId, onDelete: KeyAction.restrict)();
  TextColumn get assetRole => text()();
  BoolColumn get requiredOffline =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {
    contentCode,
    contentType,
    contentRevision,
    assetId,
    assetRole,
  };

  @override
  List<String> get customConstraints => const ['CHECK (content_revision > 0)'];
}

class PackAssetRefs extends Table {
  TextColumn get packCode => text()();
  TextColumn get variantKey => text()();
  IntColumn get packRevision => integer()();
  TextColumn get assetId =>
      text().references(AssetCatalog, #assetId, onDelete: KeyAction.restrict)();
  BoolColumn get requiredOffline =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {
    packCode,
    variantKey,
    packRevision,
    assetId,
  };

  @override
  List<String> get customConstraints => const ['CHECK (pack_revision > 0)'];
}
