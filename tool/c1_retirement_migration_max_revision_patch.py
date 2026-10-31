from pathlib import Path

path = Path('mobile/careerspeak_app/lib/data/local/database/careerspeak_database.dart')
text = path.read_text()

sync_marker = '        // Preserve already-applied retirement facts'
local_marker = '        // Older local snapshots may contain the retired marker'

sync_start = text.find(sync_marker)
local_start = text.find(local_marker)
if sync_start < 0 or local_start < 0:
    raise SystemExit('missing legacy retirement migration markers')

start = min(sync_start, local_start)
second = max(sync_start, local_start)
block_end = text.find('      }\n', second)
if block_end < 0:
    raise SystemExit('missing v6 migration block footer')

replacement = """        // Reconstruct one permanent retirement fact per stable business
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
"""

text = text[:start] + replacement + text[block_end:]
path.write_text(text)
