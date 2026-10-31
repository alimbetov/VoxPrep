import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'asset_cache_retention_schema_v10.dart';
import 'careerspeak_assessment_tables.dart';
import 'careerspeak_content_read_tables.dart';
import 'careerspeak_locale_tables.dart';
import 'careerspeak_retirement_tables.dart';
import 'careerspeak_sync_metadata_tables.dart';
import 'careerspeak_tables.dart';
import 'universal_catalogue_schema_v9.dart';

part 'careerspeak_database.g.dart';

@DriftDatabase(
  tables: [
    AppPreferences,
    InstallationRuntimeStates,
    ContentManifestStates,
    SyncRuns,
    SyncPackUpdates,
    SyncTombstones,
    ContentPackRevisions,
    LocalContentRecords,
    PackContentRefs,
    PackLocalizationRefs,
    LocaleFallbackRules,
    ContentRetirements,
    AssetCatalog,
    ContentAssetRefs,
    PackAssetRefs,
    ContentCatalogReads,
    TypedContentReads,
    LocalizedContentReads,
    AssessmentQuestionReads,
    PracticeTestRevisionReads,
    PracticeTestQuestionRefs,
    Favorites,
    ContentLearningStates,
  ],
)
final class CareerSpeakDatabase extends _$CareerSpeakDatabase {
  CareerSpeakDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'careerspeak'));

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createUniversalCatalogueSchemaV9();
      await _createAssetCacheRetentionSchemaV10();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(syncRuns);
        await migrator.createTable(syncPackUpdates);
        await migrator.createTable(syncTombstones);
      }
      if (from < 3) {
        await migrator.createTable(packContentRefs);
        await migrator.createTable(assetCatalog);
        await migrator.createTable(contentAssetRefs);
        await migrator.createTable(packAssetRefs);
      }
      if (from < 4) {
        await migrator.createTable(contentCatalogReads);
      }
      if (from < 5) {
        await migrator.createTable(packLocalizationRefs);
        await migrator.createTable(localizedContentReads);
      }
      if (from < 6) {
        await migrator.addColumn(
          contentManifestStates,
          contentManifestStates.localePolicyContentVersion,
        );
        await migrator.createTable(localeFallbackRules);
        await migrator.createTable(contentRetirements);

        // Reconstruct one permanent retirement fact per stable business
        // identity from all surviving v5 evidence. Highest retired revision wins;
        // for the same revision an APPLIED journal row wins over a synthetic
        // LEGACY_TOMBSTONE reason because it preserves Backend audit metadata.
        await customStatement('''
          WITH retirement_evidence AS (
            SELECT
              local.content_code AS content_code,
              local.content_type AS content_type,
              MAX(local.revision) AS retired_revision,
              'LEGACY_TOMBSTONE' AS reason,
              COALESCE(
                NULLIF((
                  SELECT current_content_version
                  FROM content_manifest_states
                  WHERE id = 1
                ), 0),
                1
              ) AS source_content_version,
              MAX(local.created_at) AS retired_at,
              0 AS evidence_priority
            FROM local_content_records local
            WHERE local.snapshot_state = 'TOMBSTONED'
            GROUP BY local.content_code, local.content_type

            UNION ALL

            SELECT
              st.content_code AS content_code,
              st.content_type AS content_type,
              COALESCE(NULLIF(st.revision, 0), 1) AS retired_revision,
              st.reason AS reason,
              COALESCE(
                NULLIF(sr.target_content_version, 0),
                NULLIF((
                  SELECT current_content_version
                  FROM content_manifest_states
                  WHERE id = 1
                ), 0),
                1
              ) AS source_content_version,
              COALESCE(st.applied_at, sr.updated_at) AS retired_at,
              1 AS evidence_priority
            FROM sync_tombstones st
            INNER JOIN sync_runs sr ON sr.run_id = st.run_id
            WHERE st.state = 'APPLIED'
          ),
          ranked_retirements AS (
            SELECT
              content_code,
              content_type,
              retired_revision,
              reason,
              source_content_version,
              retired_at,
              ROW_NUMBER() OVER (
                PARTITION BY content_code, content_type
                ORDER BY
                  retired_revision DESC,
                  evidence_priority DESC,
                  retired_at DESC
              ) AS retirement_rank
            FROM retirement_evidence
          )
          INSERT INTO content_retirements (
            content_code,
            content_type,
            retired_revision,
            reason,
            source_content_version,
            retired_at
          )
          SELECT
            content_code,
            content_type,
            retired_revision,
            reason,
            source_content_version,
            retired_at
          FROM ranked_retirements
          WHERE retirement_rank = 1
        ''');
      }
      if (from < 7) {
        await migrator.createTable(typedContentReads);
      }
      if (from < 8) {
        await migrator.createTable(assessmentQuestionReads);
        await migrator.createTable(practiceTestRevisionReads);
        await migrator.createTable(practiceTestQuestionRefs);
      }
      if (from < 9 && to >= 9) {
        await _createUniversalCatalogueSchemaV9();
      }
      if (from < 10 && to >= 10) {
        await _createAssetCacheRetentionSchemaV10();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createUniversalCatalogueSchemaV9() async {
    for (final statement in universalCatalogueSchemaV9Statements) {
      await customStatement(statement);
    }
  }

  Future<void> _createAssetCacheRetentionSchemaV10() async {
    for (final statement in assetCacheRetentionSchemaV10Statements) {
      await customStatement(statement);
    }
  }
}
