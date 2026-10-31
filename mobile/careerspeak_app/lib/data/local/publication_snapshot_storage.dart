import 'database/careerspeak_database.dart';

/// Durable auxiliary storage for C4 publication membership that intentionally
/// does not alter the accepted Drift v8 generated schema baseline.
///
/// Tables are created idempotently on first C4 use over the same SQLite
/// connection. They contain only immutable snapshot membership/cache data;
/// learner visibility is still fenced by ContentManifestStates.currentContentVersion.
final class PublicationSnapshotStorage {
  const PublicationSnapshotStorage(this._database);

  final CareerSpeakDatabase _database;

  Future<void> ensureReady() async {
    await _database.customStatement('''
      CREATE TABLE IF NOT EXISTS publication_practice_test_refs (
        content_version INTEGER NOT NULL,
        practice_test_code TEXT NOT NULL,
        revision INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        PRIMARY KEY (content_version, practice_test_code),
        CHECK (content_version > 0),
        CHECK (revision > 0),
        CHECK (length(trim(practice_test_code)) > 0),
        CHECK (length(trim(checksum)) = 64)
      )
    ''');
    await _database.customStatement('''
      CREATE TABLE IF NOT EXISTS publication_catalogue_refs (
        content_version INTEGER NOT NULL,
        catalogue_kind TEXT NOT NULL,
        revision INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        PRIMARY KEY (content_version, catalogue_kind),
        CHECK (content_version > 0),
        CHECK (revision > 0),
        CHECK (length(trim(catalogue_kind)) > 0),
        CHECK (length(trim(checksum)) = 64)
      )
    ''');
    await _database.customStatement('''
      CREATE TABLE IF NOT EXISTS catalogue_revision_reads (
        catalogue_kind TEXT NOT NULL,
        revision INTEGER NOT NULL,
        checksum TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        PRIMARY KEY (catalogue_kind, revision),
        CHECK (revision > 0),
        CHECK (length(trim(catalogue_kind)) > 0),
        CHECK (length(trim(checksum)) = 64),
        CHECK (length(trim(payload_json)) > 0)
      )
    ''');
  }
}
